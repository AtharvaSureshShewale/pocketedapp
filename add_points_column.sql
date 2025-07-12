-- Add points column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 0;

-- Create function to increment user points
CREATE OR REPLACE FUNCTION public.increment_user_points(p_user_id UUID, p_points INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles 
  SET points = COALESCE(points, 0) + p_points,
      updated_at = NOW()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.increment_user_points(UUID, INTEGER) TO authenticated;

-- Update existing profiles to have 0 points if they don't have any
UPDATE public.profiles 
SET points = 0 
WHERE points IS NULL; 