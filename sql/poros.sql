-- Pros Database Schema
-- Based on the Client application structure

-- Drop existing tables if they exist (in reverse order of dependencies)
DROP TABLE IF EXISTS tailored_resumes CASCADE;
DROP TABLE IF EXISTS resumes CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS checklist_items CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS user_target_companies CASCADE;
DROP TABLE IF EXISTS user_target_roles CASCADE;
DROP TABLE IF EXISTS user_target_industries CASCADE;
DROP TABLE IF EXISTS user_target_locations CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- Companies Table
CREATE TABLE companies (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    logo VARCHAR(255),
    industry VARCHAR(255) NOT NULL,
    application_timeline_internship TEXT,
    application_timeline_fulltime TEXT,
    application_timeline_contractor TEXT,
    application_timeline_coop TEXT,
    company_size VARCHAR(255),
    culture_values TEXT[], -- Array of culture values
    benefits TEXT[], -- Array of benefits
    interview_process TEXT[], -- Array of interview process steps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users Table
CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- For authentication
    linkedin_profile VARCHAR(500),
    university VARCHAR(255) NOT NULL,
    major VARCHAR(255) NOT NULL,
    graduation_year INTEGER NOT NULL,
    resume_uri VARCHAR(500),
    weekly_goal INTEGER DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Target Companies (Junction Table)
CREATE TABLE user_target_companies (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id VARCHAR(255) NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    priority INTEGER,
    custom_notes TEXT,
    UNIQUE(user_id, company_id)
);

-- User Target Roles (Many-to-Many)
CREATE TABLE user_target_roles (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(255) NOT NULL,
    UNIQUE(user_id, role)
);

-- User Target Industries (Many-to-Many)
CREATE TABLE user_target_industries (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    industry VARCHAR(255) NOT NULL,
    UNIQUE(user_id, industry)
);

-- User Target Locations (Many-to-Many)
CREATE TABLE user_target_locations (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location VARCHAR(255) NOT NULL,
    UNIQUE(user_id, location)
);

-- Applications Table
CREATE TABLE applications (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('Applied', 'Interview', 'Offer', 'Rejected')),
    applied_date DATE NOT NULL,
    notes TEXT,
    company_logo VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Resumes Table
CREATE TABLE resumes (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_uri VARCHAR(500) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tailored Resumes Table
CREATE TABLE tailored_resumes (
    id VARCHAR(255) PRIMARY KEY,
    original_resume_id VARCHAR(255) NOT NULL REFERENCES resumes(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_description TEXT NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    position_title VARCHAR(255) NOT NULL,
    tailored_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processing_status VARCHAR(50) NOT NULL DEFAULT 'processing' CHECK (processing_status IN ('processing', 'completed', 'failed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Events Table
CREATE TABLE events (
    id VARCHAR(255) PRIMARY KEY,
    company_id VARCHAR(255) NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('Tech Talk', 'Workshop', 'Networking', 'Info Session')),
    event_date DATE NOT NULL,
    description TEXT,
    registration_link VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Courses Table
CREATE TABLE courses (
    id VARCHAR(255) PRIMARY KEY,
    company_id VARCHAR(255) NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    provider VARCHAR(255) NOT NULL,
    duration VARCHAR(100) NOT NULL,
    level VARCHAR(50) NOT NULL CHECK (level IN ('Beginner', 'Intermediate', 'Advanced')),
    skills TEXT[], -- Array of skills
    link VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Checklist Items Table
CREATE TABLE checklist_items (
    id VARCHAR(255) PRIMARY KEY,
    company_id VARCHAR(255) NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id VARCHAR(255) REFERENCES users(id) ON DELETE CASCADE, -- NULL if it's a template, not NULL if user-specific
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    category VARCHAR(50) NOT NULL CHECK (category IN ('Interview Prep', 'Portfolio', 'Culture Study', 'Technical Skills')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better query performance
CREATE INDEX idx_user_target_companies_user_id ON user_target_companies(user_id);
CREATE INDEX idx_user_target_companies_company_id ON user_target_companies(company_id);
CREATE INDEX idx_applications_user_id ON applications(user_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_applications_applied_date ON applications(applied_date);
CREATE INDEX idx_resumes_user_id ON resumes(user_id);
CREATE INDEX idx_resumes_is_primary ON resumes(is_primary);
CREATE INDEX idx_tailored_resumes_resume_id ON tailored_resumes(original_resume_id);
CREATE INDEX idx_tailored_resumes_user_id ON tailored_resumes(user_id);
CREATE INDEX idx_events_company_id ON events(company_id);
CREATE INDEX idx_events_event_date ON events(event_date);
CREATE INDEX idx_courses_company_id ON courses(company_id);
CREATE INDEX idx_checklist_items_company_id ON checklist_items(company_id);
CREATE INDEX idx_checklist_items_user_id ON checklist_items(user_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Insert sample companies data
INSERT INTO companies (id, name, logo, industry, application_timeline_internship, application_timeline_fulltime, application_timeline_contractor, application_timeline_coop, company_size, culture_values, benefits, interview_process) VALUES
('1', 'Meta', '🔵', 'Social Media & Technology', 'September - November', 'August - December', 'Year-round', 'September - November', '50,000+ employees', 
 ARRAY['Innovation', 'Connection', 'Move Fast', 'Bold Vision'],
 ARRAY['Health Insurance', 'Stock Options', 'Flexible PTO', 'Remote Work Options'],
 ARRAY['Initial Recruiter Screen', 'Technical Phone Interview', 'Onsite Technical Interviews (3-4 rounds)', 'Behavioral Interview', 'Final Decision']),

('2', 'Google', '🔍', 'Search & Cloud Technology', 'September - December', 'July - November', 'Year-round', 'September - December', '150,000+ employees',
 ARRAY['Innovation', 'Data-Driven', 'User Focus', 'Technical Excellence'],
 ARRAY['Health Insurance', 'Stock Options', 'Free Meals', 'Learning Budget'],
 ARRAY['Resume Review', 'Technical Phone Screen', 'Onsite Interviews (4-5 rounds)', 'Hiring Committee Review', 'Executive Review & Offer']),

('3', 'Amazon', '📦', 'E-commerce & Cloud Services', 'October - January', 'August - December', 'Year-round', 'October - January', '1,500,000+ employees',
 ARRAY['Customer Obsession', 'Ownership', 'Invent and Simplify', 'Dive Deep'],
 ARRAY['Health Insurance', 'Stock Options', 'Career Choice Program', 'Parental Leave'],
 ARRAY['Online Application', 'Technical Assessment', 'Phone Interview', 'Onsite Loop (4-6 interviews)', 'Bar Raiser Review']),

('4', 'Apple', '🍎', 'Consumer Electronics & Software', 'November - February', 'September - January', 'Year-round', 'November - February', '150,000+ employees',
 ARRAY['Innovation', 'Excellence', 'Privacy', 'Environmental Responsibility'],
 ARRAY['Health Insurance', 'Stock Purchase Plan', 'Product Discounts', 'Wellness Programs'],
 ARRAY['Resume Review', 'Initial Phone Screen', 'Technical Phone Interview', 'Onsite Interviews (3-5 rounds)', 'Team Fit Assessment']),

('5', 'TikTok', '🎵', 'Social Media & Entertainment', 'September - November', 'Year-round', 'Year-round', 'September - November', '100,000+ employees',
 ARRAY['Creativity', 'Global Mindset', 'User-First', 'Innovation'],
 ARRAY['Health Insurance', 'Stock Options', 'Flexible Work', 'Learning Stipend'],
 ARRAY['Application Review', 'Recruiter Phone Screen', 'Technical Assessment', 'Technical Interviews (2-3 rounds)', 'Cultural Fit Interview']);

-- Insert sample events
INSERT INTO events (id, company_id, title, type, event_date, description, registration_link) VALUES
('1', '1', 'Meta Engineering Virtual Info Session', 'Info Session', '2024-03-15', 'Learn about engineering roles and career paths at Meta', 'https://meta.com/careers/events'),
('2', '1', 'React & AI Workshop', 'Workshop', '2024-03-22', 'Hands-on workshop building AI-powered React applications', NULL),
('3', '1', 'Meta Tech Talk: The Future of VR', 'Tech Talk', '2024-04-05', 'Explore cutting-edge VR technologies and career opportunities', NULL),
('4', '2', 'Google Cloud Platform Workshop', 'Workshop', '2024-03-20', 'Learn to build scalable applications on GCP', NULL),
('5', '2', 'Google I/O Extended Developer Conference', 'Tech Talk', '2024-05-14', 'Latest updates from Google I/O with local developer community', NULL),
('6', '2', 'Career Chat with Google Engineers', 'Networking', '2024-04-10', 'Informal networking session with current Google engineers', NULL),
('7', '3', 'AWS Solutions Architecture Workshop', 'Workshop', '2024-03-25', 'Design scalable cloud architectures using AWS services', NULL),
('8', '3', 'Amazon Leadership Principles in Action', 'Info Session', '2024-04-01', 'Learn how Amazon''s Leadership Principles guide daily work', NULL),
('9', '3', 'Prime Video Technology Deep Dive', 'Tech Talk', '2024-04-15', 'Behind the scenes of video streaming at global scale', NULL),
('10', '4', 'iOS Development Workshop', 'Workshop', '2024-03-30', 'Build your first iOS app with SwiftUI and Core Data', NULL),
('11', '4', 'Apple Design Thinking Session', 'Workshop', '2024-04-12', 'Learn Apple''s approach to user-centered design', NULL),
('12', '4', 'WWDC Student Program Info Session', 'Info Session', '2024-04-20', 'Learn about Apple''s student developer programs and opportunities', NULL),
('13', '5', 'TikTok Algorithm & Recommendation Systems', 'Tech Talk', '2024-04-05', 'Deep dive into machine learning algorithms powering TikTok', NULL),
('14', '5', 'Mobile Video Technology Workshop', 'Workshop', '2024-04-18', 'Learn about video processing and streaming technologies', NULL),
('15', '5', 'TikTok Engineering Career Fair', 'Networking', '2024-05-01', 'Meet TikTok engineers and learn about open positions', NULL);

-- Insert sample courses
INSERT INTO courses (id, company_id, title, provider, duration, level, skills, link) VALUES
('1', '1', 'React Development Fundamentals', 'Meta', '6 weeks', 'Beginner', ARRAY['React', 'JavaScript', 'Frontend Development'], 'https://coursera.org/learn/react-basics'),
('2', '1', 'GraphQL API Design', 'Apollo', '4 weeks', 'Intermediate', ARRAY['GraphQL', 'API Design', 'Backend Development'], 'https://apollographql.com/tutorials'),
('3', '1', 'Machine Learning for Social Networks', 'Stanford Online', '8 weeks', 'Advanced', ARRAY['Machine Learning', 'Python', 'Data Science'], 'https://stanford.edu/courses/cs224w'),
('4', '2', 'Google Cloud Platform Fundamentals', 'Google Cloud', '5 weeks', 'Beginner', ARRAY['GCP', 'Cloud Computing', 'DevOps'], 'https://cloud.google.com/training'),
('5', '2', 'Algorithms and Data Structures', 'Princeton', '10 weeks', 'Intermediate', ARRAY['Algorithms', 'Data Structures', 'Java'], 'https://coursera.org/learn/algorithms-part1'),
('6', '2', 'TensorFlow Developer Certificate', 'Google', '12 weeks', 'Advanced', ARRAY['Machine Learning', 'TensorFlow', 'Python'], 'https://tensorflow.org/certificate'),
('7', '3', 'AWS Cloud Practitioner', 'Amazon Web Services', '4 weeks', 'Beginner', ARRAY['AWS', 'Cloud Computing', 'Architecture'], 'https://aws.amazon.com/training'),
('8', '3', 'Java Programming Masterclass', 'Oracle', '8 weeks', 'Intermediate', ARRAY['Java', 'Object-Oriented Programming', 'Spring'], 'https://education.oracle.com/java'),
('9', '3', 'Distributed Systems Design', 'MIT', '12 weeks', 'Advanced', ARRAY['Distributed Systems', 'Scalability', 'Microservices'], 'https://mit.edu/courses/6.824'),
('10', '4', 'iOS App Development with Swift', 'Apple', '6 weeks', 'Beginner', ARRAY['Swift', 'iOS', 'Xcode'], 'https://developer.apple.com/swift'),
('11', '4', 'SwiftUI Fundamentals', 'Apple', '4 weeks', 'Intermediate', ARRAY['SwiftUI', 'UI Design', 'iOS'], 'https://developer.apple.com/swiftui'),
('12', '4', 'Human Interface Guidelines', 'Apple', '2 weeks', 'Beginner', ARRAY['UI/UX Design', 'Design Principles', 'Accessibility'], 'https://developer.apple.com/design'),
('13', '5', 'Computer Vision and Video Processing', 'Stanford', '8 weeks', 'Advanced', ARRAY['Computer Vision', 'Python', 'OpenCV'], 'https://stanford.edu/courses/cs231n'),
('14', '5', 'React Native Development', 'Facebook', '5 weeks', 'Intermediate', ARRAY['React Native', 'Mobile Development', 'JavaScript'], 'https://reactnative.dev/docs/tutorial'),
('15', '5', 'Recommendation Systems', 'University of Minnesota', '6 weeks', 'Advanced', ARRAY['Machine Learning', 'Data Science', 'Python'], 'https://coursera.org/learn/recommender-systems');

-- Insert sample checklist items (template items, user_id is NULL)
INSERT INTO checklist_items (id, company_id, user_id, title, description, completed, category) VALUES
('1', '1', NULL, 'Build a React Portfolio Project', 'Create a full-stack application using React and showcase your frontend skills', FALSE, 'Portfolio'),
('2', '1', NULL, 'Practice System Design Questions', 'Focus on scalable social media features like news feeds and messaging', FALSE, 'Interview Prep'),
('3', '1', NULL, 'Study Meta''s Mission and Values', 'Understand Meta''s focus on building connections and community', FALSE, 'Culture Study'),
('4', '1', NULL, 'Learn Python for Backend Development', 'Meta uses Python extensively for backend services', FALSE, 'Technical Skills'),
('5', '2', NULL, 'Master LeetCode Medium Problems', 'Focus on arrays, trees, graphs, and dynamic programming', FALSE, 'Interview Prep'),
('6', '2', NULL, 'Build a Machine Learning Project', 'Use TensorFlow or PyTorch to solve a real-world problem', FALSE, 'Portfolio'),
('7', '2', NULL, 'Study Google''s Engineering Principles', 'Understand Google''s approach to building reliable, scalable systems', FALSE, 'Culture Study'),
('8', '2', NULL, 'Learn Go Programming Language', 'Google uses Go for many backend services', FALSE, 'Technical Skills'),
('9', '3', NULL, 'Study Amazon Leadership Principles', 'Prepare STAR method examples for all 16 leadership principles', FALSE, 'Culture Study'),
('10', '3', NULL, 'Build a Distributed System Project', 'Create a microservices architecture with proper monitoring', FALSE, 'Portfolio'),
('11', '3', NULL, 'Practice Object-Oriented Design', 'Focus on design patterns and system architecture questions', FALSE, 'Interview Prep'),
('12', '3', NULL, 'Learn AWS Services', 'Get hands-on experience with EC2, S3, Lambda, and RDS', FALSE, 'Technical Skills'),
('13', '4', NULL, 'Build an iOS App Portfolio', 'Create 2-3 polished iOS apps showcasing different skills', FALSE, 'Portfolio'),
('14', '4', NULL, 'Master Swift Programming', 'Deep dive into Swift language features and best practices', FALSE, 'Technical Skills'),
('15', '4', NULL, 'Study Apple Design Principles', 'Understand Apple''s approach to intuitive, beautiful interfaces', FALSE, 'Culture Study'),
('16', '4', NULL, 'Practice iOS System Design', 'Focus on mobile-specific constraints and optimizations', FALSE, 'Interview Prep'),
('17', '5', NULL, 'Build a Social Media App', 'Create a mobile app with video features and social interactions', FALSE, 'Portfolio'),
('18', '5', NULL, 'Learn Video Processing Technologies', 'Understand video codecs, streaming, and real-time processing', FALSE, 'Technical Skills'),
('19', '5', NULL, 'Study TikTok''s Global Impact', 'Understand TikTok''s role in digital culture and creator economy', FALSE, 'Culture Study'),
('20', '5', NULL, 'Practice ML System Design', 'Focus on recommendation systems and content moderation at scale', FALSE, 'Interview Prep');

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_resumes_updated_at BEFORE UPDATE ON resumes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tailored_resumes_updated_at BEFORE UPDATE ON tailored_resumes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_checklist_items_updated_at BEFORE UPDATE ON checklist_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- View for user dashboard statistics
CREATE OR REPLACE VIEW user_dashboard_stats AS
SELECT 
    u.id as user_id,
    COUNT(DISTINCT a.id) as total_applications,
    COUNT(DISTINCT CASE WHEN a.status = 'Applied' THEN a.id END) as pending_applications,
    COUNT(DISTINCT CASE WHEN a.status = 'Interview' THEN a.id END) as interviews,
    COUNT(DISTINCT CASE WHEN a.status = 'Offer' THEN a.id END) as offers,
    COUNT(DISTINCT CASE WHEN a.status = 'Rejected' THEN a.id END) as rejected,
    u.weekly_goal,
    COUNT(DISTINCT CASE 
        WHEN a.applied_date >= DATE_TRUNC('week', CURRENT_DATE) 
        THEN a.id 
    END) as weekly_progress
FROM users u
LEFT JOIN applications a ON u.id = a.user_id
GROUP BY u.id, u.weekly_goal;

-- View for company recommendations with user target status
CREATE OR REPLACE VIEW company_recommendations_view AS
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
         c.benefits, c.interview_process, c.created_at, c.updated_at;

COMMENT ON TABLE users IS 'Stores user account information and preferences';
COMMENT ON TABLE companies IS 'Stores company information and details';
COMMENT ON TABLE applications IS 'Stores job applications made by users';
COMMENT ON TABLE resumes IS 'Stores user uploaded resumes';
COMMENT ON TABLE tailored_resumes IS 'Stores AI-tailored versions of resumes for specific job applications';
COMMENT ON TABLE user_target_companies IS 'Junction table for users and their target companies';
COMMENT ON TABLE events IS 'Stores company events (tech talks, workshops, etc.)';
COMMENT ON TABLE courses IS 'Stores recommended courses for companies';
COMMENT ON TABLE checklist_items IS 'Stores preparation checklist items (templates and user-specific)';

