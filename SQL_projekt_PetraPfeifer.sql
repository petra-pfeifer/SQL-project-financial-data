-- Struktura databáze:
-- Primární klíče: 
-- Card - card_id
-- Loan - loan_id
-- Order - order_id
-- Trans - trans_id
-- Disp - disp_id
-- Account - account_id
-- Client - client_id
-- District - district_id

-- Vztahy mezi tabulkami:
--	District a client: vztah 1:N (one-to-many), jeden okres může mít více klientů, ale každý klient pouze jeden okres
--	District a account: vztah 1:N, jeden okres může mít mnoho bankovních účtů, ale každý účet je přiřazen pouze k jednomu okresu
--	Disp a card: vztah 1:N, jedno oprávnění/dispozice může mít více platebních karet, ale každá karta má jedno oprávnění
--	Account a order: 1:N, jeden bankovní účet může mít více trvalých příkazů, ale každý příkaz se váže pouze k jednomu účtu
--  Account a loan 1:N, jeden bankovní účet může mít mnoho úůjček, ale každá půjčka se váže pouze k jednomu účtu

-- Historie poskytnutých úvěrů
-- data z tabulky loan, rok, čtvrtletí, měsíc, rok + čtvrtletí, rok, celkový souhrn.

-- Roční přehled
SELECT
    YEAR(date) AS loan_year,
    SUM(amount) AS total_loan_amount,
    AVG(amount) AS avg_loan_amount,
    COUNT(*) AS loan_count
FROM financial17_118.loan
GROUP BY YEAR(date)
ORDER BY loan_year;

-- with rollup (dopočítá mezisoučty a celkový součet)
SELECT
    YEAR(date) AS loan_year,
    QUARTER(date) AS loan_quarter,
    MONTH(date) AS loan_month,
    SUM(amount) AS total_loan_amount,
    AVG(amount) AS average_loan_amount,
    COUNT(loan_id) AS total_number_of_loans
FROM
    financial17_118.loan
GROUP BY
    loan_year,
    loan_quarter,
    loan_month
WITH ROLLUP;

-- Stav půjček
-- Celkem 682 poskytnutých půjček, 606 bylo splaceno, 76 ne.
SELECT * FROM financial17_118.loan

SELECT
    status,
    COUNT(loan_id) AS number_of_loans_with_status
FROM
    financial17_118.loan
GROUP BY
    status
ORDER BY
    number_of_loans_with_status DESC;

-- C a A odpovídá splaceným pujičkám
-- D a B odpovídá nesplaceným pujičkám

SELECT
    account_id,
    COUNT(loan_id) AS number_of_given_loans,
    SUM(amount) AS total_amount_of_loans,
    AVG(amount) AS average_loan_amount
FROM
    financial17_118.loan
WHERE
    status IN ('A', 'C')
GROUP BY
    account_id
ORDER BY
    number_of_given_loans DESC,
    total_amount_of_loans DESC,
    average_loan_amount;

-- Plně splacené půjčky podle pohlaví klienta

DROP TEMPORARY TABLE IF EXISTS tmp_fully_paid_loans_by_gender;
CREATE TEMPORARY TABLE tmp_fully_paid_loans_by_gender AS
SELECT
    c.gender,
    SUM(l.amount) AS total_repaid_amount
FROM
    financial17_118.loan AS l
INNER JOIN
    financial17_118.account AS a USING (account_id)
INNER JOIN
    financial17_118.disp AS d USING (account_id)
INNER JOIN
    financial17_118.client AS c USING (client_id)
WHERE
    l.status IN ('A', 'C')
    AND
    d.type = 'OWNER'
GROUP BY
    c.gender
ORDER BY
    c.gender;

-- Zobrazení výsledků z dočasné tabulky
SELECT
    gender,
    total_repaid_amount
FROM
    tmp_fully_paid_loans_by_gender;

-- Ověření správnosti dotazu.

WITH total_repaid_from_source AS (
    SELECT
        SUM(amount) AS amount_from_source
    FROM
        financial17_118.loan AS l
    WHERE
        l.status IN ('A', 'C')
)
SELECT
    (SELECT SUM(total_repaid_amount) FROM tmp_fully_paid_loans_by_gender) -
    (SELECT amount_from_source FROM total_repaid_from_source) AS difference_for_verification;

DROP TEMPORARY TABLE IF EXISTS tmp_fully_paid_loans_by_gender;

-- Analýza klientů - část 1.
-- Kdo má více splacených půjček - ženy nebo muži?
-- Jaký je průměrný věk dlužníka dělený podle pohlaví?


DROP TEMPORARY TABLE IF EXISTS tmp_repaid_loans_client_data;
CREATE TEMPORARY TABLE tmp_repaid_loans_client_data AS
SELECT
    l.loan_id,
    c.gender,
    c.birth_date
FROM
    financial17_118.loan AS l
INNER JOIN
    financial17_118.account AS a USING (account_id)
INNER JOIN
    financial17_118.disp AS d USING (account_id)
INNER JOIN
    financial17_118.client AS c USING (client_id)
WHERE
    l.status IN ('A', 'C')
    AND d.type = 'OWNER';

-- Odpověď na otázku 1: Kdo má více splacených půjček - ženy nebo muži?
SELECT
    gender,
    COUNT(loan_id) AS number_of_repaid_loans
FROM
    tmp_repaid_loans_client_data
GROUP BY
    gender
ORDER BY
    number_of_repaid_loans DESC;

-- ženy mají 307 a muži 299 splacených půjček.

-- Odpověď na otázku 2: Jaký je průměrný věk dlužníka rozdělený podle pohlaví?
-- rozdíl mezi rokem 2024 a rokem narození klienta
SELECT
    gender,
    AVG(2024 - YEAR(birth_date)) AS average_age_of_borrower
FROM
    tmp_repaid_loans_client_data
GROUP BY
    gender
ORDER BY
    gender;

-- Průměrný věk dlužníka muže je 64.8502 a ženy je 66.8729

-- Ověření celkového počtu záznamů v dočasné tabulce

SELECT COUNT(*) AS total_records_in_tmp_table
FROM tmp_repaid_loans_client_data;

DROP TEMPORARY TABLE IF EXISTS tmp_repaid_loans_client_data;

-- Analýza klienta - 2. část
-- která oblast má nejvíce klientů,
-- ve které oblasti byl splacen nejvyšší počet půjček,
-- ve které oblasti byla vyplacena nejvyšší částka půjček.

DROP TEMPORARY TABLE IF EXISTS tmp_repaid_loans_client_data;
CREATE TEMPORARY TABLE tmp_repaid_loans_client_data AS
SELECT
    l.loan_id,
    l.amount,
    c.gender,
    c.birth_date,
    c.client_id,
    c.district_id
FROM
    financial17_118.loan AS l
INNER JOIN
    financial17_118.account AS a USING (account_id)
INNER JOIN
    financial17_118.disp AS d USING (account_id)
INNER JOIN
    financial17_118.client AS c USING (client_id)
WHERE
    l.status IN ('A', 'C')
    AND d.type = 'OWNER';
SELECT
    gender,
    COUNT(loan_id) AS number_of_repaid_loans
FROM
    tmp_repaid_loans_client_data
GROUP BY
    gender
ORDER BY
    number_of_repaid_loans DESC;
SELECT
    gender,
    AVG(2024 - YEAR(birth_date)) AS average_age_of_borrower
FROM
    tmp_repaid_loans_client_data
GROUP BY
    gender
ORDER BY
    gender;

-- Client analysis - part 2): Která oblast má nejvíce klientů?
-- Spočítám unikátní klienty (kteří jsou majiteli účtů a mají splacenou půjčku) podle okresu.
SELECT
    d.A2 AS district_name,
    COUNT(DISTINCT trcd.client_id) AS number_of_clients
FROM
    tmp_repaid_loans_client_data AS trcd
INNER JOIN
    financial17_118.district AS d USING (district_id)
GROUP BY
    d.A2
ORDER BY
    number_of_clients DESC;

-- Odpověď: Praha má 73 klientů, Karviná 22, atd.

-- Client analysis - part 2): Ve které oblasti byl zaplacen nejvyšší počet půjček?
-- Spočítám celkový počet splacených půjček podle okresu.
SELECT
    d.A2 AS district_name,
    COUNT(trcd.loan_id) AS number_of_repaid_loans
FROM
    tmp_repaid_loans_client_data AS trcd
INNER JOIN
    financial17_118.district AS d USING (district_id)
GROUP BY
    d.A2
ORDER BY
    number_of_repaid_loans DESC;

-- Odpověď: Opět Praha se 73 klienty.

-- Client analysis - part 2: Ve které oblasti byla zaplacena nejvyšší částka půjček?
-- Spočítám celkovou sumu splacených půjček podle okresu.
SELECT
    d.A2 AS district_name,
    SUM(trcd.amount) AS total_repaid_amount
FROM
    tmp_repaid_loans_client_data AS trcd
INNER JOIN
    financial17_118.district AS d USING (district_id)
GROUP BY
    d.A2
ORDER BY
    total_repaid_amount DESC;

-- Nejvyšší částka byla zaplacena v Praze, tj. 10502628.

SELECT COUNT(*) AS total_records_in_tmp_table
FROM tmp_repaid_loans_client_data;

DROP TEMPORARY TABLE IF EXISTS tmp_repaid_loans_client_data;

-- Client analysis - part 3

DROP TEMPORARY TABLE IF EXISTS tmp_repaid_loans_client_data;
CREATE TEMPORARY TABLE tmp_repaid_loans_client_data AS
SELECT
    l.loan_id,
    l.amount,
    c.gender,
    c.birth_date,
    c.client_id,
    c.district_id
FROM
    financial17_118.loan AS l
INNER JOIN
    financial17_118.account AS a USING (account_id)
INNER JOIN
    financial17_118.disp AS d USING (account_id)
INNER JOIN
    financial17_118.client AS c USING (client_id)
WHERE
    l.status IN ('A', 'C')
    AND d.type = 'OWNER';
SELECT
    gender,
    COUNT(loan_id) AS number_of_repaid_loans
FROM
    tmp_repaid_loans_client_data
GROUP BY
    gender
ORDER BY
    number_of_repaid_loans DESC;
SELECT
    gender,
    AVG(2024 - YEAR(birth_date)) AS average_age_of_borrower
FROM
    tmp_repaid_loans_client_data
GROUP BY
    gender
ORDER BY
    gender;

SELECT
    d.A2 AS district_name,
    COUNT(DISTINCT trcd.client_id) AS number_of_clients
FROM
    tmp_repaid_loans_client_data AS trcd
INNER JOIN
    financial17_118.district AS d USING (district_id)
GROUP BY
    d.A2
ORDER BY
    number_of_clients DESC;

SELECT
    d.A2 AS district_name,
    COUNT(trcd.loan_id) AS number_of_repaid_loans
FROM
    tmp_repaid_loans_client_data AS trcd
INNER JOIN
    financial17_118.district AS d USING (district_id)
GROUP BY
    d.A2
ORDER BY
    number_of_repaid_loans DESC;

SELECT
    d.A2 AS district_name,
    SUM(trcd.amount) AS total_repaid_amount
FROM
    tmp_repaid_loans_client_data AS trcd
INNER JOIN
    financial17_118.district AS d USING (district_id)
GROUP BY
    d.A2
ORDER BY
    total_repaid_amount DESC;

-- Client analysis - part 3): Procentuální podíl každého okresu na celkové částce poskytnutých (splacených) půjček.

SELECT SUM(amount) INTO @overall_total_amount FROM tmp_repaid_loans_client_data;

SELECT
    d.district_id AS district_id,
    COUNT(DISTINCT trcd.client_id) AS customer_amount,
    SUM(trcd.amount) AS loans_given_amount,
    COUNT(trcd.loan_id) AS loans_given_count,
    ROUND(SUM(trcd.amount) / @overall_total_amount, 4) AS amount_share
FROM
    tmp_repaid_loans_client_data AS trcd
INNER JOIN
    financial17_118.district AS d USING (district_id)
GROUP BY
    d.district_id
ORDER BY
    d.district_id;

SELECT COUNT(*) AS total_records_in_tmp_table
FROM (SELECT * FROM tmp_repaid_loans_client_data) AS temp_alias_for_count;

-- DROP TEMPORARY TABLE IF EXISTS tmp_repaid_loans_client_data;

-- Selection - part 1: Výběr klienta
-- zůstatek na jejich účtu je vyšší než 1000,
-- mají více než 5 půjček,
-- narodili se po roce 1990.

SELECT
    c.client_id,
    c.gender,
    c.birth_date,
    COUNT(l.loan_id) AS total_loans_count,
    SUM(l.amount - l.payments) AS calculated_account_balance
FROM
    financial17_118.client AS c
INNER JOIN
    financial17_118.disp AS d USING (client_id)
INNER JOIN
    financial17_118.account AS a USING (account_id)
INNER JOIN
    financial17_118.loan AS l USING (account_id)
WHERE
    d.type = 'OWNER' --
    AND YEAR(c.birth_date) > 1990
GROUP BY
    c.client_id, c.gender, c.birth_date
HAVING
    SUM(l.amount - l.payments) > 1000
    AND COUNT(l.loan_id) > 5;

- Odpověď - tabulka je prázdná
-- DROP TEMPORARY TABLE IF EXISTS tmp_repaid_loans_client_data;

-- Výběr - 2. část

DROP TEMPORARY TABLE IF EXISTS tmp_all_loans_client_data;
CREATE TEMPORARY TABLE tmp_all_loans_client_data AS
SELECT
    c.client_id,        -- ID klienta
    c.gender,           -- Pohlaví klienta
    c.birth_date,       -- Datum narození klienta
    l.loan_id,          -- ID půjčky
    l.amount,           -- Výše půjčky
    l.payments          -- Měsíční splátky
FROM
    financial17_118.client AS c
INNER JOIN
    financial17_118.disp AS d USING (client_id)
INNER JOIN
    financial17_118.account AS a USING (account_id)
INNER JOIN
    financial17_118.loan AS l USING (account_id)
WHERE
    d.type = 'OWNER'; -- Bereme v úvahu pouze majitele účtů.

-- Podmínka 1: Klienti narození po roce 1990
SELECT
    COUNT(DISTINCT client_id) AS clients_born_after_1990
FROM
    tmp_all_loans_client_data
WHERE
    YEAR(birth_date) > 1990;

-- Odpověď: 0

-- Podmínka 2: Klienti s více než 5 půjčkami
SELECT
    COUNT(DISTINCT client_id) AS clients_with_more_than_5_loans
FROM
    tmp_all_loans_client_data
GROUP BY
    client_id
HAVING
    COUNT(loan_id) > 5;

-- Výsledkem je prázdná tabulka

-- Podmínka 3: Klienti se zůstatkem účtu nad 1000
SELECT
    COUNT(DISTINCT client_id) AS clients_with_balance_above_1000
FROM
    tmp_all_loans_client_data
GROUP BY
    client_id
HAVING
    SUM(amount - payments) > 1000;

-- 682 klientů s maximem počtu půjček 1 na klienta

-- Klienti narození po roce 1990 A s více než 5 půjčkami
SELECT
    COUNT(DISTINCT client_id) AS clients_born_after_1990_and_more_than_5_loans
FROM
    tmp_all_loans_client_data
WHERE
    YEAR(birth_date) > 1990
GROUP BY
    client_id
HAVING
    COUNT(loan_id) > 5;

-- Výsledkem je prázdná tabulka

-- Klienti narození po roce 1990 A s zůstatkem účtu nad 1000
SELECT
    COUNT(DISTINCT client_id) AS clients_born_after_1990_and_balance_above_1000
FROM
    tmp_all_loans_client_data
WHERE
    YEAR(birth_date) > 1990
GROUP BY
    client_id
HAVING
    SUM(amount - payments) > 1000;

-- Výsledkem je prázdná tabulka

-- Krok 17: Analýza kombinací podmínek - Klienti s více než 5 půjčkami A s "zůstatkem účtu" nad 1000.
SELECT
    COUNT(DISTINCT client_id) AS clients_more_than_5_loans_and_balance_above_1000
FROM
    tmp_all_loans_client_data
GROUP BY
    client_id
HAVING
    COUNT(loan_id) > 5
    AND SUM(amount - payments) > 1000;

-- Výsledkem je prázdná tabulka

DROP TEMPORARY TABLE IF EXISTS tmp_all_loans_client_data;

-- Karty s vypršením platnosti

DELIMITER $$

DROP PROCEDURE IF EXISTS refresh_cards_at_expiration;
$$

CREATE PROCEDURE refresh_cards_at_expiration(
    IN p_issue_year_limit INT
)
BEGIN
    DROP TABLE IF EXISTS cards_at_expiration;
    CREATE TABLE cards_at_expiration (
        client_id INT,
        card_id INT,
        expiration_date DATE,
        client_address VARCHAR(255)
    );
    INSERT INTO cards_at_expiration (client_id, card_id, expiration_date, client_address)
    SELECT
        c.client_id,
        ca.card_id,
        ADDDATE(ca.issued, INTERVAL 3 YEAR) AS expiration_date,
        d.A3 AS client_address
    FROM
        financial17_118.card AS ca
    INNER JOIN
        financial17_118.disp AS di ON ca.disp_id = di.disp_id
    INNER JOIN
        financial17_118.client AS c ON di.client_id = c.client_id
    INNER JOIN
        financial17_118.district AS d ON c.district_id = d.district_id
    WHERE
        di.type = 'OWNER'
        AND YEAR(ca.issued) <= p_issue_year_limit;

END$$

DELIMITER ;

CALL refresh_cards_at_expiration(1998);

-- Zobrazení obsahu nově vytvořené/aktualizované tabulky
SELECT
    client_id,
    card_id,
    expiration_date,
    client_address
FROM
    cards_at_expiration
ORDER BY
    expiration_date;