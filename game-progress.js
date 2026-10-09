/*
 * Galactic Champions — API de guardado en Supabase.
 *
 * Requiere:
 *   1) ./supabase-config.js con GC_SUPABASE_CONFIG.url y .publishableKey
 *   2) ejecutar supabase/progress-schema.sql en Supabase SQL Editor
 *
 * Este archivo prepara la capa de guardado; no puede leer por sí solo las
 * variables internas del juego Flash/SWF. El juego debe llamar a saveProgress()
 * y loadProgress() cuando se integre con el motor de juego.
 */
import { createClient } from
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const config = window.GC_SUPABASE_CONFIG;
if (!config?.url || !config?.publishableKey) {
  throw new Error('Falta configurar Supabase en supabase-config.js.');
}

const supabase = createClient(config.url, config.publishableKey);

function normalizeProgress(progress = {}) {
  if (!progress || typeof progress !== 'object' || Array.isArray(progress)) {
    throw new TypeError('El progreso debe ser un objeto.');
  }

  const normalized = {
    version: 1,
    gold: Number.isFinite(Number(progress.gold)) ? Math.max(0, Math.floor(Number(progress.gold))) : 0,
    level: Number.isFinite(Number(progress.level)) ? Math.max(1, Math.floor(Number(progress.level))) : 1,
    unlockedAliens: Array.isArray(progress.unlockedAliens)
      ? [...new Set(progress.unlockedAliens.filter(x => typeof x === 'string').slice(0, 500))]
      : [],
    stats: progress.stats && typeof progress.stats === 'object' && !Array.isArray(progress.stats)
      ? progress.stats
      : {},
    // Campo libre para datos adicionales que el juego pueda necesitar.
    extra: progress.extra && typeof progress.extra === 'object' && !Array.isArray(progress.extra)
      ? progress.extra
      : {}
  };

  // Evita enviar accidentalmente un guardado enorme desde el navegador.
  const bytes = new TextEncoder().encode(JSON.stringify(normalized)).length;
  if (bytes > 100_000) {
    throw new Error('El guardado supera el límite de 100 KB.');
  }
  return normalized;
}

async function requireUser() {
  const { data, error } = await supabase.auth.getUser();
  if (error) throw error;
  if (!data.user) throw new Error('Debes iniciar sesión antes de guardar el progreso.');
  return data.user;
}

/** Devuelve el progreso guardado, o null si aún no existe un guardado. */
export async function loadProgress() {
  const user = await requireUser();
  const { data, error } = await supabase
    .from('game_saves')
    .select('save_data, updated_at')
    .eq('user_id', user.id)
    .maybeSingle();

  if (error) throw error;
  if (!data) return null;
  return { ...data.save_data, _savedAt: data.updated_at };
}

/** Guarda el progreso para el usuario autenticado; nunca acepta un user_id del cliente. */
export async function saveProgress(progress) {
  const user = await requireUser();
  const saveData = normalizeProgress(progress);

  const { data, error } = await supabase
    .from('game_saves')
    .upsert(
      { user_id: user.id, save_data: saveData },
      { onConflict: 'user_id' }
    )
    .select('updated_at')
    .single();

  if (error) throw error;
  return { ok: true, savedAt: data.updated_at };
}

/** Devuelve el cliente si se necesita consultar sesión o cerrar sesión desde la web. */
export function getProgressSupabaseClient() {
  return supabase;
}
