
import { z } from "zod"; 
import { createClient } from "@supabase/supabase-js";
import { allowWrite } from "../core/guardrails"; 
import type { AgentCtx } from "../core/ctx";

const sb = createClient(process.env.VITE_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

export const readCrmClients = {
  name: "read_crm_clients",
  description: "Read crm_clients",
  parameters: z.object({ limit: z.number().default(25) }),
  handler: async (a: any, ctx: AgentCtx) => 
    (await sb.from("crm_clients").select("*").eq("studio_id", ctx.studioId).limit(a.limit)).data
};

export const createCrmClients = {
  name: "create_crm_clients",
  description: "Create row in crm_clients",
  parameters: z.object({ data: z.record(z.any()) }),
  handler: async (a: any, ctx: AgentCtx) => {
    if (allowWrite(ctx, "CREATE_LEAD") !== "allow") throw new Error("Nope");
    return (await sb.from("crm_clients").insert({ ...a.data, studio_id: ctx.studioId }).select().single()).data;
  }
};

export const updateCrmClients = {
  name: "update_crm_clients",
  description: "Update row in crm_clients",
  parameters: z.object({ id: z.string(), data: z.record(z.any()) }),
  handler: async (a: any, ctx: AgentCtx) => {
    if (allowWrite(ctx, "UPDATE_CLIENT") !== "allow") throw new Error("Not allowed");
    return (await sb.from("crm_clients").update(a.data).eq("id", a.id).eq("studio_id", ctx.studioId).select().single()).data;
  }
};
