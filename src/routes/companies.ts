import { Router, Response } from 'express';
import { query } from '../config/database';
import { body, validationResult } from 'express-validator';
import { transformToCamelCase } from '../utils/transform';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, AuthRequest } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

// All routes require authentication
router.use(authenticate);

/**
 * GET /api/companies
 * Get all companies with event, course, and checklist counts
 */
router.get('/', asyncHandler(async (req: AuthRequest, res: Response) => {
  const result = await query('SELECT * FROM company_recommendations_view ORDER BY name');
  res.json(transformToCamelCase(result.rows));
}));

/**
 * GET /api/companies/:id
 * Get company with all related events, courses, and checklist items
 */
router.get('/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const companyId = req.params.id;

  // Get company
  const companyResult = await query('SELECT * FROM companies WHERE id = $1', [companyId]);
  if (companyResult.rows.length === 0) {
    throw new AppError('Company not found', 404);
  }

  const company = companyResult.rows[0];

  // Get events
  const eventsResult = await query(
    'SELECT * FROM events WHERE company_id = $1 ORDER BY event_date ASC',
    [companyId]
  );
  company.events = eventsResult.rows;

  // Get courses
  const coursesResult = await query(
    'SELECT * FROM courses WHERE company_id = $1 ORDER BY title ASC',
    [companyId]
  );
  company.courses = coursesResult.rows;

  // Get checklist items (template items where user_id is NULL)
  const checklistResult = await query(
    'SELECT * FROM checklist_items WHERE company_id = $1 AND user_id IS NULL ORDER BY category, title',
    [companyId]
  );
  company.checklistItems = checklistResult.rows;

  res.json(transformToCamelCase(company));
}));

/**
 * POST /api/companies
 * Create a new company
 */
router.post(
  '/',
  [
    body('name').trim().notEmpty().withMessage('Company name is required'),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      id: customId, // Client might send a custom ID (e.g. custom-123-google)
      name,
      logo,
      industry,
      companyInfo,
      events,
      recommendedCourses,
      preparationChecklist
    } = req.body;

    const notes = req.body.notes || ''; // Optional notes

    // Check if company already exists by name
    const existing = await query('SELECT * FROM companies WHERE name = $1', [name]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'Company already exists' });
    }

    // Begin transaction-like sequence (not real DB transaction without client, but sequential)

    // 1. Insert Company
    const generatedId = uuidv4();

    // Insert new company
    // Using RETURNING id to get the generated ID
    const companyResult = await query(
      `INSERT INTO companies (id, name, notes, logo, industry, company_info) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       RETURNING *`,
      [generatedId, name, notes, logo, industry, companyInfo]
    );
    const newCompany = companyResult.rows[0];
    const newCompanyId = newCompany.id;

    // 2. Insert Events
    if (events && Array.isArray(events)) {
      for (const event of events) {
        const eventId = uuidv4();
        await query(
          `INSERT INTO events (id, company_id, title, description, event_date, type, registration_link)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [eventId, newCompanyId, event.title, event.description, event.date, event.type, event.registrationLink]
        );
      }
    }

    // 3. Insert Courses
    if (recommendedCourses && Array.isArray(recommendedCourses)) {
      for (const course of recommendedCourses) {
        const courseId = uuidv4();
        await query(
          `INSERT INTO courses (id, company_id, title, provider, duration, level, link, skills)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [courseId, newCompanyId, course.title, course.provider, course.duration, course.level, course.link, course.skills]
        );
      }
    }

    // 4. Insert Checklist Items (Templates)
    if (preparationChecklist && Array.isArray(preparationChecklist)) {
      for (const item of preparationChecklist) {
        const itemId = uuidv4();
        // user_id is NULL for template items
        await query(
          `INSERT INTO checklist_items (id, company_id, title, description, category, user_id)
           VALUES ($1, $2, $3, $4, $5, NULL)`,
          [itemId, newCompanyId, item.title, item.description, item.category]
        );
      }
    }

    // Return the full company object (reload it to be safe, or construct it)
    // Constructing it saves a query
    const fullCompany = {
      ...transformToCamelCase(newCompany),
      events: events || [],
      courses: recommendedCourses || [],
      checklistItems: preparationChecklist || []
    };

    res.status(201).json(fullCompany);
  })
);

export default router;


