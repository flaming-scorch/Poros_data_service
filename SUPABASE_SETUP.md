# Supabase Setup Guide

This guide will help you set up Supabase for the Poros Data Service and connect your client app.

## What is Supabase?

Supabase is an open-source Firebase alternative that provides:
- **PostgreSQL Database** - Your existing SQL schema works perfectly
- **Authentication** - Built-in auth (optional, you can use your JWT system)
- **Auto-generated APIs** - REST and GraphQL APIs from your database
- **Real-time subscriptions** - Real-time database updates
- **Storage** - File storage for resumes
- **Edge Functions** - Serverless functions (optional)

## Step 1: Create Supabase Project

1. **Sign up/Login:**
   - Go to [supabase.com](https://supabase.com)
   - Sign up or log in with GitHub

2. **Create New Project:**
   - Click "New Project"
   - Fill in:
     - **Name**: `poros-data-service`
     - **Database Password**: Create a strong password (save it!)
     - **Region**: Choose closest to your users
     - **Pricing Plan**: Free tier is fine to start
   - Click "Create new project"
   - Wait 2-3 minutes for setup

## Step 2: Get Connection Details

1. **Go to Project Settings:**
   - Click the gear icon (⚙️) in the left sidebar
   - Click "Database" or "API"

2. **Find Connection String:**
   - Under "Connection string" → "URI"
   - Copy the connection string (looks like: `postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres`)
   - Or get individual values:
     - **Host**: `db.xxxxx.supabase.co`
     - **Port**: `5432`
     - **Database**: `postgres`
     - **User**: `postgres`
     - **Password**: (the one you set)

3. **Get API Keys:**
   - Go to Settings → API
   - Copy:
     - **Project URL**: `https://xxxxx.supabase.co`
     - **anon/public key**: (starts with `eyJ...`)
     - **service_role key**: (keep secret!)

## Step 3: Load Database Schema

### Option A: Using Supabase SQL Editor (Recommended)

1. **Open SQL Editor:**
   - In Supabase dashboard, click "SQL Editor" in left sidebar
   - Click "New query"

2. **Load Schema:**
   - Open `sql/poros.sql` from your local project
   - Copy the entire contents
   - Paste into SQL Editor
   - Click "Run" (or press Cmd/Ctrl + Enter)
   - Wait for success message

3. **Verify:**
   - Go to "Table Editor" in left sidebar
   - You should see all your tables (companies, users, applications, etc.)

### Option B: Using psql Command Line

```bash
# Get connection string from Supabase dashboard
# Replace [YOUR-PASSWORD] with your database password
psql "postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres" < sql/poros.sql
```

### Option C: Using Supabase CLI (Advanced)

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Load schema
supabase db push
```

## Step 4: Configure Row Level Security (RLS)

Supabase uses Row Level Security by default. You'll need to configure it for your tables.

### Option 1: Disable RLS (For API-only access)

If you're using your own API (not Supabase's auto-generated API), you can disable RLS:

```sql
-- Run this in Supabase SQL Editor
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

### Option 2: Configure RLS Policies (For Supabase API)

If you want to use Supabase's auto-generated API, set up RLS policies:

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE resumes ENABLE ROW LEVEL SECURITY;
-- ... etc for all tables

-- Example: Users can only read/update their own data
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid()::text = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid()::text = id);

-- Applications: Users can only access their own
CREATE POLICY "Users can manage own applications" ON applications
  FOR ALL USING (auth.uid()::text = user_id);

-- Companies: Public read access
CREATE POLICY "Companies are viewable by everyone" ON companies
  FOR SELECT USING (true);
```

## Step 5: Update Your API Service

### Update Environment Variables

Update your `.env` file:

```env
# Supabase Database Connection
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres
DB_HOST=db.xxxxx.supabase.co
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your-database-password

# JWT Configuration (your own JWT system)
JWT_SECRET=your-secret-key-change-this-in-production-min-32-chars
JWT_EXPIRES_IN=7d

# Server Configuration
PORT=3000
NODE_ENV=development

# Supabase API (optional - if you want to use Supabase features)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### Update Database Connection

Your existing database connection in `src/config/database.ts` should work with Supabase! Just update the connection string.

**Important:** Supabase requires SSL connections. Update your connection:

```typescript
// In src/config/database.ts
const poolConfig: PoolConfig = {
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false // Supabase uses self-signed certificates
  },
  // ... rest of config
};
```

## Step 6: Deploy Your API

### Option A: Deploy to Vercel (Recommended for Supabase)

Vercel works great with Supabase and has free tier:

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Deploy:**
   ```bash
   vercel
   ```

3. **Set Environment Variables:**
   - Go to Vercel dashboard → Your project → Settings → Environment Variables
   - Add all variables from your `.env` file

4. **Auto-deploy from GitHub:**
   - Connect your GitHub repo in Vercel
   - Every push to main auto-deploys

### Option B: Deploy to Railway

1. Go to [railway.app](https://railway.app)
2. New Project → Deploy from GitHub
3. Select your repo
4. Add environment variables
5. Deploy!

### Option C: Deploy to Render

1. Go to [render.com](https://render.com)
2. New → Web Service
3. Connect GitHub repo
4. Add environment variables
5. Deploy!


## Step 7: Connect Your Client App

See [CLIENT_INTEGRATION_SUPABASE.md](./CLIENT_INTEGRATION_SUPABASE.md) for detailed client setup.

### Quick Setup:

1. **Install Supabase Client:**
   ```bash
   npm install @supabase/supabase-js
   ```

2. **Create Supabase Client:**
   ```typescript
   import { createClient } from '@supabase/supabase-js';
   
   const supabaseUrl = 'https://xxxxx.supabase.co';
   const supabaseAnonKey = 'your-anon-key';
   
   export const supabase = createClient(supabaseUrl, supabaseAnonKey);
   ```

3. **Use Your API or Supabase Directly:**
   - Option 1: Use your API (recommended) - same as before
   - Option 2: Use Supabase client directly for some features

## Step 8: Test Everything

1. **Test Database Connection:**
   ```bash
   # In your API service
   npm run dev
   # Should connect successfully
   ```

2. **Test API Endpoints:**
   ```bash
   curl https://your-api-url.vercel.app/health
   ```

3. **Test from Client:**
   - Update API base URL in client
   - Test signup/login
   - Test fetching companies
   - Test CRUD operations

## Advantages of Supabase

✅ **Free Tier** - Generous free tier for development  
✅ **PostgreSQL** - Your existing SQL works perfectly  
✅ **Auto-scaling** - Handles traffic automatically  
✅ **Backups** - Automatic daily backups  
✅ **Real-time** - Built-in real-time subscriptions  
✅ **Storage** - File storage for resumes  
✅ **Easy Setup** - Simple and straightforward  

## Next Steps

- [ ] Set up Supabase project
- [ ] Load database schema
- [ ] Configure RLS (if using Supabase API)
- [ ] Deploy your API service
- [ ] Update client to use new API URL
- [ ] Test everything end-to-end

## Troubleshooting

### Connection Issues

**Error: "SSL required"**
- Make sure you're using SSL in connection string
- Add `?sslmode=require` to connection string

**Error: "Connection refused"**
- Check firewall settings in Supabase
- Verify connection string is correct
- Check if database is paused (free tier pauses after inactivity)

### RLS Issues

**Error: "Row Level Security policy violation"**
- Either disable RLS (if using your own API)
- Or set up proper RLS policies

### Migration Issues

**Error: "Table already exists"**
- Drop tables first or use `IF NOT EXISTS` in CREATE statements
- Or use Supabase's migration system

## Resources

- [Supabase Docs](https://supabase.com/docs)
- [Supabase PostgreSQL Guide](https://supabase.com/docs/guides/database)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Storage](https://supabase.com/docs/guides/storage)

