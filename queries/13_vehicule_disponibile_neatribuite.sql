USE taxifleet;

-- Q13. Autovehiculele disponibile care NU sunt atribuite unui titular activ (EXCEPT)
SELECT id_vehicul, nr_inmatriculare, marca, model
FROM autovehicule
WHERE status = 'Disponibila'
EXCEPT
SELECT a.id_vehicul, a.nr_inmatriculare, a.marca, a.model
FROM autovehicule a
JOIN atribuiri_titulari atb ON a.id_vehicul = atb.id_vehicul
WHERE atb.data_sfarsit IS NULL;
