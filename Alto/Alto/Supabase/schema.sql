-- Alto Phase 1 schema
create extension if not exists "pgcrypto";

create table if not exists public.user_profiles (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz not null default now(),
    name text not null,
    gender text not null,
    age int not null check (age >= 14 and age <= 100),
    height_cm numeric not null,
    height_unit text not null,
    weight_lb int not null,
    health_conditions text[] not null default '{}',
    other_condition_text text,
    activity_preset text not null default 'Custom',
    activity_frequency_unit text,
    activity_frequency_value int,
    preferred_workouts text[] not null default '{}',
    goal_name text not null default '',
    goal_timeline_value int not null default 1,
    goal_timeline_unit text not null default 'months',
    period_days int,
    cycle_length_days int,
    last_period_date timestamptz
);

alter table public.user_profiles enable row level security;

-- Dev-only permissive policies. Tighten before production.
drop policy if exists "Anon insert user_profiles" on public.user_profiles;
create policy "Anon insert user_profiles"
on public.user_profiles
for insert
to anon, authenticated
with check (true);

drop policy if exists "Anon select user_profiles" on public.user_profiles;
create policy "Anon select user_profiles"
on public.user_profiles
for select
to anon, authenticated
using (true);
