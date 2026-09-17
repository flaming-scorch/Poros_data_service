import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { query } from '../config/database';
import { transformToCamelCase, transformToSnakeCase } from '../utils/transform';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import { authenticate, AuthRequest } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

import { createClient } from '@supabase/supabase-js';

const router = Router();

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL || '';
// Initialize Supabase Admin client for uploads (bypasses RLS)
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
if (!supabaseServiceKey) {
  console.warn('SUPABASE_SERVICE_ROLE_KEY is missing. Uploads may fail if RLS is enabled.');
}

// Create a single admin client instance if key exists, otherwise fallback to anon (which might fail)
const supabaseAdmin = supabaseServiceKey
  ? createClient(supabaseUrl, supabaseServiceKey)
  : createClient(supabaseUrl, process.env.SUPABASE_KEY || ''); // Fallback to anon client if service key is missing

router.use(authenticate);

/**
 * GET /api/resumes
 * Get all resumes for the authenticated user
 */
router.get('/', asyncHandler(async (req: AuthRequest, res: Response) => {
  const userId = req.userId!;

  const result = await query(
    'SELECT * FROM resumes WHERE user_id = $1 ORDER BY is_primary DESC, uploaded_at DESC',
    [userId]
  );

  res.json(transformToCamelCase(result.rows));
}));

/**
 * GET /api/resumes/tailored
 * Get all tailored resumes for the authenticated user
 */
router.get('/tailored', asyncHandler(async (req: AuthRequest, res: Response) => {
  const userId = req.userId!;

  const result = await query(
    `SELECT tr.*, r.name as original_resume_name, r.file_uri as original_resume_uri
     FROM tailored_resumes tr
     JOIN resumes r ON tr.original_resume_id = r.id
     WHERE tr.user_id = $1
     ORDER BY tr.tailored_at DESC`,
    [userId]
  );

  res.json(transformToCamelCase(result.rows));
}));

/**
 * GET /api/resumes/tailored/:id
 * Get a specific tailored resume
 */
router.get('/tailored/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const tailoredResumeId = req.params.id;
  const userId = req.userId!;

  const result = await query(
    `SELECT tr.*, r.name as original_resume_name, r.file_uri as original_resume_uri
     FROM tailored_resumes tr
     JOIN resumes r ON tr.original_resume_id = r.id
     WHERE tr.id = $1 AND tr.user_id = $2`,
    [tailoredResumeId, userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Tailored resume not found', 404);
  }

  res.json(transformToCamelCase(result.rows[0]));
}));

/**
 * GET /api/resumes/:id
 * Get a specific resume
 */
router.get('/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const resumeId = req.params.id;
  const userId = req.userId!;

  const result = await query(
    'SELECT * FROM resumes WHERE id = $1 AND user_id = $2',
    [resumeId, userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Resume not found', 404);
  }

  res.json(transformToCamelCase(result.rows[0]));
}));

// Configure Multer for memory storage (buffer)
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Only PDF files are allowed!'));
    }
  }
});

/**
 * POST /api/resumes
 * Upload a new resume
 */
router.post(
  '/',
  upload.single('file'), // Multer middleware
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    // removed fileUri/fileName checks as they come from file
    body('isPrimary').optional(),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      // Clean up uploaded file if validation error
      // Memory storage auto-cleans, but if using disk we would unlink

      return res.status(400).json({ errors: errors.array() });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const userId = req.userId!;
    const { name, isPrimary } = req.body;

    // Parse isPrimary since it comes as string in FormData 'true'/'false'
    const isPrimaryBool = isPrimary === 'true';

    // If this is set as primary, unset other primary resumes
    if (isPrimaryBool) {
      await query('UPDATE resumes SET is_primary = FALSE WHERE user_id = $1', [userId]);
    }

    const resumeId = uuidv4();
    const fileName = req.file.originalname;

    // Upload file to Supabase Storage
    const uniqueSuffix = `${Date.now()}-${uuidv4()}`;
    const ext = path.extname(fileName);
    const storagePath = `${userId}/${uniqueSuffix}${ext}`;

    const { data: uploadData, error: uploadError } = await supabaseAdmin
      .storage
      .from('resumes')
      .upload(storagePath, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: false
      });

    if (uploadError) {
      console.log('Supabase Config:', {
        url: supabaseUrl ? 'Set' : 'Missing',
        key: supabaseServiceKey ? 'Set' : 'Missing'
      });
      console.error('Supabase upload error details:', JSON.stringify(uploadError, null, 2));
      throw new AppError('Failed to upload file to storage', 500);
    }

    // Get public URL
    const { data: { publicUrl } } = supabaseAdmin
      .storage
      .from('resumes')
      .getPublicUrl(storagePath);

    const fileUri = publicUrl;

    const result = await query(
      `INSERT INTO resumes (id, user_id, name, file_name, file_uri, is_primary)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [resumeId, userId, name, fileName, fileUri, isPrimaryBool]
    );

    // Update user's resume_uri if this is primary
    if (isPrimaryBool) {
      await query('UPDATE users SET resume_uri = $1 WHERE id = $2', [fileUri, userId]);
    }

    res.status(201).json(transformToCamelCase(result.rows[0]));
  })
);

/**
 * PUT /api/resumes/:id
 * Update a resume
 */
router.put(
  '/:id',
  [
    body('name').optional().trim().notEmpty(),
    body('isPrimary').optional().isBoolean(),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const resumeId = req.params.id;
    const userId = req.userId!;

    // Verify resume belongs to user
    const existing = await query('SELECT id, file_uri FROM resumes WHERE id = $1 AND user_id = $2', [resumeId, userId]);
    if (existing.rows.length === 0) {
      throw new AppError('Resume not found', 404);
    }

    const updates = transformToSnakeCase(req.body);
    const { is_primary } = updates;

    // If setting as primary, unset other primary resumes
    if (is_primary) {
      await query('UPDATE resumes SET is_primary = FALSE WHERE user_id = $1 AND id != $2', [userId, resumeId]);
      // Update user's resume_uri
      await query('UPDATE users SET resume_uri = $1 WHERE id = $2', [existing.rows[0].file_uri, userId]);
    }

    const allowedFields = ['name', 'is_primary'];
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

    updateValues.push(resumeId, userId);
    const result = await query(
      `UPDATE resumes SET ${updateFields.join(', ')} 
       WHERE id = $${paramIndex} AND user_id = $${paramIndex + 1}
       RETURNING *`,
      updateValues
    );

    res.json(transformToCamelCase(result.rows[0]));
  })
);

/**
 * DELETE /api/resumes/:id
 * Delete a resume
 */
router.delete('/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const resumeId = req.params.id;
  const userId = req.userId!;

  const result = await query(
    'DELETE FROM resumes WHERE id = $1 AND user_id = $2 RETURNING id',
    [resumeId, userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Resume not found', 404);
  }

  res.json({ message: 'Resume deleted successfully' });
}));

/**
 * POST /api/resumes/tailor
 * Create a tailored resume
 */
router.post(
  '/tailor',
  [
    body('originalResumeId').trim().notEmpty().withMessage('Original resume ID is required'),
    body('jobDescription').trim().notEmpty().withMessage('Job description is required'),
    body('companyName').trim().notEmpty().withMessage('Company name is required'),
    body('positionTitle').trim().notEmpty().withMessage('Position title is required'),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.userId!;
    const { originalResumeId, jobDescription, companyName, positionTitle } = req.body;

    // Verify resume belongs to user
    const resume = await query('SELECT id FROM resumes WHERE id = $1 AND user_id = $2', [originalResumeId, userId]);
    if (resume.rows.length === 0) {
      throw new AppError('Resume not found', 404);
    }

    const tailoredResumeId = uuidv4();
    const result = await query(
      `INSERT INTO tailored_resumes (id, original_resume_id, user_id, job_description, company_name, position_title, processing_status)
       VALUES ($1, $2, $3, $4, $5, $6, 'processing')
       RETURNING *`,
      [tailoredResumeId, originalResumeId, userId, jobDescription, companyName, positionTitle]
    );

    // TODO: In a real implementation, you would trigger an AI service here to process the resume
    // For now, we'll just return the created record with 'processing' status

    res.status(201).json(transformToCamelCase(result.rows[0]));
  })
);



/**
 * PUT /api/resumes/tailored/:id
 * Update a tailored resume (upload file)
 */
router.put(
  '/tailored/:id',
  upload.single('file'),
  [
    body('processingStatus').optional().isIn(['processing', 'completed', 'failed']),
  ],
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const tailoredResumeId = req.params.id;
    const userId = req.userId!;

    // Verify it exists
    const existing = await query('SELECT id FROM tailored_resumes WHERE id = $1 AND user_id = $2', [tailoredResumeId, userId]);
    if (existing.rows.length === 0) {
      throw new AppError('Tailored resume not found', 404);
    }

    let fileUri = undefined;

    // Handle file upload if present
    if (req.file) {
      const fileName = req.file.originalname;
      const uniqueSuffix = `${Date.now()}-${uuidv4()}`;
      const ext = path.extname(fileName) || '.pdf'; // valid for blob uploads
      const storagePath = `${userId}/tailored/${uniqueSuffix}${ext}`;

      const { data, error: uploadError } = await supabaseAdmin
        .storage
        .from('resumes')
        .upload(storagePath, req.file.buffer, {
          contentType: req.file.mimetype || 'application/pdf',
          upsert: false
        });

      if (uploadError) {
        console.error('Supabase upload error:', uploadError);
        throw new AppError('Failed to upload tailored resume', 500);
      }

      const { data: { publicUrl } } = supabaseAdmin
        .storage
        .from('resumes')
        .getPublicUrl(storagePath);

      fileUri = publicUrl;
    }

    const updates = req.body;
    let queryText = 'UPDATE tailored_resumes SET updated_at = CURRENT_TIMESTAMP';
    const values = [];
    let paramIndex = 1;

    if (fileUri) {
      queryText += `, file_uri = $${paramIndex}`;
      values.push(fileUri);
      paramIndex++;
    }

    if (updates.processingStatus) {
      queryText += `, processing_status = $${paramIndex}`;
      values.push(updates.processingStatus);
      paramIndex++;
    }

    // Add other fields if needed

    queryText += ` WHERE id = $${paramIndex} AND user_id = $${paramIndex + 1} RETURNING *`;
    values.push(tailoredResumeId, userId);

    const result = await query(queryText, values);

    // Fetch the joined data to return consistent format
    const fullResult = await query(
      `SELECT tr.*, r.name as original_resume_name, r.file_uri as original_resume_uri
       FROM tailored_resumes tr
       JOIN resumes r ON tr.original_resume_id = r.id
       WHERE tr.id = $1`,
      [tailoredResumeId]
    );

    res.json(transformToCamelCase(fullResult.rows[0]));
  })
);

/**
 * DELETE /api/resumes/tailored/:id
 * Delete a tailored resume
 */
router.delete('/tailored/:id', asyncHandler(async (req: AuthRequest, res: Response) => {
  const tailoredResumeId = req.params.id;
  const userId = req.userId!;

  // First check if it exists and get file URI to delete from storage if needed
  // (Optional: delete from Supabase storage if we stored a separate copy)

  const result = await query(
    'DELETE FROM tailored_resumes WHERE id = $1 AND user_id = $2 RETURNING id',
    [tailoredResumeId, userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('Tailored resume not found', 404);
  }

  res.json({ message: 'Tailored resume deleted successfully', id: tailoredResumeId });
}));



export default router;


