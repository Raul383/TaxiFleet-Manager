-- =====================================================================
-- Date de test (valabilitatea documentelor este relativa la CURDATE())
-- =====================================================================
USE taxifleet;

INSERT INTO planuri_tarifare (denumire, procent_aplicatie, chirie_saptamanala, comision_flota_saptamanal, procent_taxe, prag_curse_bonus, valoare_bonus) VALUES
 ('Masina firma',   25, 400, 100, 10, 15, 50),
 ('Masina proprie', 25,   0, 100, 10, 15, 50);

INSERT INTO tipuri_document (denumire, categorie, obligatoriu, are_expirare) VALUES
 ('ITP','Masina',TRUE,TRUE), ('RCA','Masina',TRUE,TRUE), ('CASCO','Masina',TRUE,TRUE),
 ('Autorizatie taxi','Masina',TRUE,TRUE),
 ('Permis de conducere','Sofer',TRUE,TRUE), ('Atestat profesional','Sofer',TRUE,TRUE),
 ('Aviz medical','Sofer',TRUE,TRUE), ('Aviz psihologic','Sofer',TRUE,TRUE),
 ('Cazier judiciar','Sofer',TRUE,TRUE), ('Cazier auto','Sofer',TRUE,TRUE),
 ('Studii','Sofer',TRUE,FALSE);

INSERT INTO utilizatori (nume_utilizator, parola_hash, rol, email) VALUES
 ('admin', 'hash_demo', 'Administrator', 'admin@taxifleet.ro'),
 ('ion',   'hash_demo', 'Sofer',         'ion@taxifleet.ro'),
 ('maria', 'hash_demo', 'Sofer',         'maria@taxifleet.ro');

INSERT INTO soferi (id_utilizator, nume, prenume, cnp, telefon, adresa) VALUES
 (2, 'Popescu', 'Ion',   '1800101123456', '0740111222', 'Cluj-Napoca'),
 (3, 'Ionescu', 'Maria', '2850505123457', '0740333444', 'Cluj-Napoca');

INSERT INTO autovehicule (id_plan, nr_inmatriculare, serie_sasiu, marca, model, an_fabricatie, km_curenti, prag_revizie_km) VALUES
 (1, 'CJ01ABC', 'UU1LSDAAC12345678', 'Dacia',   'Logan',  2021, 120000, 130000),
 (2, 'CJ02XYZ', 'VF1RFB00X12345678', 'Renault', 'Megane', 2019,  98000, 100000);

INSERT INTO contracte_comodat (id_vehicul, id_sofer, numar_contract, data_inceput, data_sfarsit) VALUES
 (2, 2, 'COM-2026-001', DATE_SUB(CURDATE(), INTERVAL 60 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY));

INSERT INTO atribuiri_titulari (id_vehicul, id_sofer, data_inceput) VALUES
 (1, 1, DATE_SUB(CURDATE(), INTERVAL 30 DAY)),
 (2, 2, DATE_SUB(CURDATE(), INTERVAL 30 DAY));

-- Masina 1 (firma): ITP expira in 12 zile (pentru testul de alerta)
INSERT INTO documente (id_tip, id_vehicul, numar_document, data_emiterii, data_expirarii, cost)
SELECT t.id_tip, 1, CONCAT('M1-', t.id_tip), DATE_SUB(CURDATE(), INTERVAL 300 DAY),
       IF(t.denumire='ITP', DATE_ADD(CURDATE(), INTERVAL 12 DAY), DATE_ADD(CURDATE(), INTERVAL 200 DAY)), 150
FROM tipuri_document t WHERE t.categorie = 'Masina';
INSERT INTO documente (id_tip, id_vehicul, numar_document, data_emiterii, data_expirarii)
SELECT t.id_tip, 2, CONCAT('M2-', t.id_tip), DATE_SUB(CURDATE(), INTERVAL 100 DAY), DATE_ADD(CURDATE(), INTERVAL 250 DAY)
FROM tipuri_document t WHERE t.categorie = 'Masina';
INSERT INTO documente (id_tip, id_sofer, numar_document, data_emiterii, data_expirarii)
SELECT t.id_tip, s.id_sofer, CONCAT('S', s.id_sofer, '-', t.id_tip), DATE_SUB(CURDATE(), INTERVAL 100 DAY),
       IF(t.are_expirare, DATE_ADD(CURDATE(), INTERVAL 250 DAY), NULL)
FROM tipuri_document t CROSS JOIN soferi s WHERE t.categorie = 'Sofer';

INSERT INTO ateliere_service (denumire, telefon, adresa) VALUES ('Auto Service Nord', '0264123456', 'Cluj-Napoca');

-- Prognoza de cerere (in productie o scrie scriptul ML): ore de varf luni-vineri
INSERT INTO predictii_cerere (zi_saptamana, ora, nivel_cerere, multiplicator_sugerat, versiune_model)
SELECT z.z, h.h, IF(h.h IN (8,18), 'Ridicata', 'Normala'), IF(h.h IN (8,18), 1.40, 1.00), 'demo-v1'
FROM (SELECT 1 z UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) z
CROSS JOIN (SELECT 8 h UNION SELECT 12 UNION SELECT 18) h;