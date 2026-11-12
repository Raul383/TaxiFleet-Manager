USE taxifleet;

-- Q4. Soferii care NU au efectuat nicio tura in sistem (LEFT JOIN + IS NULL)
SELECT s.id_sofer, s.nume, s.prenume, s.telefon
FROM soferi s
LEFT JOIN ture_lucru t ON s.id_sofer = t.id_sofer
WHERE t.id_tura IS NULL;
