ALTER TABLE blog_posts ADD COLUMN images text[] DEFAULT '{}';
ALTER TABLE blog_posts ADD COLUMN content_blocks jsonb DEFAULT '[]';
