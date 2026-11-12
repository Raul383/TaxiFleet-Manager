USE taxifleet;

-- Q3. Situatia turelor inchise: sofer, masina, distanta parcursa si suma declarata
SELECT 
    t.id_tura,
    CONCAT(s.nume, ' ', s.prenume) AS sofer,
    a.nr_inmatriculare,
    t.data_ora_plecare,
    (t.km_sosire - t.km_plecare) AS km_parcursi,
    t.total_declarat,
    t.stare_reconciliere
FROM ture_lucru t
JOIN soferi s ON t.id_sofer = s.id_sofer
JOIN autovehicule a ON t.id_vehicul = a.id_vehicul
WHERE t.stare_tura = 'Inchisa'
ORDER BY t.data_ora_plecare DESC;
