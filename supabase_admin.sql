-- Pega esto en Supabase > SQL Editor > Run (después de supabase_setup.sql)

create table admins (user_id uuid primary key references auth.users(id) on delete cascade);
alter table admins enable row level security;
create policy "ver mi admin" on admins for select to authenticated using (user_id = auth.uid());

create function es_admin() returns boolean language sql security definer stable set search_path = public as
$$ select exists(select 1 from admins where user_id = auth.uid()) $$;

create table ajustes (clave text primary key, valor jsonb not null);
create table videos (
  id bigint generated always as identity primary key,
  youtube_id text not null,
  titulo text not null
);
alter table ajustes enable row level security;
alter table videos enable row level security;

-- La web pública puede leer colores y videos
create policy "leer ajustes" on ajustes for select using (true);
create policy "leer videos" on videos for select using (true);

-- Solo admins escriben
create policy "admin ajustes" on ajustes for all to authenticated using (es_admin()) with check (es_admin());
create policy "admin videos" on videos for all to authenticated using (es_admin()) with check (es_admin());
create policy "admin eventos" on eventos for all to authenticated using (es_admin()) with check (es_admin());
create policy "admin pedidos" on pedidos for all to authenticated using (es_admin()) with check (es_admin());

insert into ajustes values ('colores', '{"rojo":"#c0392b","fondo":"#0a0a0a","texto":"#e8e8e8"}');

-- PASO FINAL: crea tus usuarios en Authentication > Users, y luego conviértelos en admin
-- (cambia los emails por los reales):
-- insert into admins select id from auth.users where email in ('tu@email.com','otro@email.com');
