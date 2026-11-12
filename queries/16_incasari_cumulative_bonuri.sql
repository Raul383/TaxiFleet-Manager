USE taxifleet;

-- Q16. Evolutia cumulativa a incasarilor pe bonuri in ordine cronologica (SUM OVER)
SELECT 
    numar_serie,
    data_ora,
    suma,
    SUM(suma) OVER (ORDER BY data_ora ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS incasari_cumulative
FROM bonuri_digitale;
