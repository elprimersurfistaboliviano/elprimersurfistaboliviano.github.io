-- Pega esto en Supabase > SQL Editor > Run (después de supabase_admin.sql)

-- Carpeta pública de fotos
insert into storage.buckets (id, name, public) values ('fotos', 'fotos', true) on conflict do nothing;
create policy "fotos publicas" on storage.objects for select using (bucket_id = 'fotos');
create policy "fotos admin subir" on storage.objects for insert to authenticated with check (bucket_id = 'fotos' and public.es_admin());
create policy "fotos admin editar" on storage.objects for update to authenticated using (bucket_id = 'fotos' and public.es_admin());
create policy "fotos admin borrar" on storage.objects for delete to authenticated using (bucket_id = 'fotos' and public.es_admin());

create table integrantes (
  id bigint generated always as identity primary key,
  nombre text not null, rol text, bio text, foto_url text, orden int not null default 0
);
create table productos (
  id bigint generated always as identity primary key,
  nombre text not null, descripcion text, precio text, foto_url text,
  activo boolean not null default true, orden int not null default 0
);
alter table integrantes enable row level security;
alter table productos enable row level security;
create policy "leer integrantes" on integrantes for select using (true);
create policy "leer productos" on productos for select using (activo or public.es_admin());
create policy "admin integrantes" on integrantes for all to authenticated using (es_admin()) with check (es_admin());
create policy "admin productos" on productos for all to authenticated using (es_admin()) with check (es_admin());

-- Contenido actual de tu web, para que no se pierda al activar el panel
insert into integrantes (nombre, rol, bio, foto_url, orden) values
('Ricardo Salazar (Richi)', 'Voz / Guitarra', 'La verdad es que compongo cuando estoy triste o mientras estoy en la ducha, ahi se me ocurren la mayoría de los riffs.', 'images/image8.jpeg', 1),
('René Sánchez (Coco)', 'Bajo', 'No sabía tocar el bajo cuando me integre en la banda, ahora ya se que notas hay en el diapason 👍🏻', 'images/image9.jpg', 2),
('Mateo Aguilar', 'Guitarra', 'Guitarrista principal y creador de la mayoría de los solos de la banda, solo toco la guitarra cuando hay ensayo, no me gusta la música; también soy creador del sexo.', 'images/image10.jpg', 3),
('Diego Rojas (Dieguito)', 'Batería', 'A veces me creo Bill Bruford, me cuesta no jugar con los grooves porque si no me aburro :p', 'images/image11.jpg', 4),
('Nicolás Pérez (Ferret)', 'Teclados/Ambientes', 'Meowwwwwww', 'images/image0.jpg', 5);

insert into productos (nombre, descripcion, precio, foto_url, orden) values
('Polera Oficial', '100% algodón, serigrafiada. Logo de la banda en el frente. Tallas S – XXL.', 'Bs. ???', 'images/image2.jpg', 1),
('CD', 'Edición física del álbum. Incluye booklet con letras y fotos.', 'Bs. 100', 'images/image13.jpg', 2);

insert into ajustes (clave, valor) values ('textos', jsonb_build_object(
  'hero_eyebrow', 'Rock Indie/Alternativo · Santa Cruz, Bolivia',
  'hero_subtitulo', 'Que raro se siente, quiero saltar y salir de aquí',
  'foto_historia', 'images/image1.jpg',
  'historia', $t$Banda de Rock alternativo fundada por Ricardo Salazar y el nombre de la banda por Ignacio Guzman en 2023, poco a poco esta banda fue tomando su propio público con sus propias composiciones abriéndose un pequeño espacio en la escena musical de Santa Cruz-Bolivia

Esta banda promete un sonido inclinado al Rock Alternativo, Indie Rock, Shoegaze entre otras cosas extrañas. Estamos conformados por 5 integrantes; cada uno de nosotros formamos una parte fundamental de esta banda, lo cual le da ese brillo especial de las cosas que se hacen con cariño.

Actualmente nos rascamos las nueces$t$));
