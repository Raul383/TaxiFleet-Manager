USE taxifleet;

-- Q7. Comparatie intre multiplicatorul mediu real din bonuri si cel prezis de modelul ML
SELECT 
    pc.nivel_cerere,
    pc.multiplicator_sugerat,
    COUNT(b.id_bon) AS curse_inregistrate,
    ROUND(AVG(b.multiplicator), 2) AS multiplicator_mediu_aplicat,
    SUM(b.suma_surge) AS total_venit_surge
FROM predictii_cerere pc
JOIN bonuri_digitale b ON pc.id_predictie = b.id_predictie
GROUP BY pc.id_predictie, pc.nivel_cerere, pc.multiplicator_sugerat;
