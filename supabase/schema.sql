-- ============================================================
-- Pharmaceutical ERP & Billing — Full Supabase PostgreSQL Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query → Run
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Row Level Security helper ─────────────────────────────────
-- Disable RLS for all tables (enable & configure after going live)
-- We use anon key so all ops go through service role logic

-- ── 1. Companies ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  gstin TEXT,
  address TEXT,
  phone TEXT,
  currency TEXT DEFAULT 'INR',
  financial_year TEXT DEFAULT '2026-2027',
  industry_category TEXT DEFAULT 'Pharma',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. Locations / Godowns ────────────────────────────────────
CREATE TABLE IF NOT EXISTS locations_godowns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_godown BOOLEAN DEFAULT FALSE,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. App Users ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  role_name TEXT DEFAULT 'Standard User',
  permissions JSONB DEFAULT '{}'::jsonb,
  store_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. Parties (Customers & Suppliers) ───────────────────────
CREATE TABLE IF NOT EXISTS parties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  party_type TEXT CHECK (party_type IN ('customer', 'supplier')),
  gstin TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  pricing_tier TEXT DEFAULT 'retail',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. Patient Profiles ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS patient_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  party_id UUID REFERENCES parties(id) ON DELETE CASCADE,
  patient_name TEXT NOT NULL,
  age INT,
  gender TEXT,
  known_allergies TEXT[] DEFAULT '{}',
  chronic_refill_notes TEXT,
  prescription_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. Prescriptions ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS prescriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patient_profiles(id) ON DELETE CASCADE,
  doctor_name TEXT NOT NULL,
  doctor_license TEXT,
  rx_number TEXT NOT NULL,
  rx_details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 7. Products ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  generic_name TEXT,
  hsn_code TEXT NOT NULL,
  gst_rate DECIMAL(5,2) DEFAULT 12.0,
  schedule_type TEXT DEFAULT 'OTC',
  reorder_level INT DEFAULT 10,
  rack TEXT,
  shelf TEXT,
  barcode TEXT,
  manufacturer TEXT,
  category TEXT,
  unit TEXT,
  pack_size TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 8. Batches ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  location_id UUID,
  batch_number TEXT NOT NULL,
  mfg_date DATE,
  expiry_date DATE NOT NULL,
  retail_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  wholesale_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  distributor_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  loyalty_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  purchase_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  current_stock INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 9. Invoices ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  location_id UUID,
  invoice_number TEXT NOT NULL UNIQUE,
  party_id UUID REFERENCES parties(id),
  prescription_id UUID,
  invoice_type TEXT CHECK (invoice_type IN ('sales', 'purchase')),
  payment_method TEXT DEFAULT 'cash',
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  e_invoice_irn TEXT,
  pharmacist_approved BOOLEAN DEFAULT TRUE,
  cash_amount DECIMAL(10,2) DEFAULT 0,
  card_amount DECIMAL(10,2) DEFAULT 0,
  upi_amount DECIMAL(10,2) DEFAULT 0,
  is_cancelled BOOLEAN DEFAULT FALSE,
  cancel_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 10. Invoice Items ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoice_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  batch_id UUID REFERENCES batches(id),
  product_name TEXT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount_percent DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 11. Credit & Debit Notes ──────────────────────────────────
CREATE TABLE IF NOT EXISTS credit_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  party_id UUID REFERENCES parties(id),
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS debit_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  party_id UUID REFERENCES parties(id),
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 12. Payments ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  party_id UUID REFERENCES parties(id),
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_type TEXT CHECK (payment_type IN ('payment', 'receipt')),
  payment_mode TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 13. Accounts & Ledger ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT,
  balance DECIMAL(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ledger_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
  description TEXT,
  debit DECIMAL(12,2) DEFAULT 0,
  credit DECIMAL(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bank_reconciliations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  account_id UUID REFERENCES accounts(id),
  statement_date DATE NOT NULL,
  statement_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
  reconciled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 14. Restricted Drug Logs ──────────────────────────────────
CREATE TABLE IF NOT EXISTS restricted_drug_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  invoice_id UUID,
  product_id UUID REFERENCES products(id),
  batch_id UUID REFERENCES batches(id),
  schedule_type TEXT,
  patient_name TEXT NOT NULL,
  doctor_name TEXT NOT NULL,
  quantity INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 15. Audit Logs ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID,
  user_id UUID,
  action TEXT NOT NULL,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 16. RTV Notes ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rtv_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID,
  batch_id UUID REFERENCES batches(id),
  supplier_id UUID REFERENCES parties(id),
  quantity INT NOT NULL DEFAULT 0,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 17. Purchase Orders ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID,
  supplier_id UUID REFERENCES parties(id),
  product_id UUID REFERENCES products(id),
  quantity INT NOT NULL DEFAULT 0,
  status TEXT DEFAULT 'auto_generated',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 18. Refill Reminders ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS refill_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patient_profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  reminder_date DATE NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 19. Stores ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 20. Store Stock Transfers ─────────────────────────────────
CREATE TABLE IF NOT EXISTS store_stock_transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_store_id UUID REFERENCES stores(id),
  to_store_id UUID REFERENCES stores(id),
  product_id UUID REFERENCES products(id),
  batch_id UUID REFERENCES batches(id),
  quantity INT NOT NULL DEFAULT 0,
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 21. Stock Adjustments ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS stock_adjustments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID,
  batch_id UUID REFERENCES batches(id),
  product_id UUID REFERENCES products(id),
  quantity_change INT NOT NULL DEFAULT 0,
  adjustment_type TEXT,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 22. Supabase Storage bucket for prescriptions ─────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('prescriptions', 'prescriptions', true)
ON CONFLICT (id) DO NOTHING;

-- ── 23. RLS: Disable for all tables (open for demo) ──────────
-- In production, replace these with proper per-user policies.
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE locations_godowns DISABLE ROW LEVEL SECURITY;
ALTER TABLE app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE parties DISABLE ROW LEVEL SECURITY;
ALTER TABLE patient_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE invoices DISABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE credit_notes DISABLE ROW LEVEL SECURITY;
ALTER TABLE debit_notes DISABLE ROW LEVEL SECURITY;
ALTER TABLE payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE accounts DISABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_entries DISABLE ROW LEVEL SECURITY;
ALTER TABLE bank_reconciliations DISABLE ROW LEVEL SECURITY;
ALTER TABLE restricted_drug_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE rtv_notes DISABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE refill_reminders DISABLE ROW LEVEL SECURITY;
ALTER TABLE stores DISABLE ROW LEVEL SECURITY;
ALTER TABLE store_stock_transfers DISABLE ROW LEVEL SECURITY;
ALTER TABLE stock_adjustments DISABLE ROW LEVEL SECURITY;
