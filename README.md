# Sistem de Gestiune a Autovehiculelor, Personalului și Veniturilor pentru o Firmă de Taximetrie

## 1. Domeniul și Problema Concretă

Proiectul vizează modelarea și implementarea unei baze de date relaționale pentru o companie de transport în regim de taxi care își administrează propriul parc de autovehicule.

Problema concretă adresată o constituie descentralizarea datelor operaționale: evidența documentelor autovehiculelor (ITP semestrial, polițe RCA/CASCO, autorizații de taxi), evidența documentelor conducătorilor auto (permis, atestat profesional, avize medicale și psihologice, cazier judiciar), alocarea pe ture a șoferilor titulari, evidența sumelor încasate și predate la finalul fiecărei ture și evidența intervențiilor de mentenanță.

## 2. Scopul Proiectului

Construirea unei baze de date relaționale (normalizată minim FN3) care să asigure:

* Integritatea datelor referitoare la autovehicule, șoferi și atribuirile șofer–autovehicul;
* Monitorizarea automată a termenelor de expirare pentru documente, generarea de alerte și blocarea deschiderii turelor pentru șoferii sau mașinile cu documente expirate;
* Urmărirea istoricului de mentenanță și a cheltuielilor de service per vehicul, cu aprobarea cheltuielilor de către administrator;
* Reconcilierea încasărilor: compararea totalului încasat cu suma predată, raportate la numărul de kilometri efectuați pe fiecare tură;
* Integrarea cu un modul simplu de Machine Learning (scikit-learn) pentru estimarea costurilor de mentenanță și a riscului de avarie pe baza datelor istorice, rezultatele fiind salvate în baza de date (`predictii_mentenanta_ml`).
