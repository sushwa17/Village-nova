-- ==============================================================================
-- VillageNova Sample Seed Data: Demo Villages & Government Schemes
-- ==============================================================================

-- Seed Sample Villages
INSERT INTO villages (id, name, mandal, district, state, pincode, latitude, longitude)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Ananthagiri', 'Vikarabad', 'Vikarabad', 'Telangana', '501101', 17.3100, 77.8600),
    ('a0000000-0000-0000-0000-000000000002', 'Kondurg', 'Shadnagar', 'Ranga Reddy', 'Telangana', '509207', 17.0600, 78.2200),
    ('a0000000-0000-0000-0000-000000000003', 'Pardi', 'Arvi', 'Wardha', 'Maharashtra', '442201', 20.9900, 78.2300)
ON CONFLICT (id) DO NOTHING;

-- Seed Sample Government Schemes
INSERT INTO schemes (id, scheme_code, title, department, description, target_roles, eligibility_criteria, required_documents, official_portal_url)
VALUES
    (
        'b0000000-0000-0000-0000-000000000001',
        'PM-KISAN',
        'Pradhan Mantri Kisan Samman Nidhi',
        'Ministry of Agriculture & Farmers Welfare',
        'Income support of ₹6,000 per year in three equal installments to all landholding farmer families.',
        ARRAY['farmer'],
        '{"max_land_acres": 100, "is_landholding_farmer": true}'::jsonb,
        ARRAY['Aadhaar Card', 'Land Ownership Records (Pattadar Passbook)', 'Bank Account Details'],
        'https://pmkisan.gov.in'
    ),
    (
        'b0000000-0000-0000-0000-000000000002',
        'PMFBY',
        'Pradhan Mantri Fasal Bima Yojana',
        'Ministry of Agriculture & Farmers Welfare',
        'Comprehensive crop insurance against non-preventable natural risks from pre-sowing to post-harvest.',
        ARRAY['farmer'],
        '{"enrolled_crop_notified": true}'::jsonb,
        ARRAY['Aadhaar Card', 'Sowing Certificate', 'Land Possession Certificate', 'Bank Passbook'],
        'https://pmfby.gov.in'
    ),
    (
        'b0000000-0000-0000-0000-000000000003',
        'NSP-PRE-MATRIC',
        'National Scholarship Portal - Pre-Matric',
        'Ministry of Minority Affairs / Social Justice',
        'Financial assistance to meritorious students from disadvantaged rural communities to continue school education.',
        ARRAY['student'],
        '{"max_annual_income": 250000, "min_attendance_pct": 75}'::jsonb,
        ARRAY['Student Aadhaar', 'Previous Year Marksheet', 'Income Certificate', 'Bonafide Certificate'],
        'https://scholarships.gov.in'
    )
ON CONFLICT (id) DO NOTHING;
