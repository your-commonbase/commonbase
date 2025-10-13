import { defineConfig } from 'drizzle-kit';
import { config } from 'dotenv';
import path from 'path';

// Load environment variables from .env file
config({ path: path.join(__dirname, '.env') });

export default defineConfig({
  schema: './src/lib/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL || 'postgresql://localhost:5432/commonbase-electron',
  },
});