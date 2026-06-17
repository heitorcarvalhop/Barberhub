import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

// Edge Functions, ao contrário da API REST/Auth do Supabase, não adicionam
// CORS automaticamente — sem isso, chamadas vindas do Flutter Web (Chrome)
// são bloqueadas pelo navegador antes mesmo de chegar aqui.
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Método não permitido." }, 405);
  }

  // Cliente "do chamador": usa o JWT de quem invocou a function para
  // descobrir quem é e confirmar que tem role admin antes de qualquer ação.
  const authHeader = req.headers.get("Authorization") ?? "";
  const callerClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: callerData, error: callerError } =
    await callerClient.auth.getUser();
  if (callerError || !callerData?.user) {
    return jsonResponse({ error: "Não autenticado." }, 401);
  }

  const { data: callerProfile, error: callerProfileError } =
    await callerClient
      .from("profiles")
      .select("role")
      .eq("id", callerData.user.id)
      .single();

  if (callerProfileError || callerProfile?.role !== "admin") {
    return jsonResponse(
      { error: "Apenas administradores podem criar logins de barbearia." },
      403,
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Corpo da requisição inválido." }, 400);
  }

  const barbershopId = body.barbershopId as string | undefined;
  const name = body.name as string | undefined;
  const email = body.email as string | undefined;
  const password = body.password as string | undefined;

  if (!barbershopId || !name || !email || !password) {
    return jsonResponse({ error: "Dados incompletos." }, 400);
  }
  if (password.length < 6) {
    return jsonResponse(
      { error: "A senha precisa ter pelo menos 6 caracteres." },
      400,
    );
  }

  // Cliente com a service role key: ignora RLS, usado só a partir daqui
  // para criar o usuário e vincular o perfil à barbearia.
  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  const { data: shop, error: shopError } = await adminClient
    .from("barbershops")
    .select("id")
    .eq("id", barbershopId)
    .maybeSingle();
  if (shopError || !shop) {
    return jsonResponse({ error: "Barbearia não encontrada." }, 404);
  }

  const { data: created, error: createError } = await adminClient.auth.admin
    .createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name, role: "barberShop" },
    });

  if (createError || !created?.user) {
    return jsonResponse(
      { error: createError?.message ?? "Não foi possível criar o usuário." },
      400,
    );
  }

  // O trigger on_auth_user_created já criou a linha em profiles com
  // role=barberShop; falta só apontar linked_id para esta barbearia.
  const { error: linkError } = await adminClient
    .from("profiles")
    .update({ linked_id: barbershopId })
    .eq("id", created.user.id);

  if (linkError) {
    return jsonResponse(
      {
        error:
          "Usuário criado, mas houve falha ao vincular à barbearia. Vincule manualmente o linked_id.",
      },
      500,
    );
  }

  return jsonResponse({ userId: created.user.id }, 200);
});
