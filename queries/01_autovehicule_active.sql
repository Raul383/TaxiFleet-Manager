USE taxifleet;

-- Q1. Autovehiculele active ale flotei ordonate descrescator dupa rulajul curent
SELECT nr_inmatriculare, marca, model, an_fabricatie, km_curenti, status
FROM autovehicule
WHERE status <> 'Retrasa din circulatie'
ORDER BY km_curenti DESC;
