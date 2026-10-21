# Bartek guitarist master level maderfucker Jones

Nauka gry na gitarze od poziomu zerowego do wirtuoza. Aplikacja na iOS.
Inspirowana układem i stylem RYTMIKA·TRIP.

Całość to jeden plik `index.html`, dostępny na dwa sposoby:

- **PWA** — z GitHub Pages, instalowana z Safari na ekran początkowy.
  Trwała, darmowa, bez konta Apple. **Zobacz `INSTRUKCJA.md`.**
- **natywna powłoka iOS** (`WKWebView`) — IPA bez podpisu z CI.

Zero sieci w trakcie działania, zero zewnętrznych fontów, zero sampli —
wszystkie dźwięki są syntezowane na żywo, więc aplikacja działa w całości offline.

## Co jest w środku

| Zakładka | Zawartość |
|---|---|
| **Ścieżka** | 7 poziomów (Zero → Wirtuoz), każdy z progiem wyjścia; postęp zapisywany |
| **Stroik** | detekcja wysokości z mikrofonu, 5 strojów (Standard, Drop D, pół tonu niżej, DADGAD, Open G) |
| **Akordy** | 24 akordy z diagramami (otwarte, septymowe, barre) + trenażer zmian na czas |
| **Rytm** | 8 bić z siatką ↓↑× i metronom z podziałami oraz auto-przyspieszaniem |
| **Gryf** | 10 skal na całym gryfie, 5 pozycji, nazwy nut, odtwarzanie |
| **Technika** | 11 ćwiczeń z tabulaturą i tempami docelowymi, rekordy BPM |
| **Słuch** | rozpoznawanie interwałów i rodzajów akordów, statystyka trafień |

Dźwięk struny to **Karplus-Strong** — pobudzenie szumem i pętla opóźnienia
z tłumieniem. Brzmi jak szarpnięta struna, a nie jak oscylator, i nie
wymaga ani jednego pliku audio.

## Budowanie

Projekt Xcode nie jest trzymany w repo — generuje go **XcodeGen**
z `ios/project.yml`. Dzięki temu nie ma w historii kruchego `project.pbxproj`.

```bash
brew install xcodegen
cd ios && xcodegen generate
open BartekJones.xcodeproj
```

`index.html` z korzenia repo jest wciągany wprost do pakietu jako zasób —
jest jedno źródło prawdy, nie ma kopii do synchronizowania.

GitHub Actions (`.github/workflows/ios.yml`) buduje to samo na `macos-latest`
i publikuje **IPA bez podpisu** w Releases pod tagiem `ios`.

## Instalacja na iPhonie

iOS nie pozwala zainstalować niepodpisanej aplikacji. IPA trzeba podpisać
swoim Apple ID w momencie instalacji:

- **Sideloadly** albo **AltStore** — wystarczy darmowe Apple ID.
  Aplikacja działa 7 dni i trzeba ją odświeżyć.
- **Apple Developer Program** (99 USD/rok) — podpis ważny rok.
  Wtedy można też zbudować prosto z Xcode na podłączony telefon.

Minimalny system to **iOS 17**, czyli aplikacja działa na iOS 27
i na iPhonie 14. Niższy próg niż 27 celowo — ta sama paczka uruchomi się
też na starszych telefonach, a nic w aplikacji nie wymaga nowego SDK.

## Mikrofon w powłoce natywnej

WebKit wymaga do `getUserMedia` bezpiecznego kontekstu, a `file://` nim nie
jest. Dlatego powłoka iOS uruchamia **minimalny serwer HTTP na pętli zwrotnej**
(`ios/Sources/LocalServer.swift`, `Network.framework`, zero zależności) i
ładuje stronę z `http://127.0.0.1:28417`. Serwer podaje wyłącznie pliki
z bundle'a, tylko GET/HEAD, i nasłuchuje tylko na 127.0.0.1 — nic nie wystaje
na Wi-Fi. Port jest stały, bo `localStorage` jest kluczowany po originie;
losowy port kasowałby postępy przy każdym uruchomieniu. Gdyby port był zajęty,
powłoka wraca do `file://` — działa wtedy wszystko poza stroikiem.

## Uprawnienia

Jedyne, o co aplikacja prosi, to **mikrofon** — wyłącznie dla stroika.
Nic nie jest nagrywane ani wysyłane; sygnał jest analizowany w pamięci
(autokorelacja) i natychmiast wyrzucany.
