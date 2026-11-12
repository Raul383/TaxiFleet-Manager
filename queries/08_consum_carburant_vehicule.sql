USE taxifleet;

-- Q8. Costul total al alimentarilor si litrii consumati per autovehicul
SELECT 
    a.nr_inmatriculare,
    CONCAT(a.marca, ' ', a.model) AS vehicul,
    COUNT(al.id_alimentare) AS nr_alimentari,
    SUM(al.litri) AS total_litri,
    SUM(al.suma) AS cost_carburant
FROM autovehicule a
JOIN alimentari al ON a.id_vehicul = al.id_vehicul
GROUP BY a.id_vehicul, a.nr_inmatriculare, a.marca, a.model;
