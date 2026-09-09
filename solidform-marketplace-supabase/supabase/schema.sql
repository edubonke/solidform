-- SolidForm contractor marketplace schema for Supabase/Postgres
-- Run in the Supabase SQL editor, then create the first admin by updating
-- public.profiles.role to 'admin' for a trusted authenticated user.

create extension if not exists pgcrypto;

create type public.user_role as enum ('customer','contractor','admin');
create type public.verification_state as enum ('not_submitted','pending','verified','rejected','expired','needs_update');
create type public.project_state as enum ('draft','open','shortlisting','awarded','in_progress','completed','cancelled');
create type public.quote_state as enum ('draft','sent','viewed','accepted','declined','expired','revised');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null default 'customer',
  full_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.contractor_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  account_type text not null check (account_type in ('individual','company')),
  legal_name text not null,
  trading_name text,
  company_registration_number text,
  representative_name text not null,
  province text not null,
  city text not null,
  years_experience integer check (years_experience between 0 and 100),
  team_size integer check (team_size between 1 and 10000),
  service_categories text[] not null default '{}',
  cidb_number text,
  cidb_grade text,
  cidb_classes text[] not null default '{}',
  nhbrc_number text,
  verification_status public.verification_state not null default 'pending',
  verification_score integer not null default 0 check (verification_score between 0 and 100),
  verified_at timestamptz,
  average_rating numeric(3,2) not null default 0,
  review_count integer not null default 0,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  category text not null,
  description text not null,
  suburb text not null,
  province text not null,
  estimated_area numeric(10,2),
  budget_min numeric(14,2),
  budget_max numeric(14,2),
  desired_start_date date,
  initial_estimate_min numeric(14,2),
  initial_estimate_max numeric(14,2),
  initial_quote_snapshot jsonb not null default '{}'::jsonb,
  required_cidb_grade text,
  requires_nhbrc boolean not null default false,
  status public.project_state not null default 'draft',
  awarded_contractor_id uuid references public.contractor_profiles(user_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.project_contacts (
  project_id uuid primary key references public.projects(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  address text,
  contact_phone text,
  access_notes text
);

create table public.project_applications (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  contractor_id uuid not null references public.contractor_profiles(user_id) on delete cascade,
  message text not null,
  proposed_start_date date,
  status text not null default 'submitted' check (status in ('submitted','shortlisted','declined','withdrawn','awarded')),
  created_at timestamptz not null default now(),
  unique(project_id, contractor_id)
);

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  contractor_id uuid not null references public.contractor_profiles(user_id) on delete cascade,
  quote_number text not null,
  subtotal numeric(14,2) not null,
  vat numeric(14,2) not null default 0,
  total numeric(14,2) not null,
  valid_until date,
  estimated_duration text,
  terms text,
  line_items jsonb not null default '[]'::jsonb,
  status public.quote_state not null default 'draft',
  sent_at timestamptz,
  viewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(contractor_id, quote_number)
);

create table public.contractor_documents (
  id uuid primary key default gen_random_uuid(),
  contractor_id uuid not null references public.contractor_profiles(user_id) on delete cascade,
  document_type text not null check (document_type in ('cipc','director_id','bank_confirmation','proof_of_address','sars_tcs','coida_logs','cidb','nhbrc','bbbee','uif','public_liability','professional_registration','trade_certificate','other')),
  storage_path text,
  file_name text,
  registration_number text,
  issuer text,
  issue_date date,
  expiry_date date,
  status public.verification_state not null default 'pending',
  is_required boolean not null default true,
  uploaded_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.document_verifications (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.contractor_documents(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id),
  decision public.verification_state not null check (decision in ('verified','rejected','needs_update','expired')),
  verification_method text not null,
  official_register_url text,
  reference_checked text,
  name_matched boolean,
  number_matched boolean,
  validity_checked boolean,
  notes text,
  checked_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  contractor_id uuid not null references public.contractor_profiles(user_id) on delete cascade,
  workmanship smallint not null check (workmanship between 1 and 5),
  communication smallint not null check (communication between 1 and 5),
  timeliness smallint not null check (timeliness between 1 and 5),
  value smallint not null check (value between 1 and 5),
  cleanliness smallint not null check (cleanliness between 1 and 5),
  overall numeric(3,2) generated always as ((workmanship + communication + timeliness + value + cleanliness)::numeric / 5) stored,
  title text not null,
  feedback text not null,
  contractor_response text,
  status text not null default 'pending' check (status in ('pending','published','flagged','removed')),
  created_at timestamptz not null default now(),
  published_at timestamptz,
  unique(project_id, customer_id, contractor_id)
);

create table public.review_reports (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references public.reviews(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open','upheld','dismissed')),
  created_at timestamptz not null default now(),
  unique(review_id, reporter_id)
);

create table public.audit_events (
  id bigint generated by default as identity primary key,
  actor_id uuid references public.profiles(id),
  entity_type text not null,
  entity_id text not null,
  action text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index projects_open_match_idx on public.projects(status, province, category);
create index quotes_project_idx on public.quotes(project_id);
create index documents_contractor_idx on public.contractor_documents(contractor_id, status);
create index reviews_contractor_idx on public.reviews(contractor_id, status);

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;
create or replace function public.is_verified_contractor() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.contractor_profiles where user_id = auth.uid() and verification_status = 'verified');
$$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, role, full_name)
  values(new.id,
    case when new.raw_user_meta_data->>'role' = 'contractor' then 'contractor'::public.user_role else 'customer'::public.user_role end,
    new.raw_user_meta_data->>'full_name');
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Marketplace users cannot self-approve or manipulate public rating totals.
create or replace function public.protect_contractor_review_fields() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() and pg_trigger_depth() = 1 then
    new.verification_status := old.verification_status;
    new.verification_score := old.verification_score;
    new.verified_at := old.verified_at;
    new.average_rating := old.average_rating;
    new.review_count := old.review_count;
  end if;
  return new;
end; $$;
create trigger protect_contractor_review_fields before update on public.contractor_profiles for each row execute procedure public.protect_contractor_review_fields();

alter table public.profiles enable row level security;
alter table public.contractor_profiles enable row level security;
alter table public.projects enable row level security;
alter table public.project_contacts enable row level security;
alter table public.project_applications enable row level security;
alter table public.quotes enable row level security;
alter table public.contractor_documents enable row level security;
alter table public.document_verifications enable row level security;
alter table public.reviews enable row level security;
alter table public.review_reports enable row level security;
alter table public.audit_events enable row level security;

create policy "profile owner or admin read" on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "profile owner update" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "verified contractor profiles public" on public.contractor_profiles for select using (verification_status = 'verified' or user_id = auth.uid() or public.is_admin());
create policy "contractor creates own profile" on public.contractor_profiles for insert to authenticated with check (user_id = auth.uid());
create policy "contractor updates own profile" on public.contractor_profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "customers manage own projects" on public.projects for all to authenticated using (customer_id = auth.uid() or public.is_admin()) with check (customer_id = auth.uid() or public.is_admin());
create policy "verified contractors see open projects" on public.projects for select to authenticated using (public.is_verified_contractor() and status in ('open','shortlisting') or awarded_contractor_id = auth.uid());
create policy "project contacts protected" on public.project_contacts for select to authenticated using (customer_id = auth.uid() or public.is_admin() or exists(select 1 from public.projects p where p.id = project_id and p.awarded_contractor_id = auth.uid()));
create policy "customers manage project contacts" on public.project_contacts for all to authenticated using (customer_id = auth.uid() or public.is_admin()) with check (customer_id = auth.uid() or public.is_admin());

create policy "applications visible to parties" on public.project_applications for select to authenticated using (contractor_id = auth.uid() or public.is_admin() or exists(select 1 from public.projects p where p.id = project_id and p.customer_id = auth.uid()));
create policy "verified contractor applies" on public.project_applications for insert to authenticated with check (contractor_id = auth.uid() and public.is_verified_contractor());
create policy "applicant updates own application" on public.project_applications for update to authenticated using (contractor_id = auth.uid()) with check (contractor_id = auth.uid());

create policy "quotes visible to parties" on public.quotes for select to authenticated using (contractor_id = auth.uid() or public.is_admin() or exists(select 1 from public.projects p where p.id = project_id and p.customer_id = auth.uid()));
create policy "contractor manages own quotes" on public.quotes for all to authenticated using (contractor_id = auth.uid() or public.is_admin()) with check (contractor_id = auth.uid() or public.is_admin());

create policy "document owner and admin read" on public.contractor_documents for select to authenticated using (contractor_id = auth.uid() or public.is_admin());
create policy "contractor uploads own metadata" on public.contractor_documents for insert to authenticated with check (contractor_id = auth.uid());
create policy "contractor updates own unverified document" on public.contractor_documents for update to authenticated
using (contractor_id = auth.uid() and status <> 'verified')
with check (contractor_id = auth.uid() and status in ('not_submitted','pending','needs_update'));
create policy "admin updates documents" on public.contractor_documents for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "verifications admin only" on public.document_verifications for all to authenticated using (public.is_admin()) with check (public.is_admin() and reviewer_id = auth.uid());

create policy "published reviews public" on public.reviews for select using (status = 'published' or customer_id = auth.uid() or contractor_id = auth.uid() or public.is_admin());
create policy "completed customer reviews" on public.reviews for insert to authenticated with check (status = 'pending' and customer_id = auth.uid() and exists(select 1 from public.projects p where p.id = project_id and p.customer_id = auth.uid() and p.status = 'completed' and p.awarded_contractor_id = contractor_id));
create policy "review reports visible to reporter admin" on public.review_reports for select to authenticated using (reporter_id = auth.uid() or public.is_admin());
create policy "users report reviews" on public.review_reports for insert to authenticated with check (reporter_id = auth.uid());
create policy "audit admin read" on public.audit_events for select to authenticated using (public.is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('contractor-documents','contractor-documents',false,10485760,array['application/pdf','image/jpeg','image/png'])
on conflict (id) do nothing;

create policy "contractor uploads to own folder" on storage.objects for insert to authenticated
with check (bucket_id = 'contractor-documents' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "contractor reads own documents" on storage.objects for select to authenticated
using (bucket_id = 'contractor-documents' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
create policy "contractor replaces own documents" on storage.objects for update to authenticated
using (bucket_id = 'contractor-documents' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'contractor-documents' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "contractor deletes own documents" on storage.objects for delete to authenticated
using (bucket_id = 'contractor-documents' and (storage.foldername(name))[1] = auth.uid()::text);

-- Recalculate public contractor rating when a published review changes.
create or replace function public.refresh_contractor_rating() returns trigger language plpgsql security definer set search_path = '' as $$
declare target_contractor uuid;
begin
  target_contractor := case when tg_op = 'DELETE' then old.contractor_id else new.contractor_id end;
  update public.contractor_profiles c set
    average_rating = coalesce((select round(avg(r.overall),2) from public.reviews r where r.contractor_id = target_contractor and r.status = 'published'),0),
    review_count = (select count(*) from public.reviews r where r.contractor_id = target_contractor and r.status = 'published')
  where c.user_id = target_contractor;
  return coalesce(new,old);
end; $$;
create trigger review_rating_refresh after insert or update or delete on public.reviews for each row execute procedure public.refresh_contractor_rating();
