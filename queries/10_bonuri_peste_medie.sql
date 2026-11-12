USE taxifleet;

-- Q10. Bonurile digitale cu valoare mai mare decat media tuturor bonurilor emise
SELECT numar_serie, suma, metoda_plata, data_ora
FROM bonuri_digitale
WHERE suma > (SELECT AVG(suma) FROM bonuri_digitale);
