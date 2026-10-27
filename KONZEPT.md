# Vokabel-App für Valerie – Konzept

Englisch-Vokabeln lernen, 2. Klasse Gymnasium. Spielerisch, mit Sprechen und KI-Hilfe.

## Entscheidungen

| Thema | Entscheidung |
|---|---|
| Plattform | iOS/iPadOS, SwiftUI, iOS 17+ |
| Verteilung | TestFlight (Apple Developer Program, 99 €/Jahr) |
| KI | Claude API über einen kleinen Proxy (Cloudflare Worker), Schlüssel nie in der App |
| Eingabe | Foto vom Schulbuch **oder** nur das englische Wort tippen |
| Spiel | Punkte & Serien, Mini-Spiele, KI-Geschichten, Sprech-Challenge |

## Architektur

```
iPhone/iPad (SwiftUI + SwiftData, alles lokal gespeichert)
   │  Sprachausgabe: AVSpeechSynthesizer (britische Stimme, offline, kostenlos)
   │  Spracherkennung: SFSpeechRecognizer en-GB (auf dem Gerät, kostenlos)
   │  Texterkennung Foto: Vision (auf dem Gerät)
   │
   └── HTTPS ──> Cloudflare Worker (Proxy)
                   - hält den Anthropic-Schlüssel als Secret
                   - App-Token, Tageslimit an Anfragen
                   └──> Claude API
```

Zur KI geht nur der Vokabeltext bzw. das Foto der Buchseite, keine persönlichen Daten.

## Was die KI macht

1. **Wort prüfen & ergänzen** – Valerie tippt „becuase“ → Vorschlag „because“ + „weil“ + kurzer Beispielsatz. Valerie bestätigt mit einem Tipp.
2. **Foto auslesen** – Buchseite → Liste aus Englisch / Deutsch, Tippfehler aus der Texterkennung bereinigt, Valerie hakt ab, was übernommen wird.
3. **Antworten fair bewerten** – „the dog“ statt „dog“ oder ein kleiner Tippfehler zählt als „fast richtig“ mit Hinweis statt als Fehler.
4. **Geschichten** – kurze, kindgerechte Geschichte mit den Vokabeln der Woche als Lückentext.

## Lernen

- **Karteikasten (Leitner, 5 Fächer)** – richtige Wörter wandern nach hinten und kommen seltener, falsche wieder nach vorn.
- **Abfrage-Arten**: Deutsch → Englisch tippen, Englisch → Deutsch, Auswahl aus 4, Hören → schreiben, Sprechen.
- **Sprech-Challenge**: Wort hören, nachsprechen, die App vergleicht das Erkannte mit dem Zielwort.

## Spiel

- Sterne pro Runde, Tages-Serie, Level
- Begleiter-Tier, das mit den Sternen wächst
- Mini-Spiele: Buchstabensalat, Memory (EN/DE-Paare), Zeitrennen
- KI-Lückengeschichte

## Etappen

1. **Grundgerüst** – Units/Listen, englisches Wort tippen + KI-Ergänzung, Karteikasten-Abfrage in beide Richtungen, Vorlesen, Sterne & Serie. Proxy läuft.
2. **Foto & Sprechen** – Buchseite fotografieren, Sprech-Challenge, Hören → schreiben.
3. **Spiele** – Mini-Spiele, Begleiter-Tier, KI-Geschichten.
4. **TestFlight** – App auf Valeries Gerät.

## Was du vorbereiten musst

- **Xcode** aus dem Mac App Store installieren (aktuell ist nur das Command Line Tools-Paket da), danach einmal öffnen und die iOS-Plattform laden.
- **Apple Developer Program** beitreten (developer.apple.com/programs, als Einzelperson) – nötig für TestFlight.
- **Anthropic-API-Schlüssel** in der Console anlegen und dort ein monatliches Ausgabenlimit setzen.
- **Cloudflare-Konto** (kostenlos) für den Proxy.
