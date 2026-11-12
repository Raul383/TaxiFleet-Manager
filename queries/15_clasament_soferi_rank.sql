USE taxifleet;

-- Q15. Clasamentul soferilor in functie de suma neta de plata din deconturi (RANK OVER)
SELECT 
    CONCAT(s.nume, ' ', s.prenume) AS sofer,
    d.data_start,
    d.net_calculat,
    d.suma_de_plata,
    RANK() OVER (ORDER BY d.suma_de_plata DESC) AS loc_clasament
FROM decont_saptamanal d
JOIN soferi s ON d.id_sofer = s.id_sofer;
