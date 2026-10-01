# Budowa, pobieranie i odświeżanie Pędów bez Maca

Stan planu: 1 października 2026. To instrukcja dla GitHub Actions, iPhone'a, komputera PC potrzebnego do jednorazowej instalacji SideStore oraz Raspberry Pi w domowej sieci. Komendy na Pi są przygotowane do uruchomienia po pierwszym poprawnym buildzie; nie zostały wykonane na urządzeniach użytkownika.

## Dwie różne czynności

1. **Budowa:** GitHub Actions uruchamia Xcode na `macos-latest`, testuje aplikację i publikuje artefakt `pedy-unsigned-ipa` zawierający `Pedy-unsigned.ipa`. To plik dla prawdziwego iPhone'a, a nie build symulatora. Jest **niepodpisany**.
2. **Podpis i instalacja:** SideStore na iPhonie używa konta Apple do podpisania/importu IPA i odświeża zainstalowaną aplikację. Raspberry Pi nie tworzy ani nie odnawia tego podpisu. Przechowuje najnowszy plik instalacyjny i udostępnia go prywatnie.

## Wariant bezpłatny: SideStore + Pi

1. Po publikacji repozytorium sprawdzić zielony przebieg workflow `iOS` i pobrać artefakt. Dopiero wtedy instalować plik na telefonie.
2. Zainstalować SideStore pierwszy raz za pomocą iloader na PC i przewodu USB. SideStore wymaga konta Apple, Wi‑Fi i aplikacji LocalDevVPN podczas instalowania, aktualizowania oraz odświeżania. Zachować plik parowania tylko w zaufanym miejscu; **nie dodawać go do repo ani Pi**.
3. Na Raspberry Pi ustawić Tailscale w tym samym tailnecie co iPhone. Utworzyć osobne konto systemowe `pedy`, `/opt/pedy` z `fetch_ipa.py`, `/srv/pedy` jako katalog odczytu oraz `/etc/pedy/github.env` z `PEDY_REPO=AdasRakieta/plant-app`, `PEDY_SERVE_DIR=/srv/pedy` i tokenem `GH_READ_TOKEN`. Token o minimalnym dostępie tylko do odczytu artefaktów repo; plik środowiska właściciel root, tryb `0600`, nigdy w repo. Repo jest obecnie publiczne; kiedy artefakty publicznego repo można pobrać bez uwierzytelnienia, skrypt można rozszerzyć o taki tryb zamiast tworzyć token.
4. Umieścić `pedy-fetch.service` i `.timer` w systemd, włączyć timer. Skrypt co 6 h pobiera najnowszy artefakt z gałęzi `main`, weryfikuje strukturę IPA i zapisuje atomowo `/srv/pedy/Pedy.ipa` wraz z `build.json` i SHA-256. Najpierw uruchomić usługę ręcznie i sprawdzić log oraz sumę.
5. Udostępnić katalog przez `tailscale serve --bg /srv/pedy` (po włączeniu HTTPS w tailnecie). Potwierdzić `tailscale serve status`; używać **Serve**, nie Funnel. Adres jest dostępny dla urządzeń uprawnionych w tailnecie.
6. Na iPhonie włączyć Tailscale, pobrać `Pedy.ipa` z prywatnego adresu maliny do aplikacji Pliki. Następnie wyłączyć Tailscale, włączyć LocalDevVPN przy połączeniu Wi‑Fi i otworzyć pobrany plik w SideStore. Podczas testu sprawdzić, czy SideStore aktualizuje tę samą aplikację i zachowuje lokalne dane; stały identyfikator aplikacji jest konieczny.
7. Utrzymywać włączone Wi‑Fi i LocalDevVPN wtedy, gdy SideStore ma odnawiać podpis, oraz okresowo sprawdzić licznik ważności w `My Apps`. Automatyczne odświeżanie w tle jest funkcją SideStore, ale rzeczywisty przebieg zależy od iOS i warunków sieciowych; nie zakładać, że timer Raspberry Pi zastępuje tę czynność.

Na iOS nie można opierać tej procedury na jednocześnie aktywnych Tailscale i LocalDevVPN. Pi może pobierać nową wersję IPA bez udziału telefonu, lecz instalacja aktualizacji i odnowienie 7-dniowego podpisu odbywają się przez SideStore na iPhonie. Zdalne pobranie z Pi na sieci komórkowej jest możliwe przez Tailscale; samo odświeżenie SideStore według jego dokumentacji wymaga Wi‑Fi i LocalDevVPN.

## Gdy Tailscale ma być jedynym VPN na iPhonie

To wymaga **innej ścieżki podpisu niż darmowy SideStore**. Po dołączeniu do płatnego Apple Developer Program można zarejestrować iPhone'a, utworzyć certyfikat dystrybucyjny i profil Ad Hoc dla jego UDID, a następnie skonfigurować GitHub Actions do podpisanego archiwum. Apple opisuje też manifest do instalacji over-the-air. Wtedy Pi może serwować podpisany IPA i manifest przez HTTPS w Tailscale, bez LocalDevVPN na iPhonie. Certyfikat i profil trzeba odnawiać zgodnie z ich terminami; wybór ten wymaga konta programu i oddzielnego, kontrolowanego zarządzania sekretami CI. **Nie jest teraz skonfigurowany** i nie należy podmieniać niepodpisanego IPA w tej ścieżce. TestFlight jest jeszcze inną opcją przy płatnym koncie, lecz nie spełnia wymogu prywatnego pobierania z Pi.

## Operacyjna lista kontrolna po założeniu repo

- Workflow kompiluje na macOS, testy przechodzą i artefakt ma `Payload/Pedy.app/Info.plist`.
- Na Pi jest wyłącznie token do odczytu jednego repo, a katalog z IPA nie jest publicznym Funnel.
- iPhone pobiera IPA przez Tailscale, SideStore instaluje go po przełączeniu na LocalDevVPN i Wi‑Fi.
- Dane kolekcji pozostają po aktualizacji; wersja i identyfikator pakietu nie zmieniają się przypadkowo.
- Odświeżenie podpisu przechodzi test na iPhonie kilka dni przed upływem ważności, także po restarcie i aktualizacji iOS.

Źródła do weryfikacji przy konfiguracji: [SideStore prerequisites](https://docs.sidestore.io/docs/installation/prerequisites), [SideStore install](https://docs.sidestore.io/docs/installation/install), [SideStore FAQ](https://docs.sidestore.io/docs/faq), [Tailscale Serve](https://tailscale.com/docs/features/tailscale-serve), [Tailscale o wielu VPN](https://tailscale.com/docs/reference/faq/other-vpns), [Apple Ad Hoc](https://developer.apple.com/help/account/provisioning-profiles/create-an-ad-hoc-provisioning-profile), [Apple dystrybucja](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases).
