-- Create a cron job to generate daily quiz at 6 AM every day
SELECT cron.schedule(
  'generate-daily-quiz',
  '0 6 * * *', -- Every day at 6:00 AM
  $$
  SELECT net.http_post(
    url := 'https://your-project-ref.supabase.co/functions/v1/generate-daily-quiz',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := '{}'
  );
  $$
); 