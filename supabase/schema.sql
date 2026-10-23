-- ==============================================================================
-- HARMONIQ SUPABASE DATABASE SCHEMA
-- Features:
-- 1. Individual User Profiles (public.profiles)
-- 2. Individual User Song History (public.song_history)
-- 3. Row Level Security (RLS) policies for complete privacy between users
-- 4. Auth Triggers to automatically create profile on signup
-- 5. Updated_at auto-timestamp triggers & listening statistics helper
-- ==============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. TABLE: public.profiles
-- Stores valid, customizable profile details for each authenticated user.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT DEFAULT 'Music lover on Harmoniq',
  favorite_genre TEXT DEFAULT 'All Genres',
  total_listening_seconds BIGINT DEFAULT 0 NOT NULL,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Comments for database documentation
COMMENT ON TABLE public.profiles IS 'Stores individual user profiles linked to Supabase Auth.';
COMMENT ON COLUMN public.profiles.id IS 'References the auth.users UUID.';
COMMENT ON COLUMN public.profiles.username IS 'Unique handle for the user (e.g., @john_doe).';
COMMENT ON COLUMN public.profiles.total_listening_seconds IS 'Accumulated listening time in seconds.';

-- Enable Row Level Security (RLS) on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if re-running
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete their own profile" ON public.profiles;

-- RLS: Anyone authenticated can view public profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

-- RLS: Users can only insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- RLS: Users can only update their own profile
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- RLS: Users can only delete their own profile
CREATE POLICY "Users can delete their own profile"
  ON public.profiles FOR DELETE
  USING (auth.uid() = id);


-- ------------------------------------------------------------------------------
-- 2. TABLE: public.song_history
-- Stores individual song playback events for each authenticated user.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.song_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  album TEXT DEFAULT '',
  duration_seconds INTEGER DEFAULT 0,
  art_url TEXT,
  source TEXT NOT NULL DEFAULT 'youtube',
  played_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Comments for database documentation
COMMENT ON TABLE public.song_history IS 'Stores individual playback history records for each user.';
COMMENT ON COLUMN public.song_history.user_id IS 'Owner user UUID; strictly secured via RLS.';
COMMENT ON COLUMN public.song_history.song_id IS 'Unique identifier for track (e.g., youtube:ID or local:ID).';

-- Indexes for ultra-fast history queries and sorting
CREATE INDEX IF NOT EXISTS idx_song_history_user_played
  ON public.song_history(user_id, played_at DESC);

CREATE INDEX IF NOT EXISTS idx_song_history_user_song
  ON public.song_history(user_id, song_id);

-- Enable Row Level Security (RLS) on song_history
ALTER TABLE public.song_history ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if re-running
DROP POLICY IF EXISTS "Users can view only their own song history" ON public.song_history;
DROP POLICY IF EXISTS "Users can insert their own song history" ON public.song_history;
DROP POLICY IF EXISTS "Users can delete their own song history" ON public.song_history;

-- RLS: Users can ONLY see their own playback history
CREATE POLICY "Users can view only their own song history"
  ON public.song_history FOR SELECT
  USING (auth.uid() = user_id);

-- RLS: Users can ONLY insert history records for themselves
CREATE POLICY "Users can insert their own song history"
  ON public.song_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS: Users can ONLY delete their own history records
CREATE POLICY "Users can delete their own song history"
  ON public.song_history FOR DELETE
  USING (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 3. TRIGGERS & FUNCTIONS
-- Automatically provisions profiles on signup and manages updated timestamps.
-- ------------------------------------------------------------------------------

-- Function to handle new user registration from Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  extracted_username TEXT;
  extracted_display TEXT;
BEGIN
  -- Extract username from metadata, or fallback to email prefix
  extracted_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    split_part(NEW.email, '@', 1)
  );

  extracted_display := COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'username',
    split_part(NEW.email, '@', 1)
  );

  INSERT INTO public.profiles (
    id,
    username,
    display_name,
    avatar_url,
    bio
  ) VALUES (
    NEW.id,
    extracted_username,
    extracted_display,
    NEW.raw_user_meta_data->>'avatar_url',
    'Music lover on Harmoniq'
  )
  ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url),
    updated_at = TIMEZONE('utc', NOW());

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Execute whenever a new row is created in auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to automatically bump updated_at on record changes
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update updated_at on public.profiles
DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 4. HELPER RPC FUNCTION: increment_listening_time
-- Atomically increments listening duration for a user's profile.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.increment_listening_time(
  user_id_param UUID,
  seconds_param INTEGER
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET
    total_listening_seconds = total_listening_seconds + GREATEST(0, seconds_param),
    updated_at = TIMEZONE('utc', NOW())
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
