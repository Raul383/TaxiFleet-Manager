USE taxifleet;

CREATE OR REPLACE VIEW v_documente_scadente AS
SELECT 
    d.id_document,
    td.denumire AS tip_document,
    td.categorie,
    COALESCE(a.nr_inmatriculare, CONCAT(s.nume, ' ', s.prenume)) AS titular,
    d.numar_document,
    d.data_expirarii,
    DATEDIFF(d.data_expirarii, CURDATE()) AS zile_ramase,
    CASE 
        WHEN d.data_expirarii < CURDATE() THEN 'Expirat'
        WHEN DATEDIFF(d.data_expirarii, CURDATE()) <= 15 THEN 'Urgent (<=15 zile)'
        ELSE 'Atentie (<=30 zile)'
    END AS status_valabilitate
FROM documente d
JOIN tipuri_document td ON d.id_tip = td.id_tip
LEFT JOIN autovehicule a ON d.id_vehicul = a.id_vehicul
LEFT JOIN soferi s ON d.id_sofer = s.id_sofer
WHERE d.data_expirarii IS NOT NULL
  AND d.data_expirarii <= DATE_ADD(CURDATE(), INTERVAL 30 DAY);

SELECT * FROM v_documente_scadente;