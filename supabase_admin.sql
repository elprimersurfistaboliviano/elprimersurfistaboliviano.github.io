create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

alter table public.admins enable row level security;

create or replace function public.es_admin()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.admins
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.es_admin() from public;
revoke all on function public.es_admin() from anon;
grant execute on function public.es_admin() to authenticated;

drop policy if exists "ver mi admin" on public.admins;
create policy "ver mi admin"
  on public.admins for select to authenticated
  using (user_id = (select auth.uid()));

create table if not exists public.ajustes (
  clave text primary key,
  valor jsonb not null
);

create table if not exists public.videos (
  id bigint generated always as identity primary key,
  youtube_id text not null,
  titulo text not null
);

alter table public.ajustes enable row level security;
alter table public.videos enable row level security;

drop policy if exists "leer ajustes" on public.ajustes;
create policy "leer ajustes"
  on public.ajustes for select to anon, authenticated
  using (true);

drop policy if exists "leer videos" on public.videos;
create policy "leer videos"
  on public.videos for select to anon, authenticated
  using (true);

drop policy if exists "admin ajustes" on public.ajustes;
create policy "admin ajustes"
  on public.ajustes for all to authenticated
  using (public.es_admin())
  with check (public.es_admin());

drop policy if exists "admin videos" on public.videos;
create policy "admin videos"
  on public.videos for all to authenticated
  using (public.es_admin())
  with check (public.es_admin());

-- These tables must already exist in the public schema.
alter table public.eventos enable row level security;
alter table public.pedidos enable row level security;

drop policy if exists "admin eventos" on public.eventos;
create policy "admin eventos"
  on public.eventos for all to authenticated
  using (public.es_admin())
  with check (public.es_admin());

drop policy if exists "admin pedidos" on public.pedidos;
create policy "admin pedidos"
  on public.pedidos for all to authenticated
  using (public.es_admin())
  with check (public.es_admin());

insert into public.ajustes (clave, valor)
values ('colores', '{"rojo":"#c0392b","fondo":"#0a0a0a","texto":"#e8e8e8"}')
on conflict (clave) do nothing;

insert into public.admins (user_id)
select id
from auth.users
where email = 'surfistaboliv@gmail.com'
on conflict (user_id) do nothing;
