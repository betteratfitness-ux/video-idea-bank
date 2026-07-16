-- Video Idea Bank — Supabase schema
-- Safe to run on a fresh project OR re-run on the existing one — every
-- statement is idempotent, so it will not error or touch existing rows.
-- Run in: Supabase dashboard → SQL Editor → New query → paste → Run

create table if not exists video_ideas (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title        text not null,
  notes        text default '',
  pillar       text not null check (pillar in (
                 'stop_starting_over',
                 'workout_systems',
                 'daily_stars',
                 'simple_food',
                 'tenisha_reset',
                 'busy_parent',
                 'faith_family'
               )),
  platforms    text[] not null default '{}',
  importance   int not null default 3 check (importance between 1 and 5),
  trending     boolean not null default false,
  status       text not null default 'idea' check (status in ('idea','scripted','filmed','posted')),
  posted_url   text,
  planned_date date,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- New columns — only apply if this table already existed before this update
alter table video_ideas add column if not exists posted_url text;
alter table video_ideas add column if not exists planned_date date;
alter table video_ideas add column if not exists updated_at timestamptz not null default now();

-- Row Level Security: each user can only see and change their own rows
alter table video_ideas enable row level security;

drop policy if exists "Users manage own ideas" on video_ideas;
create policy "Users manage own ideas"
  on video_ideas
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Keep updated_at current automatically on every edit
create or replace function set_video_ideas_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists video_ideas_set_updated_at on video_ideas;
create trigger video_ideas_set_updated_at
  before update on video_ideas
  for each row
  execute function set_video_ideas_updated_at();

-- Indexes
create index if not exists video_ideas_user_id_idx on video_ideas(user_id);
create index if not exists video_ideas_status_idx on video_ideas(status);
create index if not exists video_ideas_pillar_idx on video_ideas(pillar);
