USE taxifleet;

-- Q17. CTE pentru calculul profitabilitatii nete per sofer
WITH SituatieFinanciara AS (
    SELECT 
        id_sofer,
        SUM(total_incasat) AS brut_total,
        SUM(comision_aplicatie + chirie + comision_flota + taxe) AS total_retineri,
        SUM(suma_de_plata) AS plata_finala
    FROM decont_saptamanal
    GROUP BY id_sofer
)
SELECT 
    CONCAT(s.nume, ' ', s.prenume) AS sofer,
    sf.brut_total,
    sf.total_retineri,
    sf.plata_finala
FROM SituatieFinanciara sf
JOIN soferi s ON sf.id_sofer = s.id_sofer;
