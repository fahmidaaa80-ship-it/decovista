-- Seed default categories
INSERT INTO public.categories (name, description, is_active)
VALUES
  ('Living Room', 'Living room furniture and decor', true),
  ('Bedroom', 'Bedroom furniture and decor', true),
  ('Kitchen', 'Kitchen furniture and accessories', true),
  ('Dining Room', 'Dining room furniture', true),
  ('Office', 'Office furniture and decor', true),
  ('Bathroom', 'Bathroom accessories and storage', true),
  ('Outdoor', 'Outdoor and garden furniture', true)
ON CONFLICT (name) DO NOTHING;
