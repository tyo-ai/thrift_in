const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const returnUrl = "https://thriftin.local/duitku/return";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const merchantCode = Deno.env.get("DUITKU_MERCHANT_CODE")?.trim();
    const apiKey = Deno.env.get("DUITKU_API_KEY")?.trim();
    const environment = Deno.env.get("DUITKU_ENVIRONMENT")?.trim() || "sandbox";
    if (!merchantCode || !apiKey) {
      return jsonResponse(
        { error: "DUITKU_MERCHANT_CODE or DUITKU_API_KEY is not set" },
        500,
      );
    }

    const body = await req.json();
    if (new URL(req.url).pathname.endsWith("/callback")) {
      return jsonResponse({ ok: true, received: body });
    }

    return await createTransaction(merchantCode, apiKey, environment, body);
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : "Unknown error" },
      500,
    );
  }
});

async function createTransaction(
  merchantCode: string,
  apiKey: string,
  environment: string,
  body: Record<string, unknown>,
) {
  const merchantOrderId = cleanOrderId(body.merchantOrderId);
  const paymentAmount = Number(body.paymentAmount);
  if (
    !merchantOrderId ||
    !Number.isInteger(paymentAmount) ||
    paymentAmount <= 0
  ) {
    return jsonResponse(
      { error: "Invalid merchantOrderId or paymentAmount" },
      400,
    );
  }

  const productDetails = body.productDetails?.toString() ||
    "Pembayaran Thriftin";
  const paymentMethod = cleanPaymentMethod(body.paymentMethod);
  const email = body.email?.toString() || "sandbox@thriftin.local";
  const phoneNumber = body.phoneNumber?.toString() || "08123456789";
  const customerVaName = body.customerVaName?.toString() || "Thriftin User";
  const itemDetails = Array.isArray(body.itemDetails) ? body.itemDetails : [
    {
      name: productDetails,
      price: paymentAmount,
      quantity: 1,
    },
  ];

  const stringToSign = `${merchantCode}${merchantOrderId}${paymentAmount}`;
  const timestamp = Date.now().toString();
  const signature = await hmacSha256Hex(`${merchantCode}${timestamp}`, apiKey);
  const callbackUrl = buildCallbackUrl();

  const payload = {
    paymentAmount,
    merchantOrderId,
    productDetails,
    ...(paymentMethod ? { paymentMethod } : {}),
    additionalParam: "",
    merchantUserInfo: email,
    customerVaName,
    email,
    phoneNumber,
    itemDetails,
    customerDetail: {
      firstName: customerVaName,
      email,
      phoneNumber,
    },
    callbackUrl,
    returnUrl,
    expiryPeriod: 60,
  };

  const inquiryUrl = environment === "production"
    ? "https://api-prod.duitku.com/api/merchant/createInvoice"
    : "https://api-sandbox.duitku.com/api/merchant/createInvoice";

  const response = await fetch(inquiryUrl, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "x-duitku-signature": signature,
      "x-duitku-timestamp": timestamp,
      "x-duitku-merchantcode": merchantCode,
    },
    body: JSON.stringify(payload),
  });

  const data = await response.json();
  return jsonResponse(data, response.status);
}

function buildCallbackUrl() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.replace(/\/$/, "");
  if (!supabaseUrl) return "https://thriftin.example.com/duitku/callback";
  return `${supabaseUrl}/functions/v1/create-duitku-transaction/callback`;
}

async function hmacSha256Hex(message: string, key: string) {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    cryptoKey,
    encoder.encode(message),
  );
  return [...new Uint8Array(signature)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function cleanOrderId(value: unknown) {
  const orderId = value?.toString().trim() ?? "";
  if (!/^[A-Za-z0-9._~-]{1,50}$/.test(orderId)) return "";
  return orderId;
}

function cleanPaymentMethod(value: unknown) {
  const code = value?.toString().trim().toUpperCase() ?? "";
  if (!/^[A-Z0-9]{2}$/.test(code)) return "";
  return code;
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
