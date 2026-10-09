-- Galactic Champions: perfiles con nombres de usuario únicos.
-- Ejecutar UNA VEZ en Supabase Dashboard > SQL Editor.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null,
  created_at timestamptz not null default now(),
  constraint profiles_username_format check (username ~ '^[A-Za-z0-9_]{3,20}$')
);

-- Evita duplicados incluso si cambia el uso de mayúsculas/minúsculas.
create unique index if not exists profiles_username_lower_unique
  on public.profiles (lower(username));

alter table public.profiles enable row level security;

-- Cada usuario puede consultar solamente su propio perfil.
drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

-- Permite que el usuario actualice únicamente su propia fila.
drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Crear el perfil automáticamente al registrar una cuenta.
create or replace function public.handle_new_gc_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chosen_username text;
begin
  chosen_username := btrim(coalesce(new.raw_user_meta_data ->> 'username', ''));

  if chosen_username !~ '^[A-Za-z0-9_]{3,20}$' then
    raise exception 'El nombre de usuario debe tener entre 3 y 20 caracteres: letras, números o guion bajo.';
  end if;

  insert into public.profiles (id, username)
  values (new.id, chosen_username);

  return new;
end;
$$;

drop trigger if exists on_gc_auth_user_created on auth.users;
create trigger on_gc_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_gc_user();

-- No se concede acceso anónimo a perfiles ni se expone información de correo.
revoke all on table public.profiles from anon;
grant select, update on table public.profiles to authenticated;
