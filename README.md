# LingoLama 🦙

Englisch-Vokabel-App für Valerie. Konzept: [KONZEPT.md](KONZEPT.md).

```
App/          SwiftUI-App (iOS 17+, SwiftData)
VokabelKit/   Lernlogik ohne UI: Karteikasten, Antwortprüfung, Sterne/Serie – mit Tests
proxy/        Cloudflare Worker, hält den Anthropic-Schlüssel
project.yml   Xcode-Projekt (wird mit XcodeGen erzeugt)
```

## 1. Proxy einrichten (einmalig)

```sh
cd proxy
npx wrangler login
npx wrangler kv namespace create USAGE      # ausgegebene id in wrangler.toml eintragen
npx wrangler secret put ANTHROPIC_API_KEY   # Schlüssel aus console.anthropic.com
npx wrangler secret put APP_TOKEN           # selbst ausdenken, z. B. `openssl rand -hex 24`
npx wrangler deploy
```

Danach in der Anthropic Console ein monatliches Ausgabenlimit setzen. Der Proxy lässt zusätzlich höchstens
`DAILY_LIMIT` Anfragen pro Tag durch (in `wrangler.toml`). Günstigeres Modell: `MODEL = "claude-haiku-5-5"`.

## 2. App bauen

`Secrets.xcconfig` neben `Config.xcconfig` anlegen (steht nicht im Git):

```
PROXY_HOST = vokabel-proxy.<dein-name>.workers.dev
APP_TOKEN = <derselbe Token wie oben>
```

```sh
xcodegen generate
open LingoLama.xcodeproj
```

In Xcode unter *Signing & Capabilities* dein Team wählen, dann auf Simulator oder iPhone starten.

## Tests

```sh
scripts/test-kit.sh
```
