-- Onboarding profile v2 migration
-- Aligns user_profiles with finalized onboarding fields:
-- name, gender, age, height(inches), weight(lb), health conditions,
-- activity profile (custom/week/month/not active), and female cycle fields.

begin;

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

-- If an older schema exists with weight_kg, migrate values and rename.
do $$
begin
    if exists (
        select 1 from information_schema.columns
        where table_schema = 'public'
          and table_name = 'user_profiles'
          and column_name = 'weight_kg'
    ) and not exists (
        select 1 from information_schema.columns
        where table_schema = 'public'
          and table_name = 'user_profiles'
          and column_name = 'weight_lb'
    ) then
        alter table public.user_profiles add column weight_lb int;
        update public.user_profiles
        set weight_lb = round(weight_kg * 2.20462)::int
        where weight_lb is null;
        alter table public.user_profiles drop column weight_kg;
    end if;
end $$;

alter table public.user_profiles add column if not exists created_at timestamptz not null default now();
alter table public.user_profiles add column if not exists name text;
alter table public.user_profiles add column if not exists gender text;
alter table public.user_profiles add column if not exists age int;
alter table public.user_profiles add column if not exists height_cm numeric;
alter table public.user_profiles add column if not exists height_unit text;
alter table public.user_profiles add column if not exists weight_lb int;
alter table public.user_profiles add column if not exists health_conditions text[] not null default '{}';
alter table public.user_profiles add column if not exists other_condition_text text;
alter table public.user_profiles add column if not exists activity_preset text not null default 'Custom';
alter table public.user_profiles add column if not exists activity_frequency_unit text;
alter table public.user_profiles add column if not exists activity_frequency_value int;
alter table public.user_profiles add column if not exists preferred_workouts text[] not null default '{}';
alter table public.user_profiles add column if not exists goal_name text not null default '';
alter table public.user_profiles add column if not exists goal_timeline_value int not null default 1;
alter table public.user_profiles add column if not exists goal_timeline_unit text not null default 'months';
alter table public.user_profiles add column if not exists period_days int;
alter table public.user_profiles add column if not exists cycle_length_days int;
alter table public.user_profiles add column if not exists last_period_date timestamptz;

-- Migrate old activity_sessions_per_week if present.
do $$
begin
    if exists (
        select 1 from information_schema.columns
        where table_schema = 'public'
          and table_name = 'user_profiles'
          and column_name = 'activity_sessions_per_week'
    ) then
        update public.user_profiles
        set activity_preset = coalesce(activity_preset, 'Custom'),
            activity_frequency_unit = coalesce(activity_frequency_unit, 'week'),
            activity_frequency_value = coalesce(activity_frequency_value, activity_sessions_per_week)
        where activity_frequency_value is null;

        alter table public.user_profiles drop column activity_sessions_per_week;
    end if;
end $$;

-- Remove old goal fields if they exist from prior PRD versions.
alter table public.user_profiles drop column if exists goal_type;
alter table public.user_profiles drop column if exists goal_target_date;
alter table public.user_profiles drop column if exists goal_target_value;

-- Data cleanup defaults for required fields where legacy rows may be null.
update public.user_profiles set height_unit = 'inches' where height_unit is null;
update public.user_profiles set activity_preset = 'Custom' where activity_preset is null;
update public.user_profiles set activity_frequency_unit = 'week'
where activity_preset = 'Custom' and activity_frequency_unit is null;
update public.user_profiles set activity_frequency_value = 0
where activity_preset = 'Custom' and activity_frequency_value is null;

-- Constraints for onboarding validation expectations.
do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'user_profiles_age_check'
    ) then
        alter table public.user_profiles
        add constraint user_profiles_age_check check (age >= 14 and age <= 100);
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'user_profiles_activity_frequency_non_negative'
    ) then
        alter table public.user_profiles
        add constraint user_profiles_activity_frequency_non_negative
        check (activity_frequency_value is null or activity_frequency_value >= 0);
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'user_profiles_cycle_length_range'
    ) then
        alter table public.user_profiles
        add constraint user_profiles_cycle_length_range
        check (cycle_length_days is null or (cycle_length_days >= 20 and cycle_length_days <= 40));
    end if;
end $$;

alter table public.user_profiles enable row level security;

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

commit;
