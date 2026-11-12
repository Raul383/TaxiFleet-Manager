USE taxifleet;

-- Q9. Autovehicule care au depasit pragul de revizie si NU au o interventie activa (NOT EXISTS)
SELECT a.id_vehicul, a.nr_inmatriculare, a.marca, a.model, a.km_curenti, a.prag_revizie_km
FROM autovehicule a
WHERE a.prag_revizie_km IS NOT NULL
  AND a.km_curenti >= a.prag_revizie_km
  AND NOT EXISTS (
      SELECT 1 
      FROM interventii i 
      WHERE i.id_vehicul = a.id_vehicul 
        AND i.stare IN ('Programata', 'In desfasurare')
  );
