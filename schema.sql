-- Video Idea Bank — Supabase schema
-- Safe to run on a fresh project OR re-run on the existing one — every
-- statement is idempotent, so it will not error or touch existing rows.
-- Run in: Supabase dashboard → SQL Editor → New query → paste → Run

create table if not exists video_ideas (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title        text not null,
  notes        text default '',
  -- pillar is nullable: a NULL pillar means the idea is still sitting in the
  -- Inbox, uncategorized. The CHECK still applies once a pillar is chosen —
  -- Postgres treats NULL as satisfying the check, so this needs no rewrite.
  pillar       text check (pillar in (
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
  -- Source + asset links (Phase 1) — plain URL/text fields, no file uploads yet
  source_link             text,
  script_link             text,
  canva_thumbnail_link    text,
  raw_footage_link        text,
  edited_clips_link       text,
  final_export_link       text,
  google_drive_folder_link text,
  -- Repurposing checklist (Phase 1) — flexible key/bool map, e.g.
  -- {"youtube_long":true,"short_1":false,...}. Keeping this as jsonb instead
  -- of 9 separate columns makes it painless to add more checklist items later.
  repurpose    jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Migration for tables created before this update — safe to re-run
alter table video_ideas add column if not exists posted_url text;
alter table video_ideas add column if not exists planned_date date;
alter table video_ideas add column if not exists updated_at timestamptz not null default now();
alter table video_ideas alter column pillar drop not null;
alter table video_ideas add column if not exists source_link text;
alter table video_ideas add column if not exists script_link text;
alter table video_ideas add column if not exists canva_thumbnail_link text;
alter table video_ideas add column if not exists raw_footage_link text;
alter table video_ideas add column if not exists edited_clips_link text;
alter table video_ideas add column if not exists final_export_link text;
alter table video_ideas add column if not exists google_drive_folder_link text;
alter table video_ideas add column if not exists repurpose jsonb not null default '{}'::jsonb;

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
