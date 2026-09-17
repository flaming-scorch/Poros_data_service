# Deploy to Vercel - Quick Guide

## Step 1: Login to Vercel

```bash
vercel login
```

This will open your browser to authenticate.

## Step 2: Deploy

From your project directory:

```bash
vercel
```

Follow the prompts:
- **Set up and deploy?** → Yes
- **Which scope?** → Your account
- **Link to existing project?** → No (first time)
- **Project name?** → `poros-data-service` (or press Enter for default)
- **Directory?** → `.` (current directory)
- **Override settings?** → No

## Step 3: Add Environment Variables

After first deployment, add your environment variables:

```bash
vercel env add DATABASE_URL
# Paste your Supabase connection string when prompted
# Select: Production, Preview, Development (all three)

vercel env add JWT_SECRET
# Paste your JWT secret
# Select: Production, Preview, Development

vercel env add NODE_ENV
# Enter: production
# Select: Production, Preview, Development

vercel env add PORT
# Enter: 8080 (or leave empty, Vercel sets this automatically)
# Select: Production, Preview, Development
```

Or add them in Vercel Dashboard:
1. Go to [vercel.com/dashboard](https://vercel.com/dashboard)
2. Select your project
3. Go to Settings → Environment Variables
4. Add each variable

## Step 4: Redeploy

After adding environment variables:

```bash
vercel --prod
```

## Step 5: Test Your Deployment

Your API will be at: `https://poros-data-service.vercel.app` (or your custom URL)

```bash
curl https://poros-data-service.vercel.app/health
```

## Auto-Deployment from GitHub

1. **Push to GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

2. **Connect in Vercel:**
   - Go to Vercel Dashboard
   - Click "Add New Project"
   - Import your GitHub repository
   - Vercel will auto-detect settings
   - Add environment variables
   - Deploy!

3. **Auto-deploy:**
   - Every push to `main` will auto-deploy
   - Preview deployments for other branches

## Troubleshooting

**Build fails?**
- Check that `dist/index.js` exists after build
- Verify `package.json` has `postinstall` script
- Check build logs in Vercel dashboard

**Environment variables not working?**
- Make sure you added them for the correct environment (Production/Preview/Development)
- Redeploy after adding variables: `vercel --prod`

**Database connection fails?**
- Verify DATABASE_URL is correct
- Check Supabase database isn't paused
- Ensure SSL is enabled in connection string

## Useful Commands

```bash
# Deploy to production
vercel --prod

# Deploy preview
vercel

# View logs
vercel logs

# List deployments
vercel ls

# Remove deployment
vercel remove
```


