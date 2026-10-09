# Sistema de cuentas — Galactic Champions

Esta etapa añade una página independiente `account.html` para registrar cuentas por correo/contraseña, iniciar/cerrar sesión, consultar el nombre de usuario y solicitar un enlace para restablecer la contraseña. El juego original (`game.swf`) y su lanzador Ruffle se mantienen intactos, salvo un enlace a la página de cuentas en `index.html`.

**Importante:** la interfaz no se conectará hasta crear/configurar un proyecto Supabase. No se incluyen credenciales reales en este repositorio.

## Paso 1 — Crear el proyecto

1. Crea un proyecto en [Supabase](https://supabase.com/dashboard).
2. En el panel del proyecto, copia la **Project URL** y la **publishable key** (`sb_publishable_...`). La clave `anon` antigua también es pública y compatible, si tu proyecto aún la utiliza.
3. Abre `supabase-config.js` y reemplaza los valores de ejemplo:

   ```js
   window.GC_SUPABASE_CONFIG = {
     url: 'https://TU-REF.supabase.co',
     publishableKey: 'sb_publishable_TU_CLAVE'
   };
   ```

   Nunca uses una `secret key` (`sb_secret_...`) ni una `service_role` key en el navegador, HTML, JavaScript público o GitHub.

## Paso 2 — Crear la tabla y las reglas de seguridad

1. En Supabase, abre **SQL Editor → New query**.
2. Copia el contenido completo de `supabase/schema.sql` y ejecútalo una sola vez.
3. El script crea `public.profiles`, habilita Row Level Security (RLS), permite que cada persona lea/actualice únicamente su propia fila y crea el perfil automáticamente al registrar una cuenta.
4. Un índice único sobre `lower(username)` impide que existan nombres duplicados incluso si cambian las mayúsculas (`Ben10` y `ben10` cuentan como el mismo nombre).

Si la consulta devuelve un error, no publiques todavía el sistema; resuelve el error en SQL Editor antes de continuar.

## Paso 3 — Configurar autenticación y enlaces

En Supabase, abre **Authentication → URL Configuration**:

- **Site URL:** coloca la URL base de tu web publicada en GitHub Pages.
- **Redirect URLs:** añade la URL exacta de `account.html`, por ejemplo `https://TU-USUARIO.github.io/TU-REPOSITORIO/account.html`. Sustituye usuario y repositorio por los reales.
- Para pruebas locales, añade `http://localhost:8000/account.html`.
- En **Authentication → Sign In / Providers → Email**, habilita el proveedor de correo. Recomendamos mantener la confirmación por correo activada.

Las URL de redirección deben coincidir con las URL permitidas en el panel de Supabase.

## Paso 4 — Publicar sin sustituir el juego

1. Conserva todos los archivos actuales del repositorio.
2. Añade `account.html`, `supabase-config.js`, `supabase/schema.sql` y este README.
3. Actualiza `index.html` con el enlace **Cuenta de jugador** (ya está hecho en esta versión).
4. Haz commit y push a la misma rama que publica GitHub Pages.
5. Abre `account.html` en el sitio publicado, registra una cuenta de prueba y confirma el correo si se solicita.

## Paso 5 — Probar

- Un nombre con 3–20 caracteres: letras ASCII, números o guion bajo.
- Registrar dos cuentas con el mismo nombre, variando mayúsculas: la segunda debe rechazarse.
- Confirmar el correo e iniciar sesión.
- Cerrar sesión y volver a iniciar sesión.
- Verificar que el perfil muestra el nombre correcto.
- Probar el flujo de restablecimiento de contraseña y confirmar que llega el correo.

## Alcance actual y siguiente etapa

Esta primera entrega proporciona autenticación y perfil básico. **Todavía no guarda la partida, el oro, los alienígenas ni los torneos en la nube**, y no altera el almacenamiento interno del SWF. La siguiente etapa será diseñar un formato de guardado separado, definir reglas RLS para ese guardado y probar la sincronización sin modificar el juego original.

Si una persona confirma su correo y el alta falla por nombre duplicado, debe intentar con otro nombre. El índice único de PostgreSQL es la protección definitiva contra duplicados simultáneos; la validación de JavaScript es solo una ayuda de interfaz.
