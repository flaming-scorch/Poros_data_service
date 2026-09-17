// Vercel serverless function entry point
// This file serves as the entry point for all API routes
import app from '../src/index';

// Export the Express app directly - Vercel will handle the routing
export default app;
