USE taxifleet;

-- TEST 1: Constrangerea XOR pe tabela documente (ambele FK-uri completate -> EROARE ck_doc_proprietar)
INSERT INTO documente (id_tip, id_vehicul, id_sofer, numar_document, data_emiterii, data_expirarii)
VALUES (1, 1, 1, 'ERR-XOR-01', '2026-01-01', '2027-01-01');

-- TEST 2: Trigger RB2 - Deschidere tura pe un vehicul cu ITP expirat (MM-11-TAX are ITP expirat -> EROARE 45000)
INSERT INTO ture_lucru (id_vehicul, id_sofer, data_ora_plecare, km_plecare)
VALUES (2, 1, '2026-11-12 08:00:00', 98200);

-- TEST 3: Constrangere CHECK pe kilometraj (km_sosire < km_plecare -> EROARE ck_tura_km)
INSERT INTO ture_lucru (id_vehicul, id_sofer, data_ora_plecare, km_plecare, data_ora_sosire, km_sosire)
VALUES (1, 1, '2026-11-12 08:00:00', 142500, '2026-11-12 12:00:00', 142100);

-- TEST 4: Constrangere CHECK pe CNP (lungime invalida -> EROARE ck_sofer_cnp)
INSERT INTO soferi (id_utilizator, nume, prenume, cnp, telefon)
VALUES (1, 'Test', 'Invalid', '12345', '0740000000');

-- TEST 5: Constrangere UNIQUE pe numar de inmatriculare (duplicat -> EROARE uq_auto_nr)
INSERT INTO autovehicule (id_plan, nr_inmatriculare, serie_sasiu, marca, model, an_fabricatie)
VALUES (1, 'MM-10-TAX', 'UU15SDAG599999999', 'Dacia', 'Logan', 2023);