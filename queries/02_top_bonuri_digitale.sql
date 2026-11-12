USE taxifleet;

-- Q2. Top 3 cele mai mari bonuri digitale emise (dupa suma finala incasata)
SELECT numar_serie, suma, multiplicator, suma_surge, metoda_plata, data_ora
FROM bonuri_digitale
ORDER BY suma DESC
LIMIT 3;
