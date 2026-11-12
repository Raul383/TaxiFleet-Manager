USE taxifleet;

-- Q12. Lista unificata a tuturor titularilor de documente (masini + soferi) (UNION ALL)
SELECT 'Autovehicul' AS tip_entitate, a.nr_inmatriculare AS nume_entitate, td.denumire AS document, d.cost
FROM documente d
JOIN autovehicule a ON d.id_vehicul = a.id_vehicul
JOIN tipuri_document td ON d.id_tip = td.id_tip
UNION ALL
SELECT 'Sofer' AS tip_entitate, CONCAT(s.nume, ' ', s.prenume) AS nume_entitate, td.denumire AS document, d.cost
FROM documente d
JOIN soferi s ON d.id_sofer = s.id_sofer
JOIN tipuri_document td ON d.id_tip = td.id_tip;
