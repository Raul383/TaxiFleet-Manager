USE taxifleet;

-- Q11. Soferii care au inregistrat diferente negative in decontul saptamanal (IN)
SELECT nume, prenume, telefon
FROM soferi
WHERE id_sofer IN (
    SELECT id_sofer 
    FROM decont_saptamanal 
    WHERE diferenta < 0
);
