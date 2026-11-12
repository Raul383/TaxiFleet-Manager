USE taxifleet;

-- Q14. Interogarea vederii v_documente_scadente pentru actele expirate sau scadente in 30 zile
SELECT * FROM v_documente_scadente
ORDER BY zile_ramase ASC;
