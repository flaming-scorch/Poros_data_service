# Poros Data Service API

Backend API service for the Poros application, built with Node.js, Express, and TypeScript.

## Features

- ✅ RESTful API with TypeScript
- ✅ PostgreSQL database integration
- ✅ JWT authentication
- ✅ Automatic data transformation (snake_case ↔ camelCase)
- ✅ Input validation
- ✅ Error handling
- ✅ CORS and security headers

## Setup

### Prerequisites

- Node.js 18+ and npm
- PostgreSQL 12+
- Database created and schema loaded (see main README)

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file (copy from `.env.example`):
```bash
cp .env.example .env
```

3. Configure your `.env` file:
```env
DATABASE_URL=postgresql://localhost:5432/poros
# OR use individual settings:
DB_HOST=localhost
DB_PORT=5432
DB_NAME=poros
DB_USER=postgres
DB_PASSWORD=your_password

JWT_SECRET=your-secret-key-change-this-in-production
JWT_EXPIRES_IN=7d

PORT=3000
NODE_ENV=development
```

4. Build the TypeScript code:
```bash
npm run build
```

5. Start the server:
```bash
npm start
```

For development with auto-reload:
```bash
npm run dev
```

## API Endpoints

### Authentication

#### `POST /api/auth/signup`
Create a new user account.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "university": "Calvin University",
  "major": "Computer Science",
  "graduationYear": 2024,
  "linkedinProfile": "https://linkedin.com/in/johndoe",
  "weeklyGoal": 5
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "university": "Calvin University",
    "major": "Computer Science",
    "graduationYear": 2024,
    "weeklyGoal": 5,
    "createdAt": "2024-01-15T10:30:00Z"
  },
  "token": "jwt_token_here"
}
```

#### `POST /api/auth/login`
Authenticate user and get token.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": { ... },
  "token": "jwt_token_here"
}
```

### Users

All user endpoints require authentication (Bearer token in Authorization header).

#### `GET /api/users/:id`
Get user profile with target companies, roles, industries, and locations.

**Response:**
```json
{
  "id": "uuid",
  "name": "John Doe",
  "email": "john@example.com",
  "university": "Calvin University",
  "major": "Computer Science",
  "graduationYear": 2024,
  "targetCompanies": ["1", "2", "3"],
  "targetRoles": ["Software Engineer", "Product Manager"],
  "targetIndustries": ["Technology", "Finance"],
  "targetLocations": ["San Francisco", "Seattle"],
  "weeklyGoal": 5,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

#### `PUT /api/users/:id`
Update user profile.

**Request Body:**
```json
{
  "name": "John Updated",
  "university": "New University",
  "major": "New Major",
  "graduationYear": 2025,
  "weeklyGoal": 7
}
```

#### `PUT /api/users/:id/targets`
Update user target companies, roles, industries, locations.

**Request Body:**
```json
{
  "targetCompanies": ["1", "2"],
  "targetRoles": ["Software Engineer"],
  "targetIndustries": ["Technology"],
  "targetLocations": ["San Francisco"]
}
```

#### `GET /api/users/:id/stats`
Get user dashboard statistics.

**Response:**
```json
{
  "userId": "uuid",
  "totalApplications": 10,
  "pendingApplications": 5,
  "interviews": 3,
  "offers": 1,
  "rejected": 1,
  "weeklyGoal": 5,
  "weeklyProgress": 3
}
```

### Companies

#### `GET /api/companies`
Get all companies with event, course, and checklist counts.

**Response:**
```json
[
  {
    "id": "1",
    "name": "Meta",
    "logo": "🔵",
    "industry": "Social Media & Technology",
    "eventCount": 3,
    "courseCount": 3,
    "checklistCount": 4,
    ...
  }
]
```

#### `GET /api/companies/:id`
Get company with all related events, courses, and checklist items.

**Response:**
```json
{
  "id": "1",
  "name": "Meta",
  "logo": "🔵",
  "industry": "Social Media & Technology",
  "events": [...],
  "courses": [...],
  "checklistItems": [...]
}
```

### Applications

#### `GET /api/applications`
Get all applications for the authenticated user.

#### `GET /api/applications/:id`
Get a specific application.

#### `POST /api/applications`
Create a new application.

**Request Body:**
```json
{
  "company": "Meta",
  "role": "Software Engineer",
  "location": "San Francisco, CA",
  "status": "Applied",
  "appliedDate": "2024-01-15",
  "notes": "Applied through company website",
  "companyLogo": "https://example.com/logo.png"
}
```

#### `PUT /api/applications/:id`
Update an application.

#### `DELETE /api/applications/:id`
Delete an application.

### Resumes

#### `GET /api/resumes`
Get all resumes for the authenticated user.

#### `GET /api/resumes/:id`
Get a specific resume.

#### `POST /api/resumes`
Upload a new resume.

**Request Body:**
```json
{
  "name": "My Resume",
  "fileName": "resume.pdf",
  "fileUri": "https://storage.example.com/resume.pdf",
  "isPrimary": true
}
```

#### `PUT /api/resumes/:id`
Update a resume.

#### `DELETE /api/resumes/:id`
Delete a resume.

#### `POST /api/resumes/tailor`
Create a tailored resume.

**Request Body:**
```json
{
  "originalResumeId": "uuid",
  "jobDescription": "Job description text...",
  "companyName": "Meta",
  "positionTitle": "Software Engineer"
}
```

#### `GET /api/resumes/tailored`
Get all tailored resumes for the authenticated user.

#### `GET /api/resumes/tailored/:id`
Get a specific tailored resume.

### Checklist

#### `GET /api/checklist`
Get all user-specific checklist items (optionally filtered by companyId).

#### `GET /api/checklist/:id`
Get a specific checklist item.

#### `POST /api/checklist`
Create a user-specific checklist item.

**Request Body:**
```json
{
  "companyId": "1",
  "title": "Complete portfolio project",
  "description": "Build a React app",
  "completed": false,
  "category": "Portfolio"
}
```

#### `PUT /api/checklist/:id`
Update a checklist item.

#### `DELETE /api/checklist/:id`
Delete a checklist item.

## Authentication

All endpoints except `/api/auth/*` require authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Data Transformation

The API automatically transforms data between:
- **Database format**: snake_case (e.g., `created_at`, `user_id`)
- **API format**: camelCase (e.g., `createdAt`, `userId`)

Arrays from junction tables are automatically aggregated:
- `user_target_companies` → `targetCompanies` array
- `user_target_roles` → `targetRoles` array
- etc.

## Error Handling

The API returns standard HTTP status codes:

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden (user doesn't have access)
- `404` - Not Found
- `409` - Conflict (e.g., email already exists)
- `500` - Internal Server Error

Error response format:
```json
{
  "error": "Error message here"
}
```

## Development

### Project Structure

```
src/
├── config/
│   └── database.ts          # Database connection
├── middleware/
│   ├── auth.ts              # Authentication middleware
│   └── errorHandler.ts      # Error handling
├── routes/
│   ├── auth.ts              # Authentication routes
│   ├── users.ts             # User routes
│   ├── companies.ts         # Company routes
│   ├── applications.ts      # Application routes
│   ├── resumes.ts          # Resume routes
│   └── checklist.ts         # Checklist routes
├── utils/
│   ├── auth.ts              # Auth utilities (hash, JWT)
│   └── transform.ts         # Data transformation
└── index.ts                 # Main server file
```

### Type Checking

```bash
npm run type-check
```

### Building

```bash
npm run build
```

## Testing

You can test the API using tools like:
- Postman
- curl
- httpie
- Your client application

Example with curl:

```bash
# Sign up
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "university": "Calvin University",
    "major": "Computer Science",
    "graduationYear": 2024
  }'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'

# Get companies (with token)
curl http://localhost:3000/api/companies \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Production Deployment

1. Set `NODE_ENV=production` in your environment
2. Use a strong `JWT_SECRET`
3. Configure proper CORS origins
4. Use environment variables for all sensitive data
5. Set up proper logging and monitoring
6. Use a process manager like PM2
7. Set up SSL/TLS (HTTPS)

## Next Steps

- [ ] Add rate limiting
- [ ] Add request logging
- [ ] Add API documentation (Swagger/OpenAPI)
- [ ] Add unit and integration tests
- [ ] Add file upload handling for resumes
- [ ] Integrate AI service for resume tailoring
- [ ] Add email verification
- [ ] Add password reset functionality


