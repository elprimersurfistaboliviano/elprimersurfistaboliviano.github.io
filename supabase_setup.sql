-- Pega esto en Supabase > SQL Editor > Run

create table eventos (
  id bigint generated always as identity primary key,
  nombre text not null,
  fecha timestamptz not null,
  lugar text,
  precio numeric not null default 0,
  capacidad int not null,
  activo boolean not null default true
);

create table pedidos (
  id bigint generated always as identity primary key,
  codigo text unique not null,
  evento_id bigint not null references eventos(id),
  nombre text not null,
  email text not null,
  telefono text not null,
  cantidad int not null check (cantidad between 1 and 10),
  total numeric not null,
  estado text not null default 'pendiente' check (estado in ('pendiente','pagado','cancelado')),
  creado timestamptz not null default now()
);

-- Nadie desde la web puede leer/escribir las tablas directamente
alter table eventos enable row level security;
alter table pedidos enable row level security;

-- La web solo ve eventos activos con entradas disponibles (sin datos de compradores)
create view eventos_publicos as
select e.id, e.nombre, e.fecha, e.lugar, e.precio,
       e.capacidad - coalesce((select sum(p.cantidad) from pedidos p
         where p.evento_id = e.id and p.estado <> 'cancelado'), 0)::int as disponibles
from eventos e where e.activo;
grant select on eventos_publicos to anon;

-- Reserva atómica: evita vender más entradas que la capacidad
create function reservar_entradas(p_evento bigint, p_nombre text, p_email text, p_telefono text, p_cantidad int)
returns json language plpgsql security definer set search_path = public as $$
declare ev eventos; vendidas int; cod text; tot numeric;
begin
  select * into ev from eventos where id = p_evento and activo for update;
  if not found then raise exception 'Evento no disponible'; end if;
  select coalesce(sum(cantidad),0) into vendidas from pedidos where evento_id = p_evento and estado <> 'cancelado';
  if vendidas + p_cantidad > ev.capacidad then raise exception 'No quedan suficientes entradas'; end if;
  cod := 'EPSB-' || upper(substr(md5(random()::text), 1, 6));
  tot := ev.precio * p_cantidad;
  insert into pedidos(codigo, evento_id, nombre, email, telefono, cantidad, total)
    values (cod, p_evento, left(p_nombre,80), left(p_email,120), left(p_telefono,20), p_cantidad, tot);
  return json_build_object('codigo', cod, 'total', tot);
end $$;
grant execute on function reservar_entradas to anon;

-- Evento de prueba (bórralo luego)
insert into eventos(nombre, fecha, lugar, precio, capacidad)
values ('Show de prueba', '2026-12-20 20:00-04', 'Santa Cruz', 30, 100);
