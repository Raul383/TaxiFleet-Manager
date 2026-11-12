USE taxifleet;

-- Q5. Interventiile in service impreuna cu atelierul, vehiculul si piesele inlocuite
SELECT 
    a.nr_inmatriculare,
    ats.denumire AS atelier,
    i.tip_interventie,
    i.data_interventie,
    pi.denumire_piesa,
    pi.cantitate,
    (pi.cantitate * pi.pret_unitar) AS subtotal_piesa
FROM interventii i
JOIN autovehicule a ON i.id_vehicul = a.id_vehicul
JOIN ateliere_service ats ON i.id_atelier = ats.id_atelier
LEFT JOIN piese_interventie pi ON i.id_interventie = pi.id_interventie;
