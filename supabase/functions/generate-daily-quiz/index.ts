import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Check if today's quiz already exists
    const today = new Date()
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    const endOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59)

    const existingQuiz = await supabase
      .from('quizzes')
      .select('id')
      .gte('created_at', startOfDay.toISOString())
      .lte('created_at', endOfDay.toISOString())
      .maybeSingle()

    if (existingQuiz) {
      return new Response(
        JSON.stringify({ message: 'Quiz for today already exists' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get next day number
    const lastQuiz = await supabase
      .from('quizzes')
      .select('day_number')
      .order('day_number', { ascending: false })
      .limit(1)
      .maybeSingle()

    const nextDay = lastQuiz ? lastQuiz.day_number + 1 : 1

    // Generate quiz content using AI
    const quizContent = await generateQuizContent(nextDay)

    // Create the quiz
    const quizResponse = await supabase
      .from('quizzes')
      .insert({
        title: quizContent.title,
        description: quizContent.description,
        day_number: nextDay,
        points_per_question: 10,
        is_active: true,
      })
      .select()
      .single()

    const quizId = quizResponse.id

    // Create questions for the quiz
    for (const question of quizContent.questions) {
      await supabase.from('quiz_questions').insert({
        quiz_id: quizId,
        question_text: question.question,
        option_a: question.options.A,
        option_b: question.options.B,
        option_c: question.options.C,
        option_d: question.options.D,
        correct_option: question.correct_answer,
        points: 10,
      })
    }

    return new Response(
      JSON.stringify({ 
        message: 'Quiz generated successfully',
        day: nextDay,
        title: quizContent.title
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error generating quiz:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function generateQuizContent(dayNumber: number) {
  const financeTopics = [
    'Personal Budgeting',
    'Investment Basics',
    'Credit and Debt Management',
    'Emergency Funds',
    'Retirement Planning',
    'Tax Basics',
    'Insurance Fundamentals',
    'Real Estate Investment',
    'Stock Market Basics',
    'Cryptocurrency Fundamentals',
    'Financial Goal Setting',
    'Risk Management',
    'Compound Interest',
    'Diversification',
    'Financial Statements',
    'Business Finance',
    'International Finance',
    'Behavioral Finance',
    'Financial Technology',
    'Sustainable Investing',
  ]

  const topic = financeTopics[(dayNumber - 1) % financeTopics.length]

  // For now, return fallback content
  // In production, you would integrate with an AI service here
  return getFallbackQuizContent(dayNumber, topic)
}

function getFallbackQuizContent(dayNumber: number, topic: string) {
  const fallbackQuizzes: Record<string, any> = {
    'Personal Budgeting': {
      title: `Day ${dayNumber}: Personal Budgeting - Managing Your Money`,
      description: 'Learn the fundamentals of creating and maintaining a personal budget.',
      questions: [
        {
          question: 'What is the 50/30/20 budgeting rule?',
          options: {
            A: '50% needs, 30% wants, 20% savings',
            B: '50% savings, 30% needs, 20% wants',
            C: '50% wants, 30% savings, 20% needs',
            D: '50% needs, 30% savings, 20% wants'
          },
          correct_answer: 'A'
        },
        {
          question: 'Which of the following is considered a "need" in budgeting?',
          options: {
            A: 'Entertainment subscriptions',
            B: 'Housing and utilities',
            C: 'Vacation expenses',
            D: 'Dining out'
          },
          correct_answer: 'B'
        },
        {
          question: 'What is the purpose of tracking expenses?',
          options: {
            A: 'To impress friends with spending',
            B: 'To identify spending patterns and make better decisions',
            C: 'To avoid paying taxes',
            D: 'To get more credit cards'
          },
          correct_answer: 'B'
        },
        {
          question: 'Which budgeting method involves using cash for different spending categories?',
          options: {
            A: 'Digital budgeting',
            B: 'Envelope method',
            C: 'Credit card method',
            D: 'Investment budgeting'
          },
          correct_answer: 'B'
        },
        {
          question: 'What percentage of your income should you aim to save?',
          options: {
            A: 'At least 5%',
            B: 'At least 10%',
            C: 'At least 20%',
            D: 'All of the above are good targets'
          },
          correct_answer: 'D'
        }
      ]
    },
    'Investment Basics': {
      title: `Day ${dayNumber}: Investment Basics - Growing Your Wealth`,
      description: 'Understand the fundamentals of investing and building wealth over time.',
      questions: [
        {
          question: 'What is compound interest?',
          options: {
            A: 'Interest earned only on the principal amount',
            B: 'Interest earned on both principal and accumulated interest',
            C: 'A type of loan interest',
            D: 'Interest paid by the government'
          },
          correct_answer: 'B'
        },
        {
          question: 'Which investment typically has the highest risk?',
          options: {
            A: 'Government bonds',
            B: 'Savings account',
            C: 'Individual stocks',
            D: 'Money market account'
          },
          correct_answer: 'C'
        },
        {
          question: 'What is diversification?',
          options: {
            A: 'Putting all money in one investment',
            B: 'Spreading investments across different assets',
            C: 'Investing only in stocks',
            D: 'Avoiding all investments'
          },
          correct_answer: 'B'
        },
        {
          question: 'What is a mutual fund?',
          options: {
            A: 'A single stock investment',
            B: 'A pool of money from many investors',
            C: 'A type of bank account',
            D: 'A government bond'
          },
          correct_answer: 'B'
        },
        {
          question: 'What is the time value of money?',
          options: {
            A: 'Money is worth more today than in the future',
            B: 'Money loses value over time',
            C: 'Money has no time component',
            D: 'Money is always worth the same'
          },
          correct_answer: 'A'
        }
      ]
    }
  }

  return fallbackQuizzes[topic] || fallbackQuizzes['Personal Budgeting']
} 