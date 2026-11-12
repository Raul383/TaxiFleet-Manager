# Changelog

Toate modificările notabile aduse acestui proiect vor fi consemnate în acest fișier.

## [v0.8-crud-interogari] - 2026-11-12
### Adăugat
- Trigger-ul `trg_verifica_documente_tura` în `db/procedures/01_triggers.sql` pentru aplicarea regulii de business RB2 (blocarea deschiderii turelor la acte expirate).
- Vederea `v_documente_scadente` în `db/views/01_v_documente_scadente.sql` pentru monitorizarea documentelor expirate sau scadente în 30 de zile.
- Scriptul complet de populare cu date de test în `db/seed/01_insert_date.sql`.
- Scriptul de verificare a integrității datelor în `teste/01_test_constrangeri.sql` (testare XOR, RB2, `CHECK`, `UNIQUE`).
- Cele 20 de interogări SQL individuale în `queries/01..20*.sql` (`SELECT`, `JOIN`, `GROUP BY`/`HAVING`, subinterogări, `UNION`/`EXCEPT`, `VIEW`, CTE, funcții fereastră și DML).
- Aplicația web CRUD în Python + Flask (`app/app.py`, `app/db.py` și șabloanele HTML din `app/templates/`) cu tratarea prietenoasă a excepțiilor SQL și rulare live a rapoartelor.
- Fișierul `requirements.txt` și configurarea conexiunii la baza de date prin variabile de mediu (`.env`).

## [v0.4-model-fizic-ddl] - 2026-11-05
### Adăugat
- Scriptul DDL complet pentru crearea bazei de date `taxifleet` și a celor 19 tabele în MariaDB (`db/schema/01_create_tables.sql`).
- Definirea constrângerilor de integritate la nivel fizic (`PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `CHECK` și constrângerea XOR pe `documente`) și a indecșilor pentru optimizarea interogărilor.

## [v0.3-proiectare] - 2026-10-28
### Adăugat
- Modelul logic relațional derivat din diagrama ER (tabele, chei primare, chei externe și tabele de legătură pentru relațiile M:N).
- Verificarea și justificarea normalizării schemei până la Forma Normală 3 (3NF).
- Dicționarul de date complet (descrierea tabelelor, coloanelor, tipurilor de date, domeniilor de valori și regulilor de integritate).

## [v0.2-model-er] - 2026-10-21
### Adăugat
- Analiza detaliată a cerințelor funcționale și nefuncționale ale sistemului de gestiune a flotei taxi.
- Definirea regulilor de business (RB1–RB4) și a fluxurilor operaționale (ture, deconturi săptămânale, mentenanță, alerte).
- Diagrama Entitate-Relație (ER) în notație Chen cuprinzând cele 19 entități, atributele și cardinalitățile (1:1, 1:N, M:N, relație exclusivă XOR).

## [v0.1-analiza] - 2026-10-14
### Adăugat
- Structura inițială de directoare a depozitului conform specificațiilor proiectului.
- Fișierul `README.md` conținând titlul, domeniul, problema concretă și scopul sistemului.
- Fișierul `.gitignore` pentru medii de dezvoltare și fișiere generate automat.
- Inițializarea etapelor de analiză pentru baza de date de gestiune taxi.