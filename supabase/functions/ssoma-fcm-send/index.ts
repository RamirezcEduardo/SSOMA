// Envía notificaciones push (Firebase Cloud Messaging, API HTTP v1) a los
// usuarios indicados, buscando sus tokens de dispositivo en ssoma_push_tokens.
//
// verify_jwt=false a propósito: esta app no usa Supabase Auth (sesión propia
// via b2c_sessions) y el resto del backend (ssoma_tareas, etc.) ya es de acceso
// permisivo por diseño, así que se mantiene el mismo modelo de confianza.
//
// La cuenta de servicio de Firebase (JSON de "Generar nueva clave privada") se
// guarda cifrada en Supabase Vault (secreto 'fcm_service_account_json'), no
// como variable de entorno — así queda protegida sin depender de que alguien
// la configure a mano con `supabase secrets set`. Se lee vía la función
// public.ssoma_get_fcm_service_account(), restringida a service_role
// (ver supabase/migrations/0016_ssoma_fcm_service_account_accessor.sql).
//
// Body esperado: { usuario_ids: number[], titulo: string, cuerpo: string, datos?: object, color?: "#RRGGBB" }
// El canal "ssoma_tareas" ("SSOMA · Tareas") lo crea la app en el dispositivo
// (ver ssomaInicializarPush en index.html); si no existe todavía, Android usa
// el canal por defecto en su lugar.

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// La app la llama desde supabase-js (fetch en el WebView de Capacitor), que
// primero manda un preflight OPTIONS. Sin estos headers el navegador bloquea
// la llamada real antes de que llegue acá (por eso no se veían errores del
// lado de la app: el POST nunca salía).
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } });
}

function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : new Uint8Array(input);
  let str = "";
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const clean = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function getFcmAccessToken(serviceAccount: { client_email: string; private_key: string }): Promise<string> {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 30_000) {
    return cachedAccessToken.token;
  }
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claimSet))}`;
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, new TextEncoder().encode(unsigned));
  const jwt = `${unsigned}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`No se pudo obtener el access token de FCM: ${JSON.stringify(json)}`);
  cachedAccessToken = { token: json.access_token, expiresAt: Date.now() + json.expires_in * 1000 };
  return json.access_token;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Método no permitido" }, 405);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { data: fcmServiceAccountJson, error: secretError } = await supabase.rpc("ssoma_get_fcm_service_account");
  if (secretError) {
    return jsonResponse({ error: `No se pudo leer la credencial de Firebase: ${secretError.message}` }, 500);
  }
  if (!fcmServiceAccountJson) {
    return jsonResponse({ error: "Firebase no está configurado todavía (falta el secreto fcm_service_account_json en Vault)." });
  }

  let payload: { usuario_ids?: number[]; titulo?: string; cuerpo?: string; datos?: Record<string, unknown>; color?: string };
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Body inválido" }, 400);
  }
  const usuarioIds = Array.isArray(payload.usuario_ids) ? payload.usuario_ids : [];
  const titulo = (payload.titulo || "").toString().slice(0, 200);
  const cuerpo = (payload.cuerpo || "").toString().slice(0, 500);
  // Rojo por defecto (Adecco) si el llamador no manda un color específico por tipo de aviso.
  const color = /^#[0-9A-Fa-f]{6}$/.test(payload.color || "") ? payload.color! : "#E31E24";
  if (!usuarioIds.length || !titulo) {
    return jsonResponse({ error: "usuario_ids y titulo son obligatorios" }, 400);
  }

  const serviceAccount = JSON.parse(fcmServiceAccountJson);
  const projectId = serviceAccount.project_id;

  const { data: tokens, error } = await supabase
    .from("ssoma_push_tokens")
    .select("token")
    .in("usuario_id", usuarioIds);
  if (error) {
    return jsonResponse({ error: error.message }, 500);
  }
  if (!tokens || !tokens.length) {
    return jsonResponse({ enviados: 0, motivo: "Ningún destinatario tiene la app instalada con notificaciones activas." });
  }

  const accessToken = await getFcmAccessToken(serviceAccount);
  const datos = payload.datos && typeof payload.datos === "object" ? payload.datos : {};
  const datosString: Record<string, string> = {};
  for (const [k, v] of Object.entries(datos)) datosString[k] = String(v);

  const resultados = await Promise.all(
    tokens.map(async (row) => {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: "POST",
        headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token: row.token,
            notification: { title: titulo, body: cuerpo },
            data: datosString,
            android: { priority: "high", notification: { channel_id: "ssoma_tareas", color } },
          },
        }),
      });
      if (res.ok) return { ok: true };
      const body = await res.text();
      // Token inválido o app desinstalada: se limpia para no seguir intentando.
      if (res.status === 404 || res.status === 400) {
        await supabase.from("ssoma_push_tokens").delete().eq("token", row.token);
      }
      return { ok: false, status: res.status, body };
    }),
  );

  const enviados = resultados.filter((r) => r.ok).length;
  return jsonResponse({ enviados, total: tokens.length, resultados });
});
