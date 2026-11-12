USE taxifleet;

-- Q18. INSERT: Inregistrarea unei noi alerte pentru un decont cu diferenta negativa
INSERT INTO alerte (tip_alerta, nivel, mesaj, id_sofer)
SELECT 'Diferenta incasari', 'Info', CONCAT('Diferenta de ', diferenta, ' RON la decontul #', id_decont), id_sofer
FROM decont_saptamanal
WHERE diferenta < 0
LIMIT 1;
