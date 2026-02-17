-- ============================================================
-- CV-SCANNER - Supabase Schema
-- Ejecutar en SQL Editor de tu nuevo proyecto Supabase
-- ============================================================

-- 1. TABLA: usuarios (sincronizada con auth.users)
-- El trigger crea un registro aquí cuando un usuario se registra
CREATE TABLE IF NOT EXISTS public.usuarios (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  correo TEXT NOT NULL UNIQUE,
  nombre_usuario TEXT,
  apellido_usuario TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger: crear usuario en tabla usuarios al registrarse en Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.usuarios (id, correo, nombre_usuario, apellido_usuario)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nombre', ''),
    COALESCE(NEW.raw_user_meta_data->>'apellido', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. TABLA: perfil_information (datos del CV del usuario)
CREATE TABLE IF NOT EXISTS public.perfil_information (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombres TEXT,
  apellidos TEXT,
  direccion TEXT,
  telefono TEXT,
  correo TEXT,
  nacionalidad TEXT,
  fecha_nacimiento TEXT,
  estado_civil TEXT,
  linkedin TEXT,
  github TEXT,
  portafolio TEXT,
  perfil_profesional TEXT,
  objetivos_profesionales TEXT,
  experiencia_laboral TEXT,
  educacion TEXT,
  habilidades TEXT,
  idiomas TEXT,
  certificaciones TEXT,
  proyectos TEXT,
  publicaciones TEXT,
  premios TEXT,
  voluntariados TEXT,
  referencias TEXT,
  expectativas_laborales TEXT,
  experiencia_internacional TEXT,
  permisos_documentacion TEXT,
  vehiculo_licencias TEXT,
  contacto_emergencia TEXT,
  disponibilidad_entrevistas TEXT,
  fotografia TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. TABLA: audio_transcrito (transcripciones de audio del CV)
CREATE TABLE IF NOT EXISTS public.audio_transcrito (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transcripcion TEXT,
  enlace_audio TEXT,
  transcripcion_organizada_json JSONB,
  informacion_audios TEXT,
  informacion_organizada_usuario JSONB,
  esquema_json JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. TABLA: cv_analizados (CVs analizados desde formulario)
CREATE TABLE IF NOT EXISTS public.cv_analizados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT,
  apellido TEXT,
  telefono TEXT,
  email TEXT,
  experiencia TEXT,
  educacion TEXT,
  habilidades TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfil_information ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audio_transcrito ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cv_analizados ENABLE ROW LEVEL SECURITY;

-- usuarios: cada usuario solo ve/edita su propio registro
CREATE POLICY "usuarios_select_own" ON public.usuarios
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "usuarios_update_own" ON public.usuarios
  FOR UPDATE USING (auth.uid() = id);

-- perfil_information: cada usuario solo accede a su perfil
CREATE POLICY "perfil_select_own" ON public.perfil_information
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "perfil_insert_own" ON public.perfil_information
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "perfil_update_own" ON public.perfil_information
  FOR UPDATE USING (auth.uid() = id);

-- audio_transcrito: permitir acceso autenticado (ajustar según necesidad)
CREATE POLICY "audio_select_authenticated" ON public.audio_transcrito
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "audio_insert_authenticated" ON public.audio_transcrito
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "audio_update_authenticated" ON public.audio_transcrito
  FOR UPDATE TO authenticated USING (true);

-- cv_analizados: permitir acceso autenticado
CREATE POLICY "cv_select_authenticated" ON public.cv_analizados
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "cv_insert_authenticated" ON public.cv_analizados
  FOR INSERT TO authenticated WITH CHECK (true);

-- ============================================================
-- STORAGE BUCKETS (crear desde Dashboard o con SQL)
-- ============================================================
-- Nota: Los buckets se crean desde Supabase Dashboard > Storage
-- Buckets necesarios:
--   1. "audios" - público, para archivos de audio (.webm)
--   2. "cv" - para archivos PDF/CVs subidos
