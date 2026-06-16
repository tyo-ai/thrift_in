import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json();
    const userId = Number(body.userId);
    const title = cleanText(body.title, "ThriftIn");
    const messageBody = cleanText(body.body, "Kamu punya notifikasi baru");
    const payload = typeof body.payload === "object" && body.payload !== null
      ? body.payload as Record<string, string>
      : {};

    if (!Number.isInteger(userId) || userId <= 0) {
      return jsonResponse({ error: "Invalid userId" }, 400);
    }

    const supabase = createAdminClient();
    const { data: tokens, error } = await supabase
      .from("user_fcm_tokens")
      .select("token")
      .eq("user_id", userId);

    if (error) throw error;
    if (!tokens?.length) {
      return jsonResponse({ ok: true, sent: 0, reason: "No FCM token" });
    }

    const accessToken = await getFirebaseAccessToken();
    const serviceAccount = getServiceAccount();
    const results = await Promise.allSettled(
      tokens.map(({ token }) =>
        sendMessage({
          accessToken,
          projectId: serviceAccount.project_id,
          token,
          title,
          body: messageBody,
          payload,
        })
      ),
    );

    const sent = results.filter((result) => result.status === "fulfilled")
      .length;
    const failed = results.length - sent;
    return jsonResponse({ ok: true, sent, failed });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : "Unknown error" },
      500,
    );
  }
});

function createAdminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_ANON_KEY") ??
    parseJsonSecretMap(Deno.env.get("SUPABASE_SECRET_KEYS"))?.default;
  if (!url || !key) {
    throw new Error("SUPABASE_URL or Supabase API key is missing");
  }

  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

function parseJsonSecretMap(value: string | undefined) {
  if (!value) return null;
  try {
    return JSON.parse(value) as Record<string, string>;
  } catch {
    return null;
  }
}

async function sendMessage({
  accessToken,
  projectId,
  token,
  title,
  body,
  payload,
}: {
  accessToken: string;
  projectId: string;
  token: string;
  title: string;
  body: string;
  payload: Record<string, string>;
}) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: stringifyPayload({ ...payload, title, body }),
          android: {
            priority: "HIGH",
            notification: {
              channel_id: payload.type === "chat"
                ? "thriftin_chat"
                : "thriftin_general",
              sound: "default",
            },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    throw new Error(await response.text());
  }
}

async function getFirebaseAccessToken() {
  const serviceAccount = getServiceAccount();
  const now = Math.floor(Date.now() / 1000);
  const jwt = await createJwt({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
    issuedAt: now,
    expiresAt: now + 3600,
  });

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error_description ?? "Failed to get FCM access token");
  }
  return data.access_token as string;
}

function getServiceAccount() {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not set");
  }
  return JSON.parse(raw) as {
    project_id: string;
    client_email: string;
    private_key: string;
  };
}

async function createJwt({
  clientEmail,
  privateKey,
  issuedAt,
  expiresAt,
}: {
  clientEmail: string;
  privateKey: string;
  issuedAt: number;
  expiresAt: number;
}) {
  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = base64UrlEncode(
    JSON.stringify({
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: issuedAt,
      exp: expiresAt,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64UrlEncode(signature)}`;
}

function pemToArrayBuffer(pem: string) {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function base64UrlEncode(value: string | ArrayBuffer) {
  const bytes = typeof value === "string"
    ? new TextEncoder().encode(value)
    : new Uint8Array(value);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function stringifyPayload(payload: Record<string, string>) {
  return Object.fromEntries(
    Object.entries(payload).map(([key, value]) => [key, String(value)]),
  );
}

function cleanText(value: unknown, fallback: string) {
  const text = value?.toString().trim();
  return text && text.length <= 180 ? text : fallback;
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
