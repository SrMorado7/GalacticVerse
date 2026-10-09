-- Galactic Champions: guardado de progreso por usuario.
-- Ejecuta este archivo UNA SOLA VEZ en Supabase > SQL Editor.
-- No modifica la tabla public.profiles existente.

create table if not exists public.game_saves (
  user_id uuid primary key references auth.users (id) on delete cascade,
  save_data jsonb not null default jsonb_build_object(
    'version', 1,
    'gold', 0,
    'level', 1,
    'unlockedAliens', jsonb_build_array(),
    'stats', jsonb_build_object()
  ),
  updated_at timestamptz not null default now(),
  constraint game_saves_data_is_object check (jsonb_typeof(save_data) = 'object')
);

alter table public.game_saves enable row level security;

drop policy if exists "Users can read their own game save" on public.game_saves;
create policy "Users can read their own game save"
  on public.game_saves for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own game save" on public.game_saves;
create policy "Users can create their own game save"
  on public.game_saves for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own game save" on public.game_saves;
create policy "Users can update their own game save"
  on public.game_saves for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on table public.game_saves from anon;
grant select, insert, update on table public.game_saves to authenticated;

-- updated_at se mantiene en el servidor para cada guardado.
create or replace function public.gc_touch_game_save_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists gc_game_saves_updated_at on public.game_saves;
create trigger gc_game_saves_updated_at
before update on public.game_saves
for each row execute function public.gc_touch_game_save_updated_at();
