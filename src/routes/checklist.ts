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
 * GET /api/checklist
 * Get all checklist items for the authenticated user (both template and user-specific)
 */
router.get('/', asyncHandler(async (req: AuthRequest, res: Response) => {
  const userId = req.userId!;
  const { companyId } = req.query;

  let queryText = 'SELECT * FROM checklist_items WHERE user_id = $1';
  const params: any[] = [userId];

  if (companyId) {
    queryText += ' AND company_id = $2';
    params.push(companyId);
  }

  queryText += ' ORDER BY category, title';

  const result = await query(queryText, params);
  res.json(transformToCamelCase(result.rows));
}));

/**
 * GET /api/checklist/:id
 * Get a specific checklist item
 */
router.get('/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const checklistId = req.params.id;
  const userId = req.userId!;

  const result = await query(
    'SELECT * FROM checklist_items WHERE id = $1 AND user_id = $2',
    [checklistId, userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Checklist item not found', 404);
  }

  res.json(transformToCamelCase(result.rows[0]));
}));

/**
 * POST /api/checklist
 * Create a user-specific checklist item
 */
router.post(
  '/',
  [
    body('companyId').trim().notEmpty().withMessage('Company ID is required'),
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('category').isIn(['Interview Prep', 'Portfolio', 'Culture Study', 'Technical Skills']).withMessage('Valid category is required'),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.userId!;
    const { companyId, title, description, completed, category } = req.body;

    // Check if item already exists for this user/company/title
    const existing = await query(
      'SELECT id FROM checklist_items WHERE user_id = $1 AND company_id = $2 AND title = $3',
      [userId, companyId, title]
    );

    let result;
    if (existing.rows.length > 0) {
      // Update existing
      result = await query(
        `UPDATE checklist_items 
         SET completed = $1, description = COALESCE($2, description), category = COALESCE($3, category)
         WHERE id = $4
         RETURNING *`,
        [completed || false, description, category, existing.rows[0].id]
      );
    } else {
      // Insert new
      const checklistId = uuidv4();
      result = await query(
        `INSERT INTO checklist_items (id, company_id, user_id, title, description, completed, category)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [checklistId, companyId, userId, title, description || null, completed || false, category]
      );
    }

    res.status(201).json(transformToCamelCase(result.rows[0]));
  })
);

/**
 * PUT /api/checklist/:id
 * Update a checklist item
 */
router.put(
  '/:id',
  [
    body('category').optional().isIn(['Interview Prep', 'Portfolio', 'Culture Study', 'Technical Skills']),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const checklistId = req.params.id;
    const userId = req.userId!;

    // Verify checklist item belongs to user
    const existing = await query('SELECT id FROM checklist_items WHERE id = $1 AND user_id = $2', [checklistId, userId]);
    if (existing.rows.length === 0) {
      throw new AppError('Checklist item not found', 404);
    }

    const updates = transformToSnakeCase(req.body);
    const allowedFields = ['title', 'description', 'completed', 'category'];
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

    updateValues.push(checklistId, userId);
    const result = await query(
      `UPDATE checklist_items SET ${updateFields.join(', ')} 
       WHERE id = $${paramIndex} AND user_id = $${paramIndex + 1}
       RETURNING *`,
      updateValues
    );

    res.json(transformToCamelCase(result.rows[0]));
  })
);

/**
 * DELETE /api/checklist/:id
 * Delete a checklist item
 */
router.delete('/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const checklistId = req.params.id;
  const userId = req.userId!;

  const result = await query(
    'DELETE FROM checklist_items WHERE id = $1 AND user_id = $2 RETURNING id',
    [checklistId, userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Checklist item not found', 404);
  }

  res.json({ message: 'Checklist item deleted successfully' });
}));

export default router;


