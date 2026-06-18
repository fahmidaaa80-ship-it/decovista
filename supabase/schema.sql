-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.users (
  id uuid NOT NULL,
  full_name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text,
  avatar_url text,
  user_type text DEFAULT 'customer'::text CHECK (user_type = ANY (ARRAY['customer'::text, 'designer'::text, 'admin'::text])),
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  role text DEFAULT 'user'::text,
  profile_img text,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.categories (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  image_url text,
  parent_id uuid,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (id),
  CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories(id)
);
CREATE TABLE public.products (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  price numeric NOT NULL,
  discount_price numeric,
  category_id uuid,
  material text,
  stock integer DEFAULT 0,
  rating numeric DEFAULT 0,
  review_count integer DEFAULT 0,
  colors text[] DEFAULT '{}',
  images text[] DEFAULT '{}',
  content_blocks jsonb DEFAULT '[]',
  is_featured boolean DEFAULT false,
  is_new boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT products_pkey PRIMARY KEY (id),
  CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)
);
CREATE TABLE public.cart (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  product_id uuid,
  package_id uuid,
  quantity integer DEFAULT 1,
  is_package boolean DEFAULT false,
  customizations jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cart_pkey PRIMARY KEY (id),
  CONSTRAINT cart_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
  CONSTRAINT cart_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.design_packages(id),
  CONSTRAINT cart_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.orders (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_number text NOT NULL UNIQUE,
  user_id uuid,
  total_amount numeric NOT NULL,
  shipping_address jsonb NOT NULL,
  payment_method text NOT NULL,
  payment_status text DEFAULT 'pending'::text,
  order_status text DEFAULT 'pending'::text,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.order_items (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  order_id uuid,
  product_id uuid,
  package_id uuid,
  quantity integer DEFAULT 1,
  price numeric NOT NULL,
  is_package boolean DEFAULT false,
  customizations jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT order_items_pkey PRIMARY KEY (id),
  CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id),
  CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.wishlist (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  product_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT wishlist_pkey PRIMARY KEY (id),
  CONSTRAINT wishlist_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
  CONSTRAINT wishlist_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.design_packages (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  room_type text NOT NULL,
  style text,
  price numeric NOT NULL,
  discount_price numeric,
  preview_image text,
  images text[] DEFAULT '{}',
  estimated_budget numeric,
  room_size text,
  wall_color_suggestions text[] DEFAULT '{}',
  is_customizable boolean DEFAULT true,
  is_featured boolean DEFAULT false,
  rating numeric DEFAULT 0,
  review_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT design_packages_pkey PRIMARY KEY (id)
);
CREATE TABLE public.reviews (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  product_id uuid,
  package_id uuid,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title text,
  comment text,
  images text[] DEFAULT '{}',
  is_verified_purchase boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reviews_pkey PRIMARY KEY (id),
  CONSTRAINT reviews_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
  CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.bookings (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  designer_id uuid,
  booking_date date NOT NULL,
  booking_time time without time zone NOT NULL,
  meeting_type text NOT NULL,
  meeting_link text,
  status text DEFAULT 'pending'::text,
  payment_status text DEFAULT 'pending'::text,
  payment_amount numeric,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_designer_id_fkey FOREIGN KEY (designer_id) REFERENCES public.users(id),
  CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.banners (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  subtitle text NOT NULL,
  image_url text NOT NULL,
  primary_action text NOT NULL DEFAULT 'Shop Now'::text,
  secondary_action text NOT NULL DEFAULT 'Explore'::text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT banners_pkey PRIMARY KEY (id)
);
CREATE TABLE public.offers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  discount text NOT NULL,
  description text NOT NULL,
  category_name text NOT NULL,
  background_color text NOT NULL DEFAULT '#FFE5E5'::text,
  text_color text NOT NULL DEFAULT '#D32F2F'::text,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT offers_pkey PRIMARY KEY (id)
);
CREATE TABLE public.completed_projects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  before_image text NOT NULL,
  after_image text NOT NULL,
  category text NOT NULL,
  is_active boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT completed_projects_pkey PRIMARY KEY (id)
);
CREATE TABLE public.blog_posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  excerpt text NOT NULL,
  content text DEFAULT '',
  images text[] DEFAULT '{}',
  content_blocks jsonb DEFAULT '[]',
  image text NOT NULL,
  category text NOT NULL,
  read_time text NOT NULL DEFAULT '5 min read'::text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT blog_posts_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_designs (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  package_id uuid NOT NULL,
  customizations jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_designs_pkey PRIMARY KEY (id),
  CONSTRAINT user_designs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT user_designs_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.design_packages(id)
);
CREATE TABLE public.likes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  product_id uuid NOT NULL,
  liked_at timestamp with time zone DEFAULT now(),
  CONSTRAINT likes_pkey PRIMARY KEY (id),
  CONSTRAINT likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT likes_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
  CONSTRAINT likes_user_product_unique UNIQUE (user_id, product_id)
);

-- Enable Row-Level Security on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can read and update their own data
CREATE POLICY "Users can read own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can read all profiles" ON public.users FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND user_type = 'admin'));

-- RLS Policies: Products and categories are readable by all
CREATE POLICY "Products are publicly readable" ON public.products FOR SELECT USING (true);
CREATE POLICY "Categories are publicly readable" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Admins can manage categories" ON public.categories FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND user_type = 'admin'));
CREATE POLICY "Design packages are publicly readable" ON public.design_packages FOR SELECT USING (true);
CREATE POLICY "Blog posts are publicly readable" ON public.blog_posts FOR SELECT USING (true);

-- RLS Policies: Cart is user-scoped
CREATE POLICY "Users can manage own cart" ON public.cart FOR ALL USING (auth.uid() = user_id);

-- RLS Policies: Orders are user-scoped
CREATE POLICY "Users can read own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can read all orders" ON public.orders FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND user_type = 'admin'));

-- RLS Policies: Order items are accessible via own orders
CREATE POLICY "Users can read own order items" ON public.order_items FOR SELECT USING (EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND user_id = auth.uid()));
CREATE POLICY "Users can create own order items" ON public.order_items FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND user_id = auth.uid()));

-- RLS Policies: Wishlist is user-scoped
CREATE POLICY "Users can manage own wishlist" ON public.wishlist FOR ALL USING (auth.uid() = user_id);

-- RLS Policies: Reviews are user-scoped for write, public for read
CREATE POLICY "Reviews are publicly readable" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users can create own reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON public.reviews FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies: Likes are user-scoped
CREATE POLICY "Likes are publicly readable" ON public.likes FOR SELECT USING (true);
CREATE POLICY "Users can manage own likes" ON public.likes FOR ALL USING (auth.uid() = user_id);

-- RLS Policies: User designs are user-scoped
CREATE POLICY "Users can manage own designs" ON public.user_designs FOR ALL USING (auth.uid() = user_id);