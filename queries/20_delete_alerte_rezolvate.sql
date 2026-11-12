USE taxifleet;

-- Q20. DELETE: Stergerea alertelor marcate ca rezolvate mai vechi de 30 de zile
DELETE FROM alerte
WHERE rezolvata = TRUE 
  AND data_generare < DATE_SUB(NOW(), INTERVAL 30 DAY);
