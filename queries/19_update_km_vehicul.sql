USE taxifleet;

-- Q19. UPDATE: Actualizarea kilometrajului curent al vehiculului pe baza ultimei ture inchise
UPDATE autovehicule a
SET a.km_curenti = (
    SELECT MAX(t.km_sosire) 
    FROM ture_lucru t 
    WHERE t.id_vehicul = a.id_vehicul AND t.km_sosire IS NOT NULL
)
WHERE a.id_vehicul = 1;
