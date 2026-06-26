"""Fix missing tables - run inside backend container"""
import asyncio
from app.db.session import engine

TABLES_SQL = [
    # essl_locations (from c2d3e4f5a6b7)
    """CREATE TABLE IF NOT EXISTS essl_locations (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        essl_server_id UUID NOT NULL REFERENCES essl_servers(id) ON DELETE CASCADE,
        code VARCHAR(100) NOT NULL,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        is_active BOOLEAN NOT NULL DEFAULT true,
        synced_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(essl_server_id, code)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_essl_locations_tenant_id ON essl_locations(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_essl_locations_essl_server_id ON essl_locations(essl_server_id)",

    # holidays (from d3e4f5a6b7c8)
    """CREATE TABLE IF NOT EXISTS holidays (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        date DATE NOT NULL,
        type VARCHAR(50) NOT NULL DEFAULT 'company',
        description TEXT,
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(tenant_id, date)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_holidays_tenant_id ON holidays(tenant_id)",

    # employee_categories (from e4f5a6b7c8d9)
    """CREATE TABLE IF NOT EXISTS employee_categories (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        code VARCHAR(100) NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT true,
        ot_formula VARCHAR(50) NOT NULL DEFAULT 'out_punch',
        min_ot_minutes INTEGER NOT NULL DEFAULT 0,
        max_ot_minutes INTEGER NOT NULL DEFAULT 0,
        grace_minutes INTEGER NOT NULL DEFAULT 0,
        half_day_threshold_minutes INTEGER NOT NULL DEFAULT 240,
        absent_threshold_minutes INTEGER NOT NULL DEFAULT 0,
        late_absent_minutes INTEGER NOT NULL DEFAULT 0,
        late_occurrences_absent_count INTEGER NOT NULL DEFAULT 0,
        weekly_off_1 INTEGER NOT NULL DEFAULT 6,
        weekly_off_2 INTEGER,
        weekly_off_2_week VARCHAR(50) NOT NULL DEFAULT 'every',
        consider_first_last_punch BOOLEAN NOT NULL DEFAULT true,
        neglect_last_in_on_missed_out BOOLEAN NOT NULL DEFAULT false,
        consider_early_coming BOOLEAN NOT NULL DEFAULT true,
        consider_late_going BOOLEAN NOT NULL DEFAULT true,
        deduct_break_hours BOOLEAN NOT NULL DEFAULT true,
        mark_wo_holiday_absent_if_prefix_absent BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(tenant_id, code)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_employee_categories_tenant_id ON employee_categories(tenant_id)",

    # tenant_settings (from e4f5a6b7c8d9)
    """CREATE TABLE IF NOT EXISTS tenant_settings (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
        attendance_year_start_month INTEGER NOT NULL DEFAULT 1,
        attendance_year_start_day INTEGER NOT NULL DEFAULT 1,
        min_punch_difference_minutes INTEGER NOT NULL DEFAULT 1,
        punch_begin_before_minutes INTEGER NOT NULL DEFAULT 60,
        auto_shift_if_no_schedule BOOLEAN NOT NULL DEFAULT true,
        fixed_shift_mode BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_tenant_settings_tenant_id ON tenant_settings(tenant_id)",

    # shift_groups (from f5a6b7c8d9e0)
    """CREATE TABLE IF NOT EXISTS shift_groups (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        description VARCHAR(512),
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(tenant_id, name)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_shift_groups_tenant_id ON shift_groups(tenant_id)",

    # shift_group_members
    """CREATE TABLE IF NOT EXISTS shift_group_members (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        group_id UUID NOT NULL REFERENCES shift_groups(id) ON DELETE CASCADE,
        shift_id UUID NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(group_id, shift_id)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_shift_group_members_tenant_id ON shift_group_members(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_shift_group_members_group_id ON shift_group_members(group_id)",
    "CREATE INDEX IF NOT EXISTS ix_shift_group_members_shift_id ON shift_group_members(shift_id)",

    # shift_rosters
    """CREATE TABLE IF NOT EXISTS shift_rosters (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        description VARCHAR(512),
        rotation_pattern VARCHAR(50) NOT NULL DEFAULT 'weekly',
        weekly_off_1 INTEGER NOT NULL DEFAULT 6,
        weekly_off_2 INTEGER,
        weekly_off_2_week VARCHAR(50) NOT NULL DEFAULT 'every',
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(tenant_id, name)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_shift_rosters_tenant_id ON shift_rosters(tenant_id)",

    # shift_roster_entries
    """CREATE TABLE IF NOT EXISTS shift_roster_entries (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        roster_id UUID NOT NULL REFERENCES shift_rosters(id) ON DELETE CASCADE,
        day_number INTEGER NOT NULL,
        shift_id UUID REFERENCES shifts(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(roster_id, day_number)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_shift_roster_entries_tenant_id ON shift_roster_entries(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_shift_roster_entries_roster_id ON shift_roster_entries(roster_id)",

    # department_shifts
    """CREATE TABLE IF NOT EXISTS department_shifts (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
        shift_id UUID NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
        effective_from DATE NOT NULL,
        effective_to DATE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(tenant_id, department_id, shift_id, effective_from)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_department_shifts_tenant_id ON department_shifts(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_department_shifts_department_id ON department_shifts(department_id)",
    "CREATE INDEX IF NOT EXISTS ix_department_shifts_shift_id ON department_shifts(shift_id)",

    # outdoor_duties (from a6b7c8d9e0f1)
    """CREATE TABLE IF NOT EXISTS outdoor_duties (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        from_time TIME,
        to_time TIME,
        reason TEXT,
        location VARCHAR(255),
        status VARCHAR(50) NOT NULL DEFAULT 'pending',
        approved_by UUID REFERENCES employees(id) ON DELETE SET NULL,
        approved_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_outdoor_duties_tenant_id ON outdoor_duties(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_outdoor_duties_employee_id ON outdoor_duties(employee_id)",

    # ot_register
    """CREATE TABLE IF NOT EXISTS ot_register (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        ot_hours FLOAT NOT NULL,
        ot_type VARCHAR(50) NOT NULL DEFAULT 'normal',
        status VARCHAR(50) NOT NULL DEFAULT 'pending',
        approved_by UUID REFERENCES employees(id) ON DELETE SET NULL,
        remarks TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_ot_register_tenant_id ON ot_register(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_ot_register_employee_id ON ot_register(employee_id)",

    # work_codes
    """CREATE TABLE IF NOT EXISTS work_codes (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        code VARCHAR(50) NOT NULL,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(tenant_id, code)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_work_codes_tenant_id ON work_codes(tenant_id)",

    # salary_structures (from b7c8d9e0f1a2)
    """CREATE TABLE IF NOT EXISTS salary_structures (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        basic FLOAT NOT NULL DEFAULT 0,
        hra FLOAT NOT NULL DEFAULT 0,
        da FLOAT NOT NULL DEFAULT 0,
        conveyance FLOAT NOT NULL DEFAULT 0,
        medical FLOAT NOT NULL DEFAULT 0,
        special FLOAT NOT NULL DEFAULT 0,
        pf_employee FLOAT NOT NULL DEFAULT 0,
        pf_employer FLOAT NOT NULL DEFAULT 0,
        esi_employee FLOAT NOT NULL DEFAULT 0,
        esi_employer FLOAT NOT NULL DEFAULT 0,
        professional_tax FLOAT NOT NULL DEFAULT 0,
        income_tax FLOAT NOT NULL DEFAULT 0,
        effective_from DATE NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(employee_id, effective_from)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_salary_structures_tenant_id ON salary_structures(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_salary_structures_employee_id ON salary_structures(employee_id)",

    # pay_slips
    """CREATE TABLE IF NOT EXISTS pay_slips (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        basic FLOAT NOT NULL DEFAULT 0,
        hra FLOAT NOT NULL DEFAULT 0,
        da FLOAT NOT NULL DEFAULT 0,
        conveyance FLOAT NOT NULL DEFAULT 0,
        medical FLOAT NOT NULL DEFAULT 0,
        special FLOAT NOT NULL DEFAULT 0,
        gross_earnings FLOAT NOT NULL DEFAULT 0,
        pf FLOAT NOT NULL DEFAULT 0,
        esi FLOAT NOT NULL DEFAULT 0,
        pt FLOAT NOT NULL DEFAULT 0,
        it FLOAT NOT NULL DEFAULT 0,
        total_deductions FLOAT NOT NULL DEFAULT 0,
        net_pay FLOAT NOT NULL DEFAULT 0,
        working_days INTEGER NOT NULL DEFAULT 0,
        present_days INTEGER NOT NULL DEFAULT 0,
        absent_days INTEGER NOT NULL DEFAULT 0,
        leave_days INTEGER NOT NULL DEFAULT 0,
        ot_hours FLOAT NOT NULL DEFAULT 0,
        ot_amount FLOAT NOT NULL DEFAULT 0,
        lop_days INTEGER NOT NULL DEFAULT 0,
        lop_amount FLOAT NOT NULL DEFAULT 0,
        status VARCHAR(50) NOT NULL DEFAULT 'draft',
        generated_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        UNIQUE(tenant_id, employee_id, month, year)
    )""",
    "CREATE INDEX IF NOT EXISTS ix_pay_slips_tenant_id ON pay_slips(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_pay_slips_employee_id ON pay_slips(employee_id)",

    # loans
    """CREATE TABLE IF NOT EXISTS loans (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        loan_type VARCHAR(100) NOT NULL,
        amount FLOAT NOT NULL,
        emi_amount FLOAT NOT NULL,
        start_date DATE NOT NULL,
        total_installments INTEGER NOT NULL,
        paid_installments INTEGER NOT NULL DEFAULT 0,
        status VARCHAR(50) NOT NULL DEFAULT 'active',
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_loans_tenant_id ON loans(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_loans_employee_id ON loans(employee_id)",

    # documents (from c8d9e0f1a2b3)
    """CREATE TABLE IF NOT EXISTS documents (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
        doc_type VARCHAR(50) NOT NULL DEFAULT 'other',
        title VARCHAR(255) NOT NULL,
        file_path VARCHAR(512) NOT NULL,
        file_name VARCHAR(255) NOT NULL,
        file_size INTEGER DEFAULT 0,
        mime_type VARCHAR(100),
        uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
        is_confidential BOOLEAN DEFAULT false,
        expiry_date DATE,
        description TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_documents_tenant_id ON documents(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_documents_employee_id ON documents(employee_id)",

    # onboarding_tasks
    """CREATE TABLE IF NOT EXISTS onboarding_tasks (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        assigned_to UUID REFERENCES employees(id) ON DELETE SET NULL,
        due_date DATE,
        status VARCHAR(50) NOT NULL DEFAULT 'pending',
        completed_at TIMESTAMPTZ,
        order_index INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_onboarding_tasks_tenant_id ON onboarding_tasks(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_onboarding_tasks_employee_id ON onboarding_tasks(employee_id)",

    # exit_requests
    """CREATE TABLE IF NOT EXISTS exit_requests (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        resignation_date DATE NOT NULL,
        last_working_date DATE,
        reason TEXT,
        status VARCHAR(50) NOT NULL DEFAULT 'pending',
        approved_by UUID REFERENCES employees(id) ON DELETE SET NULL,
        approved_at TIMESTAMPTZ,
        exit_interview_notes TEXT,
        clearance_status VARCHAR(50) NOT NULL DEFAULT 'pending',
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_exit_requests_tenant_id ON exit_requests(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_exit_requests_employee_id ON exit_requests(employee_id)",

    # employee_events
    """CREATE TABLE IF NOT EXISTS employee_events (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        event_type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        event_date DATE NOT NULL,
        created_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_employee_events_tenant_id ON employee_events(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_employee_events_employee_id ON employee_events(employee_id)",

    # expense_categories (from d9e0f1a2b3c4)
    """CREATE TABLE IF NOT EXISTS expense_categories (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        code VARCHAR(100) NOT NULL,
        description TEXT,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_expense_categories_tenant_id ON expense_categories(tenant_id)",

    # expense_claims
    """CREATE TABLE IF NOT EXISTS expense_claims (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL,
        amount FLOAT NOT NULL,
        date DATE NOT NULL,
        description TEXT,
        receipt_path VARCHAR(512),
        status VARCHAR(50) NOT NULL DEFAULT 'draft',
        approved_by UUID REFERENCES employees(id) ON DELETE SET NULL,
        approved_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_expense_claims_tenant_id ON expense_claims(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_expense_claims_employee_id ON expense_claims(employee_id)",

    # tax_declarations
    """CREATE TABLE IF NOT EXISTS tax_declarations (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        financial_year VARCHAR(10) NOT NULL,
        hra_received FLOAT DEFAULT 0,
        rent_paid FLOAT DEFAULT 0,
        section_80c FLOAT DEFAULT 0,
        section_80d FLOAT DEFAULT 0,
        home_loan_interest FLOAT DEFAULT 0,
        other_exemptions FLOAT DEFAULT 0,
        status VARCHAR(50) DEFAULT 'draft',
        remarks TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_tax_declarations_tenant_id ON tax_declarations(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_tax_declarations_employee_id ON tax_declarations(employee_id)",

    # benefits
    """CREATE TABLE IF NOT EXISTS benefits (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        type VARCHAR(50) DEFAULT 'allowance',
        amount FLOAT DEFAULT 0,
        frequency VARCHAR(50) DEFAULT 'monthly',
        is_taxable BOOLEAN DEFAULT true,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_benefits_tenant_id ON benefits(tenant_id)",

    # employee_benefits
    """CREATE TABLE IF NOT EXISTS employee_benefits (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        benefit_id UUID NOT NULL REFERENCES benefits(id) ON DELETE CASCADE,
        amount FLOAT DEFAULT 0,
        effective_from DATE NOT NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_employee_benefits_tenant_id ON employee_benefits(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_employee_benefits_employee_id ON employee_benefits(employee_id)",
    "CREATE INDEX IF NOT EXISTS ix_employee_benefits_benefit_id ON employee_benefits(benefit_id)",

    # company_assets
    """CREATE TABLE IF NOT EXISTS company_assets (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        asset_code VARCHAR(100) NOT NULL,
        category VARCHAR(100) DEFAULT 'other',
        serial_number VARCHAR(255),
        purchase_date DATE,
        warranty_expiry DATE,
        assigned_to UUID REFERENCES employees(id) ON DELETE SET NULL,
        status VARCHAR(50) DEFAULT 'available',
        description TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_company_assets_tenant_id ON company_assets(tenant_id)",

    # travel_requests
    """CREATE TABLE IF NOT EXISTS travel_requests (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        destination VARCHAR(255) NOT NULL,
        purpose TEXT,
        from_date DATE NOT NULL,
        to_date DATE NOT NULL,
        estimated_cost FLOAT DEFAULT 0,
        status VARCHAR(50) DEFAULT 'pending',
        approved_by UUID REFERENCES employees(id) ON DELETE SET NULL,
        approved_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_travel_requests_tenant_id ON travel_requests(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_travel_requests_employee_id ON travel_requests(employee_id)",

    # announcements
    """CREATE TABLE IF NOT EXISTS announcements (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        priority VARCHAR(50) DEFAULT 'normal',
        publish_at TIMESTAMPTZ,
        expires_at TIMESTAMPTZ,
        is_active BOOLEAN DEFAULT true,
        created_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_announcements_tenant_id ON announcements(tenant_id)",

    # polls
    """CREATE TABLE IF NOT EXISTS polls (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        question VARCHAR(500) NOT NULL,
        options JSONB NOT NULL,
        expires_at TIMESTAMPTZ,
        is_anonymous BOOLEAN DEFAULT false,
        is_active BOOLEAN DEFAULT true,
        created_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_polls_tenant_id ON polls(tenant_id)",

    # poll_responses
    """CREATE TABLE IF NOT EXISTS poll_responses (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
        employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
        selected_option INTEGER NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_poll_responses_tenant_id ON poll_responses(tenant_id)",
    "CREATE INDEX IF NOT EXISTS ix_poll_responses_poll_id ON poll_responses(poll_id)",
    "CREATE INDEX IF NOT EXISTS ix_poll_responses_employee_id ON poll_responses(employee_id)",

    # notification_templates
    """CREATE TABLE IF NOT EXISTS notification_templates (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        event_type VARCHAR(100) NOT NULL,
        channel VARCHAR(50) DEFAULT 'in_app',
        subject_template VARCHAR(500),
        body_template TEXT NOT NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )""",
    "CREATE INDEX IF NOT EXISTS ix_notification_templates_tenant_id ON notification_templates(tenant_id)",
]

COLUMNS_SQL = [
    # category_id on employees (from e4f5a6b7c8d9)
    """DO $$ BEGIN
        ALTER TABLE employees ADD COLUMN category_id UUID REFERENCES employee_categories(id) ON DELETE SET NULL;
    EXCEPTION WHEN duplicate_column THEN NULL;
    END $$""",
    "CREATE INDEX IF NOT EXISTS ix_employees_category_id ON employees(category_id)",

    # shift_group_id on employees (from f5a6b7c8d9e0)
    """DO $$ BEGIN
        ALTER TABLE employees ADD COLUMN shift_group_id UUID REFERENCES shift_groups(id) ON DELETE SET NULL;
    EXCEPTION WHEN duplicate_column THEN NULL;
    END $$""",
    "CREATE INDEX IF NOT EXISTS ix_employees_shift_group_id ON employees(shift_group_id)",

    # shift_roster_id on employees (from f5a6b7c8d9e0)
    """DO $$ BEGIN
        ALTER TABLE employees ADD COLUMN shift_roster_id UUID REFERENCES shift_rosters(id) ON DELETE SET NULL;
    EXCEPTION WHEN duplicate_column THEN NULL;
    END $$""",
    "CREATE INDEX IF NOT EXISTS ix_employees_shift_roster_id ON employees(shift_roster_id)",
]


async def main():
    async with engine.begin() as conn:
        for sql in TABLES_SQL + COLUMNS_SQL:
            try:
                await conn.execute(__import__('sqlalchemy').text(sql))
            except Exception as e:
                if 'already exists' in str(e).lower() or 'duplicate' in str(e).lower():
                    pass
                else:
                    print(f"ERROR: {e}")
                    print(f"  SQL: {sql[:100]}...")
        print("Done! All tables created.")

    # Update alembic_version to head
    async with engine.begin() as conn:
        await conn.execute(__import__('sqlalchemy').text(
            "UPDATE alembic_version SET version_num = '34d53d38e2ec'"
        ))
        print("Alembic version stamped to head: 34d53d38e2ec")

    await engine.dispose()

if __name__ == '__main__':
    asyncio.run(main())
