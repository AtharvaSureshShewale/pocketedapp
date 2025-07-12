# Automated Quiz Generation Setup

This guide explains how to set up automated daily quiz generation for the Pocketed app.

## Overview

The automated quiz system:
- ✅ **Generates new finance quizzes daily** without admin intervention
- ✅ **Tracks user progress** through quiz days (Day 1, Day 2, etc.)
- ✅ **Shows completion status** for each quiz
- ✅ **Locks future quizzes** until previous days are completed
- ✅ **Uses AI-generated content** with fallback questions

## Features

### For Users:
- **New users start at Day 1**
- **Existing users see their current day**
- **Completed quizzes remain visible** with scores
- **Future days are locked** until previous days are completed
- **Visual indicators** for completed, current, and locked quizzes

### For Admins:
- **No manual intervention required**
- **Automatic daily quiz generation**
- **Finance-focused topics** (20 different topics that cycle)
- **AI-generated questions** with fallback content

## Setup Instructions

### 1. Database Setup

Run the SQL script to create the required tables:

```sql
-- Execute the contents of supabase_quiz_schema.sql
-- This creates:
-- - user_quiz_progress table
-- - RLS policies
-- - Triggers for automatic progress tracking
```

### 2. Deploy Edge Function (Optional)

For production, deploy the Supabase Edge Function:

```bash
# Deploy the function
supabase functions deploy generate-daily-quiz

# Set up cron job (replace with your project URL)
supabase db push --include-all
```

### 3. Manual Setup (Alternative)

If you don't want to use Edge Functions, the app will automatically generate quizzes when users visit the quiz page for the first time each day.

## How It Works

### Quiz Generation:
1. **Daily Check**: App checks if today's quiz exists
2. **AI Generation**: Uses Gemini AI to create finance questions
3. **Fallback Content**: If AI fails, uses pre-written questions
4. **Topic Rotation**: Cycles through 20 finance topics

### User Progression:
1. **New Users**: Start at Day 1
2. **Quiz Completion**: Automatically advances to next day
3. **Progress Tracking**: Stores current day and completion status
4. **Visual Feedback**: Shows completed, current, and locked states

### Topics Covered:
- Personal Budgeting
- Investment Basics
- Credit and Debt Management
- Emergency Funds
- Retirement Planning
- Tax Basics
- Insurance Fundamentals
- Real Estate Investment
- Stock Market Basics
- Cryptocurrency Fundamentals
- Financial Goal Setting
- Risk Management
- Compound Interest
- Diversification
- Financial Statements
- Business Finance
- International Finance
- Behavioral Finance
- Financial Technology
- Sustainable Investing

## Testing

Use the debug buttons on the home page:

1. **Check Current Day**: Shows user's current quiz day
2. **Reset to Day 1**: Resets user progress (for testing)
3. **Check Progression**: Shows available quizzes
4. **Generate Quiz**: Manually triggers quiz generation

## Troubleshooting

### Quiz Not Generating:
- Check if today's quiz already exists
- Verify AI API key is valid
- Check fallback content is working

### User Progress Issues:
- Verify user_quiz_progress table exists
- Check RLS policies are correct
- Ensure triggers are working

### Visual Issues:
- Clear app cache
- Restart the app
- Check quiz progression data

## Future Enhancements

- [ ] **More AI Topics**: Expand beyond 20 topics
- [ ] **Difficulty Levels**: Add beginner/intermediate/advanced
- [ ] **Quiz Analytics**: Track completion rates and scores
- [ ] **Personalized Content**: Based on user interests
- [ ] **Multi-language Support**: Generate quizzes in different languages

## API Reference

### Key Functions:

```dart
// Get user's current day
await getUserCurrentDay()

// Get all quiz progression data
await getUserQuizProgression()

// Generate new quiz (admin only)
await generateAutomatedDailyQuiz()

// Initialize automated generation
await initializeAutomatedQuizGeneration()
```

### Database Tables:

- `quizzes`: Quiz metadata
- `quiz_questions`: Individual questions
- `user_quiz_attempts`: User quiz attempts
- `user_quiz_progress`: User progression tracking
- `quiz_leaderboard`: Quiz scores and rankings 