import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../config/database';
import { hashPassword, comparePassword, generateToken } from '../utils/auth';
import { transformToCamelCase } from '../utils/transform';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

/**
 * POST /api/auth/signup
 * Create a new user account
 */
router.post(
  '/signup',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('university').trim().notEmpty().withMessage('University is required'),
    body('major').trim().notEmpty().withMessage('Major is required'),
    body('graduationYear').isInt({ min: 2020, max: 2030 }).withMessage('Valid graduation year is required'),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email, password, university, major, graduationYear, linkedinProfile, weeklyGoal } = req.body;

    // Check if user already exists
    const existingUser = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      throw new AppError('User with this email already exists', 409);
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Create user
    const userId = uuidv4();
    const result = await query(
      `INSERT INTO users (id, name, email, password_hash, university, major, graduation_year, linkedin_profile, weekly_goal)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, name, email, university, major, graduation_year, linkedin_profile, weekly_goal, created_at`,
      [userId, name, email, passwordHash, university, major, graduationYear, linkedinProfile || null, weeklyGoal || 5]
    );

    const user = transformToCamelCase(result.rows[0]);
    const token = generateToken(userId, email);

    res.status(201).json({
      user,
      token,
    });
  })
);

/**
 * POST /api/auth/login
 * Authenticate user and return token
 */
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  asyncHandler(async (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    // Find user
    const result = await query(
      'SELECT id, name, email, password_hash, university, major, graduation_year, linkedin_profile, weekly_goal, created_at FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      throw new AppError('Invalid email or password', 401);
    }

    const user = result.rows[0];

    // Verify password
    const isValid = await comparePassword(password, user.password_hash);
    if (!isValid) {
      throw new AppError('Invalid email or password', 401);
    }

    // Generate token
    const token = generateToken(user.id, user.email);

    // Remove password_hash from response
    delete user.password_hash;
    const userResponse = transformToCamelCase(user);

    res.json({
      user: userResponse,
      token,
    });
  })
);

export default router;


