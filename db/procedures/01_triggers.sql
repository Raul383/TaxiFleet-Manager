USE taxifleet;

-- ==========================================================
-- TRIGGER RB2: Blocare deschidere tura daca exista acte expirate
-- ==========================================================
DELIMITER //
CREATE TRIGGER trg_verifica_documente_tura
BEFORE INSERT ON ture_lucru
FOR EACH ROW
BEGIN
    DECLARE v_expirate INT DEFAULT 0;

    SELECT COUNT(*) INTO v_expirate
    FROM documente d
    JOIN tipuri_document td ON d.id_tip = td.id_tip
    WHERE td.obligatoriu = TRUE
      AND d.data_expirarii IS NOT NULL
      AND d.data_expirarii < DATE(NEW.data_ora_plecare)
      AND (d.id_vehicul = NEW.id_vehicul OR d.id_sofer = NEW.id_sofer);

    IF v_expirate > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RB2 Incalcat: Vehiculul sau soferul are cel putin un document obligatoriu expirat!';
    END IF;
END //
DELIMITER ;

-- ==========================================================
-- POPULARE DATE DE TEST (SEED)
-- ==========================================================

-- 1. Utilizatori
INSERT INTO utilizatori (nume_utilizator, parola_hash, rol, email) VALUES
('admin_raul', 'pbkdf2:sha256:260000$hash_admin_1', 'Administrator', 'raul.admin@taxifleet.ro'),
('popescu_ion', 'pbkdf2:sha256:260000$hash_sofer_1', 'Sofer', 'ion.popescu@taxifleet.ro'),
('ionescu_mihai', 'pbkdf2:sha256:260000$hash_sofer_2', 'Sofer', 'mihai.ionescu@taxifleet.ro'),
('vasilescu_dan', 'pbkdf2:sha256:260000$hash_sofer_3', 'Sofer', 'dan.vasilescu@taxifleet.ro'),
('georgescu_alex', 'pbkdf2:sha256:260000$hash_sofer_4', 'Sofer', 'alex.georgescu@taxifleet.ro');

-- 2. Planuri tarifare
INSERT INTO planuri_tarifare (denumire, procent_aplicatie, chirie_saptamanala, comision_flota_saptamanal, procent_taxe, prag_curse_bonus, valoare_bonus) VALUES
('Standard Flota (Masina Firmei)', 25.00, 450.00, 100.00, 10.00, 80, 200.00),
('Partener Comodat (Masina Proprie)', 25.00, 0.00, 150.00, 10.00, 100, 250.00);

-- 3. Soferi
INSERT INTO soferi (id_utilizator, nume, prenume, cnp, telefon, adresa, status_activ) VALUES
(2, 'Popescu', 'Ion', '1850512240011', '0740111222', 'Str. Victoriei nr. 10, Baia Mare', TRUE),
(3, 'Ionescu', 'Mihai', '1900823240022', '0740222333', 'Bd. Unirii nr. 24, Baia Mare', TRUE),
(4, 'Vasilescu', 'Dan', '1921104240033', '0740333444', 'Str. Culturii nr. 5, Baia Mare', TRUE),
(5, 'Georgescu', 'Alex', '1950219240044', '0740444555', 'Str. Independentei nr. 18, Baia Mare', FALSE);

-- 4. Autovehicule
INSERT INTO autovehicule (id_plan, nr_inmatriculare, serie_sasiu, marca, model, an_fabricatie, km_curenti, prag_revizie_km, status) VALUES
(1, 'MM-10-TAX', 'UU15SDAG512345678', 'Dacia', 'Logan', 2021, 142500, 145000, 'Disponibila'),
(1, 'MM-11-TAX', 'UU15SDAG587654321', 'Dacia', 'Logan', 2022, 98200, 95000, 'Disponibila'), -- A depasit pragul de revizie!
(1, 'MM-12-TAX', 'TMBJJ7NE4J0123456', 'Skoda', 'Octavia', 2020, 210400, 215000, 'In Service'),
(2, 'MM-99-PRO', 'WVWZZZ3CZWE654321', 'Volkswagen', 'Passat', 2019, 185000, 190000, 'Disponibila');

-- 5. Contracte comodat
INSERT INTO contracte_comodat (id_vehicul, id_sofer, numar_contract, data_inceput, data_sfarsit) VALUES
(4, 3, 'CMD-2026-001', '2026-01-15', '2027-01-15');

-- 6. Tipuri document
INSERT INTO tipuri_document (denumire, categorie, obligatoriu, are_expirare) VALUES
('RCA', 'Masina', TRUE, TRUE),
('ITP', 'Masina', TRUE, TRUE),
('Copie Conforma Taxi', 'Masina', TRUE, TRUE),
('Permis Conducere', 'Sofer', TRUE, TRUE),
('Atestat Profesional Taxi', 'Sofer', TRUE, TRUE),
('Cazier Judiciar', 'Sofer', FALSE, TRUE);

-- 7. Documente (XOR: fie id_vehicul, fie id_sofer; includem si expirate / aproape de expirare)
INSERT INTO documente (id_tip, id_vehicul, id_sofer, numar_document, data_emiterii, data_expirarii, cost) VALUES
(1, 1, NULL, 'RCA-MM10-2026', '2026-01-10', '2027-01-10', 1450.00),
(2, 1, NULL, 'ITP-MM10-2026', '2026-06-01', '2026-12-05', 180.00),  -- Expira curand (< 30 zile)
(1, 2, NULL, 'RCA-MM11-2026', '2026-03-15', '2027-03-15', 1500.00),
(2, 2, NULL, 'ITP-MM11-2025', '2025-10-01', '2026-10-01', 180.00),  -- EXPIRAT! (va bloca tura pe MM-11-TAX)
(4, NULL, 1, 'PRM-POP-001',   '2020-05-10', '2030-05-10', 0.00),
(5, NULL, 1, 'ATS-POP-001',   '2022-04-01', '2027-04-01', 250.00),
(4, NULL, 2, 'PRM-ION-002',   '2021-07-12', '2031-07-12', 0.00),
(5, NULL, 2, 'ATS-ION-002',   '2022-02-15', '2027-02-15', 250.00),
(5, NULL, 3, 'ATS-VAS-003',   '2021-09-01', '2026-09-01', 250.00);  -- EXPIRAT! (soferul 3 are atestat expirat)

-- 8. Atribuiri titulari (M:N)
INSERT INTO atribuiri_titulari (id_vehicul, id_sofer, data_inceput, data_sfarsit) VALUES
(1, 1, '2026-01-01', NULL),
(2, 3, '2026-02-01', NULL),
(4, 2, '2026-01-15', NULL);

-- 9. Predictii cerere (pentru ML / surge)
INSERT INTO predictii_cerere (zi_saptamana, ora, nivel_cerere, multiplicator_sugerat, versiune_model) VALUES
(5, 18, 'Ridicata', 1.35, 'v1.0-baseline'),
(5, 22, 'Foarte ridicata', 1.65, 'v1.0-baseline'),
(6, 23, 'Foarte ridicata', 1.80, 'v1.0-baseline'),
(1, 10, 'Scazuta', 1.00, 'v1.0-baseline');

-- 10. Decont saptamanal
INSERT INTO decont_saptamanal (id_sofer, id_plan, id_admin_verificare, data_start, data_sfarsit, total_incasat, total_declarat, diferenta, comision_aplicatie, chirie, comision_flota, taxe, net_calculat, total_ajustari, datorie_anterioara, suma_de_plata, datorie_noua, total_ore_lucrate, numar_ture_lungi, flag_norma_sub_48, stare_decont) VALUES
(1, 1, 1, '2026-11-02 04:00:00', '2026-11-09 04:00:00', 2400.00, 2400.00, 0.00, 600.00, 450.00, 100.00, 240.00, 1010.00, 200.00, 0.00, 1210.00, 0.00, 50.50, 1, FALSE, 'Verificat'),
(2, 2, 1, '2026-11-02 04:00:00', '2026-11-09 04:00:00', 1850.00, 1790.00, -60.00, 462.50, 0.00, 150.00, 185.00, 1052.50, -50.00, 0.00, 1002.50, 0.00, 42.00, 0, TRUE, 'Generat');

-- 11. Ture lucru (inserate cu date anterioare expirarii sau pe masini/soferi cu acte valide)
INSERT INTO ture_lucru (id_vehicul, id_sofer, id_decont, id_admin_verificare, data_ora_plecare, km_plecare, data_ora_sosire, km_sosire, total_declarat, stare_tura, inchisa_automat, stare_reconciliere) VALUES
(1, 1, 1, 1, '2026-11-03 07:00:00', 141800, '2026-11-03 16:30:00', 142050, 620.00, 'Inchisa', FALSE, 'Conforma'),
(1, 1, 1, 1, '2026-11-04 08:00:00', 142050, '2026-11-04 20:00:00', 142320, 780.00, 'Inchisa', TRUE, 'Conforma'),
(4, 2, 2, NULL, '2026-11-05 14:00:00', 184500, '2026-11-05 23:00:00', 184780, 540.00, 'Inchisa', FALSE, 'Diferenta semnalata');

-- 12. Bonuri digitale
INSERT INTO bonuri_digitale (id_tura, id_decont, id_predictie, numar_serie, suma, multiplicator, suma_surge, data_ora, metoda_plata) VALUES
(1, 1, 4, 'BON-2026-1001', 35.00, 1.00, 0.00, '2026-11-03 10:15:00', 'Card'),
(1, 1, 1, 'BON-2026-1002', 54.00, 1.35, 14.00, '2026-11-03 16:10:00', 'Numerar'),
(2, 1, 2, 'BON-2026-1003', 82.50, 1.65, 32.50, '2026-11-04 19:45:00', 'Card'),
(3, 2, 3, 'BON-2026-1004', 90.00, 1.80, 40.00, '2026-11-05 22:30:00', 'Numerar'),
(3, 2, 1, 'BON-2026-1005', 45.00, 1.35, 11.67, '2026-11-05 18:20:00', 'Card');

-- 13. Alimentari
INSERT INTO alimentari (id_vehicul, id_sofer, data_ora, litri, suma, km_bord, rezervor_plin) VALUES
(1, 1, '2026-11-03 16:40:00', 38.50, 285.00, 142052, TRUE),
(4, 2, '2026-11-05 23:15:00', 42.00, 310.00, 184785, TRUE);

-- 14. Sesizari, Ateliere, Interventii, Piese
INSERT INTO sesizari (id_sofer, id_vehicul, id_admin_inspectie, descriere, stare) VALUES
(1, 3, 1, 'Bataie la articulatia fata dreapta pe drum denivelat', 'Trimisa la service');

INSERT INTO ateliere_service (denumire, telefon, adresa) VALUES
('AutoService Nord Baia Mare', '0262223344', 'Bd. Bucuresti nr. 55, Baia Mare');

INSERT INTO interventii (id_vehicul, id_atelier, id_admin, id_sesizare, tip_interventie, stare, data_interventie, km_la_interventie, descriere, cost_total) VALUES
(3, 1, 1, 1, 'Reparatie', 'In desfasurare', '2026-11-10', 210400, 'Inlocuire brat suspensie si bieleta antiruliu', 680.00);

INSERT INTO piese_interventie (id_interventie, denumire_piesa, cantitate, pret_unitar) VALUES
(1, 'Brat suspensie fata dreapta', 1, 420.00),
(1, 'Bieleta antiruliu', 2, 130.00);

-- 15. Ajustari decont & Alerte
INSERT INTO ajustari_decont (id_sofer, id_decont, id_admin, id_tura, tip_ajustare, suma, descriere, data_fapta) VALUES
(1, 1, 1, NULL, 'Bonus curse', 200.00, 'Depasire prag 80 curse saptamanale', '2026-11-08'),
(2, 2, 1, 3, 'Retinere daune', 50.00, 'Diferenta nejustificata la casa', '2026-11-05');

INSERT INTO alerte (tip_alerta, nivel, mesaj, id_document, id_vehicul) VALUES
('Document', 'Expirat', 'ITP expirat pentru autovehiculul MM-11-TAX!', 4, 2),
('Revizie', '15 zile', 'Autovehiculul MM-11-TAX a depasit pragul de revizie (98200 / 95000 km).', NULL, 2);