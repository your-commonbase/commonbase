import { pgTable, uuid, text, json, timestamp, customType } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

// Custom vector type for pgvector
const vector = customType<{ data: number[]; notNull: false; default: false }>({
  dataType() {
    return 'vector(1536)';
  },
  toDriver(value: number[]): string {
    return `[${value.join(',')}]`;
  },
  fromDriver(value: string): number[] {
    return value
      .slice(1, -1) // Remove [ and ]
      .split(',')
      .map(Number);
  },
});

export const commonbase = pgTable('commonbase', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  data: text('data').notNull(),
  metadata: json('metadata').$type<{
    title?: string;
    author?: string; // For file uploads, this will be the file name
    source?: string;
    type?: string;
    filePath?: string; // Local file path for file uploads
    fileSize?: number;
    mimeType?: string;
    links?: string[];
    backlinks?: string[];
    [key: string]: any;
  }>().default({}),
  created: timestamp('created').defaultNow().notNull(),
  updated: timestamp('updated').defaultNow().notNull(),
});

export const embeddings = pgTable('embeddings', {
  id: uuid('id').primaryKey().references(() => commonbase.id, { onDelete: 'cascade' }),
  embedding: vector('embedding').notNull(),
});

export type CommonbaseEntry = typeof commonbase.$inferSelect;
export type NewCommonbaseEntry = typeof commonbase.$inferInsert;
export type Embedding = typeof embeddings.$inferSelect;
export type NewEmbedding = typeof embeddings.$inferInsert;