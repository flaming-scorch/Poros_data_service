import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { asyncHandler, AppError } from '../middleware/errorHandler';

const router = Router();

router.use(authenticate);

interface JobDetails {
  companyName: string;
  positionTitle: string;
  jobDescription: string;
}

interface TavilyResult {
  title: string;
  url: string;
  content: string;
  score: number;
}

router.post('/tailor-resume', asyncHandler(async (req: AuthRequest, res: Response) => {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  const { resumeBase64, jobDetails } = req.body as {
    resumeBase64?: string;
    jobDetails?: JobDetails;
  };

  if (!apiKey) {
    throw new AppError('Resume tailoring is not configured', 503);
  }

  if (!resumeBase64 || !jobDetails?.companyName || !jobDetails.positionTitle || !jobDetails.jobDescription) {
    throw new AppError('Resume PDF and complete job details are required', 400);
  }

  const prompt = `You are an expert resume writer and ATS optimization specialist.

Tailor the attached resume for:
Company: ${jobDetails.companyName}
Position: ${jobDetails.positionTitle}

Job description:
${jobDetails.jobDescription}

Preserve factual accuracy. Never invent skills, employment, education, metrics, or achievements. Prioritize relevant evidence, use standard section headings, and return a complete single-column HTML document suitable for printing on one US Letter page. Use black text, 0.5-inch margins, and readable type no smaller than 9pt. Return only raw HTML without Markdown fences.`;

  const upstream = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4096,
      messages: [{
        role: 'user',
        content: [
          {
            type: 'document',
            source: {
              type: 'base64',
              media_type: 'application/pdf',
              data: resumeBase64,
            },
          },
          { type: 'text', text: prompt },
        ],
      }],
    }),
  });

  const data = await upstream.json() as {
    content?: Array<{ text?: string }>;
    error?: { message?: string };
  };

  if (!upstream.ok) {
    throw new AppError(data.error?.message || 'Resume tailoring request failed', upstream.status);
  }

  const html = data.content?.[0]?.text;
  if (!html) {
    throw new AppError('AI provider returned an empty response', 502);
  }

  res.json({ html });
}));

router.post('/search', asyncHandler(async (req: AuthRequest, res: Response) => {
  const apiKey = process.env.TAVILY_API_KEY;
  const { companyName, kind } = req.body as {
    companyName?: string;
    kind?: 'events' | 'courses';
  };

  if (!apiKey) {
    throw new AppError('Company research is not configured', 503);
  }

  if (!companyName || !['events', 'courses'].includes(kind || '')) {
    throw new AppError('Company name and a valid search kind are required', 400);
  }

  const year = new Date().getFullYear();
  const query = kind === 'events'
    ? `${companyName} upcoming career events tech talks workshops ${year}`
    : `${companyName} online courses tutorials training certification`;

  const upstream = await fetch('https://api.tavily.com/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      api_key: apiKey,
      query,
      search_depth: 'basic',
      include_answer: false,
      include_raw_content: false,
      max_results: 5,
    }),
  });

  const data = await upstream.json() as {
    results?: TavilyResult[];
    query?: string;
    detail?: string;
  };

  if (!upstream.ok) {
    throw new AppError(data.detail || 'Company research request failed', upstream.status);
  }

  res.json({ results: data.results || [], query: data.query || query });
}));

router.post('/company-profile', asyncHandler(async (req: AuthRequest, res: Response) => {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  const { companyName } = req.body as { companyName?: string };

  if (!apiKey) {
    throw new AppError('Company enrichment is not configured', 503);
  }

  if (!companyName) {
    throw new AppError('Company name is required', 400);
  }

  const prompt = `Research ${companyName} for a student preparing an internship application. Return only valid JSON with this exact structure:
{"name":"","industry":"","logo":"","companyInfo":{"size":"","culture":[],"benefits":[],"interviewProcess":[]},"applicationTimeline":{"internship":"","fullTime":"","contractor":"","coop":""},"preparationChecklist":[{"id":"1","title":"","description":"","completed":false,"category":"Portfolio"}]}

Use cautious language for facts that may change. Do not invent event dates, URLs, benefits, hiring timelines, or interview steps. Checklist categories must be Portfolio, Interview Prep, Culture Study, or Technical Skills.`;

  const upstream = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  const data = await upstream.json() as {
    content?: Array<{ text?: string }>;
    error?: { message?: string };
  };

  if (!upstream.ok) {
    throw new AppError(data.error?.message || 'Company enrichment request failed', upstream.status);
  }

  const text = data.content?.[0]?.text;
  if (!text) {
    throw new AppError('AI provider returned an empty response', 502);
  }

  try {
    res.json(JSON.parse(text.trim()));
  } catch {
    throw new AppError('AI provider returned invalid JSON', 502);
  }
}));

export default router;
