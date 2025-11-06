-- Users are anchored to Cognito sub; email is mirrored locally for queries.
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cognito_sub   TEXT UNIQUE NOT NULL,
  email         CITEXT UNIQUE NOT NULL,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  phone         TEXT,
  mfa_enabled   BOOLEAN NOT NULL DEFAULT FALSE,
  roles         TEXT[] NOT NULL DEFAULT ARRAY['BUYER'], -- BUYER, SELLER_PENDING, SELLER_VERIFIED, ADMIN
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seller profile (one per user). Store-level configuration & status.
CREATE TABLE seller_profiles (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) UNIQUE,
  store_name   TEXT,
  legal_name   TEXT,
  address_json JSONB,      -- {line1, city, state, postal, country}
  phone        TEXT,
  status       TEXT NOT NULL DEFAULT 'PENDING_PROFILE', -- PENDING_PROFILE | KYC_REQUIRED | KYC_IN_REVIEW | VERIFIED | REJECTED
  risk_tier    TEXT NOT NULL DEFAULT 'TIER0',           -- limits mgmt
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Stripe Connect + payouts linkage.
CREATE TABLE payout_accounts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES users(id) UNIQUE,
  provider         TEXT NOT NULL,                       -- 'stripe'
  account_id       TEXT NOT NULL,                       -- acct_*
  charges_enabled  BOOLEAN NOT NULL DEFAULT FALSE,
  payouts_enabled  BOOLEAN NOT NULL DEFAULT FALSE,
  requirements     JSONB,                               -- mirror Stripe requirements
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- KYC lifecycle and results (Stripe Identity or Persona).
CREATE TABLE kyc_checks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id),
  provider      TEXT NOT NULL,             -- 'stripe_identity' | 'persona'
  external_id   TEXT UNIQUE,               -- verification id
  status        TEXT NOT NULL,             -- CREATED | IN_REVIEW | VERIFIED | REJECTED
  reason        TEXT,                      -- failure reason
  payload       JSONB,                     -- redacted response
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Track the act of applying (useful for resubmits, manual review notes).
CREATE TABLE seller_applications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id),
  stage       TEXT NOT NULL, -- PROFILE_SUBMITTED | CONNECT_CREATED | KYC_STARTED | COMPLETED | REJECTED
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Minimal audit trail.
CREATE TABLE audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID,
  actor       TEXT NOT NULL,      -- 'system' | 'user:<id>' | 'admin:<id>'
  action      TEXT NOT NULL,      -- 'ROLE_CHANGED' | 'KYC_STATUS' | 'PAYOUT_CHANGED' ...
  metadata    JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
