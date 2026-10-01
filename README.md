# Pędy

Natywna aplikacja iOS do pielęgnacji domowych roślin. Kod zawiera pierwszy fragment: lokalną kolekcję, wspólne planowanie kontroli podłoża, szczegóły kontroli i historię obserwacji. Pierwszy build i test na iPhonie są jeszcze przed nami; to początek implementacji, nie komplet opisany w specyfikacji.

## Uruchomienie

Wymagane: macOS, Xcode z SDK iOS i [XcodeGen](https://github.com/yonaskolb/XcodeGen). W katalogu repozytorium:

```sh
xcodegen generate
open Pedy.xcodeproj
```

W Xcode wybierz schemat `Pedy` i symulator iPhone. Docelowo iOS 17+. Testy: `xcodebuild test -project Pedy.xcodeproj -scheme Pedy -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO` (nazwa dostępnego symulatora może się różnić). Projekt jest aplikacją SwiftUI ze SwiftData; nie osadza strony WWW.

Ta sesja robocza ma środowisko Linux bez Swift i Xcode, dlatego kompilacja iOS nie została tu wykonana. GitHub Actions na macOS weryfikuje projekt po publikacji repozytorium i produkuje **niepodpisany** plik IPA z builda dla urządzenia. Pierwszą kompilację oraz zachowanie w symulatorze trzeba sprawdzić przed uznaniem etapu za ukończony.

## Stan i dalsza praca

Pełna mapa: [docs/widoki.md](docs/widoki.md). Architektura, etapy i kryteria: [docs/architektura.md](docs/architektura.md). Pierwszy fragment obejmuje dodanie własnej rośliny, wybór daty i odstępu kontroli, plan wspólnej sesji, kontrolę wilgotności, jawny zapis podlewania i historię. Nie używa jeszcze bazy gatunków, zdjęć, diagnozy ani powiadomień. Tekst o podłożu jest ogólny; treści zależne od gatunku pojawią się po opracowaniu zweryfikowanego atlasu.

Nie wpisuj kluczy usług analizy zdjęć do aplikacji ani repozytorium. Zdjęcia i historia są danymi użytkownika; ich eksport/usuwanie oraz zasady wysyłania zostaną ukończone przed wydaniem.

Dystrybucja bez Maca: [SideStore, GitHub Actions i Raspberry Pi](docs/dystrybucja.md). Plik IPA z CI jest instalowany i podpisywany przez SideStore na iPhonie. Raspberry Pi może przechowywać kolejne wersje przez Tailscale, ale nie odnawia sama podpisu SideStore.
