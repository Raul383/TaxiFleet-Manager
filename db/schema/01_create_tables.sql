DROP DATABASE IF EXISTS taxifleet;
CREATE DATABASE taxifleet CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; -- Pentru a include diacritice
USE taxifleet;

-- 1. UTILIZATORI (Administrator, Sofer)
CREATE TABLE utilizatori (
  id_utilizator   INT AUTO_INCREMENT PRIMARY KEY,
  nume_utilizator VARCHAR(50)  NOT NULL,
  parola_hash     VARCHAR(255) NOT NULL,
  rol             ENUM('Administrator','Sofer') NOT NULL,
  email           VARCHAR(100) NOT NULL,
  data_creare     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_utilizatori_nume  UNIQUE (nume_utilizator),
  CONSTRAINT uq_utilizatori_email UNIQUE (email)
) ENGINE=InnoDB;

-- 2. PLANURI_TARIFARE (reguli financiare: masina firmei / masina proprie)
CREATE TABLE planuri_tarifare (
  id_plan                   INT AUTO_INCREMENT PRIMARY KEY,
  denumire                  VARCHAR(50) NOT NULL,
  procent_aplicatie         DECIMAL(5,2)  NOT NULL DEFAULT 25,
  chirie_saptamanala        DECIMAL(10,2) NOT NULL DEFAULT 0,
  comision_flota_saptamanal DECIMAL(10,2) NOT NULL DEFAULT 0,
  procent_taxe              DECIMAL(5,2)  NOT NULL DEFAULT 0,
  prag_curse_bonus          INT           NOT NULL DEFAULT 0,   -- 0 = fara bonus
  valoare_bonus             DECIMAL(10,2) NOT NULL DEFAULT 0,
  CONSTRAINT uq_plan_denumire UNIQUE (denumire),
  CONSTRAINT ck_plan_proc  CHECK (procent_aplicatie BETWEEN 0 AND 100 AND procent_taxe BETWEEN 0 AND 100),
  CONSTRAINT ck_plan_sume  CHECK (chirie_saptamanala >= 0 AND comision_flota_saptamanal >= 0 AND valoare_bonus >= 0),
  CONSTRAINT ck_plan_prag  CHECK (prag_curse_bonus >= 0)
) ENGINE=InnoDB;

-- 3. SOFERI (fiecare sofer are un cont de utilizator: 1:1)
CREATE TABLE soferi (
  id_sofer       INT AUTO_INCREMENT PRIMARY KEY,
  id_utilizator  INT NOT NULL,
  nume           VARCHAR(50) NOT NULL,
  prenume        VARCHAR(50) NOT NULL,
  cnp            VARCHAR(13) NOT NULL,
  telefon        VARCHAR(15) NOT NULL,
  adresa         VARCHAR(150) NULL,
  status_activ   BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT uq_sofer_cont UNIQUE (id_utilizator),
  CONSTRAINT uq_sofer_cnp  UNIQUE (cnp),
  CONSTRAINT fk_sofer_cont FOREIGN KEY (id_utilizator) REFERENCES utilizatori(id_utilizator),
  CONSTRAINT ck_sofer_cnp  CHECK (CHAR_LENGTH(cnp) = 13 AND cnp REGEXP '^[0-9]+$')
) ENGINE=InnoDB;

-- 4. AUTOVEHICULE
CREATE TABLE autovehicule (
  id_vehicul        INT AUTO_INCREMENT PRIMARY KEY,
  id_plan           INT NOT NULL,
  nr_inmatriculare  VARCHAR(15) NOT NULL,
  serie_sasiu       VARCHAR(17) NOT NULL,
  marca             VARCHAR(50) NOT NULL,
  model             VARCHAR(50) NOT NULL,
  an_fabricatie     INT NOT NULL,
  km_curenti        INT NOT NULL DEFAULT 0,
  prag_revizie_km   INT NULL,
  status            ENUM('Disponibila','In Tura','In Service','Retrasa din circulatie') NOT NULL DEFAULT 'Disponibila',
  CONSTRAINT uq_auto_nr    UNIQUE (nr_inmatriculare),
  CONSTRAINT uq_auto_sasiu UNIQUE (serie_sasiu),
  CONSTRAINT fk_auto_plan  FOREIGN KEY (id_plan) REFERENCES planuri_tarifare(id_plan),
  CONSTRAINT ck_auto_an    CHECK (an_fabricatie BETWEEN 1990 AND 2100),
  CONSTRAINT ck_auto_km    CHECK (km_curenti >= 0),
  CONSTRAINT ck_auto_prag  CHECK (prag_revizie_km IS NULL OR prag_revizie_km > 0)
) ENGINE=InnoDB;

-- 5. CONTRACTE_COMODAT (masina proprie a unui sofer, pusa in folosinta firmei)
CREATE TABLE contracte_comodat (
  id_contract     INT AUTO_INCREMENT PRIMARY KEY,
  id_vehicul      INT NOT NULL,
  id_sofer        INT NOT NULL,
  numar_contract  VARCHAR(30) NOT NULL,
  data_inceput    DATE NOT NULL,
  data_sfarsit    DATE NOT NULL,
  CONSTRAINT uq_contract_nr    UNIQUE (numar_contract),
  CONSTRAINT fk_contract_auto  FOREIGN KEY (id_vehicul) REFERENCES autovehicule(id_vehicul),
  CONSTRAINT fk_contract_sofer FOREIGN KEY (id_sofer)   REFERENCES soferi(id_sofer),
  CONSTRAINT ck_contract_date  CHECK (data_sfarsit > data_inceput)
) ENGINE=InnoDB;

-- 6. TIPURI_DOCUMENT
CREATE TABLE tipuri_document (
  id_tip        INT AUTO_INCREMENT PRIMARY KEY,
  denumire      VARCHAR(60) NOT NULL,
  categorie     ENUM('Masina','Sofer') NOT NULL,
  obligatoriu   BOOLEAN NOT NULL DEFAULT TRUE,
  are_expirare  BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT uq_tip_denumire UNIQUE (denumire)
) ENGINE=InnoDB;

-- 7. DOCUMENTE (ale unei masini SAU ale unui sofer)
CREATE TABLE documente (
  id_document     INT AUTO_INCREMENT PRIMARY KEY,
  id_tip          INT NOT NULL,
  id_vehicul      INT NULL,
  id_sofer        INT NULL,
  numar_document  VARCHAR(50) NULL,
  data_emiterii   DATE NOT NULL,
  data_expirarii  DATE NULL,
  cost            DECIMAL(10,2) NULL,
  CONSTRAINT fk_doc_tip     FOREIGN KEY (id_tip)     REFERENCES tipuri_document(id_tip),
  CONSTRAINT fk_doc_vehicul FOREIGN KEY (id_vehicul) REFERENCES autovehicule(id_vehicul),
  CONSTRAINT fk_doc_sofer   FOREIGN KEY (id_sofer)   REFERENCES soferi(id_sofer),
  CONSTRAINT ck_doc_proprietar CHECK ((id_vehicul IS NULL) <> (id_sofer IS NULL)),
  CONSTRAINT ck_doc_date  CHECK (data_expirarii IS NULL OR data_expirarii > data_emiterii),
  CONSTRAINT ck_doc_cost  CHECK (cost IS NULL OR cost >= 0)
) ENGINE=InnoDB;
CREATE INDEX ix_doc_expirare ON documente (data_expirarii);

-- 8. ATRIBUIRI_TITULARI (sofer - masina, cu istoric) = relatia M:N
CREATE TABLE atribuiri_titulari (
  id_atribuire  INT AUTO_INCREMENT PRIMARY KEY,
  id_vehicul    INT NOT NULL,
  id_sofer      INT NOT NULL,
  data_inceput  DATE NOT NULL,
  data_sfarsit  DATE NULL,
  CONSTRAINT fk_atr_auto  FOREIGN KEY (id_vehicul) REFERENCES autovehicule(id_vehicul),
  CONSTRAINT fk_atr_sofer FOREIGN KEY (id_sofer)   REFERENCES soferi(id_sofer),
  CONSTRAINT ck_atr_date  CHECK (data_sfarsit IS NULL OR data_sfarsit >= data_inceput)
) ENGINE=InnoDB;

-- 9. PREDICTII_CERERE (rezultatele modelului ML: cerere / surge pe ore)
CREATE TABLE predictii_cerere (
  id_predictie          INT AUTO_INCREMENT PRIMARY KEY,
  zi_saptamana          TINYINT NOT NULL,      -- 1 = luni ... 7 = duminica
  ora                   TINYINT NOT NULL,      -- 0..23
  nivel_cerere          ENUM('Scazuta','Normala','Ridicata','Foarte ridicata') NOT NULL,
  multiplicator_sugerat DECIMAL(3,2) NOT NULL DEFAULT 1.00,
  data_generare         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  versiune_model        VARCHAR(30) NOT NULL,
  CONSTRAINT uq_pred_slot UNIQUE (zi_saptamana, ora, versiune_model),
  CONSTRAINT ck_pred_zi   CHECK (zi_saptamana BETWEEN 1 AND 7),
  CONSTRAINT ck_pred_ora  CHECK (ora BETWEEN 0 AND 23),
  CONSTRAINT ck_pred_mult CHECK (multiplicator_sugerat >= 1)
) ENGINE=InnoDB;

-- 10. DECONT_SAPTAMANAL
CREATE TABLE decont_saptamanal (
  id_decont            INT AUTO_INCREMENT PRIMARY KEY,
  id_sofer             INT NOT NULL,
  id_plan              INT NOT NULL,
  id_admin_verificare  INT NULL,
  id_admin_plata       INT NULL,
  data_start           DATETIME NOT NULL,       -- luni 04:00
  data_sfarsit         DATETIME NOT NULL,       -- urmatoarea luni 04:00 (exclusiv)
  total_incasat        DECIMAL(10,2) NOT NULL,  -- suma BONURILOR din saptamana (dupa ora bonului)
  total_declarat       DECIMAL(10,2) NOT NULL,  -- declarat pe turele inceput in saptamana
  diferenta            DECIMAL(10,2) NOT NULL,  -- declarat - bonuri (pe aceleasi ture); negativ = lipsa
  comision_aplicatie   DECIMAL(10,2) NOT NULL,
  chirie               DECIMAL(10,2) NOT NULL,
  comision_flota       DECIMAL(10,2) NOT NULL,
  taxe                 DECIMAL(10,2) NOT NULL,
  net_calculat         DECIMAL(10,2) NOT NULL,
  total_ajustari       DECIMAL(10,2) NOT NULL DEFAULT 0,   -- bonusuri - amenzi - retineri
  datorie_anterioara   DECIMAL(10,2) NOT NULL DEFAULT 0,
  suma_de_plata        DECIMAL(10,2) NOT NULL,
  datorie_noua         DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_ore_lucrate    DECIMAL(7,2)  NOT NULL,
  numar_ture_lungi     INT NOT NULL,
  flag_norma_sub_48    BOOLEAN NOT NULL,
  stare_decont         ENUM('Generat','Verificat','Achitat') NOT NULL DEFAULT 'Generat',
  data_plata           DATETIME NULL,
  data_generare        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_decont_sofer_sapt UNIQUE (id_sofer, data_start),
  CONSTRAINT fk_decont_sofer FOREIGN KEY (id_sofer) REFERENCES soferi(id_sofer),
  CONSTRAINT fk_decont_plan  FOREIGN KEY (id_plan)  REFERENCES planuri_tarifare(id_plan),
  CONSTRAINT fk_decont_adm1  FOREIGN KEY (id_admin_verificare) REFERENCES utilizatori(id_utilizator),
  CONSTRAINT fk_decont_adm2  FOREIGN KEY (id_admin_plata)      REFERENCES utilizatori(id_utilizator),
  CONSTRAINT ck_decont_date  CHECK (data_sfarsit > data_start),
  CONSTRAINT ck_decont_plata CHECK (suma_de_plata >= 0 AND datorie_noua >= 0 AND datorie_anterioara >= 0)
) ENGINE=InnoDB;

-- 11. TURE_LUCRU
CREATE TABLE ture_lucru (
  id_tura                     INT AUTO_INCREMENT PRIMARY KEY,
  id_vehicul                  INT NOT NULL,
  id_sofer                    INT NOT NULL,
  id_decont                   INT NULL,       -- decontul saptamanii in care a inceput tura
  id_admin_verificare         INT NULL,
  data_ora_plecare            DATETIME NOT NULL,
  km_plecare                  INT NOT NULL,
  data_ora_sosire             DATETIME NULL,
  km_sosire                   INT NULL,
  total_declarat              DECIMAL(10,2) NULL,
  stare_tura                  ENUM('Deschisa','Blocata','De completat','Inchisa') NOT NULL DEFAULT 'Deschisa',
  inchisa_automat             BOOLEAN NOT NULL DEFAULT FALSE,
  data_ora_blocare            DATETIME NULL,  -- calculata la pornire (15h / 8h / ore ramase pana la 60)
  data_ora_ultima_activitate  DATETIME NULL,
  stare_reconciliere          ENUM('In curs','Conforma','Diferenta semnalata','Verificata') NOT NULL DEFAULT 'In curs',
  data_verificare             DATETIME NULL,
  CONSTRAINT fk_tura_auto   FOREIGN KEY (id_vehicul) REFERENCES autovehicule(id_vehicul),
  CONSTRAINT fk_tura_sofer  FOREIGN KEY (id_sofer)   REFERENCES soferi(id_sofer),
  CONSTRAINT fk_tura_decont FOREIGN KEY (id_decont)  REFERENCES decont_saptamanal(id_decont),
  CONSTRAINT fk_tura_admin  FOREIGN KEY (id_admin_verificare) REFERENCES utilizatori(id_utilizator),
  CONSTRAINT ck_tura_km   CHECK (km_plecare >= 0 AND (km_sosire IS NULL OR km_sosire >= km_plecare)),
  CONSTRAINT ck_tura_ore  CHECK (data_ora_sosire IS NULL OR data_ora_sosire > data_ora_plecare),
  CONSTRAINT ck_tura_suma CHECK (total_declarat IS NULL OR total_declarat >= 0)
) ENGINE=InnoDB;
CREATE INDEX ix_tura_sofer   ON ture_lucru (id_sofer, data_ora_plecare);
CREATE INDEX ix_tura_vehicul ON ture_lucru (id_vehicul, data_ora_plecare);

-- 12. BONURI_DIGITALE (fiecare bon = o cursa)
CREATE TABLE bonuri_digitale (
  id_bon        INT AUTO_INCREMENT PRIMARY KEY,
  id_tura       INT NOT NULL,
  id_decont     INT NULL,                 -- decontul saptamanii dupa ora bonului
  id_predictie  INT NULL,                 -- slotul de cerere folosit pentru multiplicator
  numar_serie   VARCHAR(40) NOT NULL,
  suma          DECIMAL(10,2) NOT NULL,   -- pretul final (include surge-ul)
  multiplicator DECIMAL(3,2)  NOT NULL DEFAULT 1.00,
  suma_surge    DECIMAL(10,2) NOT NULL DEFAULT 0,
  data_ora      DATETIME NOT NULL,
  metoda_plata  ENUM('Numerar','Card') NOT NULL,
  CONSTRAINT uq_bon_serie UNIQUE (numar_serie),
  CONSTRAINT fk_bon_tura    FOREIGN KEY (id_tura)      REFERENCES ture_lucru(id_tura),
  CONSTRAINT fk_bon_decont  FOREIGN KEY (id_decont)    REFERENCES decont_saptamanal(id_decont),
  CONSTRAINT fk_bon_pred    FOREIGN KEY (id_predictie) REFERENCES predictii_cerere(id_predictie),
  CONSTRAINT ck_bon CHECK (suma > 0 AND multiplicator >= 1 AND suma_surge >= 0 AND suma_surge <= suma)
) ENGINE=InnoDB;
CREATE INDEX ix_bon_data ON bonuri_digitale (data_ora);

-- 13. ALIMENTARI
CREATE TABLE alimentari (
  id_alimentare  INT AUTO_INCREMENT PRIMARY KEY,
  id_vehicul     INT NOT NULL,
  id_sofer       INT NOT NULL,
  data_ora       DATETIME NOT NULL,
  litri          DECIMAL(6,2) NOT NULL,
  suma           DECIMAL(10,2) NOT NULL,
  km_bord        INT NOT NULL,
  rezervor_plin  BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_alim_auto  FOREIGN KEY (id_vehicul) REFERENCES autovehicule(id_vehicul),
  CONSTRAINT fk_alim_sofer FOREIGN KEY (id_sofer)   REFERENCES soferi(id_sofer),
  CONSTRAINT ck_alim CHECK (litri > 0 AND suma >= 0 AND km_bord >= 0)
) ENGINE=InnoDB;

-- 14. SESIZARI
CREATE TABLE sesizari (
  id_sesizare          INT AUTO_INCREMENT PRIMARY KEY,
  id_sofer             INT NOT NULL,
  id_vehicul           INT NOT NULL,
  id_admin_inspectie   INT NULL,
  data_sesizare        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  descriere            TEXT NOT NULL,
  stare                ENUM('Noua','Inspectata','Trimisa la service','Rezolvata') NOT NULL DEFAULT 'Noua',
  data_inspectie       DATETIME NULL,
  observatii_inspectie TEXT NULL,
  CONSTRAINT fk_ses_sofer FOREIGN KEY (id_sofer)   REFERENCES soferi(id_sofer),
  CONSTRAINT fk_ses_auto  FOREIGN KEY (id_vehicul) REFERENCES autovehicule(id_vehicul),
  CONSTRAINT fk_ses_admin FOREIGN KEY (id_admin_inspectie) REFERENCES utilizatori(id_utilizator)
) ENGINE=InnoDB;

-- 15. ATELIERE_SERVICE
CREATE TABLE ateliere_service (
  id_atelier  INT AUTO_INCREMENT PRIMARY KEY,
  denumire    VARCHAR(100) NOT NULL,
  telefon     VARCHAR(15) NULL,
  adresa      VARCHAR(150) NULL,
  CONSTRAINT uq_atelier UNIQUE (denumire)
) ENGINE=InnoDB;

-- 16. INTERVENTII (inregistrate de administrator)
CREATE TABLE interventii (
  id_interventie    INT AUTO_INCREMENT PRIMARY KEY,
  id_vehicul        INT NOT NULL,
  id_atelier        INT NOT NULL,
  id_admin          INT NOT NULL,
  id_sesizare       INT NULL,
  tip_interventie   ENUM('Revizie','Reparatie') NOT NULL DEFAULT 'Reparatie',
  stare             ENUM('Programata','In desfasurare','Finalizata') NOT NULL DEFAULT 'In desfasurare',
  data_interventie  DATE NOT NULL,
  data_finalizare   DATE NULL,
  km_la_interventie INT NULL,
  descriere         TEXT NULL,
  cost_total        DECIMAL(10,2) NOT NULL DEFAULT 0,
  CONSTRAINT uq_int_sesizare UNIQUE (id_sesizare),
  CONSTRAINT fk_int_auto    FOREIGN KEY (id_vehicul)  REFERENCES autovehicule(id_vehicul),
  CONSTRAINT fk_int_atelier FOREIGN KEY (id_atelier)  REFERENCES ateliere_service(id_atelier),
  CONSTRAINT fk_int_admin   FOREIGN KEY (id_admin)    REFERENCES utilizatori(id_utilizator),
  CONSTRAINT fk_int_ses     FOREIGN KEY (id_sesizare) REFERENCES sesizari(id_sesizare),
  CONSTRAINT ck_int_cost CHECK (cost_total >= 0),
  CONSTRAINT ck_int_data CHECK (data_finalizare IS NULL OR data_finalizare >= data_interventie)
) ENGINE=InnoDB;

-- 17. PIESE_INTERVENTIE
CREATE TABLE piese_interventie (
  id_piesa        INT AUTO_INCREMENT PRIMARY KEY,
  id_interventie  INT NOT NULL,
  denumire_piesa  VARCHAR(100) NOT NULL,
  cantitate       INT NOT NULL DEFAULT 1,
  pret_unitar     DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_piesa_int FOREIGN KEY (id_interventie) REFERENCES interventii(id_interventie) ON DELETE CASCADE,
  CONSTRAINT ck_piesa CHECK (cantitate > 0 AND pret_unitar >= 0)
) ENGINE=InnoDB;

-- 18. AJUSTARI_DECONT (amenzi, retineri pentru daune, bonus pentru curse)
CREATE TABLE ajustari_decont (
  id_ajustare       INT AUTO_INCREMENT PRIMARY KEY,
  id_sofer          INT NOT NULL,
  id_decont         INT NULL,     -- NULL = in asteptare; intra in primul decont generat dupa introducere
  id_admin          INT NULL,     -- NULL doar pentru bonusul automat
  id_tura           INT NULL,     -- tura la care se refera (ex. amenda)
  tip_ajustare      ENUM('Amenda','Retinere daune','Bonus curse') NOT NULL,
  suma              DECIMAL(10,2) NOT NULL,   -- pozitiva; semnul rezulta din tip
  descriere         VARCHAR(255) NULL,
  data_fapta        DATE NOT NULL,
  data_introducere  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_aj_sofer  FOREIGN KEY (id_sofer)   REFERENCES soferi(id_sofer),
  CONSTRAINT fk_aj_decont FOREIGN KEY (id_decont)  REFERENCES decont_saptamanal(id_decont),
  CONSTRAINT fk_aj_admin  FOREIGN KEY (id_admin)   REFERENCES utilizatori(id_utilizator),
  CONSTRAINT fk_aj_tura   FOREIGN KEY (id_tura)    REFERENCES ture_lucru(id_tura),
  CONSTRAINT ck_aj_suma   CHECK (suma > 0)
) ENGINE=InnoDB;

-- 19. ALERTE
CREATE TABLE alerte (
  id_alerta      INT AUTO_INCREMENT PRIMARY KEY,
  tip_alerta     ENUM('Document','Revizie','Contract','Sesizare','Diferenta incasari',
                      'Tura 12 ore','Tura blocata','Aproape de 60 ore','Ture lungi epuizate','Tura inchisa automat') NOT NULL,
  nivel          ENUM('30 zile','15 zile','Expirat','Info') NULL,
  mesaj          VARCHAR(255) NOT NULL,
  data_generare  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  rezolvata      BOOLEAN NOT NULL DEFAULT FALSE,
  id_sofer       INT NULL,        -- destinatar (alertele de limita merg doar catre sofer)
  id_document    INT NULL,
  id_vehicul     INT NULL,
  id_sesizare    INT NULL,
  id_tura        INT NULL,
  id_contract    INT NULL,
  CONSTRAINT fk_al_sofer FOREIGN KEY (id_sofer)    REFERENCES soferi(id_sofer),
  CONSTRAINT fk_al_doc   FOREIGN KEY (id_document) REFERENCES documente(id_document),
  CONSTRAINT fk_al_auto  FOREIGN KEY (id_vehicul)  REFERENCES autovehicule(id_vehicul),
  CONSTRAINT fk_al_ses   FOREIGN KEY (id_sesizare) REFERENCES sesizari(id_sesizare),
  CONSTRAINT fk_al_tura  FOREIGN KEY (id_tura)     REFERENCES ture_lucru(id_tura),
  CONSTRAINT fk_al_ctr   FOREIGN KEY (id_contract) REFERENCES contracte_comodat(id_contract),
  CONSTRAINT ck_al_legatura CHECK (COALESCE(id_sofer,id_document,id_vehicul,id_sesizare,id_tura,id_contract) IS NOT NULL)
) ENGINE=InnoDB;