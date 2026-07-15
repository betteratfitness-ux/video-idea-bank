-- Video Idea Bank — Supabase schema
-- Run this once in your Supabase project: SQL Editor → New query → paste → Run

create table if not exists video_ideas (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title       text not null,
  notes       text default '',
  pillar      text not null check (pillar in (
                'stop_starting_over',
                'workout_systems',
                'daily_stars',
                'simple_food',
                'tenisha_reset',
                'busy_parent',
                'faith_family'
              )),
  platforms   text[] not null default '{}',
  importance  int not null default 3 check (importance between 1 and 5),
  trending    boolean not null default false,
  status      text not null default 'idea' check (status in ('idea','scripted','filmed','posted')),
  created_at  timestamptz not null default now()
);

alter table video_ideas enable row level security;

create policy "Users manage own ideas"
  on video_ideas
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists video_ideas_user_id_idx on video_ideas(user_id);
