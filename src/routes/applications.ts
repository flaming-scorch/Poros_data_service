import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../config/database';
import { transformToCamelCase, transformToSnakeCase } from '../utils/transform';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, AuthRequest } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

// All routes require authentication
router.use(authenticate);

/**
 * GET /api/applications
 * Get all applications for the authenticated user
 */
router.get('/', asyncHandler(async (req: AuthRequest, res: Response) => {
  const userId = req.userId!;

  const result = await query(
    'SELECT * FROM applications WHERE user_id = $1 ORDER BY applied_date DESC, created_at DESC',
    [userId]
  );

  res.json(transformToCamelCase(result.rows));
}));

/**
 * GET /api/applications/:id
 * Get a specific application
 */
router.get('/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const applicationId = req.params.id;
  const userId = req.userId!;

  const result = await query(
    'SELECT * FROM applications WHERE id = $1 AND user_id = $2',
    [applicationId, userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Application not found', 404);
  }

  res.json(transformToCamelCase(result.rows[0]));
}));

/**
 * POST /api/applications
 * Create a new application
 */
router.post(
  '/',
  [
    body('company').trim().notEmpty().withMessage('Company is required'),
    body('role').trim().notEmpty().withMessage('Role is required'),
    body('location').trim().notEmpty().withMessage('Location is required'),
    body('status').isIn(['Applied', 'Interview', 'Offer', 'Rejected']).withMessage('Valid status is required'),
    body('appliedDate').notEmpty().withMessage('Applied date is required'),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.userId!;
    const { company, role, location, status, appliedDate, notes, companyLogo } = req.body;

    const applicationId = uuidv4();
    const result = await query(
      `INSERT INTO applications (id, user_id, company, role, location, status, applied_date, notes, company_logo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [applicationId, userId, company, role, location, status, appliedDate, notes || null, companyLogo || null]
    );

    res.status(201).json(transformToCamelCase(result.rows[0]));
  })
);

/**
 * PUT /api/applications/:id
 * Update an application
 */
router.put(
  '/:id',
  [
    body('status').optional().isIn(['Applied', 'Interview', 'Offer', 'Rejected']),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const applicationId = req.params.id;
    const userId = req.userId!;

    // Verify application belongs to user
    const existing = await query('SELECT id FROM applications WHERE id = $1 AND user_id = $2', [applicationId, userId]);
    if (existing.rows.length === 0) {
      throw new AppError('Application not found', 404);
    }

    const updates = transformToSnakeCase(req.body);
    const allowedFields = ['company', 'role', 'location', 'status', 'applied_date', 'notes', 'company_logo'];
    const updateFields: string[] = [];
    const updateValues: any[] = [];
    let paramIndex = 1;

    for (const field of allowedFields) {
      if (updates[field] !== undefined) {
        updateFields.push(`${field} = $${paramIndex}`);
        updateValues.push(updates[field]);
        paramIndex++;
      }
    }

    if (updateFields.length === 0) {
      throw new AppError('No valid fields to update', 400);
    }

    updateValues.push(applicationId, userId);
    const result = await query(
      `UPDATE applications SET ${updateFields.join(', ')} 
       WHERE id = $${paramIndex} AND user_id = $${paramIndex + 1}
       RETURNING *`,
      updateValues
    );

    res.json(transformToCamelCase(result.rows[0]));
  })
);

/**
 * DELETE /api/applications/:id
 * Delete an application
 */
router.delete('/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const applicationId = req.params.id;
  const userId = req.userId!;

  const result = await query(
    'DELETE FROM applications WHERE id = $1 AND user_id = $2 RETURNING id',
    [applicationId, userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Application not found', 404);
  }

  res.json({ message: 'Application deleted successfully' });
}));

export default router;


