# Poros Data Service

A TypeScript REST API for Poros, an application that helps students organize job searches, manage resumes, track applications, and research target companies.

## Jojo Osei-Kofi's role

My contributions focused on mobile authentication, resume-management and job-tracker workflows, frontend integration with this API, and usability testing. See [my project-wide contribution summary](https://github.com/flaming-scorch/Poros-Project#jojo-osei-kofis-contributions). This backend is part of the collaborative team project.

## Technology

- Node.js, Express, and TypeScript
- PostgreSQL and Supabase
- JWT authentication with bcrypt password hashing
- Multer for PDF uploads
- Anthropic and Tavily integrations through authenticated server-side routes
- GitHub Actions and deployment configurations for Vercel, Render, and Railway

## Implemented API areas

- Authentication: `/api/auth`
- Users and career targets: `/api/users`
- Resumes and tailored-resume records: `/api/resumes`
- Companies: `/api/companies`
- Applications: `/api/applications`
- Preparation checklists: `/api/checklist`
- AI resume tailoring and company research: `/api/ai`

AI provider credentials stay on the server. The mobile client never receives Anthropic, Tavily, database, JWT, or Supabase service-role secrets.

## Local setup

### 1. Install dependencies

```bash
npm install
```

### 2. Create a local environment file

Copy `.env.example` to `.env`, then replace every placeholder with credentials from services you control.

```env
PORT=3000
DATABASE_URL=postgres://user:password@localhost:5432/poros
JWT_SECRET=replace_with_a_long_random_value
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
ANTHROPIC_API_KEY=your_anthropic_api_key
TAVILY_API_KEY=your_tavily_api_key
```

Use Node.js 22 and a separate Supabase project for this prototype. Set DATABASE_URL to that project's PostgreSQL connection string. Create a storage bucket named `resumes`; the current upload implementation uses public object URLs, so use synthetic demonstration PDFs only.

Run `sql/poros.sql` in the new project's SQL editor to initialize the schema. This script DROPS existing Poros tables; run it only against an empty, disposable development database. It is not an upgrade migration.

For a local PostgreSQL database, set `DB_SSL=false`; Supabase storage credentials are still required for uploads. Never reuse the original class team's shared database or credentials.

### 3. Run and verify

```bash
npm run type-check
npm run dev
```

Open `http://localhost:3000/health` to verify the service.

## Security notes

- AI routes require a valid JWT. The prototype has not received a comprehensive security audit.
- Passwords are hashed before storage.
- Uploads are limited to PDF files.
- Secret files and uploaded documents are excluded by `.gitignore`.
- Production deployments should restrict CORS to approved origins.
- Resume storage currently returns public URLs. Private storage and signed downloads are required before using real personal documents.
- AI routes need deployment-level rate limiting and provider spending limits before public operation.

## Related repositories

- [Poros mobile client](https://github.com/flaming-scorch/Poros-Client)
- [Project overview and usability research](https://github.com/flaming-scorch/Poros-Project)

## Academic context

Poros was built by a five-person Calvin University CS 262 team. See the project overview for team attribution and Jojo Osei-Kofi's documented contributions.

## Team

Poros was created for Calvin University's CS 262 Software Engineering course by:

- [Jojo Osei-Kofi](https://github.com/Jojo-Osei-Kofi)
- [Kofi Baah Nyarko](https://github.com/KofiBaahNyarko)
- [Ose Aisuodionoe-Shadrach](https://github.com/Ose-97)
- [Ruhama Getahun](https://github.com/RuhamaGetahun)
- [Youssef Dalil](https://github.com/YoussefDalil24)

The repository preserves team attribution because Poros was collaborative work.

## Provenance

This portfolio copy imports the cleaned snapshot from [the original team repository](https://github.com/Jojo-Osei-Kofi/Poros_data_service/tree/a43908caf428a12fada4b15afa661c9d5d59722d). Original development history remains there. Import commits here do not represent sole authorship. Portfolio cleanup and migration were assisted by Codex.

See [validation results and remaining limitations](VALIDATION.md) before running a demo.

The Vercel deployment workflow is manual; configure your own deployment project and secrets before starting it.
