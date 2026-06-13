import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const otpTtlMinutes = 10;
const maxAttempts = 5;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
    if (!supabaseUrl || !serviceKey) {
      return jsonResponse({ error: "Supabase service env is not set" }, 500);
    }

    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false },
    });
    const body = await req.json();
    const action = body.action?.toString();

    if (action === "request") {
      return await requestOtp(supabase, body);
    }
    if (action === "reset") {
      return await resetPassword(supabase, body);
    }

    return jsonResponse({ error: "Invalid action" }, 400);
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : "Unknown error" },
      500,
    );
  }
});

async function requestOtp(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const email = normalizeEmail(body.email);
  if (!email) return jsonResponse({ error: "Email tidak valid" }, 400);

  const { data: user, error: userError } = await supabase
    .from("users")
    .select("id, name, email")
    .eq("email", email)
    .maybeSingle();

  if (userError) return jsonResponse({ error: userError.message }, 500);

  // Avoid account enumeration. The UI receives success even if email is unknown.
  if (!user) return jsonResponse({ ok: true });

  const code = generateOtp();
  const codeHash = await sha256(`${email}:${code}`);
  const expiresAt = new Date(Date.now() + otpTtlMinutes * 60_000)
    .toISOString();

  const { error: insertError } = await supabase
    .from("password_reset_otps")
    .insert({
      email,
      code_hash: codeHash,
      expires_at: expiresAt,
    });
  if (insertError) return jsonResponse({ error: insertError.message }, 500);

  const emailResult = await sendOtpEmail({
    to: email,
    name: user.name?.toString() || "Sobat ThriftIn",
    code,
  });

  if (!emailResult.ok) {
    return jsonResponse({ error: emailResult.error }, 500);
  }

  return jsonResponse({ ok: true });
}

async function resetPassword(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const email = normalizeEmail(body.email);
  const code = body.code?.toString().replace(/\D/g, "") ?? "";
  const newPassword = body.newPassword?.toString() ?? "";
  if (!email || code.length !== 6) {
    return jsonResponse({ error: "Kode OTP tidak valid" }, 400);
  }
  if (newPassword.length < 8) {
    return jsonResponse({ error: "Password minimal 8 karakter" }, 400);
  }

  const { data: rows, error: otpError } = await supabase
    .from("password_reset_otps")
    .select("id, code_hash, expires_at, attempts, used_at")
    .eq("email", email)
    .is("used_at", null)
    .order("created_at", { ascending: false })
    .limit(1);
  if (otpError) return jsonResponse({ error: otpError.message }, 500);
  if (!rows || rows.length === 0) {
    return jsonResponse({ error: "OTP tidak ditemukan" }, 400);
  }

  const otp = rows[0] as {
    id: number;
    code_hash: string;
    expires_at: string;
    attempts: number;
    used_at: string | null;
  };
  if (new Date(otp.expires_at).getTime() < Date.now()) {
    return jsonResponse({ error: "OTP sudah kedaluwarsa" }, 400);
  }
  if ((otp.attempts ?? 0) >= maxAttempts) {
    return jsonResponse({ error: "OTP terlalu sering dicoba" }, 429);
  }

  const expectedHash = await sha256(`${email}:${code}`);
  if (expectedHash !== otp.code_hash) {
    await supabase
      .from("password_reset_otps")
      .update({ attempts: (otp.attempts ?? 0) + 1 })
      .eq("id", otp.id);
    return jsonResponse({ error: "OTP salah" }, 400);
  }

  const passwordHash = await sha256(newPassword);
  const { error: updateError } = await supabase
    .from("users")
    .update({ password: passwordHash })
    .eq("email", email);
  if (updateError) return jsonResponse({ error: updateError.message }, 500);

  await supabase
    .from("password_reset_otps")
    .update({ used_at: new Date().toISOString() })
    .eq("id", otp.id);

  return jsonResponse({ ok: true });
}

async function sendOtpEmail(
  params: { to: string; name: string; code: string },
): Promise<{ ok: true } | { ok: false; error: string }> {
  const resendApiKey = Deno.env.get("RESEND_API_KEY")?.trim();
  const fromEmail = Deno.env.get("RESEND_FROM_EMAIL")?.trim() ||
    "noreply@example.com";
  const fromName = Deno.env.get("RESEND_FROM_NAME")?.trim() || "ThriftIn";
  if (!resendApiKey) {
    return { ok: false, error: "RESEND_API_KEY is not set" };
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: `${fromName} <${fromEmail}>`,
      to: [params.to],
      subject: "Kode OTP Reset Password ThriftIn",
      html: otpHtml(params.name, params.code),
      text:
        `Kode OTP reset password ThriftIn kamu adalah ${params.code}. Kode berlaku ${otpTtlMinutes} menit.`,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    return { ok: false, error: text };
  }
  return { ok: true };
}

function otpHtml(name: string, code: string) {
  return `
    <div style="font-family:Arial,sans-serif;line-height:1.5;color:#111827">
      <h2 style="margin:0 0 12px">Reset password ThriftIn</h2>
      <p>Halo ${escapeHtml(name)},</p>
      <p>Masukkan kode OTP berikut untuk membuat password baru:</p>
      <p style="font-size:28px;font-weight:700;letter-spacing:6px;margin:20px 0">${code}</p>
      <p>Kode berlaku ${otpTtlMinutes} menit. Abaikan email ini kalau kamu tidak meminta reset password.</p>
    </div>
  `;
}

function generateOtp() {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return (array[0] % 1_000_000).toString().padStart(6, "0");
}

function normalizeEmail(value: unknown) {
  const email = value?.toString().trim().toLowerCase() ?? "";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return "";
  return email;
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
