# Projekt: Analýza finančních dat pomocí SQL

Tento projekt je součástí workshopu z kurzu **SQL - datová analýza** od Coders Lab. Cílem je shrnout a upevnit získané znalosti a zároveň si vyzkoušet práci datového analytika ve finančním sektoru. Analýza je prováděna na **anonymizované databázi české banky**, která obsahuje reálná data o klientech, bankovních účtech, transakcích, půjčkách a platebních kartách.

---

**Klíčové úkoly a cíle projektu**

Během řešení workshopu jsem se zaměřila na několik hlavních oblastí, abych provedla ucelenou analýzu finančních dat a získala cenné poznatky.

**1. Historie poskytnutých úvěrů:**
- Vytvoření souhrnu poskytnutých půjček, rozděleného podle roku, čtvrtletí a měsíce.
- Výsledky zahrnují celkovou částku, průměrnou částku a počet půjček.

**2. Stav půjček a analýza účtů:**
- Identifikace, které statusy v databázi odpovídají splaceným a nesplaceným půjčkám.
- Seřazení bankovních účtů podle počtu splacených půjček, jejich celkové částky a průměrné částky.

**3. Analýza klientů podle pohlaví a věku:**
- Zjištění, zda mají více splacených půjček ženy nebo muži.
- Výpočet průměrného věku dlužníků, rozdělený podle pohlaví.

**4. Geografická analýza klientů:**
- Určení okresu s nejvyšším počtem klientů.
- Identifikace okresu s nejvyšším počtem splacených půjček a nejvyšší celkovou splacenou částkou.
- Výpočet procentuálního podílu každého okresu na celkové částce splacených půjček.

**5. Výběr klientů na základě specifických kritérií:**
- Vyhledání klientů, kteří splňují kombinaci tří podmínek: zůstatek na účtu > 1000, více než 5 půjček a datum narození po roce 1990.
- Analýza, která z těchto podmínek je nejvíce omezující a vede k prázdnému výsledku.

**6. Správa vypršení platnosti karet:**
- Vytvoření uložené procedury pro automatické generování a aktualizaci tabulky `cards_at_expiration`.
- Tato tabulka obsahuje informace o klientech, jejich kartách, datu vypršení platnosti (3 roky od vydání) a adrese klienta.

---

## Klíčové poznatky a výsledky

- **Stav půjček**: Z celkových 682 půjček bylo 606 splaceno, zatímco 76 zůstalo nesplacených.
- **Profil klientů**: Zjistilo se, že ženy splatily o něco více půjček (307) než muži (299).
- **Geografické dominanty**: Okres Praha se ukázal jako dominantní ve všech sledovaných kategoriích – měl nejvíce klientů, nejvíce splacených půjček a nejvyšší celkovou splacenou částku.
- **Omezené výsledky**: Analýza výběrových kritérií ukázala, že v datové sadě se nevyskytují klienti, kteří by splňovali všechny tři podmínky pro vyhledávání (věk, počet půjček a zůstatek na účtu). Důvodem je, že žádný klient se nenarodil po roce 1990 a žádný klient neměl více než 5 půjček.
- **Automatizace**: Úspěšně byla vytvořena uložená procedura, která zefektivňuje proces správy dat o vypršení platnosti karet.

---

