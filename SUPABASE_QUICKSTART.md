# Supabase Quick Start

Get your Poros Data Service running with Supabase in 10 minutes!

## Step 1: Create Supabase Project (2 min)

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Fill in:
   - Name: `poros-data-service`
   - Database Password: (save this!)
   - Region: (choose closest)
4. Click "Create new project"
5. Wait 2-3 minutes

## Step 2: Load Database Schema (2 min)

1. In Supabase dashboard → **SQL Editor** → **New query**
2. Open `sql/poros.sql` from your project
3. Copy entire file contents
4. Paste into SQL Editor
5. Click **Run** (or Cmd/Ctrl + Enter)
6. ✅ Success!

## Step 3: Disable RLS (1 min)

Since you're using your own API (not Supabase's auto-generated API), disable Row Level Security:

1. In SQL Editor, run:
```sql
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE applications DISABLE ROW LEVEL SECURITY;
ALTER TABLE resumes DISABLE ROW LEVEL SECURITY;
ALTER TABLE tailored_resumes DISABLE ROW LEVEL SECURITY;
ALTER TABLE events DISABLE ROW LEVEL SECURITY;
ALTER TABLE courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_target_companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_target_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_target_industries DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_target_locations DISABLE ROW LEVEL SECURITY;
```

## Step 4: Get Connection String (1 min)

1. Go to **Settings** (⚙️) → **Database**
2. Under "Connection string" → "URI"
3. Copy the connection string
4. It looks like: `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres`
5. Replace `[PASSWORD]` with your actual password

## Step 5: Update .env File (1 min)

Update your `.env` file:

```env
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.xxxxx.supabase.co:5432/postgres
JWT_SECRET=your-secret-key-change-this-min-32-chars
NODE_ENV=development
PORT=3000
```

## Step 6: Test Locally (2 min)

```bash
# Install dependencies (if not done)
npm install

# Start the server
npm run dev

# Test health endpoint
curl http://localhost:3000/health

# Should return: {"status":"ok","timestamp":"..."}
```

## Step 7: Deploy API (1 min)

### Option A: Vercel (Easiest)

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel

# Add environment variables in Vercel dashboard
# Copy all from your .env file
```

### Option B: Railway

1. Go to [railway.app](https://railway.app)
2. New Project → Deploy from GitHub
3. Select your repo
4. Add environment variables
5. Deploy!

## Step 8: Update Client (1 min)

In your client app:

```typescript
// src/config/api.ts
const API_BASE_URL = __DEV__
  ? 'http://localhost:3000'
  : 'https://your-api.vercel.app'; // Your deployed URL
```

## ✅ Done!

Your setup:
- ✅ Supabase database with schema loaded
- ✅ API service running locally
- ✅ API deployed to cloud
- ✅ Client configured

## Test Everything

```bash
# Test signup
curl -X POST https://your-api.vercel.app/api/auth/signup \
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

## Troubleshooting

**Connection fails?**
- Check connection string has correct password
- Verify database isn't paused (free tier)
- Make sure SSL is enabled (automatic with Supabase)

**RLS errors?**
- Make sure you disabled RLS (Step 3)

**API won't start?**
- Check environment variables are set
- Verify database connection string

## Next Steps

- [ ] Set up auto-deployment (GitHub Actions)
- [ ] Configure CORS for your client domain
- [ ] Add monitoring/logging
- [ ] Set up database backups

For detailed setup, see [SUPABASE_SETUP.md](./SUPABASE_SETUP.md)

