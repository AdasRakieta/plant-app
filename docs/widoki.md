# Pędy — plan aplikacji natywnej iOS

Wersja 1.0 · 1 października 2026 · specyfikacja do przygotowania planu implementacji.

## Status ustaleń

Użytkownik zaakceptował kierunek wizualny „Terakotowy rytuał”, czyli drugi z trzech pokazanych wariantów, oraz dopracowany ekran szczegółów zadania. Nazwa Pędy zastąpiła roboczą nazwę Listwa. Ten dokument opisuje widoki, działanie i zależności; nie oznacza, że aplikacja jest już zaimplementowana lub że dostawca AI został wybrany. Wszystkie poniższe rozwiązania szczegółowe są propozycją projektową w ramach zaakceptowanego zakresu.

Najważniejsze wymagania: rzeczywiście natywna aplikacja iOS, estetyka iOS, zieleń/terakota/beż, kolekcja roślin, identyfikacja ze zdjęć, baza gatunków do wyszukiwania także przed zakupem, wymagania i właściwości gatunków, diagnoza objawów ze zdjęcia, przypomnienia o podlewaniu i nawożeniu oraz automatyczne łączenie czynności w sesje. Każde zadanie ma szczegóły wyjaśniające, jak wykonać kontrolę, jak powinny wyglądać liście i jak suche powinno być podłoże danego gatunku.

## System wizualny i nawigacja

- Ciepły beż #F5EBDD jako tło, terakota #B65D43 jako akcent i główne działania, ciemna zieleń #3C5240 jako uzupełnienie. Kolory tekstu dobierane po weryfikacji kontrastu.
- Natywna typografia systemowa, obsługa powiększania tekstu, ikony systemowe, duże obszary dotyku, czytelne grupy formularzy i subtelne separatory.
- Fotografie roślin wspierają orientację; instrukcje pozostają tekstowo dostępne. W produkcji zdjęcia referencyjne objawów muszą być zweryfikowane i mieć prawo do wykorzystania. Grafiki generowane do makiet nie są bazą diagnostyczną.
- Cztery główne zakładki: Dzisiaj, Rośliny, Atlas, Diagnoza. Ustawienia pod przyciskiem w nagłówku Dzisiaj. Przycisk dodawania dostępny w Roślinach i pustym ekranie Dzisiaj.
- Szczegóły mają natywną nawigację wstecz. Krótkie wybory, filtry i szybkie zapisy są arkuszami; aparat i porównanie zdjęć mogą zajmować cały ekran.
- Stan przewijania i filtry pozostają po powrocie. Rozpoczęta sesja oraz formularze nie znikają po przełączeniu zakładki.
- Wersja jasna jako podstawowy projekt; ciemna zachowuje ziemisty charakter. VoiceOver, tekstowe etykiety ikon, brak informacji przekazywanej wyłącznie kolorem, ograniczenie ruchu.

## Pełna mapa widoków

W tabelach „pełny” oznacza osobny ekran, „arkusz” krótszy formularz/wybór, a „stan” wariant istniejącego widoku. Widoki nie muszą odpowiadać oddzielnym plikom kodu.

### Pierwsze uruchomienie

| ID / forma | Widok i zawartość | Działania i przejścia |
|---|---|---|
| O01 · pełny | Powitanie: korzyść „Zadbaj o rośliny w jednym rytmie”, krótka informacja o kolekcji i planie | „Dodaj pierwszą roślinę” → A01; „Najpierw poznaj atlas” → B01. Bez obowiązkowego konta |
| O02 · arkusz | Preferencje pielęgnacji: preferowane dni i pora wspólnej sesji | Zapis → plan; „Później” pozostawia ustawienia domyślne. Dostępne ponownie w U02 |
| O03 · kontekstowy arkusz | Przypomnienia: wyjaśnienie, kiedy będą wysyłane | Prośba systemowa dopiero przy aktywacji przypomnień; odmowa nie blokuje aplikacji |

### Dzisiaj i wspólne sesje

| ID / forma | Widok i zawartość | Działania i przejścia |
|---|---|---|
| D01 · pełny | Dzisiaj: krótki pasek dni, najbliższa wspólna sesja, zadania wymagające kontroli wcześniej, rozróżnienie zaległych czynności | Dzień zmienia listę; sesja → D02; zadanie → T01; ustawienia → U01 |
| D02 · pełny | Szczegóły sesji: dzień, szacowany czas, rośliny, czynności w kolejności wykonania, powód wspólnego terminu | „Rozpocznij” → D03; zadanie → T01; zmiana dnia → D05 |
| D03 · pełny | Tryb sesji: jedna roślina/czynność naraz, postęp, instrukcja, wynik kontroli | Zapis wyniku, następne zadanie, pominięcie z powodem, przerwanie i wznowienie. Zakończenie → D04 |
| D04 · pełny | Podsumowanie sesji: wykonane działania, obserwacje, odłożone czynności i kolejne kontrole | Powrót do Dzisiaj; cofnięcie omyłkowego wpisu; przejście do konkretnej rośliny |
| D05 · arkusz | Zmień termin: dozwolone dni, zadania mieszczące się w wybranym dniu, pozostałe czynności | Podgląd zmian przed zapisem; niedopuszczalne przesunięcie nie jest oferowane jako rekomendacja |
| D06 · arkusz | Dlaczego taki plan: potrzeby roślin, ostatnie działania i preferencje użytkownika | Wyjaśnienie bez pozornie dokładnych prognoz; edycja preferencji → U02 |

### Szczegóły czynności

| ID / forma | Widok i zawartość | Działania i przejścia |
|---|---|---|
| T01 · pełny | Szczegóły zadania: zdjęcie/nazwa/stanowisko, cel, instrukcja dopasowana do gatunku, wybór wyniku | Kontrola podłoża → T02; kontrola liści → T04; instrukcja podlewania → T03; nawożenie → T06. Dotknięcie nazwy → P02 |
| T02 · wariant T01 | Sprawdź podłoże: gdzie i na jakiej głębokości sprawdzić, jaki stopień przesuszenia odpowiada temu gatunkowi/podłożu, jak rozpoznać wynik | „Wilgotne”, „Suche zgodnie z instrukcją”, „Nie wiem”. Wynik wilgotny zapisuje obserwację i planuje ponowną kontrolę; suchy pokazuje zalecenia, ale nie zapisuje automatycznie podlewania |
| T03 · wariant T01 + arkusz zapisu | Podlewanie: sposób wykonania, odpływ nadmiaru wody, instrukcja dla danej konfiguracji | „Podlano” zapisuje faktyczny termin; ilość opcjonalna, bez obowiązkowej uniwersalnej dawki; „Odłóż” z powodem |
| T04 · pełny | Jak powinny wyglądać liście: referencje właściwego gatunku/odmiany, młode i dojrzałe liście, naturalne różnice, widoczne zmiany warte kontroli | Przykład → T05; „Porównaj z moją rośliną” → zdjęcie; „Zauważyłem problem” → G01 |
| T05 · pełny | Szczegół przykładu: fotografia, zaznaczony obszar, opis cechy, kiedy może być naturalna, jakie dodatkowe informacje sprawdzić | Powrót do porównania; dodanie obserwacji; rozpoczęcie diagnozy. Przykład nie stanowi rozpoznania choroby |
| T06 · wariant T01 | Nawożenie: sezon, ostatni wpis, wymagania gatunku, typ nawozu, instrukcja oparta na etykiecie produktu | Zapis daty/nawozu/dawki opcjonalnej; odłożenie z powodem. Dawka nie może być zgadywana na podstawie samego gatunku |
| T07 · wariant T01 | Pozostałe czynności: kontrola szkodników, czyszczenie liści, obrót doniczki, przesadzanie, cięcie — tylko tam, gdzie uzasadnione | Odpowiednia instrukcja, zapis wykonania lub obserwacji, własna notatka. Nie tworzyć identycznych obowiązków dla każdego gatunku |
| T08 · arkusz | Szybki zapis i korekta: faktyczna data, czynność, notatka, opcjonalne zdjęcie | Edycja/cofnięcie wpisu przelicza plan; cofnięcie nie usuwa innych wpisów |

### Kolekcja i konkretna roślina

| ID / forma | Widok i zawartość | Działania i przejścia |
|---|---|---|
| P01 · pełny | Moje rośliny: fotografia, nazwa, stanowisko, najbliższa czynność; wyszukiwanie i grupowanie po pomieszczeniu | Dodaj → A01; karta → P02; filtr pomieszczeń i sortowanie |
| P02 · pełny | Profil rośliny: zdjęcie, własna nazwa i gatunek, stanowisko, najbliższe zadanie, skrót wymagań, ostatnia obserwacja | Zadanie → T01; wymagania → P03; historia → P05; warunki → P04; diagnoza → G01; menu → P07 |
| P03 · pełny | Wymagania i opis: światło, podłoże, wilgotność, temperatura, podlewanie, nawożenie, rozmiar/wzrost, właściwości, bezpieczeństwo dla zwierząt | Rozwinięcia instrukcji, porównanie wymagań z zapisanym stanowiskiem, referencje liści → T04; linki do źródeł |
| P04 · pełny formularz | Warunki konkretnej rośliny: pomieszczenie, kierunek okna, odległość, bezpośrednie słońce/rozproszone światło, doniczka i odpływ, podłoże, ostatnie znane działania | Zapis pokazuje wpływ na plan. Pola nieznane można zostawić; brak pomiarów nie oznacza dokładnej oceny światła |
| P05 · pełny | Historia: chronologiczne działania, obserwacje, zdjęcia i przypadki diagnozy | Filtry typu wpisu, nowy wpis → T08, szczegół/korekta wpisu; brak automatycznego oznaczania wszystkich zadań jako wykonane |
| P06 · pełny | Galeria postępów: zdjęcia z datami i porównanie dwóch zdjęć | Dodaj z aparatu/zdjęć; porównaj; usuń wybrane zdjęcie z potwierdzeniem |
| P07 · arkusz/menu | Edycja rośliny: nazwa, zdjęcie, korekta gatunku, archiwizacja, usunięcie | Korekta gatunku zachowuje historię i przelicza przyszłe zadania; usunięcie wyraźnie odróżnione od archiwizacji |
| P08 · arkusz + pełna lista | Pomieszczenia: nazwa i domyślne opisowe warunki stanowiska, przypisane rośliny | Dodaj/edytuj, przenieś roślinę; usunięcie pomieszczenia zachowuje rośliny i wymaga nowego przypisania lub „Bez pomieszczenia” |

### Dodawanie i identyfikacja

| ID / forma | Widok i zawartość | Działania i przejścia |
|---|---|---|
| A01 · arkusz | Dodaj roślinę: zrób zdjęcie, wybierz zdjęcie, wyszukaj gatunek, dodaj nierozpoznaną | Aparat/zdjęcia → A02; ręcznie → B01 w trybie wyboru; nierozpoznana → A04 |
| A02 · pełny + stan analizy | Zdjęcie do identyfikacji: wskazówki kadrowania, podgląd, możliwość dodatkowego ujęcia | Użytkownik zatwierdza wysłanie do analizy; ponowne zdjęcie; anulowanie. Informacja, że zdjęcie jest analizowane przez usługę zewnętrzną |
| A03 · pełny | Wynik identyfikacji: kandydat/kandydaci, zdjęcia porównawcze, cechy odróżniające, poziom niepewności | Potwierdź gatunek → A04; dodatkowe zdjęcie; ręczne wyszukanie; „Nie wiem” zapisuje roślinę nierozpoznaną. Bez wymuszania pewności |
| A04 · pełny formularz | Dane początkowe: własna nazwa, miejsce, podłoże/doniczka, ostatnie podlewanie jeśli znane | Zapis → A05; nieznane wartości są jawnie nieznane. Nie domyślać się ostatniej daty |
| A05 · pełny | Pierwszy plan: podsumowanie potrzeb, początkowe kontrole, dopasowanie do wspólnej sesji | Potwierdzenie zapisu kolekcji i preferencji → P02 lub D01; możliwość korekty danych |

### Atlas i wybór przed zakupem

| ID / forma | Widok i zawartość | Działania i przejścia |
|---|---|---|
| B01 · pełny | Atlas: wyszukiwanie nazw polskich/łacińskich i synonimów, lista wyników z fotografią i skrótem warunków | Gatunek → B03; filtry → B02; w trybie dodawania wybór gatunku prowadzi do A04 |
| B02 · arkusz | Filtry: tolerowane warunki światła, trudność, rozmiar, bezpieczeństwo dla zwierząt | Zastosuj/wyczyść. Przy niepotwierdzonych danych oznaczenie „Brak danych”, nie domniemanie bezpieczeństwa |
| B03 · pełny | Karta gatunku: zdjęcia, nazwy, opis, wymagania, właściwości, referencje liści i źródła | „Dodaj do moich roślin” → A04; „Sprawdź dopasowanie” → B04; ulubione → B05 |
| B04 · pełny | Czy pasuje do mojego domu: wybór stanowiska, porównanie jego opisowych warunków z potrzebami gatunku, braki danych | Wskazówki, co zmienić/sprawdzić; edycja stanowiska. Bez pozornie dokładnego procentu dopasowania |
| B05 · pełny | Zapisane do zakupu: ulubione gatunki i krótkie notatki | Karta gatunku, usuń z listy, „Już mam” → A04. Bez koszyka i sklepu internetowego w podstawowym zakresie |

### Diagnoza ze zdjęcia

| ID / forma | Widok i zawartość | Działania i przejścia |
|---|---|---|
| G01 · pełny | Start diagnozy: wybór swojej rośliny lub rośliny spoza kolekcji, krótki opis objawu | Aparat/zdjęcia → G02; kontynuacja wcześniejszego przypadku → G06 |
| G02 · pełny | Zdjęcia objawów: cała roślina, zbliżenie problemu, opcjonalnie spód liścia/podłoże | Dodaj, zamień, usuń ujęcie; wskazówki ostrości; dalej → G03 |
| G03 · pełny formularz | Pytania: kiedy objaw wystąpił, ostatnie podlewanie/nawóz, światło, zmiana miejsca, szkodniki | Wstępne wartości z historii do potwierdzenia; „Nie wiem”; wysłanie → G04 |
| G04 · stan | Analiza: informacja o wysyłaniu/przetwarzaniu, zachowany szkic | Anuluj; bez duplikowania żądań przy ponowieniu; błąd → zachowany formularz |
| G05 · pełny | Wynik: możliwe przyczyny uporządkowane według zgodności z danymi, poziom niepewności, czego jeszcze nie wiadomo, zalecane kontrole i działania | Rozwiń przyczynę, dodaj zdjęcie, zapisz przypadek, dodaj wybrane działania do planu. AI nie zapisuje automatycznie leczenia/nawożenia |
| G06 · pełny | Obserwacja przypadku: zdjęcia przed/po, zalecenia, wykonane kroki, termin ponownej kontroli | Aktualizacja, ponowna analiza z kontekstem, oznaczenie poprawy/braku poprawy/zamknięcia; historia pozostaje |

### Ustawienia

| ID / forma | Widok i zawartość | Działania i przejścia |
|---|---|---|
| U01 · pełny | Ustawienia: plan, powiadomienia, wygląd, dane i prywatność, pomoc | Przejścia do poniższych ekranów; brak obowiązkowego logowania w lokalnej wersji |
| U02 · pełny formularz | Rytm pielęgnacji: preferowane dni/pora, stopień grupowania, przerwa/wyjazd | Podgląd wpływu na plan; okres wyjazdu pokazuje zadania, które wymagają opiekuna zamiast odkładać wszystko |
| U03 · pełny | Powiadomienia: wspólne podsumowanie, pilne kontrole, pora, status zgody systemowej | Przykład treści, aktywacja/wyłączenie; przy odmowie link do ustawień systemowych |
| U04 · pełny | Wygląd i dostępność: jasny/ciemny/systemowy, preferencje animacji zgodne z systemem | Podgląd wyglądu. Rozmiar tekstu i VoiceOver obsługiwane systemowo |
| U05 · pełny | Dane i prywatność: lokalne dane, przesyłanie zdjęć, zasady retencji po wyborze dostawcy, eksport i usuwanie | Eksport historii/kolekcji; usuwanie z wyraźnym potwierdzeniem. Nie obiecywać synchronizacji lub retencji, której jeszcze nie wdrożono |
| U06 · pełny | Pomoc i źródła: działanie planera, ograniczenia rozpoznawania, źródła atlasu, zgłoszenie błędnych informacji | Instrukcje; przejście do odpowiedniego ekranu; dane źródła i data aktualizacji treści |

## Przejścia kluczowych procesów

1. Dodawanie: Rośliny → Dodaj → aparat/zdjęcie → kandydaci → potwierdzenie gatunku → warunki konkretnej rośliny → pierwszy plan → profil.
2. Pielęgnacja: Dzisiaj → sesja → kontrola podłoża/liści → obserwacja → ewentualna instrukcja działania → faktyczny zapis wykonania → następne zadanie → podsumowanie.
3. Kupno: Atlas → filtry → karta gatunku → porównanie ze stanowiskiem → zapis do zakupu → po zakupie dodanie egzemplarza do kolekcji.
4. Problem: profil lub szczegół zadania → diagnoza → zdjęcia → pytania → możliwe przyczyny → wybrane kontrole do planu → obserwacja efektów.

## Logika planera

Planowanie opiera się na wymaganiach gatunku, warunkach egzemplarza, sezonie i rzeczywistych zapisach. Nie przyjmuje uniwersalnego „podlewaj co 7 dni”. Terminy są prognozami kontroli; nowe obserwacje mogą je skorygować.

Każda czynność ma najwcześniejszy dopuszczalny termin, termin preferowany, najpóźniejszy dopuszczalny termin i priorytet. Kontrola wymagająca oceny użytkownika ma stan oczekujący na wynik. Okna terminów wynikają z reguł pielęgnacji, a nie z chęci dopasowania wszystkich roślin za wszelką cenę.

Algorytm wybiera wspólne dni tam, gdzie okna się pokrywają, preferując dni użytkownika i ograniczając liczbę sesji. Czynności pilne lub niemieszczące się we wspólnym terminie pozostają oddzielne. Grupowanie obejmuje też wiele czynności przy jednej roślinie; kolejność uwzględnia zależności, np. najpierw kontrola podłoża, później ewentualne podlewanie.

Przykład: kontrola rośliny A mieści się między piątkiem a niedzielą, B między sobotą a poniedziałkiem, a C wymaga sprawdzenia w czwartek. Plan proponuje A+B w sobotę, C w czwartek. Gdy A jest nadal wilgotna, zapisuje kontrolę i wyznacza następną; nie oznacza podlewania jako wykonanego.

Zapis podlewania, korekta daty, zmiana gatunku/podłoża, odłożenie czynności i aktualizacja przypadku diagnozy przeliczają przyszły plan oraz przypomnienia. Historia pozostaje niezmieniona poza jawną edycją. Nadrobienie zaległości nie generuje podwójnych dawek ani dwóch takich samych czynności jednocześnie.

Powiadomienia domyślnie zbierają czynności w jedno podsumowanie sesji. Osobny komunikat tylko dla ważnej kontroli poza sesją. Otwarcie powiadomienia prowadzi do właściwego zadania lub sesji; usunięty wpis ma bezpieczne przekierowanie do aktualnego planu.

## Dane i odpowiedzialności

| Obiekt | Najważniejsze dane / odpowiedzialność |
|---|---|
| Gatunek | Nazwy/synonimy, opis, wymagania, właściwości, bezpieczeństwo, reguły sezonowe, referencje fotograficzne, źródła i daty aktualizacji |
| Egzemplarz | Własna nazwa, potwierdzony lub nieznany gatunek, zdjęcia, stanowisko, podłoże/doniczka, indywidualne ustawienia |
| Stanowisko | Pomieszczenie, opis światła, kierunek okna, odległość, opcjonalne obserwacje warunków |
| Czynność | Typ, powiązany egzemplarz, dopuszczalne okno, priorytet, instrukcja, wynik/stan, zależności |
| Sesja | Wybrany dzień, czynności, kolejność, postęp i wyjaśnienie grupowania |
| Wpis historii | Faktyczna data, czynność/obserwacja, notatka, zdjęcia, korekty |
| Przypadek diagnozy | Zdjęcia, odpowiedzi, możliwe przyczyny, niepewność, wybrane kroki i przebieg obserwacji |
| Preferencje | Dni/pora, powiadomienia, wygląd, zgody na analizę zdjęć |

Rozpoznawanie zdjęć proponuje gatunek; użytkownik go zatwierdza. Atlas ma opracowane i zweryfikowane treści, a nie opisy generowane na nowo bez kontroli. Diagnoza formułuje hipotezy i następne kroki. Planer działa według jawnych reguł i obserwacji; nie wymaga odpowiedzi AI do wyświetlenia codziennych zadań.

## Stany wspólne i wyjątki

- Pusta kolekcja: zachęta do dodania lub wejścia do atlasu; pusty plan nie wygląda jak błąd.
- Brak zadań: komunikat o braku czynności i najbliższa sesja, bez sztucznego tworzenia obowiązków.
- Brak wyników w atlasie: zmiana zapytania/filtrów; możliwość zapisania nierozpoznanej rośliny.
- Nierozpoznana roślina: zachowane zdjęcie i notatki, ponowna identyfikacja; brak szczegółowych zaleceń opartych na zgadywanym gatunku.
- Brak internetu: dostęp do lokalnej kolekcji, historii, zapisanych treści i planu; analiza zdjęć wymaga ponowienia po odzyskaniu połączenia.
- Brak zgody na aparat/zdjęcia/powiadomienia: ręczne alternatywy i możliwość otwarcia ustawień, bez zapętlania próśb.
- Niewyraźne zdjęcie albo niepewna analiza: prośba o inne ujęcie/dodatkowe dane, żadnej wymuszonej diagnozy.
- Błąd usługi AI/limit: szkic zachowany, jasne ponowienie bez dublowania przypadku.
- Zadania zaległe: kontrola bieżącego stanu, nie mechaniczne wykonanie wszystkich dawnych podlewań.
- Zmiana strefy/czasu, restart i wyjście z aplikacji: plan zgodny z preferencjami użytkownika, zachowany postęp sesji, odtworzone przypomnienia.
- Usunięcie/archiwizacja rośliny: aktualizacja planu i przypomnień, wyraźna informacja o skutkach dla historii.
- Wycofanie zgody na analizę: lokalne funkcje dalej działają; nowe zdjęcia nie są automatycznie przesyłane.

## Zakres i kolejność późniejszego planu implementacji

1. Fundament natywny i system wizualny: nawigacja, trwały lokalny zapis, modele danych, komponenty i dostępność. Preferowany kierunek: SwiftUI; konkretny minimalny iOS i rozwiązanie zapisu do ustalenia przy planie technicznym.
2. Kolekcja i atlas: ręczne dodawanie, stanowiska, profile, instrukcje i wiarygodna baza treści z licencjonowanymi zdjęciami.
3. Zadania i historia: kontrola podłoża/liści, zapis wykonania, korekty, galeria.
4. Planer i powiadomienia: okna czynności, grupowanie, sesje, ponowne planowanie oraz działanie po restarcie i zmianie czasu.
5. Identyfikacja zdjęć: aparat, potwierdzanie gatunku, backend i wybrany dostawca; klucze usług pozostają po stronie serwera.
6. Diagnoza: zdjęcia/pytania, niepewność, zapis przypadku, działania do planu i obserwacja efektów.
7. Dopracowanie i wydanie: ustawienia, eksport/usuwanie, stany błędów/offline, dostępność, testy na fizycznym iPhonie i dystrybucja testowa.

Pierwsza kompletna wersja powinna zawierać wszystkie główne wymagania, w tym identyfikację, diagnozę i grupowanie. Etapy oznaczają kolejność budowy, nie zgodę na pominięcie funkcji. Synchronizacja między urządzeniami, współdzielenie kolekcji, widżety, integracje z czujnikami i sklep nie są wymaganiami podstawowymi; można je rozważyć później.

Projekt pozostaje natywny. Podgląd graficzny lub interaktywny prototyp nie może być przedstawiony jako gotowa aplikacja iOS. Budowa, podpisywanie i testy natywnego wydania wymagają odpowiedniego środowiska Apple; dostępność tego środowiska trzeba sprawdzić przy planie implementacji.

## Kryteria odbioru

- Każde zadanie prowadzi do instrukcji odpowiadającej gatunkowi i warunkom konkretnej rośliny.
- Liście można porównać z właściwym gatunkiem/odmianą; podłoże ma opis sposobu sprawdzenia i oczekiwanego przesuszenia, nie samą etykietę „suche”.
- „Wilgotne” zapisuje kontrolę i koryguje plan; podlewanie wymaga osobnego potwierdzenia wykonania.
- Sesja grupuje czynności tylko w dopuszczalnych terminach i zachowuje postęp po przerwaniu.
- Można rozpoznać roślinę ze zdjęcia i skorygować wynik; można też dodać ją ręcznie bez internetu.
- Atlas obsługuje wyszukiwanie i dobór przed zakupem; pola bez danych nie mają wymyślonych wartości.
- Diagnoza pokazuje niepewność, dodatkowe pytania i działania, które użytkownik świadomie dodaje do planu.
- Podstawowe widoki działają z powiększonym tekstem, VoiceOver oraz przy odmowie opcjonalnych uprawnień.
- Powiadomienie prowadzi do aktualnego zadania, a poprawki i usunięcia nie zostawiają starych przypomnień.

## Skrót do kontynuacji rozmowy

Rozwijamy Pędy: natywną aplikację iOS do pielęgnacji roślin, UI po polsku, zaakceptowany wariant 2 „Terakotowy rytuał” i szczegóły kontroli podłoża. Cztery zakładki Dzisiaj/Rośliny/Atlas/Diagnoza. Klikalne zadania uczą wykonania kontroli i pokazują referencje liści. Wyniki obserwacji korygują plan. Planer grupuje czynności w bezpiecznych oknach i nie nakazuje podlewania wyłącznie według kalendarza. Wymagane są identyfikacja zdjęć z potwierdzeniem, wyszukiwalny atlas i diagnoza objawów z niepewnością. Ten dokument jest podstawą dalszego planu implementacji; nie wybrano jeszcze dostawcy AI ani źródła bazy, minimalnego iOS, synchronizacji lub modelu kosztowego.
