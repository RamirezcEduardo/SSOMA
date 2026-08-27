// Envía notificaciones push (Firebase Cloud Messaging, API HTTP v1) a los
// usuarios indicados, buscando sus tokens de dispositivo en ssoma_push_tokens.
//
// verify_jwt=false a propósito: esta app no usa Supabase Auth (sesión propia
// via b2c_sessions) y el resto del backend (ssoma_tareas, etc.) ya es de acceso
// permisivo por diseño, así que se mantiene el mismo modelo de confianza.
//
// Requiere el secreto FCM_SERVICE_ACCOUNT_JSON: el contenido completo del JSON
// de la cuenta de servicio de Firebase (Project Settings → Cuentas de servicio
// → Generar nueva clave privada). Configúralo con:
//   supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat service-account.json)"
//
// Body esperado: { usuario_ids: number[], titulo: string, cuerpo: string, datos?: object }

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");

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
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método no permitido" }), { status: 405 });
  }
  if (!FCM_SERVICE_ACCOUNT_JSON) {
    return new Response(
      JSON.stringify({ error: "Firebase no está configurado todavía (falta el secreto FCM_SERVICE_ACCOUNT_JSON)." }),
      { status: 200 },
    );
  }

  let payload: { usuario_ids?: number[]; titulo?: string; cuerpo?: string; datos?: Record<string, unknown> };
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Body inválido" }), { status: 400 });
  }
  const usuarioIds = Array.isArray(payload.usuario_ids) ? payload.usuario_ids : [];
  const titulo = (payload.titulo || "").toString().slice(0, 200);
  const cuerpo = (payload.cuerpo || "").toString().slice(0, 500);
  if (!usuarioIds.length || !titulo) {
    return new Response(JSON.stringify({ error: "usuario_ids y titulo son obligatorios" }), { status: 400 });
  }

  const serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
  const projectId = serviceAccount.project_id;
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  const { data: tokens, error } = await supabase
    .from("ssoma_push_tokens")
    .select("token")
    .in("usuario_id", usuarioIds);
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
  if (!tokens || !tokens.length) {
    return new Response(JSON.stringify({ enviados: 0, motivo: "Ningún destinatario tiene la app instalada con notificaciones activas." }), { status: 200 });
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
            android: { priority: "high" },
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
  return new Response(JSON.stringify({ enviados, total: tokens.length, resultados }), { status: 200 });
});
