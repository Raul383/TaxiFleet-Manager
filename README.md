# Sistem de Gestiune a Autovehiculelor, Personalului și Veniturilor pentru o Firmă de Taximetrie
## 1. Domeniul și Problema Concretă
Proiectul vizează modelarea și implementarea unei baze de date relaționale pentru o companie de transport în regim de taxi care își administrează propriul parc de autovehicule.

Problema concretă adresată o constituie descentralizarea datelor operaționale: evidența documentelor autovehiculelor (ITP semestrial, polițe RCA/CASCO, verificări metrologice ceas de taxat, autorizații de transport), evidența documentelor conducătorilor auto (atestate profesionale, avize medicale/psihologice), alocarea pe ture a șoferilor titulari și evidența sumelor încasate la finalul fiecărui schimb de lucru.

## 2. Scopul Proiectului
Construirea unei baze de date relaționale (normalizată minim FN3) care să asigure:
* Integritatea datelor referitoare la autovehicule, șoferi și contracte;
* Monitorizarea automată a termenelor de expirare pentru acte și declanșarea restricțiilor operaționale;
* Urmărirea istoricului de mentenanță și a cheltuielilor de service per vehicul;
* Reconcilierea încasărilor zilnice din rapoartele fiscale cu numărul de kilometri efectuați pe fiecare tură;
* Integrarea cu un modul simplu de Machine Learning (scikit-learn) pentru predicția/clasificarea costurilor de mentenanță sau a anomaliilor de consum/încasări pe baza datelor istorice.