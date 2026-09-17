-- Pros Database Queries
-- Useful SQL queries for the Pros application

-- ============================================================================
-- USER QUERIES
-- ============================================================================

-- Get user profile with all details
SELECT 
    u.*,
    array_agg(DISTINCT utc.company_id) FILTER (WHERE utc.company_id IS NOT NULL) as target_company_ids,
    array_agg(DISTINCT utr.role) FILTER (WHERE utr.role IS NOT NULL) as target_roles,
    array_agg(DISTINCT uti.industry) FILTER (WHERE uti.industry IS NOT NULL) as target_industries,
    array_agg(DISTINCT utl.location) FILTER (WHERE utl.location IS NOT NULL) as target_locations
FROM users u
LEFT JOIN user_target_companies utc ON u.id = utc.user_id
LEFT JOIN user_target_roles utr ON u.id = utr.user_id
LEFT JOIN user_target_industries uti ON u.id = uti.user_id
LEFT JOIN user_target_locations utl ON u.id = utl.user_id
WHERE u.id = 'USER_ID_HERE'
GROUP BY u.id;

-- Get user dashboard statistics
SELECT * FROM user_dashboard_stats WHERE user_id = 'USER_ID_HERE';

-- Get user's target companies with company details
SELECT 
    c.*,
    utc.added_at,
    utc.priority,
    utc.custom_notes
FROM user_target_companies utc
JOIN companies c ON utc.company_id = c.id
WHERE utc.user_id = 'USER_ID_HERE'
ORDER BY utc.priority ASC, utc.added_at ASC;

-- Update user weekly goal
UPDATE users 
SET weekly_goal = 10 
WHERE id = 'USER_ID_HERE';

-- Get users by graduation year
SELECT 
    id,
    name,
    university,
    major,
    graduation_year
FROM users
WHERE graduation_year = 2024
ORDER BY created_at DESC;

-- ============================================================================
-- APPLICATION QUERIES
-- ============================================================================

-- Get all applications for a user with status counts
SELECT 
    a.*,
    CASE 
        WHEN a.status = 'Applied' THEN 'pending'
        WHEN a.status = 'Interview' THEN 'interview'
        WHEN a.status = 'Offer' THEN 'offer'
        WHEN a.status = 'Rejected' THEN 'rejected'
    END as status_category
FROM applications a
WHERE a.user_id = 'USER_ID_HERE'
ORDER BY a.applied_date DESC;

-- Get applications by status
SELECT 
    status,
    COUNT(*) as count,
    array_agg(id) as application_ids
FROM applications
WHERE user_id = 'USER_ID_HERE'
GROUP BY status;

-- Get applications for current week
SELECT 
    a.*,
    c.logo as company_logo
FROM applications a
LEFT JOIN companies c ON a.company = c.name
WHERE a.user_id = 'USER_ID_HERE'
  AND a.applied_date >= DATE_TRUNC('week', CURRENT_DATE)
  AND a.applied_date < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 week'
ORDER BY a.applied_date DESC;

-- Get applications for a specific company
SELECT 
    a.*,
    u.name as user_name
FROM applications a
JOIN users u ON a.user_id = u.id
WHERE a.company = 'Google'
ORDER BY a.applied_date DESC;

-- Get applications by date range
SELECT 
    a.*,
    c.logo as company_logo
FROM applications a
LEFT JOIN companies c ON a.company = c.name
WHERE a.user_id = 'USER_ID_HERE'
  AND a.applied_date BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY a.applied_date DESC;

-- Update application status
UPDATE applications 
SET 
    status = 'Interview',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'APPLICATION_ID_HERE';

-- Get applications with interview scheduled (status = 'Interview')
SELECT 
    a.*,
    u.name as user_name,
    u.email as user_email
FROM applications a
JOIN users u ON a.user_id = u.id
WHERE a.status = 'Interview'
ORDER BY a.applied_date ASC;

-- ============================================================================
-- COMPANY QUERIES
-- ============================================================================

-- Get all companies with full details
SELECT 
    c.id,
    c.name,
    c.logo,
    c.industry,
    c.application_timeline_internship,
    c.application_timeline_fulltime,
    c.application_timeline_contractor,
    c.application_timeline_coop,
    c.company_size,
    c.culture_values,
    c.benefits,
    c.interview_process,
    c.created_at,
    c.updated_at,
    COUNT(DISTINCT e.id) as event_count,
    COUNT(DISTINCT co.id) as course_count,
    COUNT(DISTINCT ch.id) as checklist_count
FROM companies c
LEFT JOIN events e ON c.id = e.company_id
LEFT JOIN courses co ON c.id = co.company_id
LEFT JOIN checklist_items ch ON c.id = ch.company_id AND ch.user_id IS NULL
GROUP BY c.id, c.name, c.logo, c.industry, c.application_timeline_internship, 
         c.application_timeline_fulltime, c.application_timeline_contractor, 
         c.application_timeline_coop, c.company_size, c.culture_values, 
         c.benefits, c.interview_process, c.created_at, c.updated_at
ORDER BY c.name;

-- Get company recommendations view
SELECT * FROM company_recommendations_view
ORDER BY name;

-- Get company with all events, courses, and checklist items
SELECT 
    c.id,
    c.name,
    c.logo,
    c.industry,
    c.application_timeline_internship,
    c.application_timeline_fulltime,
    c.application_timeline_contractor,
    c.application_timeline_coop,
    c.company_size,
    c.culture_values,
    c.benefits,
    c.interview_process,
    c.created_at,
    c.updated_at,
    json_agg(DISTINCT jsonb_build_object(
        'id', e.id,
        'title', e.title,
        'type', e.type,
        'event_date', e.event_date,
        'description', e.description,
        'registration_link', e.registration_link
    )) FILTER (WHERE e.id IS NOT NULL) as events,
    json_agg(DISTINCT jsonb_build_object(
        'id', co.id,
        'title', co.title,
        'provider', co.provider,
        'duration', co.duration,
        'level', co.level,
        'skills', co.skills,
        'link', co.link
    )) FILTER (WHERE co.id IS NOT NULL) as courses,
    json_agg(DISTINCT jsonb_build_object(
        'id', ch.id,
        'title', ch.title,
        'description', ch.description,
        'category', ch.category,
        'completed', ch.completed
    )) FILTER (WHERE ch.id IS NOT NULL) as checklist_items
FROM companies c
LEFT JOIN events e ON c.id = e.company_id
LEFT JOIN courses co ON c.id = co.company_id
LEFT JOIN checklist_items ch ON c.id = ch.company_id AND ch.user_id IS NULL
WHERE c.id = 'COMPANY_ID_HERE'
GROUP BY c.id, c.name, c.logo, c.industry, c.application_timeline_internship, 
         c.application_timeline_fulltime, c.application_timeline_contractor, 
         c.application_timeline_coop, c.company_size, c.culture_values, 
         c.benefits, c.interview_process, c.created_at, c.updated_at;

-- Search companies by industry
SELECT * FROM companies
WHERE industry ILIKE '%Technology%'
ORDER BY name;

-- Get companies by size
SELECT 
    company_size,
    COUNT(*) as count,
    array_agg(name) as companies
FROM companies
GROUP BY company_size
ORDER BY count DESC;

-- ============================================================================
-- EVENT QUERIES
-- ============================================================================

-- Get upcoming events for a user's target companies
SELECT 
    e.*,
    c.name as company_name,
    c.logo as company_logo,
    utc.user_id,
    utc.priority
FROM events e
JOIN companies c ON e.company_id = c.id
JOIN user_target_companies utc ON c.id = utc.company_id
WHERE utc.user_id = 'USER_ID_HERE'
  AND e.event_date >= CURRENT_DATE
ORDER BY e.event_date ASC, utc.priority ASC;

-- Get upcoming events for all companies
SELECT 
    e.*,
    c.name as company_name,
    c.logo as company_logo
FROM events e
JOIN companies c ON e.company_id = c.id
WHERE e.event_date >= CURRENT_DATE
ORDER BY e.event_date ASC;

-- Get events by type
SELECT 
    type,
    COUNT(*) as count,
    array_agg(title) as event_titles
FROM events
WHERE event_date >= CURRENT_DATE
GROUP BY type
ORDER BY count DESC;

-- Get events for a specific company
SELECT 
    e.*,
    c.name as company_name
FROM events e
JOIN companies c ON e.company_id = c.id
WHERE c.id = 'COMPANY_ID_HERE'
ORDER BY e.event_date ASC;

-- ============================================================================
-- COURSE QUERIES
-- ============================================================================

-- Get recommended courses for a user's target companies
SELECT 
    co.*,
    c.name as company_name,
    c.logo as company_logo,
    utc.user_id,
    utc.priority
FROM courses co
JOIN companies c ON co.company_id = c.id
JOIN user_target_companies utc ON c.id = utc.company_id
WHERE utc.user_id = 'USER_ID_HERE'
ORDER BY utc.priority ASC, co.level, co.title;

-- Get courses by level
SELECT 
    level,
    COUNT(*) as count,
    array_agg(title) as course_titles
FROM courses
GROUP BY level
ORDER BY level;

-- Get courses by company
SELECT 
    co.*,
    c.name as company_name
FROM courses co
JOIN companies c ON co.company_id = c.id
WHERE c.id = 'COMPANY_ID_HERE'
ORDER BY co.level, co.title;

-- Search courses by skill
SELECT 
    co.*,
    c.name as company_name
FROM courses co
JOIN companies c ON co.company_id = c.id
WHERE 'Python' = ANY(co.skills)
ORDER BY co.level, co.title;

-- ============================================================================
-- CHECKLIST QUERIES
-- ============================================================================

-- Get checklist items for a user's target companies (templates)
SELECT 
    ch.*,
    c.name as company_name,
    c.logo as company_logo,
    utc.user_id,
    utc.priority
FROM checklist_items ch
JOIN companies c ON ch.company_id = c.id
JOIN user_target_companies utc ON c.id = utc.company_id
WHERE utc.user_id = 'USER_ID_HERE'
  AND ch.user_id IS NULL
ORDER BY utc.priority ASC, ch.category, ch.title;

-- Get user-specific checklist items (completed/in-progress)
SELECT 
    ch.*,
    c.name as company_name,
    c.logo as company_logo
FROM checklist_items ch
JOIN companies c ON ch.company_id = c.id
WHERE ch.user_id = 'USER_ID_HERE'
ORDER BY ch.category, ch.completed, ch.title;

-- Get checklist progress by company for a user
SELECT 
    c.name as company_name,
    c.id as company_id,
    COUNT(*) as total_items,
    COUNT(*) FILTER (WHERE ch.completed = TRUE) as completed_items,
    ROUND(COUNT(*) FILTER (WHERE ch.completed = TRUE)::numeric / COUNT(*)::numeric * 100, 2) as completion_percentage
FROM checklist_items ch
JOIN companies c ON ch.company_id = c.id
WHERE ch.user_id = 'USER_ID_HERE'
GROUP BY c.id, c.name
ORDER BY completion_percentage DESC;

-- Get checklist items by category
SELECT 
    category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE completed = TRUE) as completed,
    COUNT(*) FILTER (WHERE completed = FALSE) as pending
FROM checklist_items
WHERE user_id = 'USER_ID_HERE'
GROUP BY category
ORDER BY category;

-- Update checklist item completion status
UPDATE checklist_items
SET 
    completed = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'CHECKLIST_ITEM_ID_HERE' AND user_id = 'USER_ID_HERE';

-- ============================================================================
-- RESUME QUERIES
-- ============================================================================

-- Get all resumes for a user
SELECT 
    r.*,
    COUNT(tr.id) as tailored_count
FROM resumes r
LEFT JOIN tailored_resumes tr ON r.id = tr.original_resume_id
WHERE r.user_id = 'USER_ID_HERE'
GROUP BY r.id
ORDER BY r.is_primary DESC, r.uploaded_at DESC;

-- Get primary resume for a user
SELECT * FROM resumes
WHERE user_id = 'USER_ID_HERE'
  AND is_primary = TRUE
LIMIT 1;

-- Get tailored resumes for a specific resume
SELECT 
    tr.*,
    r.name as original_resume_name,
    r.file_name as original_resume_file_name
FROM tailored_resumes tr
JOIN resumes r ON tr.original_resume_id = r.id
WHERE tr.original_resume_id = 'RESUME_ID_HERE'
ORDER BY tr.tailored_at DESC;

-- Get all tailored resumes for a user
SELECT 
    tr.*,
    r.name as original_resume_name,
    c.logo as company_logo
FROM tailored_resumes tr
JOIN resumes r ON tr.original_resume_id = r.id
LEFT JOIN companies c ON tr.company_name = c.name
WHERE tr.user_id = 'USER_ID_HERE'
ORDER BY tr.tailored_at DESC;

-- Get tailored resumes by processing status
SELECT 
    processing_status,
    COUNT(*) as count,
    array_agg(id) as tailored_resume_ids
FROM tailored_resumes
WHERE user_id = 'USER_ID_HERE'
GROUP BY processing_status;

-- Set a resume as primary
UPDATE resumes
SET 
    is_primary = (id = 'RESUME_ID_HERE'),
    updated_at = CURRENT_TIMESTAMP
WHERE user_id = 'USER_ID_HERE';

-- ============================================================================
-- ANALYTICS QUERIES
-- ============================================================================

-- Get application success rate by company
SELECT 
    company,
    COUNT(*) as total_applications,
    COUNT(*) FILTER (WHERE status = 'Offer') as offers,
    COUNT(*) FILTER (WHERE status = 'Interview') as interviews,
    COUNT(*) FILTER (WHERE status = 'Rejected') as rejected,
    ROUND(COUNT(*) FILTER (WHERE status = 'Offer')::numeric / COUNT(*)::numeric * 100, 2) as offer_rate,
    ROUND(COUNT(*) FILTER (WHERE status = 'Interview')::numeric / COUNT(*)::numeric * 100, 2) as interview_rate
FROM applications
WHERE user_id = 'USER_ID_HERE'
GROUP BY company
HAVING COUNT(*) > 0
ORDER BY total_applications DESC;

-- Get application trends by month
SELECT 
    DATE_TRUNC('month', applied_date) as month,
    COUNT(*) as applications,
    COUNT(*) FILTER (WHERE status = 'Interview') as interviews,
    COUNT(*) FILTER (WHERE status = 'Offer') as offers
FROM applications
WHERE user_id = 'USER_ID_HERE'
GROUP BY DATE_TRUNC('month', applied_date)
ORDER BY month DESC;

-- Get most applied to companies
SELECT 
    company,
    COUNT(*) as application_count,
    MAX(applied_date) as last_application_date
FROM applications
WHERE user_id = 'USER_ID_HERE'
GROUP BY company
ORDER BY application_count DESC
LIMIT 10;

-- Get user progress toward weekly goal
SELECT 
    u.id,
    u.name,
    u.weekly_goal,
    COUNT(a.id) FILTER (
        WHERE a.applied_date >= DATE_TRUNC('week', CURRENT_DATE)
    ) as weekly_progress,
    u.weekly_goal - COUNT(a.id) FILTER (
        WHERE a.applied_date >= DATE_TRUNC('week', CURRENT_DATE)
    ) as remaining,
    CASE 
        WHEN COUNT(a.id) FILTER (
            WHERE a.applied_date >= DATE_TRUNC('week', CURRENT_DATE)
        ) >= u.weekly_goal THEN TRUE
        ELSE FALSE
    END as goal_met
FROM users u
LEFT JOIN applications a ON u.id = a.user_id
WHERE u.id = 'USER_ID_HERE'
GROUP BY u.id, u.name, u.weekly_goal;

-- Get target company application status
SELECT 
    c.name as company_name,
    c.logo as company_logo,
    utc.priority,
    COUNT(a.id) as application_count,
    MAX(a.applied_date) as last_application_date,
    MAX(a.status) FILTER (WHERE a.status IN ('Interview', 'Offer')) as best_status
FROM user_target_companies utc
JOIN companies c ON utc.company_id = c.id
LEFT JOIN applications a ON utc.user_id = a.user_id AND a.company = c.name
WHERE utc.user_id = 'USER_ID_HERE'
GROUP BY c.id, c.name, c.logo, utc.priority
ORDER BY utc.priority ASC;

-- ============================================================================
-- SEARCH QUERIES
-- ============================================================================

-- Search companies by name (case-insensitive)
SELECT * FROM companies
WHERE name ILIKE '%search_term%'
ORDER BY name;

-- Search applications by company or role
SELECT 
    a.*,
    c.logo as company_logo
FROM applications a
LEFT JOIN companies c ON a.company = c.name
WHERE a.user_id = 'USER_ID_HERE'
  AND (a.company ILIKE '%search_term%' OR a.role ILIKE '%search_term%')
ORDER BY a.applied_date DESC;

-- Search courses by title or skills
SELECT 
    co.*,
    c.name as company_name
FROM courses co
JOIN companies c ON co.company_id = c.id
WHERE co.title ILIKE '%search_term%'
   OR EXISTS (
       SELECT 1 FROM unnest(co.skills) skill 
       WHERE skill ILIKE '%search_term%'
   )
ORDER BY co.title;

-- ============================================================================
-- MAINTENANCE QUERIES
-- ============================================================================

-- Get database statistics
SELECT 
    'users' as table_name,
    COUNT(*) as row_count
FROM users
UNION ALL
SELECT 'companies', COUNT(*) FROM companies
UNION ALL
SELECT 'applications', COUNT(*) FROM applications
UNION ALL
SELECT 'resumes', COUNT(*) FROM resumes
UNION ALL
SELECT 'tailored_resumes', COUNT(*) FROM tailored_resumes
UNION ALL
SELECT 'events', COUNT(*) FROM events
UNION ALL
SELECT 'courses', COUNT(*) FROM courses
UNION ALL
SELECT 'checklist_items', COUNT(*) FROM checklist_items
UNION ALL
SELECT 'user_target_companies', COUNT(*) FROM user_target_companies;

-- Get users with no applications
SELECT 
    u.id,
    u.name,
    u.email,
    u.created_at
FROM users u
LEFT JOIN applications a ON u.id = a.user_id
WHERE a.id IS NULL;

-- Get orphaned tailored resumes (resume deleted but tailored resume exists)
SELECT 
    tr.*
FROM tailored_resumes tr
LEFT JOIN resumes r ON tr.original_resume_id = r.id
WHERE r.id IS NULL;

-- Clean up old completed tailored resumes (older than 90 days)
-- DELETE FROM tailored_resumes
-- WHERE processing_status = 'completed'
--   AND tailored_at < CURRENT_DATE - INTERVAL '90 days';

-- ============================================================================
-- EXAMPLE COMPLEX QUERIES
-- ============================================================================

-- Get comprehensive user dashboard data
SELECT 
    u.id as user_id,
    u.name,
    u.weekly_goal,
    -- Application stats
    (SELECT COUNT(*) FROM applications WHERE user_id = u.id) as total_applications,
    (SELECT COUNT(*) FROM applications WHERE user_id = u.id AND status = 'Applied') as pending_applications,
    (SELECT COUNT(*) FROM applications WHERE user_id = u.id AND status = 'Interview') as interviews,
    -- Resume stats
    (SELECT COUNT(*) FROM resumes WHERE user_id = u.id) as total_resumes,
    (SELECT COUNT(*) FROM tailored_resumes WHERE user_id = u.id) as total_tailored_resumes,
    -- Target companies
    (SELECT COUNT(*) FROM user_target_companies WHERE user_id = u.id) as target_company_count,
    -- Weekly progress
    (SELECT COUNT(*) FROM applications 
     WHERE user_id = u.id 
       AND applied_date >= DATE_TRUNC('week', CURRENT_DATE)
    ) as weekly_progress
FROM users u
WHERE u.id = 'USER_ID_HERE';

-- Get company preparation status for a user
SELECT 
    c.id,
    c.name,
    c.logo,
    utc.priority,
    utc.custom_notes,
    -- Checklist progress
    COUNT(DISTINCT ch.id) as total_checklist_items,
    COUNT(DISTINCT ch.id) FILTER (WHERE ch.completed = TRUE) as completed_items,
    -- Upcoming events
    COUNT(DISTINCT e.id) FILTER (WHERE e.event_date >= CURRENT_DATE) as upcoming_events,
    -- Available courses
    COUNT(DISTINCT co.id) as available_courses,
    -- Application status
    COUNT(DISTINCT a.id) as application_count,
    MAX(a.status) FILTER (WHERE a.status IN ('Interview', 'Offer')) as best_status
FROM user_target_companies utc
JOIN companies c ON utc.company_id = c.id
LEFT JOIN checklist_items ch ON c.id = ch.company_id AND (ch.user_id = utc.user_id OR ch.user_id IS NULL)
LEFT JOIN events e ON c.id = e.company_id
LEFT JOIN courses co ON c.id = co.company_id
LEFT JOIN applications a ON utc.user_id = a.user_id AND a.company = c.name
WHERE utc.user_id = 'USER_ID_HERE'
GROUP BY c.id, c.name, c.logo, utc.priority, utc.custom_notes
ORDER BY utc.priority ASC;

