-- Add presence columns to users table
alter table public.users
  add column if not exists is_online boolean not null default false,
  add column if not exists last_seen text;

-- Update RLS: existing policies already allow anon + authenticated all access,
-- so no new policies needed. Just update schema.
