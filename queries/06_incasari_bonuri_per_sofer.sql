USE taxifleet;

-- Q6. Total incasari din bonuri si numarul de curse per sofer (incasari > 100 RON)
SELECT 
    CONCAT(s.nume, ' ', s.prenume) AS sofer,
    COUNT(b.id_bon) AS numar_curse,
    SUM(b.suma) AS total_incasat_bonuri,
    ROUND(AVG(b.suma), 2) AS valoare_medie_cursa
FROM soferi s
JOIN ture_lucru t ON s.id_sofer = t.id_sofer
JOIN bonuri_digitale b ON t.id_tura = b.id_tura
GROUP BY s.id_sofer, s.nume, s.prenume
HAVING SUM(b.suma) > 100
ORDER BY total_incasat_bonuri DESC;
