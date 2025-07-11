-- Create quizzes table
CREATE TABLE IF NOT EXISTS public.quizzes (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    day_number INTEGER NOT NULL,
    points_per_question INTEGER NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Create quiz_questions table
CREATE TABLE IF NOT EXISTS public.quiz_questions (
    id BIGSERIAL PRIMARY KEY,
    quiz_id BIGINT REFERENCES public.quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_c TEXT NOT NULL,
    option_d TEXT NOT NULL,
    correct_option TEXT NOT NULL CHECK (correct_option IN ('A', 'B', 'C', 'D')),
    points INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create user_quiz_attempts table
CREATE TABLE IF NOT EXISTS public.user_quiz_attempts (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    quiz_id BIGINT REFERENCES public.quizzes(id) ON DELETE CASCADE,
    score INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Create user_quiz_answers table
CREATE TABLE IF NOT EXISTS public.user_quiz_answers (
    id BIGSERIAL PRIMARY KEY,
    attempt_id BIGINT REFERENCES public.user_quiz_attempts(id) ON DELETE CASCADE,
    question_id BIGINT REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
    selected_option TEXT NOT NULL CHECK (selected_option IN ('A', 'B', 'C', 'D')),
    is_correct BOOLEAN NOT NULL,
    points_earned INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create quiz_leaderboard table
CREATE TABLE IF NOT EXISTS public.quiz_leaderboard (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_score INTEGER DEFAULT 0,
    quizzes_completed INTEGER DEFAULT 0,
    last_quiz_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create profiles table if it doesn't exist (for leaderboard user info)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    username TEXT,
    avatar_url TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create trigger to update profiles when a user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Set up Row Level Security (RLS) policies

-- Enable RLS on all tables
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quiz_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_leaderboard ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Quizzes policies (anyone can read, only authenticated users can create/update)
CREATE POLICY "Anyone can read quizzes" ON public.quizzes
  FOR SELECT USING (true);
  
CREATE POLICY "Authenticated users can create quizzes" ON public.quizzes
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  
CREATE POLICY "Authenticated users can update quizzes" ON public.quizzes
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Quiz questions policies (anyone can read, only authenticated users can create)
CREATE POLICY "Anyone can read quiz questions" ON public.quiz_questions
  FOR SELECT USING (true);
  
CREATE POLICY "Authenticated users can create quiz questions" ON public.quiz_questions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- User quiz attempts policies (users can read/write their own attempts)
CREATE POLICY "Users can read their own attempts" ON public.user_quiz_attempts
  FOR SELECT USING (auth.uid() = user_id);
  
CREATE POLICY "Users can create their own attempts" ON public.user_quiz_attempts
  FOR INSERT WITH CHECK (auth.uid() = user_id);
  
CREATE POLICY "Users can update their own attempts" ON public.user_quiz_attempts
  FOR UPDATE USING (auth.uid() = user_id);

-- User quiz answers policies (users can read/write their own answers)
CREATE POLICY "Users can read their own answers" ON public.user_quiz_answers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_quiz_attempts
      WHERE id = attempt_id AND user_id = auth.uid()
    )
  );
  
CREATE POLICY "Users can create their own answers" ON public.user_quiz_answers
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_quiz_attempts
      WHERE id = attempt_id AND user_id = auth.uid()
    )
  );

-- Quiz leaderboard policies (anyone can read, users can only update their own entries)
CREATE POLICY "Anyone can read leaderboard" ON public.quiz_leaderboard
  FOR SELECT USING (true);
  
CREATE POLICY "Users can create their own leaderboard entry" ON public.quiz_leaderboard
  FOR INSERT WITH CHECK (auth.uid() = user_id);
  
CREATE POLICY "Users can update their own leaderboard entry" ON public.quiz_leaderboard
  FOR UPDATE USING (auth.uid() = user_id);

-- Profiles policies (anyone can read, users can update their own profile)
CREATE POLICY "Anyone can read profiles" ON public.profiles
  FOR SELECT USING (true);
  
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id); 