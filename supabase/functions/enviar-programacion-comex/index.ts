import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import * as XLSX from "npm:xlsx@0.18.5";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const FROM_EMAIL = Deno.env.get("RESEND_FROM_EMAIL") || "Adecco Inbound <onboarding@resend.dev>";

const VIA_ICONOS: Record<string, string> = { "MARITIMO": "🚢", "AEREO": "✈️", "TRASLADO VIRTUAL": "🚚" };

function fmtFecha(iso: string | null | undefined): string {
  if (!iso) return "—";
  const d = new Date(iso + "T00:00:00");
  return d.toLocaleDateString("es-PE", { weekday: "short", day: "2-digit", month: "short" });
}

function escapeHtml(s: unknown): string {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string));
}

interface Entrega {
  tipo: string; tipoContenedor?: string; cantidad: number | string; fecha: string;
  via?: string; bl?: string; ocHija?: string; proveedor?: string; linea?: string;
  eta?: string; sobrestadia?: string; agencia?: string; lpns?: number | string;
}

function construirExcelBase64(entregas: Entrega[]): string {
  const filas = entregas.map((e) => ({
    "Fecha de entrega": e.fecha || "",
    "Tipo de carga": e.tipo === "contenedor" ? "Contenedor" : "Carga suelta",
    "Tipo de contenedor": e.tipoContenedor || "",
    "Cantidad": Number(e.cantidad) || 0,
    "Vía": e.via || "",
    "BL": e.bl || "",
    "OC Hija": e.ocHija || "",
    "Proveedor": e.proveedor || "",
    "Línea": e.linea || "",
    "ETA": e.eta || "",
    "Sobrestadía": e.sobrestadia || "",
    "Agencia": e.agencia || "",
    "LPNs": e.lpns || "",
  }));
  const ws = XLSX.utils.json_to_sheet(filas);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, "Programación");
  return XLSX.write(wb, { type: "base64", bookType: "xlsx" }) as string;
}

function construirHtml(datos: { nombre?: string; area?: string; correo: string; dni?: string; entregas: Entrega[] }): string {
  const { nombre, area, correo, dni, entregas } = datos;
  const totalCont = entregas.filter((e) => e.tipo === "contenedor").reduce((a, e) => a + (Number(e.cantidad) || 0), 0);
  const totalPallets = entregas.filter((e) => e.tipo === "carga_suelta").reduce((a, e) => a + (Number(e.cantidad) || 0), 0);
  const filasHtml = entregas.map((e) => `
    <tr>
      <td style="padding:11px 10px;border-bottom:1px solid #EDEEF1;font-weight:700;font-family:Consolas,'Courier New',monospace;font-size:12px;">${escapeHtml(fmtFecha(e.fecha))}</td>
      <td style="padding:11px 10px;border-bottom:1px solid #EDEEF1;">
        <span style="display:inline-block;padding:2px 8px;border-radius:20px;font-size:10.5px;font-weight:700;white-space:nowrap;${e.tipo === "contenedor" ? "background:#EAF1FE;color:#2563EB;" : "background:#FEF3E2;color:#B45309;"}">${e.tipo === "contenedor" ? "📦 " + escapeHtml(e.tipoContenedor || "Contenedor") : "🧱 Carga suelta"}</span>
      </td>
      <td style="padding:11px 10px;border-bottom:1px solid #EDEEF1;">${VIA_ICONOS[e.via || ""] || "📦"} ${escapeHtml(e.via) || "—"}</td>
      <td style="padding:11px 10px;border-bottom:1px solid #EDEEF1;">${escapeHtml(e.bl) || "—"}<br><span style="color:#6B7280;">${escapeHtml(e.proveedor) || "—"}</span></td>
      <td style="padding:11px 10px;border-bottom:1px solid #EDEEF1;text-align:right;font-family:Consolas,'Courier New',monospace;font-weight:700;">${escapeHtml(e.cantidad)}</td>
    </tr>`).join("");

  return `<!doctype html><html><head><meta charset="utf-8"></head><body style="margin:0;background:#EDEEF1;font-family:Arial,Helvetica,sans-serif;">
  <div style="max-width:600px;margin:0 auto;background:#ffffff;">
    <div style="height:6px;background:#E31E24;"></div>
    <div style="padding:28px 28px 8px;color:#1A1D23;">
      <div style="font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:#E31E24;margin-bottom:18px;">Adecco Inbound</div>
      <div style="background:#EAF7EF;border:1px solid #BFE3CC;border-radius:10px;padding:16px 18px;margin-bottom:22px;">
        <p style="font-size:16px;font-weight:800;color:#15803D;margin:0 0 3px;">✅ Programación registrada correctamente</p>
        <p style="font-size:12.5px;color:#3F6B4C;margin:0;">${escapeHtml(new Date().toLocaleString("es-PE"))}</p>
      </div>
      <p style="font-size:14px;line-height:1.6;margin:0 0 20px;">Hola${nombre ? " " + escapeHtml(nombre) : ""},<br><br>Se registró la programación de entregas que cargaste como <b>${escapeHtml(area) || "COMEX"}</b> (${escapeHtml(correo)}${dni ? ", DNI " + escapeHtml(dni) : ""}). El equipo de recepción ya la puede ver en su agenda diaria.</p>
      <table role="presentation" style="width:100%;border-collapse:collapse;margin-bottom:22px;">
        <tr>
          <td style="padding:12px 14px;background:#F6F7F9;border:1px solid #E1E3E8;text-align:center;border-radius:9px 0 0 9px;">
            <span style="display:block;font-size:19px;font-weight:800;font-family:Consolas,monospace;">${entregas.length}</span>
            <span style="display:block;font-size:10px;color:#6B7280;text-transform:uppercase;">Entregas</span>
          </td>
          <td style="padding:12px 14px;background:#F6F7F9;border:1px solid #E1E3E8;text-align:center;">
            <span style="display:block;font-size:19px;font-weight:800;font-family:Consolas,monospace;">${totalCont}</span>
            <span style="display:block;font-size:10px;color:#6B7280;text-transform:uppercase;">Contenedores</span>
          </td>
          <td style="padding:12px 14px;background:#F6F7F9;border:1px solid #E1E3E8;text-align:center;border-radius:0 9px 9px 0;">
            <span style="display:block;font-size:19px;font-weight:800;font-family:Consolas,monospace;">${totalPallets}</span>
            <span style="display:block;font-size:10px;color:#6B7280;text-transform:uppercase;">Pallets</span>
          </td>
        </tr>
      </table>
      <p style="font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:.06em;color:#6B7280;margin:0 0 10px;">Detalle de lo programado</p>
      <table role="presentation" style="width:100%;border-collapse:collapse;margin-bottom:8px;font-size:12.5px;">
        <thead><tr>
          <th style="text-align:left;font-size:10.5px;text-transform:uppercase;color:#6B7280;padding:0 10px 8px;border-bottom:2px solid #E1E3E8;">Fecha</th>
          <th style="text-align:left;font-size:10.5px;text-transform:uppercase;color:#6B7280;padding:0 10px 8px;border-bottom:2px solid #E1E3E8;">Tipo</th>
          <th style="text-align:left;font-size:10.5px;text-transform:uppercase;color:#6B7280;padding:0 10px 8px;border-bottom:2px solid #E1E3E8;">Vía</th>
          <th style="text-align:left;font-size:10.5px;text-transform:uppercase;color:#6B7280;padding:0 10px 8px;border-bottom:2px solid #E1E3E8;">BL / Proveedor</th>
          <th style="text-align:right;font-size:10.5px;text-transform:uppercase;color:#6B7280;padding:0 10px 8px;border-bottom:2px solid #E1E3E8;">Cant.</th>
        </tr></thead>
        <tbody>${filasHtml}</tbody>
      </table>
      <div style="display:flex;align-items:center;gap:12px;background:#F6F7F9;border:1px solid #E1E3E8;border-radius:10px;padding:14px 16px;margin:22px 0;">
        <div style="width:36px;height:36px;border-radius:8px;background:#15803D;color:#fff;display:flex;align-items:center;justify-content:center;font-size:16px;">📊</div>
        <div>
          <div style="font-size:12.5px;font-weight:700;">programacion.xlsx</div>
          <div style="font-size:11px;color:#6B7280;margin-top:1px;">Mismo detalle en Excel, listo para tus registros</div>
        </div>
      </div>
      <p style="font-size:12px;color:#6B7280;line-height:1.6;margin:18px 0 24px;">¿Necesitas corregir algo? Vuelve a entrar al formulario y agrega una entrega nueva — no hace falta escribirnos, el operador va a ver el cambio apenas la cargues.</p>
    </div>
    <div style="border-top:1px solid #E1E3E8;padding:18px 28px 24px;font-size:11px;color:#9AA1AC;line-height:1.7;">
      Este correo se generó automáticamente al enviar tu programación en <b style="color:#6B7280;">Programación de Contenedores — Adecco Inbound</b>.<br>
      Si no reconoces esta programación, ignora este mensaje o contacta a tu contraparte en Adecco.
    </div>
  </div>
  </body></html>`;
}

Deno.serve(async (req: Request) => {
  const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    if (!RESEND_API_KEY) {
      console.error("Falta el secreto RESEND_API_KEY (Edge Functions → Secrets del proyecto).");
      return new Response(JSON.stringify({ error: "Falta configurar el secreto RESEND_API_KEY en Edge Functions." }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
    }
    const bodyJson = await req.json();
    const { correo, nombre, dni, area, entregas } = bodyJson as { correo: string; nombre?: string; dni?: string; area?: string; entregas: Entrega[] };
    if (!correo || !Array.isArray(entregas) || !entregas.length) {
      console.error("Faltan datos en el body:", JSON.stringify(bodyJson));
      return new Response(JSON.stringify({ error: "Faltan datos: correo y al menos una entrega." }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }

    const excelBase64 = construirExcelBase64(entregas);
    const html = construirHtml({ nombre, area, correo, dni, entregas });
    const hoy = new Date().toISOString().slice(0, 10);

    const resendResp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { "Authorization": `Bearer ${RESEND_API_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: [correo],
        subject: `✅ Tu programación de contenedores fue registrada — ${hoy}`,
        html,
        attachments: [{ filename: `programacion_${hoy}.xlsx`, content: excelBase64 }],
      }),
    });

    const resendData = await resendResp.json();
    if (!resendResp.ok) {
      console.error("Resend rechazó el envío:", resendResp.status, JSON.stringify(resendData));
      return new Response(JSON.stringify({ error: "Resend rechazó el envío", detalle: resendData }), { status: 502, headers: { ...cors, "Content-Type": "application/json" } });
    }

    console.log("Correo enviado:", resendData.id, "->", correo);
    return new Response(JSON.stringify({ ok: true, id: resendData.id }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (err) {
    console.error("Excepción no controlada:", err instanceof Error ? err.stack : String(err));
    return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
