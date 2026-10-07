-- ==============================================================================
-- VillageNova PostgreSQL Schema - Initial Baseline
-- Created: October 2026 | Supabase / PostgreSQL Migration
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMS
CREATE TYPE resident_role_type AS ENUM (
    'farmer',
    'cattle_owner',
    'student',
    'job_seeker',
    'business_owner',
    'shg_livelihood',
    'resident_family'
);

CREATE TYPE soil_type_enum AS ENUM (
    'clay',
    'loamy',
    'black',
    'red',
    'sandy',
    'unknown'
);

CREATE TYPE water_source_enum AS ENUM (
    'borewell',
    'canal',
    'rainfed',
    'tank',
    'other'
);

CREATE TYPE crop_stage_enum AS ENUM (
    'sowing',
    'germination',
    'vegetative',
    'flowering',
    'maturity',
    'harvest',
    'post_harvest'
);

-- 3. VILLAGES
CREATE TABLE IF NOT EXISTS villages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    mandal VARCHAR(150) NOT NULL,
    district VARCHAR(150) NOT NULL,
    state VARCHAR(150) NOT NULL,
    pincode VARCHAR(10),
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. RESIDENT PROFILES (1:1 with auth.users)
CREATE TABLE IF NOT EXISTS resident_profiles (
    id UUID PRIMARY KEY, -- references auth.users(id) in Supabase
    full_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(20),
    village_id UUID REFERENCES villages(id) ON DELETE SET NULL,
    preferred_language VARCHAR(20) DEFAULT 'en',
    verified_badge BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. RESIDENT ROLES (One resident -> multiple roles)
CREATE TABLE IF NOT EXISTS resident_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resident_id UUID NOT NULL REFERENCES resident_profiles(id) ON DELETE CASCADE,
    role resident_role_type NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(resident_id, role)
);

-- 6. FARMS
CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resident_id UUID NOT NULL REFERENCES resident_profiles(id) ON DELETE CASCADE,
    farm_name VARCHAR(150) DEFAULT 'Main Farm',
    land_acres NUMERIC(6, 2) NOT NULL,
    soil_type soil_type_enum DEFAULT 'unknown',
    water_source water_source_enum DEFAULT 'other',
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. CROPS
CREATE TABLE IF NOT EXISTS crops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    crop_name VARCHAR(100) NOT NULL,
    variety VARCHAR(100),
    sowing_date DATE NOT NULL,
    current_stage crop_stage_enum DEFAULT 'sowing',
    farming_goal VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. CROP ACTIVITIES
CREATE TABLE IF NOT EXISTS crop_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_id UUID NOT NULL REFERENCES crops(id) ON DELETE CASCADE,
    activity_type VARCHAR(100) NOT NULL, -- irrigation, fertilizer, pesticide, weeding, soil_check
    description TEXT,
    cost_incurred NUMERIC(10, 2) DEFAULT 0.0,
    performed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. CROP OBSERVATIONS (Photos & Diagnostics)
CREATE TABLE IF NOT EXISTS crop_observations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_id UUID NOT NULL REFERENCES crops(id) ON DELETE CASCADE,
    observation_text TEXT NOT NULL,
    photo_url TEXT,
    ai_diagnosis_summary TEXT,
    severity_level VARCHAR(50), -- mild, moderate, critical
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. FARM EXPENSES
CREATE TABLE IF NOT EXISTS farm_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    crop_id UUID REFERENCES crops(id) ON DELETE SET NULL,
    category VARCHAR(100) NOT NULL, -- seeds, fertilizer, labor, machinery, water
    amount NUMERIC(10, 2) NOT NULL,
    expense_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. VILLAGE UPDATES (Community bulletin feed)
CREATE TABLE IF NOT EXISTS village_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    village_id UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    author_id UUID REFERENCES resident_profiles(id) ON DELETE SET NULL,
    category VARCHAR(50) NOT NULL, -- panchayat, agriculture, education, emergency, community
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    is_emergency BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. GOVERNMENT SCHEMES
CREATE TABLE IF NOT EXISTS schemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_code VARCHAR(100) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    department VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    target_roles VARCHAR(100)[] DEFAULT '{}',
    eligibility_criteria JSONB DEFAULT '{}'::jsonb,
    required_documents TEXT[] DEFAULT '{}',
    official_portal_url TEXT,
    deadline DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. SCHEME MATCHES
CREATE TABLE IF NOT EXISTS scheme_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resident_id UUID NOT NULL REFERENCES resident_profiles(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    match_status VARCHAR(50) DEFAULT 'potentially_eligible', -- eligible, potentially_eligible, applied
    match_score NUMERIC(5, 2) DEFAULT 0.0,
    match_reasons TEXT[] DEFAULT '{}',
    is_saved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(resident_id, scheme_id)
);

-- 14. TASKS & PROGRESS
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resident_id UUID NOT NULL REFERENCES resident_profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    domain VARCHAR(50) NOT NULL, -- farm, scheme, education, village
    due_date DATE,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. CONVERSATIONS & MESSAGES (Ask VillageNova History)
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resident_id UUID NOT NULL REFERENCES resident_profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) DEFAULT 'Chat with VillageNova',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL, -- user, assistant, system
    content TEXT NOT NULL,
    actions JSONB DEFAULT '[]'::jsonb,
    sources JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 16. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE resident_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE resident_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE crops ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE farm_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheme_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE villages ENABLE ROW LEVEL SECURITY;
ALTER TABLE village_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE schemes ENABLE ROW LEVEL SECURITY;

-- Residents can only access their own profile
CREATE POLICY "Residents read own profile" ON resident_profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Residents update own profile" ON resident_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Residents can only access their own farms and crops
CREATE POLICY "Residents access own farms" ON farms
    FOR ALL USING (auth.uid() = resident_id);
CREATE POLICY "Residents access own tasks" ON tasks
    FOR ALL USING (auth.uid() = resident_id);

-- Public read access for verified village updates & schemes
CREATE POLICY "Public read village updates" ON village_updates
    FOR SELECT USING (true);
CREATE POLICY "Public read schemes" ON schemes
    FOR SELECT USING (true);
CREATE POLICY "Public read villages" ON villages
    FOR SELECT USING (true);
