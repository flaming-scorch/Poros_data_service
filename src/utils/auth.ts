import bcrypt from 'bcrypt';
import jwt, { SignOptions } from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * Hash a password using bcrypt
 */
export async function hashPassword(password: string): Promise<string> {
  const saltRounds = 10;
  return bcrypt.hash(password, saltRounds);
}

/**
 * Compare a password with a hash
 */
export async function comparePassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

/**
 * Generate a JWT token for a user
 */
export function generateToken(userId: string, email: string): string {
  const secret = JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET is not configured');
  }
  return jwt.sign(
    { userId, email },
    secret,
    { expiresIn: JWT_EXPIRES_IN } as SignOptions
  );
}

/**
 * Verify a JWT token
 */
export function verifyToken(token: string): { userId: string; email: string } {
  const secret = JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET is not configured');
  }
  try {
    const decoded = jwt.verify(token, secret) as { userId: string; email: string };
    return decoded;
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
}
