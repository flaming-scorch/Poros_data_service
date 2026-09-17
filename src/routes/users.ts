import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../config/database';
import { transformToCamelCase, transformToSnakeCase } from '../utils/transform';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

/**
 * GET /api/users/:id
 * Get user profile with target companies, roles, industries, locations
 */
router.get('/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const userId = req.params.id;

  // Verify user can only access their own profile
  if (userId !== req.userId) {
    throw new AppError('Unauthorized', 403);
  }

  // Get user with all related data
  const userResult = await query(
    `SELECT id, name, email, linkedin_profile, university, major, graduation_year, 
            resume_uri, weekly_goal, created_at, updated_at
     FROM users WHERE id = $1`,
    [userId]
  );

  if (userResult.rows.length === 0) {
    throw new AppError('User not found', 404);
  }

  const user = userResult.rows[0];

  // Get target companies
  const companiesResult = await query(
    `SELECT company_id FROM user_target_companies WHERE user_id = $1 ORDER BY priority DESC, added_at ASC`,
    [userId]
  );
  user.target_companies = companiesResult.rows.map((row: any) => row.company_id);

  // Get target roles
  const rolesResult = await query(
    `SELECT role FROM user_target_roles WHERE user_id = $1`,
    [userId]
  );
  user.target_roles = rolesResult.rows.map((row: any) => row.role);

  // Get target industries
  const industriesResult = await query(
    `SELECT industry FROM user_target_industries WHERE user_id = $1`,
    [userId]
  );
  user.target_industries = industriesResult.rows.map((row: any) => row.industry);

  // Get target locations
  const locationsResult = await query(
    `SELECT location FROM user_target_locations WHERE user_id = $1`,
    [userId]
  );
  user.target_locations = locationsResult.rows.map((row: any) => row.location);

  res.json(transformToCamelCase(user));
}));

/**
 * PUT /api/users/:id
 * Update user profile
 */
router.put(
  '/:id',
  [
    body('name').optional().trim().notEmpty(),
    body('university').optional().trim().notEmpty(),
    body('major').optional().trim().notEmpty(),
    body('graduationYear').optional().isInt({ min: 2020, max: 2030 }),
    body('weeklyGoal').optional().isInt({ min: 1, max: 20 }),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.params.id;

    // Verify user can only update their own profile
    if (userId !== req.userId) {
      throw new AppError('Unauthorized', 403);
    }

    const updates = transformToSnakeCase(req.body);
    const allowedFields = ['name', 'university', 'major', 'graduation_year', 'linkedin_profile', 'weekly_goal'];
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

    updateValues.push(userId);
    const result = await query(
      `UPDATE users SET ${updateFields.join(', ')} WHERE id = $${paramIndex} 
       RETURNING id, name, email, linkedin_profile, university, major, graduation_year, resume_uri, weekly_goal, created_at, updated_at`,
      updateValues
    );

    if (result.rows.length === 0) {
      throw new AppError('User not found', 404);
    }

    res.json(transformToCamelCase(result.rows[0]));
  })
);

/**
 * PUT /api/users/:id/targets
 * Update user target companies, roles, industries, locations
 */
router.put(
  '/:id/targets',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.params.id;

    // Verify user can only update their own targets
    if (userId !== req.userId) {
      throw new AppError('Unauthorized', 403);
    }

    const { targetCompanies, targetRoles, targetIndustries, targetLocations } = req.body;

    // Update target companies
    if (targetCompanies !== undefined) {
      await query('DELETE FROM user_target_companies WHERE user_id = $1', [userId]);
      if (Array.isArray(targetCompanies) && targetCompanies.length > 0) {
        for (const companyId of targetCompanies) {
          await query(
            'INSERT INTO user_target_companies (user_id, company_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [userId, companyId]
          );
        }
      }
    }

    // Update target roles
    if (targetRoles !== undefined) {
      await query('DELETE FROM user_target_roles WHERE user_id = $1', [userId]);
      if (Array.isArray(targetRoles) && targetRoles.length > 0) {
        for (const role of targetRoles) {
          await query(
            'INSERT INTO user_target_roles (user_id, role) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [userId, role]
          );
        }
      }
    }

    // Update target industries
    if (targetIndustries !== undefined) {
      await query('DELETE FROM user_target_industries WHERE user_id = $1', [userId]);
      if (Array.isArray(targetIndustries) && targetIndustries.length > 0) {
        for (const industry of targetIndustries) {
          await query(
            'INSERT INTO user_target_industries (user_id, industry) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [userId, industry]
          );
        }
      }
    }

    // Update target locations
    if (targetLocations !== undefined) {
      await query('DELETE FROM user_target_locations WHERE user_id = $1', [userId]);
      if (Array.isArray(targetLocations) && targetLocations.length > 0) {
        for (const location of targetLocations) {
          await query(
            'INSERT INTO user_target_locations (user_id, location) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [userId, location]
          );
        }
      }
    }

    res.json({ message: 'Targets updated successfully' });
  })
);

/**
 * GET /api/users/:id/stats
 * Get user dashboard statistics
 */
router.get('/:id/stats', asyncHandler(async (req: AuthRequest, res: Response) => {
  const userId = req.params.id;

  // Verify user can only access their own stats
  if (userId !== req.userId) {
    throw new AppError('Unauthorized', 403);
  }

  const result = await query(
    'SELECT * FROM user_dashboard_stats WHERE user_id = $1',
    [userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Stats not found', 404);
  }

  res.json(transformToCamelCase(result.rows[0]));
}));

export default router;


