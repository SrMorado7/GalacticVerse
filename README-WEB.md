# Ejecutar Galactic Champions en GitHub Pages

Esta versión añade una página web (`index.html`) que carga el archivo original `game.swf` mediante [Ruffle](https://ruffle.rs/), un emulador de Flash que funciona en navegadores modernos.

**Importante:** esto no convierte el juego a JavaScript/HTML nativo. Es el primer paso para publicarlo y jugarlo desde una página web conservando los archivos originales. La compatibilidad depende de Ruffle; algunas funciones de Flash pueden requerir ajustes.

## Publicar en GitHub Pages

1. Crea un repositorio en GitHub.
2. Sube el contenido de esta carpeta (no solamente el ZIP) a la raíz del repositorio. `index.html` y `game.swf` deben quedar en la raíz, y también deben conservarse las carpetas `config/`, `texts/` y todos los demás archivos originales.
3. En GitHub abre **Settings → Pages**.
4. En **Build and deployment**, selecciona **Deploy from a branch**.
5. Selecciona la rama principal (`main`) y la carpeta `/(root)`, y guarda.
6. Abre la URL que GitHub Pages indique cuando termine el despliegue.

## Probar localmente

No abras `index.html` directamente con `file://`, porque los navegadores pueden bloquear la carga de recursos locales. Sirve la carpeta mediante un servidor HTTP local, por ejemplo:

```bash
python -m http.server 8000
```

Luego abre `http://localhost:8000` desde esa carpeta.

## Si no carga

- Confirma que `game.swf` y `index.html` estén en la raíz publicada.
- Abre las herramientas de desarrollador del navegador y revisa **Console** y **Network**.
- Ruffle se carga desde un CDN, así que la primera página necesita conexión a Internet.
- El juego carga configuración, textos y recursos externos; no cambies la estructura de carpetas sin comprobar las rutas.
- El proyecto original recomienda abrir `game.swf` con Ruffle. Si hay diferencias de compatibilidad, compara el comportamiento con la versión de escritorio de Ruffle.

## Próxima etapa de desarrollo

Para modear la lógica con mayor control, el siguiente trabajo es analizar los SWF y determinar qué sistemas se pueden portar a JavaScript/HTML Canvas, manteniendo `config/config.json` como fuente de datos cuando sea viable. Conviene hacerlo por sistemas (combate, selección de equipo, mapa, tienda y torneos), con pruebas de regresión.

## Sistema de cuentas (etapa inicial)

Se añadió `account.html` para el registro e inicio de sesión con Supabase, junto con `supabase-config.js` y `supabase/schema.sql`. Consulta [`README-SUPABASE.md`](README-SUPABASE.md) para configurar el proyecto y las URL permitidas. No se requiere ni debe usarse una clave secreta en el cliente. Esta etapa no modifica el SWF ni sincroniza todavía las partidas.
