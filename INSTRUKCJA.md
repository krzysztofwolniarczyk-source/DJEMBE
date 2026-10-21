# Bartek Jones — instalacja na iPhonie bez App Store

Są dwie drogi. **Pierwsza jest trwała i darmowa** — tak samo instalowaliście
RYTMIKA·TRIP. Druga daje natywną aplikację, ale iOS każe ją odświeżać albo
płacić Apple. Nie ma trzeciej: natywnej aplikacji spoza App Store nie da się
na iPhonie zainstalować „raz na zawsze” za darmo — to polityka Apple, nie
ograniczenie tej aplikacji.

---

## Droga 1 — PWA z GitHub Pages (trwała, polecana)

Aplikacja jest w 100% webowa, więc zainstalowana z Safari na ekran początkowy
działa jak natywna: własna ikona, pełny ekran, offline, **działający mikrofon**
(HTTPS daje bezpieczny kontekst) i **nigdy nie wygasa**. Nie potrzebuje
żadnego komputera ani konta Apple.

### Raz, na komputerze (~2 minuty)

1. Wejdź na stronę repozytorium na github.com.
2. **Settings → General → Danger Zone → Change visibility → Public.**
   W darmowym planie GitHub Pages działa tylko dla publicznych repozytoriów.
   (Workflow `pages.yml` celowo pomija wdrożenie, dopóki repo jest prywatne.)
3. **Settings → Pages → Build and deployment → Source: „GitHub Actions”.**
   Jednorazowo. Workflow nie jest w stanie zrobić tego sam — jego token może
   wdrażać na już włączone Pages, ale nie ma prawa ich włączyć
   (sprawdzone: `Resource not accessible by integration`).
4. **Actions → „Publikuj PWA (GitHub Pages)” → Run workflow** — albo po prostu
   dowolny push do `main`.
5. Po ~1 minucie aplikacja jest pod adresem:

   `https://krzysztofwolniarczyk-source.github.io/DJEMBE/`

   Jeśli zmienisz nazwę repozytorium, ostatni człon adresu zmieni się razem z nią.

### Na iPhonie

1. Otwórz ten adres w **Safari** (nie w Chrome — na iOS instalację na ekran
   początkowy najpewniej robi Safari).
2. Dotknij **Udostępnij** (kwadrat ze strzałką w górę) → **Dodaj do ekranu
   początkowego** → **Dodaj**.
3. Na ekranie pojawi się ikona **Bartek Jones**. Uruchamia się pełnoekranowo,
   po pierwszym otwarciu online działa też offline.

### Mikrofon

**Stroik → Włącz mikrofon** → na pytanie systemu **Zezwól**. Jeśli pytanie się
nie pojawi albo dostęp był wcześniej odrzucony: **Ustawienia → Safari →
Mikrofon → Zezwól** (albo **Pytaj**), a potem otwórz aplikację ponownie.

### Aktualizacje

Push do repozytorium — przy następnym otwarciu z internetem aplikacja pobierze
nową wersję. Postępy (poziomy, rekordy, statystyka słuchu) zostają na telefonie.

---

## Droga 2 — natywna aplikacja (IPA)

Workflow `ios.yml` buduje **IPA bez podpisu** (Releases → tag `ios`). Żeby
trafiła na telefon, trzeba ją podpisać przy instalacji:

| Sposób | Koszt | Jak długo działa | Co trzeba mieć |
|---|---|---|---|
| **AltStore** / **Sideloadly** | darmowe Apple ID | **7 dni** | komputer (Windows/macOS) |
| **Apple Developer Program** | 99 USD / rok | **1 rok** | konto dev; można budować wprost z Xcode na telefon |

**O komputerze córki:** jeśli to na nim chodzi AltServer, to on potrafi
**odświeżać aplikację automatycznie w tle** — wystarczy, że iPhone jest co
kilka dni w tej samej sieci Wi-Fi co ten komputer. To najbliższe „na stałe”,
jakie daje darmowe konto, ale limit to 3 aplikacje naraz i 7-dniowy certyfikat.
PWA z drogi 1 nie ma żadnego z tych ograniczeń.

W wersji natywnej strona jest podawana z wbudowanego serwera na
`http://127.0.0.1:28417` — dzięki temu stroik ma dostęp do mikrofonu także tutaj.
