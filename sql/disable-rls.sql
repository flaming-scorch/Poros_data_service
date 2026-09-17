-- Disable Row Level Security for all tables
-- (Not needed if using Supabase's auto-generated API with proper RLS policies)

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

-- Verify RLS is disabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;




