import Anthropic from "@anthropic-ai/sdk";

export interface Env {
  ANTHROPIC_API_KEY: string;
  APP_TOKEN: string;
  USAGE: KVNamespace;
  MODEL?: string;
  DAILY_LIMIT?: string;
}

const DEFAULT_MODEL = "claude-opus-5-5";
const DEFAULT_DAILY_LIMIT = 300;
const MAX_WORDS_PER_REQUEST = 40;

// Kept stable so it can be cached across requests.
const ENRICH_SYSTEM = `Du hilfst einem Kind in der 2. Klasse Gymnasium (Bayern/Deutschland, ca. 12 Jahre), Englisch-Vokabeln anzulegen.
Das Kind tippt englische Wörter oder kurze Ausdrücke, oft mit Rechtschreibfehlern.
Für jede Eingabe:
- english: die richtig geschriebene englische Vokabel in britischer Schreibweise, so wie sie in einem deutschen Schulbuch (z. B. Green Line, Access) stünde. Verben mit "to" nur, wenn das Kind es selbst geschrieben hat.
- german: die gängigste deutsche Übersetzung für diese Klassenstufe. Bei Nomen mit Artikel (der/die/das). Mehrere Bedeutungen mit ", " trennen, höchstens drei.
- example: ein kurzer, kindgerechter englischer Beispielsatz (höchstens 10 Wörter).
- corrected: true, wenn du die Schreibweise der Eingabe ändern musstest.
- note: kurzer deutscher Hinweis für das Kind, wenn corrected true ist oder die Eingabe unklar war (z. B. "Achtung: 'because' schreibt man mit au"). Sonst leer.
Ist eine Eingabe gar kein englisches Wort und nicht erkennbar, setze english auf die Eingabe, german auf "" und erkläre es in note.
Behalte die Reihenfolge der Eingaben bei.`;

const CHECK_SYSTEM = `Du bewertest Antworten eines Kindes (2. Klasse Gymnasium) bei einer Englisch-Vokabelabfrage. Sei fair und ermutigend.
- correct: Bedeutung und Schreibweise stimmen. Kleinigkeiten wie Groß-/Kleinschreibung, fehlender Artikel ("dog" statt "the dog"), "to" bei Verben oder ein gleichwertiges Synonym zählen als richtig.
- almost: Bedeutung stimmt, aber ein kleiner Rechtschreibfehler (z. B. ein Buchstabe falsch, vertauscht oder vergessen).
- wrong: falsches Wort, falsche Bedeutung oder mehrere Fehler.
feedback: ein kurzer, freundlicher deutscher Satz für das Kind (höchstens 15 Wörter). Bei almost oder wrong nenne die richtige Schreibweise.`;

const ENRICH_SCHEMA = {
  type: "object",
  properties: {
    words: {
      type: "array",
      items: {
        type: "object",
        properties: {
          input: { type: "string" },
          english: { type: "string" },
          german: { type: "string" },
          example: { type: "string" },
          corrected: { type: "boolean" },
          note: { type: "string" },
        },
        required: ["input", "english", "german", "example", "corrected", "note"],
        additionalProperties: false,
      },
    },
  },
  required: ["words"],
  additionalProperties: false,
};

const CHECK_SCHEMA = {
  type: "object",
  properties: {
    verdict: { type: "string", enum: ["correct", "almost", "wrong"] },
    feedback: { type: "string" },
  },
  required: ["verdict", "feedback"],
  additionalProperties: false,
};

class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      if (request.method !== "POST") throw new HttpError(405, "Nur POST");
      if (request.headers.get("x-app-token") !== env.APP_TOKEN) throw new HttpError(401, "Falscher App-Token");

      const path = new URL(request.url).pathname;
      const body = await request.json().catch(() => {
        throw new HttpError(400, "Ungültiges JSON");
      });

      await countRequest(env);

      if (path === "/enrich") return json(await enrich(env, body));
      if (path === "/check") return json(await check(env, body));
      throw new HttpError(404, "Unbekannter Pfad");
    } catch (error) {
      if (error instanceof HttpError) return json({ error: error.message }, error.status);
      if (error instanceof Anthropic.RateLimitError) return json({ error: "KI ist gerade überlastet" }, 503);
      if (error instanceof Anthropic.APIError) {
        console.error(`Anthropic ${error.status}: ${error.message}`);
        return json({ error: "KI-Fehler" }, 502);
      }
      console.error(error);
      return json({ error: "Interner Fehler" }, 500);
    }
  },
};

async function enrich(env: Env, body: any) {
  const words: unknown = body?.words;
  if (!Array.isArray(words) || words.length === 0 || !words.every((w) => typeof w === "string")) {
    throw new HttpError(400, "words muss eine Liste von Texten sein");
  }
  if (words.length > MAX_WORDS_PER_REQUEST) throw new HttpError(400, `Höchstens ${MAX_WORDS_PER_REQUEST} Wörter auf einmal`);

  const list = words.map((w, i) => `${i + 1}. ${w.trim().slice(0, 80)}`).join("\n");
  return ask(env, ENRICH_SYSTEM, `Eingaben:\n${list}`, ENRICH_SCHEMA);
}

async function check(env: Env, body: any) {
  const { prompt, expected, answer, direction } = body ?? {};
  if (![prompt, expected, answer].every((v) => typeof v === "string")) {
    throw new HttpError(400, "prompt, expected und answer sind Pflicht");
  }
  const target = direction === "en-de" ? "Deutsch" : "Englisch";
  const text = `Abgefragt: "${prompt.slice(0, 120)}"\nErwartete Antwort auf ${target}: "${expected.slice(0, 120)}"\nAntwort des Kindes: "${answer.slice(0, 120)}"`;
  return ask(env, CHECK_SYSTEM, text, CHECK_SCHEMA);
}

async function ask(env: Env, system: string, text: string, schema: Record<string, unknown>) {
  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const model = env.MODEL || DEFAULT_MODEL;
  // Server-side fallbacks exist for Opus/Fable/Sonnet 5.5, not for Haiku.
  const withFallback = !model.startsWith("claude-haiku");

  const response = await client.beta.messages.create({
    model,
    max_tokens: 8000,
    output_config: { effort: "low", format: { type: "json_schema", schema } },
    system: [{ type: "text", text: system, cache_control: { type: "ephemeral" } }],
    messages: [{ role: "user", content: text }],
    ...(withFallback ? { betas: ["server-side-fallback-2026-07-01"], fallbacks: "default" } : {}),
  });

  if (response.stop_reason === "refusal") throw new HttpError(422, "Die KI konnte das nicht bearbeiten");
  if (response.stop_reason === "max_tokens") throw new HttpError(502, "Antwort der KI war zu lang");

  const textBlock = response.content.find((b) => b.type === "text");
  if (!textBlock || textBlock.type !== "text") throw new HttpError(502, "Leere Antwort der KI");
  return JSON.parse(textBlock.text);
}

// Simple daily cap so a bug or a leaked token can't run up the bill.
async function countRequest(env: Env) {
  const limit = Number(env.DAILY_LIMIT) || DEFAULT_DAILY_LIMIT;
  const key = `count:${new Date().toISOString().slice(0, 10)}`;
  const count = Number(await env.USAGE.get(key)) || 0;
  if (count >= limit) throw new HttpError(429, "Tageslimit erreicht – morgen geht's weiter!");
  await env.USAGE.put(key, String(count + 1), { expirationTtl: 60 * 60 * 48 });
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}
