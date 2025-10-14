import { NextRequest, NextResponse } from 'next/server';
import { writeFile, mkdir } from 'fs/promises';
import path from 'path';
import { db } from '@/lib/db';
import { commonbase, embeddings } from '@/lib/db/schema';
import { generateEmbedding } from '@/lib/embeddings';
import { eq } from 'drizzle-orm';
import { isDemoMode, getDemoModeError } from '@/lib/demo-mode';

async function transcribeImage(imagePath: string): Promise<string> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY environment variable is not set');
  }

  // Read the image file as base64
  const fs = await import('fs/promises');
  const imageBuffer = await fs.readFile(imagePath);
  const base64Image = imageBuffer.toString('base64');

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: 'Describe this image in detail. Focus on the main content, text, and any important visual elements.',
            },
            {
              type: 'image_url',
              image_url: {
                url: `data:image/jpeg;base64,${base64Image}`,
              },
            },
          ],
        },
      ],
      max_tokens: 500,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status}`);
  }
  const data = await response.json();
  return data.choices[0].message.content;
}

export async function POST(request: NextRequest) {
  try {
    // Check if demo mode is enabled
    if (isDemoMode()) {
      const error = getDemoModeError();
      return NextResponse.json({ 
        error: error.message,
        action: error.action 
      }, { status: 403 });
    }

    const formData = await request.formData();
    const image = formData.get('image') as File;
    const link = formData.get('link') as string;
    const parentTitle = formData.get('parentTitle') as string;
    const parentSource = formData.get('parentSource') as string;

    if (!image) {
      return NextResponse.json({ error: 'Image is required' }, { status: 400 });
    }

    // Create assets/images directory if it doesn't exist
    const assetsDir = path.join(process.cwd(), 'public', 'assets', 'images');
    await mkdir(assetsDir, { recursive: true });

    // Generate unique filename
    const timestamp = Date.now();
    const extension = path.extname(image.name);
    const filename = `${timestamp}${extension}`;
    const filepath = path.join(assetsDir, filename);

    // Save image to disk
    const bytes = await image.arrayBuffer();
    const buffer = Buffer.from(bytes);
    await writeFile(filepath, buffer);

    const imageUrl = `/assets/images/${filename}`;

    try {
      // Transcribe image using GPT-4V
      const transcription = await transcribeImage(filepath);

      // Create database entry
      const metadata: any = {
        type: 'image',
        source: imageUrl,
        originalFilename: image.name,
      };

      // Add parent metadata if this is a comment
      if (link) {
        metadata.isComment = true;
        metadata.links = [link];
        if (parentTitle) metadata.title = parentTitle;
        if (parentSource) metadata.parentSource = parentSource;
      }

      const [newEntry] = await db
        .insert(commonbase)
        .values({
          data: transcription,
          metadata,
        })
        .returning();

      // Generate and store embedding
      try {
        const embedding = await generateEmbedding(transcription);
        await db.insert(embeddings).values({
          id: newEntry.id,
          embedding,
        });
      } catch (embeddingError) {
        console.error('Failed to generate embedding:', embeddingError);
      }

      // If this is a comment (link is provided), update parent record's backlinks
      if (link) {
        try {
          const [parentEntry] = await db
            .select()
            .from(commonbase)
            .where(eq(commonbase.id, link));

          if (parentEntry) {
            const currentBacklinks = parentEntry.metadata?.backlinks || [];
            await db
              .update(commonbase)
              .set({
                metadata: {
                  ...parentEntry.metadata,
                  backlinks: [...currentBacklinks, newEntry.id],
                },
                updated: new Date(),
              })
              .where(eq(commonbase.id, link));
          }
        } catch (linkError) {
          console.error('Failed to update parent backlinks:', linkError);
        }
      }

      return NextResponse.json(newEntry);
    } catch (transcriptionError) {
      console.error('Failed to transcribe image:', transcriptionError);
      return NextResponse.json(
        { error: 'Failed to transcribe image' },
        { status: 500 }
      );
    }
  } catch (error) {
    console.error('Error adding image:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}