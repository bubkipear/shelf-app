-- SHELF APP DATABASE SCHEMA
-- Supabase PostgreSQL Schema

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- USERS TABLE
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  premium_expires_at TIMESTAMP WITH TIME ZONE,
  is_premium BOOLEAN DEFAULT FALSE,
  experiment_count INTEGER DEFAULT 0,
  max_free_experiments INTEGER DEFAULT 3
);

-- EXPERIMENTS TABLE
CREATE TABLE public.experiments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  intention TEXT,
  frequency TEXT, -- 'Daily', 'A few times a week', 'Weekly'
  duration_days INTEGER,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'active', -- 'active', 'abandoned', 'completed'
  is_public BOOLEAN DEFAULT TRUE,
  icon_preset TEXT DEFAULT 'book', -- Maps to ExperimentIcon enum
  has_custom_image BOOLEAN DEFAULT FALSE,
  custom_image_url TEXT,
  closing_reflection TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CHECK-INS TABLE
CREATE TABLE public.check_ins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experiment_id UUID NOT NULL REFERENCES public.experiments(id) ON DELETE CASCADE,
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  did_complete BOOLEAN DEFAULT TRUE,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- EXPERIMENT LIKES/SOCIAL INTERACTIONS
CREATE TABLE public.experiment_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experiment_id UUID NOT NULL REFERENCES public.experiments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(experiment_id, user_id)
);

-- STORAGE BUCKET FOR CUSTOM IMAGES
INSERT INTO storage.buckets (id, name, public) VALUES ('experiment-images', 'experiment-images', true);

-- ROW LEVEL SECURITY POLICIES

-- Users can only see/edit their own profile
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Experiments: Users can CRUD their own, read public ones
ALTER TABLE public.experiments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own experiments" ON public.experiments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view public experiments" ON public.experiments FOR SELECT USING (is_public = true);
CREATE POLICY "Users can insert own experiments" ON public.experiments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own experiments" ON public.experiments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own experiments" ON public.experiments FOR DELETE USING (auth.uid() = user_id);

-- Check-ins: Users can CRUD their own experiment check-ins
ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own check-ins" ON public.check_ins FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.experiments 
    WHERE experiments.id = check_ins.experiment_id 
    AND experiments.user_id = auth.uid()
  )
);

-- Likes: Users can like any public experiment
ALTER TABLE public.experiment_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all likes" ON public.experiment_likes FOR SELECT USING (true);
CREATE POLICY "Users can manage own likes" ON public.experiment_likes FOR ALL USING (auth.uid() = user_id);

-- STORAGE POLICY
CREATE POLICY "Users can upload own images" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'experiment-images' AND auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Anyone can view public images" ON storage.objects FOR SELECT USING (bucket_id = 'experiment-images');

-- FUNCTIONS

-- Update user experiment count when experiments change
CREATE OR REPLACE FUNCTION update_user_experiment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users 
    SET experiment_count = experiment_count + 1 
    WHERE id = NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.users 
    SET experiment_count = experiment_count - 1 
    WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update experiment count
CREATE TRIGGER experiment_count_trigger
  AFTER INSERT OR DELETE ON public.experiments
  FOR EACH ROW
  EXECUTE FUNCTION update_user_experiment_count();

-- Function to check premium limits
CREATE OR REPLACE FUNCTION check_experiment_limit()
RETURNS TRIGGER AS $$
DECLARE
  user_record RECORD;
BEGIN
  SELECT experiment_count, is_premium, max_free_experiments
  INTO user_record
  FROM public.users
  WHERE id = NEW.user_id;
  
  -- Allow if premium user
  IF user_record.is_premium THEN
    RETURN NEW;
  END IF;
  
  -- Check if exceeds free limit
  IF user_record.experiment_count >= user_record.max_free_experiments THEN
    RAISE EXCEPTION 'Free tier limited to % experiments. Upgrade to premium for unlimited experiments.', 
      user_record.max_free_experiments;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to enforce experiment limits
CREATE TRIGGER experiment_limit_trigger
  BEFORE INSERT ON public.experiments
  FOR EACH ROW
  EXECUTE FUNCTION check_experiment_limit();