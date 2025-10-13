import { db, commonbase, embeddings, CommonbaseEntry, NewCommonbaseEntry } from './db';
import { generateEmbedding } from './embeddings';
import { parseFile, ParsedFile } from './file-parser';
import { eq, desc, sql, ilike, or } from 'drizzle-orm';

export class CommonbaseService {
  static async addEntry(data: string, metadata: any = {}, embedding?: number[]): Promise<CommonbaseEntry> {
    try {
      // Create new entry
      const entryValues: NewCommonbaseEntry = {
        data,
        metadata,
      };

      const [newEntry] = await db
        .insert(commonbase)
        .values(entryValues)
        .returning();

      // Generate or use provided embedding
      try {
        let finalEmbedding: number[];

        if (embedding && Array.isArray(embedding) && embedding.length === 1536) {
          finalEmbedding = embedding;
        } else {
          finalEmbedding = await generateEmbedding(data);
        }

        await db.insert(embeddings).values({
          id: newEntry.id,
          embedding: finalEmbedding,
        });
      } catch (embeddingError) {
        console.error('Failed to process embedding:', embeddingError);
        // Continue without embedding rather than failing completely
      }

      return newEntry;
    } catch (error) {
      console.error('Error adding entry:', error);
      throw error;
    }
  }

  static async addFileEntry(filePath: string): Promise<CommonbaseEntry> {
    try {
      const parsedFile = await parseFile(filePath);

      // Create entry with file content and metadata
      return await this.addEntry(parsedFile.content, parsedFile.metadata);
    } catch (error) {
      console.error('Error adding file entry:', error);
      throw error;
    }
  }

  static async getEntry(id: string): Promise<CommonbaseEntry | null> {
    try {
      const [entry] = await db
        .select()
        .from(commonbase)
        .where(eq(commonbase.id, id))
        .limit(1);

      return entry || null;
    } catch (error) {
      console.error('Error getting entry:', error);
      throw error;
    }
  }

  static async updateEntry(id: string, data?: string, metadata?: any): Promise<CommonbaseEntry | null> {
    try {
      const updates: Partial<NewCommonbaseEntry> = {
        updated: new Date(),
      };

      if (data !== undefined) {
        updates.data = data;
      }
      if (metadata !== undefined) {
        updates.metadata = metadata;
      }

      const [updatedEntry] = await db
        .update(commonbase)
        .set(updates)
        .where(eq(commonbase.id, id))
        .returning();

      // Regenerate embedding if data was updated
      if (data !== undefined) {
        try {
          const newEmbedding = await generateEmbedding(data);
          await db
            .update(embeddings)
            .set({ embedding: newEmbedding })
            .where(eq(embeddings.id, id));
        } catch (embeddingError) {
          console.error('Failed to update embedding:', embeddingError);
        }
      }

      return updatedEntry || null;
    } catch (error) {
      console.error('Error updating entry:', error);
      throw error;
    }
  }

  static async deleteEntry(id: string): Promise<boolean> {
    try {
      const result = await db
        .delete(commonbase)
        .where(eq(commonbase.id, id))
        .returning();

      return result.length > 0;
    } catch (error) {
      console.error('Error deleting entry:', error);
      throw error;
    }
  }

  static async listEntries(offset = 0, limit = 50): Promise<CommonbaseEntry[]> {
    try {
      const entries = await db
        .select()
        .from(commonbase)
        .orderBy(desc(commonbase.created))
        .offset(offset)
        .limit(limit);

      return entries;
    } catch (error) {
      console.error('Error listing entries:', error);
      throw error;
    }
  }

  static async searchEntries(query: string, limit = 20): Promise<CommonbaseEntry[]> {
    try {
      // Full-text search using PostgreSQL
      const entries = await db
        .select()
        .from(commonbase)
        .where(
          or(
            ilike(commonbase.data, `%${query}%`),
            sql`${commonbase.metadata}::text ILIKE ${`%${query}%`}`
          )
        )
        .orderBy(desc(commonbase.created))
        .limit(limit);

      return entries;
    } catch (error) {
      console.error('Error searching entries:', error);
      throw error;
    }
  }

  static async semanticSearch(query: string, limit = 20): Promise<CommonbaseEntry[]> {
    try {
      // Generate embedding for the query
      const queryEmbedding = await generateEmbedding(query);

      // Use pgvector similarity search
      const results = await db
        .select({
          id: commonbase.id,
          data: commonbase.data,
          metadata: commonbase.metadata,
          created: commonbase.created,
          updated: commonbase.updated,
          similarity: sql<number>`1 - (${embeddings.embedding} <=> ${JSON.stringify(queryEmbedding)})`,
        })
        .from(commonbase)
        .innerJoin(embeddings, eq(commonbase.id, embeddings.id))
        .orderBy(sql`${embeddings.embedding} <=> ${JSON.stringify(queryEmbedding)}`)
        .limit(limit);

      return results;
    } catch (error) {
      console.error('Error in semantic search:', error);
      throw error;
    }
  }

  static async getRandomEntries(limit = 10): Promise<CommonbaseEntry[]> {
    try {
      const entries = await db
        .select()
        .from(commonbase)
        .orderBy(sql`RANDOM()`)
        .limit(limit);

      return entries;
    } catch (error) {
      console.error('Error getting random entries:', error);
      throw error;
    }
  }

  static async linkEntries(parentId: string, childId: string): Promise<void> {
    try {
      // Update parent's metadata to include child in links
      const [parent] = await db
        .select()
        .from(commonbase)
        .where(eq(commonbase.id, parentId));

      if (parent) {
        const currentLinks = parent.metadata?.links || [];
        await db
          .update(commonbase)
          .set({
            metadata: {
              ...parent.metadata,
              links: [...new Set([...currentLinks, childId])],
            },
            updated: new Date(),
          })
          .where(eq(commonbase.id, parentId));
      }

      // Update child's metadata to include parent in backlinks
      const [child] = await db
        .select()
        .from(commonbase)
        .where(eq(commonbase.id, childId));

      if (child) {
        const currentBacklinks = child.metadata?.backlinks || [];
        await db
          .update(commonbase)
          .set({
            metadata: {
              ...child.metadata,
              backlinks: [...new Set([...currentBacklinks, parentId])],
            },
            updated: new Date(),
          })
          .where(eq(commonbase.id, childId));
      }
    } catch (error) {
      console.error('Error linking entries:', error);
      throw error;
    }
  }

  static async getSimilarEntries(entryId: string, limit = 5): Promise<CommonbaseEntry[]> {
    try {
      // Get the embedding for the current entry
      const [entryEmbedding] = await db
        .select({ embedding: embeddings.embedding })
        .from(embeddings)
        .where(eq(embeddings.id, entryId));

      if (!entryEmbedding) {
        return [];
      }

      // Find similar entries using cosine similarity
      const results = await db
        .select({
          id: commonbase.id,
          data: commonbase.data,
          metadata: commonbase.metadata,
          created: commonbase.created,
          updated: commonbase.updated,
          similarity: sql<number>`1 - (${embeddings.embedding} <=> ${JSON.stringify(entryEmbedding.embedding)})`,
        })
        .from(commonbase)
        .innerJoin(embeddings, eq(commonbase.id, embeddings.id))
        .where(sql`${commonbase.id} != ${entryId}`)
        .orderBy(sql`${embeddings.embedding} <=> ${JSON.stringify(entryEmbedding.embedding)}`)
        .limit(limit);

      return results;
    } catch (error) {
      console.error('Error getting similar entries:', error);
      throw error;
    }
  }
}