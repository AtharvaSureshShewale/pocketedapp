-- Setup script for the main leaderboard table
-- This creates a leaderboard table that combines profile points and quiz scores

-- 1. Create the leaderboard table with basic structure
CREATE TABLE IF NOT EXISTS public.leaderboard (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(profile_id)
);

-- 2. Add points column to profiles table if it doesn't exist
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 0;

-- 3. Update existing profiles to have 0 points if they don't have any
UPDATE public.profiles SET points = 0 WHERE points IS NULL;

-- 4. Create function to increment user points
CREATE OR REPLACE FUNCTION increment_user_points(p_user_id UUID, p_points INTEGER)
RETURNS VOID AS $$
BEGIN
    -- Update profile points
    UPDATE public.profiles 
    SET points = COALESCE(points, 0) + p_points 
    WHERE id = p_user_id;
    
    -- Update leaderboard entry
    INSERT INTO public.leaderboard (profile_id, score, created_at)
    VALUES (
        p_user_id, 
        (SELECT COALESCE(points, 0) FROM public.profiles WHERE id = p_user_id) +
        COALESCE((SELECT total_score FROM public.quiz_leaderboard WHERE user_id = p_user_id), 0),
        NOW()
    )
    ON CONFLICT (profile_id) 
    DO UPDATE SET 
        score = (SELECT COALESCE(points, 0) FROM public.profiles WHERE id = p_user_id) +
                COALESCE((SELECT total_score FROM public.quiz_leaderboard WHERE user_id = p_user_id), 0),
        created_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- 5. Create function to sync leaderboard for a user
CREATE OR REPLACE FUNCTION sync_user_leaderboard(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    profile_points INTEGER;
    quiz_score INTEGER;
    total_score INTEGER;
BEGIN
    -- Get profile points
    SELECT COALESCE(points, 0) INTO profile_points
    FROM public.profiles 
    WHERE id = p_user_id;
    
    -- Get quiz score
    SELECT COALESCE(total_score, 0) INTO quiz_score
    FROM public.quiz_leaderboard 
    WHERE user_id = p_user_id;
    
    -- Calculate total score
    total_score := profile_points + quiz_score;
    
    -- Upsert leaderboard entry
    INSERT INTO public.leaderboard (profile_id, score, created_at)
    VALUES (p_user_id, total_score, NOW())
    ON CONFLICT (profile_id) 
    DO UPDATE SET 
        score = total_score,
        created_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- 6. Create trigger function to update leaderboard when profile points change
CREATE OR REPLACE FUNCTION update_leaderboard_on_profile_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Call sync function for the updated user
    PERFORM sync_user_leaderboard(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger function to update leaderboard when quiz scores change
CREATE OR REPLACE FUNCTION update_leaderboard_on_quiz_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Call sync function for the updated user
    PERFORM sync_user_leaderboard(NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger function to update leaderboard when quiz scores are deleted
CREATE OR REPLACE FUNCTION update_leaderboard_on_quiz_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Call sync function for the deleted user
    PERFORM sync_user_leaderboard(OLD.user_id);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 9. Create triggers
DROP TRIGGER IF EXISTS trigger_update_leaderboard_on_profile_change ON public.profiles;
CREATE TRIGGER trigger_update_leaderboard_on_profile_change
    AFTER UPDATE OF points ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_leaderboard_on_profile_change();

DROP TRIGGER IF EXISTS trigger_update_leaderboard_on_quiz_change ON public.quiz_leaderboard;
CREATE TRIGGER trigger_update_leaderboard_on_quiz_change
    AFTER INSERT OR UPDATE ON public.quiz_leaderboard
    FOR EACH ROW
    EXECUTE FUNCTION update_leaderboard_on_quiz_change();

DROP TRIGGER IF EXISTS trigger_update_leaderboard_on_quiz_delete ON public.quiz_leaderboard;
CREATE TRIGGER trigger_update_leaderboard_on_quiz_delete
    AFTER DELETE ON public.quiz_leaderboard
    FOR EACH ROW
    EXECUTE FUNCTION update_leaderboard_on_quiz_delete();

-- 10. Initialize leaderboard with existing data
INSERT INTO public.leaderboard (profile_id, score, created_at)
SELECT 
    p.id,
    COALESCE(p.points, 0) + COALESCE(q.total_score, 0),
    NOW()
FROM public.profiles p
LEFT JOIN public.quiz_leaderboard q ON p.id = q.user_id
ON CONFLICT (profile_id) 
DO UPDATE SET 
    score = EXCLUDED.score,
    created_at = NOW();

-- 11. Set up Row Level Security (RLS)
ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;

-- Allow users to read all leaderboard entries
CREATE POLICY "Allow users to read leaderboard" ON public.leaderboard
    FOR SELECT USING (true);

-- Allow users to update their own leaderboard entry (for sync purposes)
CREATE POLICY "Allow users to update own leaderboard entry" ON public.leaderboard
    FOR UPDATE USING (auth.uid() = profile_id);

-- Allow users to insert their own leaderboard entry (for sync purposes)
CREATE POLICY "Allow users to insert own leaderboard entry" ON public.leaderboard
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- 12. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_leaderboard_score ON public.leaderboard(score DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_profile_id ON public.leaderboard(profile_id);
CREATE INDEX IF NOT EXISTS idx_profiles_points ON public.profiles(points DESC);

-- 13. Grant necessary permissions
GRANT SELECT ON public.leaderboard TO authenticated;
GRANT INSERT, UPDATE ON public.leaderboard TO authenticated;
GRANT USAGE ON SEQUENCE public.leaderboard_id_seq TO authenticated;

-- 14. Create a view for easy leaderboard queries with profile info
CREATE OR REPLACE VIEW public.leaderboard_with_profiles AS
SELECT 
    l.id,
    l.profile_id,
    l.score,
    l.created_at,
    p.username,
    p.points as profile_points,
    COALESCE(q.total_score, 0) as quiz_score,
    q.quizzes_completed,
    q.last_quiz_date
FROM public.leaderboard l
INNER JOIN public.profiles p ON l.profile_id = p.id
LEFT JOIN public.quiz_leaderboard q ON l.profile_id = q.user_id
ORDER BY l.score DESC;

-- Grant access to the view
GRANT SELECT ON public.leaderboard_with_profiles TO authenticated;

-- 15. Print summary
DO $$
BEGIN
    RAISE NOTICE '✅ Leaderboard setup completed successfully!';
    RAISE NOTICE '📊 Leaderboard table created with % entries', (SELECT COUNT(*) FROM public.leaderboard);
    RAISE NOTICE '👥 Profiles with points: %', (SELECT COUNT(*) FROM public.profiles WHERE points > 0);
    RAISE NOTICE '🎯 Quiz entries: %', (SELECT COUNT(*) FROM public.quiz_leaderboard);
END $$; 