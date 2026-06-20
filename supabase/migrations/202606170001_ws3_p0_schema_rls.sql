-- WS3: P0 schema + tenant RLS.
-- Scope: docs/data-schema.md ★ tables only. P1+ mode/direct/multistore tables are intentionally not created.

create or replace function public.current_tenant_id()
returns text
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'tenant_id', '')
$$;

create table if not exists public.restaurant (
  id text primary key,
  tenant_id text not null,
  name text not null,
  seats integer not null default 0,
  default_theme text,
  default_view text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.owner_account (
  id text primary key,
  tenant_id text not null,
  email text not null,
  auth_provider text not null check (auth_provider in ('apple', 'magiclink')),
  display_name text not null,
  role text not null check (role in ('owner', 'staff')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.section (
  id text primary key,
  tenant_id text not null,
  restaurant_id text not null references public.restaurant(id),
  name text not null,
  sort integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.course_template (
  id text primary key,
  tenant_id text not null,
  restaurant_id text not null references public.restaurant(id),
  name text not null,
  version integer not null default 1,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.dish (
  id text primary key,
  tenant_id text not null,
  course_template_id text not null references public.course_template(id),
  name text not null,
  sort integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.component (
  id text primary key,
  tenant_id text not null,
  dish_id text not null references public.dish(id),
  name text not null,
  sort integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.prep_task (
  id text primary key,
  tenant_id text not null,
  component_id text not null references public.component(id),
  name text not null,
  scale_mode text not null check (scale_mode in ('per_cover', 'per_portion', 'fixed_batch')),
  coeff_per_cover double precision,
  coeff_per_portion double precision,
  "yield" double precision not null default 1.0,
  round_step double precision,
  covers_per_batch integer,
  batch_size double precision,
  unit text not null,
  duration_min integer not null default 0,
  lead_min_before_open integer not null default 0,
  shelf_life_days integer,
  section_id text references public.section(id),
  default_storage_zone text,
  instruction text,
  sort integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.service_day (
  id text primary key,
  tenant_id text not null,
  restaurant_id text not null references public.restaurant(id),
  date date not null,
  service_period text not null check (service_period in ('lunch', 'dinner', 'part1', 'part2')),
  open_time text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.service_cover (
  id text primary key,
  tenant_id text not null,
  service_day_id text not null references public.service_day(id),
  course_template_id text not null references public.course_template(id),
  covers integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.task_instance (
  id text primary key,
  tenant_id text not null,
  service_day_id text not null references public.service_day(id),
  prep_task_id text not null references public.prep_task(id),
  status text not null check (status in ('not_started', 'in_progress', 'done')),
  assignee_section_id text references public.section(id),
  completed_by text,
  checked_at timestamptz,
  prep_day date not null,
  planned_qty double precision not null,
  unit text not null,
  start_at text,
  finish_at text,
  sort integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.waste_log (
  id text primary key,
  tenant_id text not null,
  service_day_id text not null references public.service_day(id),
  prep_task_id text not null references public.prep_task(id),
  covers integer not null,
  planned_qty double precision not null,
  made_qty double precision not null,
  leftover_qty double precision not null,
  waste_reason text check (waste_reason in ('overmade', 'expiry', 'quality', 'other')),
  carryover_to_next boolean not null default false,
  unit text not null,
  recorded_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.business_calendar (
  id text primary key,
  tenant_id text not null,
  restaurant_id text not null references public.restaurant(id),
  closed_dates jsonb not null default '[]'::jsonb,
  closed_weekdays jsonb not null default '[]'::jsonb,
  holidays jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.device (
  id text primary key,
  tenant_id text not null,
  name text not null,
  restaurant_id text not null references public.restaurant(id),
  default_view_override text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.settings (
  id text primary key,
  tenant_id text not null,
  restaurant_id text not null references public.restaurant(id),
  key text not null,
  value jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.entitlement (
  id text primary key,
  tenant_id text not null,
  plan text not null check (plan in ('free', 'lite', 'standard', 'pro', 'connect')),
  features jsonb not null default '{}'::jsonb,
  valid_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.event_log (
  id text primary key,
  tenant_id text not null,
  type text not null,
  payload jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null,
  actor text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.reservation (
  id text primary key,
  tenant_id text not null,
  service_day_id text not null references public.service_day(id),
  source text not null check (source in ('manual', 'csv', 'email', 'api', 'direct')),
  visit_time text not null,
  covers integer not null,
  course_template_id text references public.course_template(id),
  course_text text,
  party_name text,
  note text,
  structured boolean not null default false,
  dup_group text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.reservation add column if not exists note text;
alter table public.prep_task add column if not exists instruction text;

create index if not exists restaurant_tenant_idx on public.restaurant(tenant_id);
create index if not exists owner_account_tenant_idx on public.owner_account(tenant_id);
create index if not exists section_tenant_idx on public.section(tenant_id);
create index if not exists course_template_tenant_idx on public.course_template(tenant_id);
create index if not exists dish_tenant_idx on public.dish(tenant_id);
create index if not exists component_tenant_idx on public.component(tenant_id);
create index if not exists prep_task_tenant_idx on public.prep_task(tenant_id);
create index if not exists service_day_tenant_idx on public.service_day(tenant_id);
create index if not exists service_cover_tenant_idx on public.service_cover(tenant_id);
create index if not exists task_instance_tenant_idx on public.task_instance(tenant_id);
create index if not exists task_instance_service_status_idx on public.task_instance(service_day_id, status);
create index if not exists task_instance_prep_day_idx on public.task_instance(prep_day);
create index if not exists waste_log_tenant_idx on public.waste_log(tenant_id);
create index if not exists waste_log_task_created_idx on public.waste_log(prep_task_id, created_at);
create index if not exists business_calendar_tenant_idx on public.business_calendar(tenant_id);
create index if not exists device_tenant_idx on public.device(tenant_id);
create index if not exists settings_tenant_idx on public.settings(tenant_id);
create index if not exists entitlement_tenant_idx on public.entitlement(tenant_id);
create index if not exists event_log_tenant_idx on public.event_log(tenant_id);
create index if not exists reservation_tenant_idx on public.reservation(tenant_id);
create index if not exists reservation_service_visit_idx on public.reservation(service_day_id, visit_time);

do $$
declare
  table_name text;
  p0_tables text[] := array[
    'restaurant',
    'owner_account',
    'section',
    'course_template',
    'dish',
    'component',
    'prep_task',
    'service_day',
    'service_cover',
    'task_instance',
    'waste_log',
    'business_calendar',
    'device',
    'settings',
    'entitlement',
    'event_log',
    'reservation'
  ];
begin
  foreach table_name in array p0_tables loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format(
      'create policy %I on public.%I for select using (tenant_id = public.current_tenant_id())',
      table_name || '_tenant_select',
      table_name
    );
    execute format(
      'create policy %I on public.%I for insert with check (tenant_id = public.current_tenant_id())',
      table_name || '_tenant_insert',
      table_name
    );
    execute format(
      'create policy %I on public.%I for update using (tenant_id = public.current_tenant_id()) with check (tenant_id = public.current_tenant_id())',
      table_name || '_tenant_update',
      table_name
    );
    execute format(
      'create policy %I on public.%I for delete using (tenant_id = public.current_tenant_id())',
      table_name || '_tenant_delete',
      table_name
    );
  end loop;
end $$;
