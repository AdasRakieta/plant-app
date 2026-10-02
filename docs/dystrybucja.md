# Pobieranie Pędów i odnawianie podpisu SideStore

Stan: 2 października 2026. Repo zawiera konfigurację do uruchomienia na Raspberry Pi; instalacja na Pi i test na iPhonie wymagają dostępu do tych urządzeń.

## Ustalone działanie

1. GitHub Actions buduje **niepodpisane** `Pedy-unsigned.ipa` dla iPhone'a. Pi co 6 godzin sprawdza artefakty z `main`, wybiera najnowszy przebieg zakończony sukcesem, weryfikuje strukturę IPA i zapisuje go pod stałą nazwą `/srv/pedy/Pedy.ipa`. Lokalna kopia pozostaje dostępna także po wygaśnięciu artefaktu GitHub lub chwilowym błędzie pobrania.
2. Pi udostępnia stronę w sieci domowej pod `http://192.168.1.218:8787/app/` oraz prywatnie w Tailscale pod `https://malina.tail384b18.ts.net/app/`. Pod oboma adresami jest `Pedy.ipa`, ikona i źródło SideStore. Tailscale Serve wymaga włączenia HTTPS w tailnecie i dostępu tego urządzenia zgodnie z regułami tailnetu. Nie używamy publicznego Funnel.
3. SideStore na iPhonie podpisuje i instaluje pobrane IPA. To samo IPA można pobrać wielokrotnie; Pi nie przechowuje konta Apple, certyfikatu SideStore ani pliku parowania.
4. SideStore okresowo odnawia podpis własny i aplikacji w tle, pod warunkiem że iOS da mu czas oraz spełnione są warunki sieciowe. Pi nie może wymusić tego odnowienia.

## Instalacja na Pi

Najpierw opublikować aktualny kod i uzyskać zielony przebieg workflow `iOS`. Na Pi z połączonym Tailscale sklonować repo i z jego katalogu głównego uruchomić:

```sh
sudo bash pi/install.sh
```

Instalator zapyta o fine-grained token GitHub ograniczony do repo `AdasRakieta/plant-app`, z uprawnieniem `Actions: read`. Zapisze go w `/etc/pedy/github.env` z prawami `0600`. Jeśli plik już istnieje, pozostawi go. Zainstaluje usługi `pedy-fetch.timer` i `pedy-serve.service`, stronę i ikonę; pobierze IPA oraz doda `/app` do Tailscale Serve, jeśli ta ścieżka jest wolna. Nie zastępuje istniejącej konfiguracji innych ścieżek Serve.

Sprawdzić na Pi:

```sh
systemctl status pedy-fetch.timer pedy-serve.service
sudo systemctl start pedy-fetch.service
sudo journalctl -u pedy-fetch.service -n 30 --no-pager
(cd /srv/pedy && sha256sum -c Pedy.sha256)
curl -I http://127.0.0.1:8787/app/Pedy.ipa
tailscale serve status
```

Następnie otworzyć oba adresy `/app/` na iPhonie. Adres LAN wymaga połączenia z domowym Wi-Fi i dostępu do portu TCP 8787 na Pi. Jeśli na Pi działa zapora, dopuścić ten port tylko z podsieci domowej. Adres Tailscale wymaga aktywnego Tailscale na telefonie. Jeśli `/app` w Serve było już zajęte, sprawdzić jego cel i zwolnić ścieżkę przed ponownym uruchomieniem instalatora.

## Podpis i odświeżanie na iPhonie

1. Zainstalować SideStore pierwszy raz przez iloader na komputerze, wgrać plik parowania do SideStore i wykonać pierwsze ręczne odświeżenie samego SideStore. Plik parowania zachować poza repo i Pi.
2. W domu pobrać IPA z lokalnego `/app/`. Poza domem pobrać je przez Tailscale do Plików, a następnie przełączyć VPN z Tailscale na LocalDevVPN. Do instalowania i odświeżania SideStore wymaga Wi-Fi oraz LocalDevVPN. Na iPhonie nie należy zakładać równoczesnego działania obu VPN.
3. Otworzyć IPA w SideStore albo dodać źródło przyciskiem na stronie `/app/`. Strona lokalna dodaje `source-local.json` z lokalnym URL IPA; strona Tailscale dodaje `source.json` z adresem tailnetu. Ze względu na wymagany LocalDevVPN najpewniejsza instalacja w domu to lokalny URL. Przy aktualizacji nie usuwać starej aplikacji; ten sam identyfikator pozwala zachować jej dane. Potwierdzić to na urządzeniu po pierwszej aktualizacji.
4. Włączyć odświeżanie aplikacji w tle dla SideStore, pozostawić dostęp do Wi-Fi i LocalDevVPN. Tryb niskiego zużycia energii i tryb niskiego transferu danych ograniczają odświeżanie w tle. Regularnie sprawdzać w `My Apps` liczniki SideStore i Pędów; kilka dni przed wygaśnięciem wykonać ręczne odświeżenie obu.

Automatyzacja Skrótów uruchamiana po dołączeniu do domowego Wi-Fi może przypominać o sprawdzeniu SideStore. Jeśli konkretna wersja iOS oraz LocalDevVPN udostępnia działające sterowanie VPN w Skrótach, można przetestować jej włączenie. Nie traktować takiej automatyzacji jako gwarancji podpisu: SideStore nie udostępnia udokumentowanej akcji Skrótów do odnowienia podpisu. Przycisk `Refresh` w SideStore pozostaje drogą awaryjną.

SideStore zgłaszał błąd parametru `appIdName` dla nazwy `Pędy`. Dlatego nazwa pakietu i nazwa aplikacji w źródle są teraz ASCII: `Pedy`; nazwa strony i interfejsu pozostaje „Pędy”. Identyfikator aplikacji `pl.pedy.app` nie zmienia się. Nowy IPA zawiera ikonę oraz `CFBundleShortVersionString` i `CFBundleVersion`, których źródło wymaga do pokazywania aktualizacji.

**Po wygaśnięciu:** jeśli wygasły Pędy, a SideStore działa, włączyć Wi-Fi i LocalDevVPN oraz spróbować odświeżyć lub ponownie wgrać tę samą wersję IPA bez usuwania aplikacji. Jeśli wygasł sam SideStore i nie otwiera się, trzeba zainstalować go ponownie przez iloader na komputerze, potem odświeżyć Pędy. Gdy wygasł plik parowania, utworzyć go ponownie w iloader. Pi i lokalne połączenie nie mogą samodzielnie wskrzesić wygasłego SideStore.

## Warunki odbioru

- Zielony przebieg `iOS` na `main`; `build.json` na Pi wskazuje jego `run_id`.
- Oba adresy `/app/Pedy.ipa` pobierają identyczne bajty, zgodne z `Pedy.sha256`.
- Oba warianty źródła zawierają identyfikator `pl.pedy.app`, numer wersji i adres IPA odpowiedni dla użytego połączenia.
- Po aktualizacji przez SideStore dane aplikacji pozostają na iPhonie.
- Ręczne odświeżenie SideStore i Pędów działa na domowym Wi-Fi z LocalDevVPN; po kilku dniach sprawdzony zostaje również rzeczywisty przebieg w tle.

Źródła: [SideStore FAQ](https://docs.sidestore.io/docs/faq), [źródła SideStore](https://docs.sidestore.io/docs/advanced/app-sources), [format AltSource](https://faq.altstore.io/developers/make-a-source), [błąd `appIdName` w SideStore](https://github.com/SideStore/SideStore/issues/1489), [wymagania SideStore](https://docs.sidestore.io/docs/installation/prerequisites), [instalacja i odzyskiwanie SideStore](https://docs.sidestore.io/docs/installation/install), [plik parowania](https://docs.sidestore.io/docs/advanced/pairing-file), [Tailscale Serve](https://tailscale.com/docs/reference/tailscale-cli/serve), [automatyzacje iOS](https://support.apple.com/guide/shortcuts/add-automations-apdfbdbd7123/ios).
