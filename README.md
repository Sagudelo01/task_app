# Senkai

App de gestión de tareas con autenticación y base de datos en la nube.

🔗 **Demo:** https://taskapp-orcin-zeta.vercel.app

## Funcionalidades

- Registro e inicio de sesión con email y contraseña
- Sesión persistente
- CRUD de tareas: crear, editar, marcar como completada y eliminar
- Filtros: Todas, Pendientes, Completadas
- Tema oscuro con Material 3

## Stack

- **Flutter** 3.x (Dart)
- **Supabase** (Auth + PostgreSQL + RLS)

## Requisitos

- Flutter SDK ^3.12.2
- Proyecto en [Supabase](https://supabase.com) con Auth por email habilitado

## Instalación

```bash
git clone <url-del-repo>
cd task_app
flutter pub get
```

## Configuración

1. Copia `.env.example` a `.env`:

```bash
cp .env.example .env
```

2. Edita `.env` con los datos de tu proyecto en Supabase:

```
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_publishable_key
```

> Las claves se empaquetan en el build. Si editas `.env`, hace un rebuild completo.

## Base de datos

Ejecuta este SQL en el SQL Editor de Supabase para crear la tabla `tasks` y las políticas RLS:

```sql
CREATE TABLE tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven sus propias tareas"
  ON tasks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Usuarios crean sus propias tareas"
  ON tasks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios editan sus propias tareas"
  ON tasks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Usuarios eliminan sus propias tareas"
  ON tasks FOR DELETE
  USING (auth.uid() = user_id);
```

## Ejecutar

```bash
# Desarrollo local
flutter run -d chrome --web-port=3000

# El puerto fijo 3000 es necesario para que coincida con el Site URL de Supabase y funcione la confirmación por email. Sin esto la confirmación no funcionará.

# Build de producción
flutter build web --dart-define=SUPABASE_URL=tu_url --dart-define=SUPABASE_ANON_KEY=tu_key
```

## Estructura del proyecto

```
lib/
├── main.dart              # entrada de la app y tema
├── config/                # configuración de Supabase
├── models/                # modelo Task
├── services/              # auth_service, task_service
├── screens/               # login, register, home
```
