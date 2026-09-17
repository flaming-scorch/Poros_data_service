# Setup Guide

Quick setup guide for the Poros Data Service.

## Prerequisites

- Node.js 18+ and npm
- PostgreSQL 12+
- Git (optional)

## Step 1: Database Setup

1. **Install PostgreSQL** (if not already installed):
   ```bash
   # macOS
   brew install postgresql@15
   brew services start postgresql@15
   
   # Or download from https://www.postgresql.org/download/
   ```

2. **Add PostgreSQL to your PATH** (if installed via Homebrew):
   
   Add this line to your `~/.zshrc` file (or `~/.bash_profile` if using bash):
   ```bash
   export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
   ```
   
   Then reload your shell:
   ```bash
   source ~/.zshrc
   ```
   
   Or for this session only:
   ```bash
   export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
   ```

3. **Create the database**:
   ```bash
   createdb poros
   ```

3. **Load the schema and seed data**:
   ```bash
   psql poros < sql/poros.sql
   ```

4. **Verify the setup** (optional):
   ```bash
   ./test_sql.sh
   ```

## Step 2: API Setup

1. **Install Node.js dependencies**:
   ```bash
   npm install
   ```

2. **Create environment file**:
   
   Create a `.env` file in the root directory with the following content:
   
   ```env
   # Database Configuration
   DATABASE_URL=postgresql://localhost:5432/poros
   # OR use individual settings:
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=poros
   DB_USER=postgres
   DB_PASSWORD=your_password_here

   # JWT Configuration
   JWT_SECRET=your-secret-key-change-this-in-production-min-32-chars
   JWT_EXPIRES_IN=7d

   # Server Configuration
   PORT=3000
   NODE_ENV=development
   ```
   
   **Important**: 
   - Replace `your_password_here` with your PostgreSQL password
   - Change `JWT_SECRET` to a strong random string (at least 32 characters) for production
   - If you don't have a PostgreSQL password, you can leave `DB_PASSWORD` empty

3. **Build the TypeScript code**:
   ```bash
   npm run build
   ```

4. **Start the server**:
   ```bash
   # Development mode (with auto-reload)
   npm run dev
   
   # OR production mode
   npm start
   ```

5. **Verify the API is running**:
   ```bash
   curl http://localhost:3000/health
   ```
   
   You should see:
   ```json
   {"status":"ok","timestamp":"2024-01-15T10:30:00.000Z"}
   ```

## Step 3: Test the API

### Test Authentication

1. **Sign up a new user**:
   ```bash
   curl -X POST http://localhost:3000/api/auth/signup \
     -H "Content-Type: application/json" \
     -d '{
       "name": "Test User",
       "email": "test@example.com",
       "password": "password123",
       "university": "Calvin University",
       "major": "Computer Science",
       "graduationYear": 2024
     }'
   ```

2. **Login**:
   ```bash
   curl -X POST http://localhost:3000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "password123"
     }'
   ```
   
   Save the `token` from the response.

3. **Get companies** (using the token):
   ```bash
   curl http://localhost:3000/api/companies \
     -H "Authorization: Bearer YOUR_TOKEN_HERE"
   ```

## Troubleshooting

### Database Connection Issues

- **Error: "connection refused"**
  - Make sure PostgreSQL is running: `brew services start postgresql@15`
  - Check your database credentials in `.env`

- **Error: "database does not exist"**
  - Create the database: `createdb poros`
  - Load the schema: `psql poros < sql/poros.sql`

### API Issues

- **Error: "Cannot find module"**
  - Run `npm install` to install dependencies
  - Run `npm run build` to compile TypeScript

- **Error: "Port already in use"**
  - Change the `PORT` in your `.env` file
  - Or stop the process using port 3000

### TypeScript Errors

- Run `npm run type-check` to see detailed TypeScript errors
- Make sure all dependencies are installed: `npm install`

## Next Steps

1. ✅ Database setup - **DONE**
2. ✅ API setup - **DONE**
3. ⚠️ Connect your client application to the API
4. ⚠️ Deploy to production (see API_README.md for production tips)

## Additional Resources

- [API Documentation](./API_README.md) - Complete API reference
- [Main README](./README.md) - Project overview
- [Compatibility Summary](./COMPATIBILITY_SUMMARY.md) - Database-client compatibility

