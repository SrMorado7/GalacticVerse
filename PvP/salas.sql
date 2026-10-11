-- Galactic Champions PvP - Prueba 1: salas privadas, SIN combate.
-- Ejecutar una sola vez en Supabase SQL Editor.
-- No cambia game_saves, perfiles ni el sistema de cuentas.

create table if not exists public.pvp_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-F0-9]{8}$'),
  host_id uuid not null references auth.users(id) on delete cascade,
  guest_id uuid references auth.users(id) on delete set null,
  host_name text not null,
  guest_name text,
  created_at timestamptz not null default now(),
  constraint different_pvp_players check (guest_id is null or guest_id <> host_id)
);

alter table public.pvp_rooms enable row level security;
revoke all on public.pvp_rooms from anon, authenticated;
grant select on public.pvp_rooms to authenticated;
drop policy if exists "pvp participants see their own room" on public.pvp_rooms;
create policy "pvp participants see their own room"
on public.pvp_rooms for select to authenticated
using (auth.uid() = host_id or auth.uid() = guest_id);

-- Los jugadores no pueden escribir la tabla directamente: solo mediante RPC validadas.
create or replace function public.pvp_create_room()
returns jsonb language plpgsql security definer
set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_code text;
  v_room_id uuid;
  v_name text;
  v_attempt int;
begin
  if v_uid is null then raise exception 'Debes iniciar sesión'; end if;
  select left(coalesce(nullif(btrim(raw_user_meta_data->>'username'), ''),
                       nullif(btrim(raw_user_meta_data->>'display_name'), ''),
                       'Jugador-' || left(v_uid::text,8)), 32)
  into v_name from auth.users where id = v_uid;
  for v_attempt in 1..8 loop
    v_code := upper(encode(gen_random_bytes(4), 'hex'));
    begin
      insert into public.pvp_rooms(code, host_id, host_name)
      values (v_code, v_uid, v_name) returning id into v_room_id;
      return jsonb_build_object('id',v_room_id,'code',v_code);
    exception when unique_violation then
      -- Si hay colisión de código, volver a generar.
    end;
  end loop;
  raise exception 'No se pudo generar un código único';
end;
$$;

create or replace function public.pvp_join_room(p_code text)
returns jsonb language plpgsql security definer
set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_name text;
  v_room public.pvp_rooms%rowtype;
begin
  if v_uid is null then raise exception 'Debes iniciar sesión'; end if;
  if p_code is null or upper(btrim(p_code)) !~ '^[A-F0-9]{8}$' then
    raise exception 'El código debe tener 8 caracteres hexadecimales';
  end if;
  select left(coalesce(nullif(btrim(raw_user_meta_data->>'username'), ''),
                       nullif(btrim(raw_user_meta_data->>'display_name'), ''),
                       'Jugador-' || left(v_uid::text,8)), 32)
  into v_name from auth.users where id = v_uid;
  update public.pvp_rooms
     set guest_id=v_uid, guest_name=v_name
   where code=upper(btrim(p_code))
     and host_id<>v_uid
     and (guest_id is null or guest_id=v_uid)
  returning * into v_room;
  if not found then
    raise exception 'Sala inexistente, completa o creada por tu propia cuenta';
  end if;
  return jsonb_build_object('id',v_room.id,'code',v_room.code);
end;
$$;

create or replace function public.pvp_leave_room(p_room_id uuid)
returns void language plpgsql security definer
set search_path = '' as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'Debes iniciar sesión'; end if;
  -- Salir como anfitrión cierra la sala; como invitado libera su lugar.
  delete from public.pvp_rooms where id=p_room_id and host_id=v_uid;
  if not found then
    update public.pvp_rooms set guest_id=null, guest_name=null
      where id=p_room_id and guest_id=v_uid;
  end if;
end;
$$;

revoke all on function public.pvp_create_room() from public, anon;
revoke all on function public.pvp_join_room(text) from public, anon;
revoke all on function public.pvp_leave_room(uuid) from public, anon;
grant execute on function public.pvp_create_room() to authenticated;
grant execute on function public.pvp_join_room(text) to authenticated;
grant execute on function public.pvp_leave_room(uuid) to authenticated;
