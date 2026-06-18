-- Restore categories with exact UUIDs that products reference
INSERT INTO public.categories (id, name, description, is_active)
VALUES
  ('8e08b551-8d39-4540-bc13-c7e5269d60e7', 'Bedroom', 'Bedroom furniture and decor', true),
  ('11768c79-b547-42f4-a256-6e13b07ef708', 'Living Room', 'Living room furniture and decor', true),
  ('761db939-8584-495e-96c1-26d435e8ddfc', 'Dining Room', 'Dining room furniture', true),
  ('20479115-69ec-4dec-8659-ad3492f57d04', 'Kitchen', 'Kitchen furniture and accessories', true),
  (gen_random_uuid(), 'Office', 'Office furniture and decor', true),
  (gen_random_uuid(), 'Bathroom', 'Bathroom accessories and storage', true),
  (gen_random_uuid(), 'Outdoor', 'Outdoor and garden furniture', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active;