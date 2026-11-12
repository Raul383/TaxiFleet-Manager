import glob
import os
from flask import Flask, flash, redirect, render_template, request, url_for
from mysql.connector import Error
from db import format_db_error, get_connection

app = Flask(__name__)
app.secret_key = "taxifleet_secret_key_local"

QUERIES_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "queries"))


@app.route("/")
def index():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT COUNT(*) AS total FROM autovehicule")
    total_auto = cur.fetchone()["total"]
    cur.execute("SELECT COUNT(*) AS total FROM soferi WHERE status_activ = TRUE")
    total_soferi = cur.fetchone()["total"]
    cur.execute("SELECT COUNT(*) AS total FROM ture_lucru")
    total_ture = cur.fetchone()["total"]
    cur.execute("SELECT * FROM v_documente_scadente ORDER BY zile_ramase ASC")
    scadente = cur.fetchall()
    cur.execute("SELECT * FROM alerte WHERE rezolvata = FALSE ORDER BY data_generare DESC")
    alerte = cur.fetchall()
    cur.close()
    conn.close()
    return render_template(
        "index.html",
        total_auto=total_auto,
        total_soferi=total_soferi,
        total_ture=total_ture,
        scadente=scadente,
        alerte=alerte,
    )


# ==================== 1. CRUD AUTOVEHICULE ====================
@app.route("/autovehicule", methods=["GET", "POST"])
def autovehicule():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)

    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "create":
                cur.execute(
                    """INSERT INTO autovehicule
                       (id_plan, nr_inmatriculare, serie_sasiu, marca, model, an_fabricatie, km_curenti, prag_revizie_km, status)
                       VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                    (
                        request.form["id_plan"],
                        request.form["nr_inmatriculare"].upper().strip(),
                        request.form["serie_sasiu"].upper().strip(),
                        request.form["marca"].strip(),
                        request.form["model"].strip(),
                        int(request.form["an_fabricatie"]),
                        int(request.form["km_curenti"]),
                        int(request.form["prag_revizie_km"]) if request.form.get("prag_revizie_km") else None,
                        request.form["status"],
                    ),
                )
                conn.commit()
                flash("Autovehicul adăugat cu succes!", "success")

            elif action == "update":
                cur.execute(
                    """UPDATE autovehicule
                       SET km_curenti = %s, status = %s, id_plan = %s
                       WHERE id_vehicul = %s""",
                    (
                        int(request.form["km_curenti"]),
                        request.form["status"],
                        request.form["id_plan"],
                        request.form["id_vehicul"],
                    ),
                )
                conn.commit()
                flash("Autovehicul actualizat!", "success")

            elif action == "delete":
                cur.execute("DELETE FROM autovehicule WHERE id_vehicul = %s", (request.form["id_vehicul"],))
                conn.commit()
                flash("Autovehicul șters!", "success")

        except Error as e:
            conn.rollback()
            flash(format_db_error(e), "danger")

        cur.close()
        conn.close()
        return redirect(url_for("autovehicule"))

    cur.execute(
        """SELECT a.*, p.denumire AS plan_nume
           FROM autovehicule a
           JOIN planuri_tarifare p ON a.id_plan = p.id_plan
           ORDER BY a.id_vehicul"""
    )
    lista = cur.fetchall()
    cur.execute("SELECT id_plan, denumire FROM planuri_tarifare")
    planuri = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("autovehicule.html", lista=lista, planuri=planuri)


# ==================== 2. CRUD SOFERI ====================
@app.route("/soferi", methods=["GET", "POST"])
def soferi():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)

    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "create":
                nume = request.form["nume"].strip()
                prenume = request.form["prenume"].strip()
                username = f"{nume.lower()}_{prenume.lower()}_{request.form['cnp'][-3:]}"
                email = f"{username}@taxifleet.ro"
                cur.execute(
                    "INSERT INTO utilizatori (nume_utilizator, parola_hash, rol, email) VALUES (%s, %s, 'Sofer', %s)",
                    (username, "pbkdf2:sha256:260000$default_hash", email),
                )
                id_user = cur.lastrowid
                cur.execute(
                    """INSERT INTO soferi (id_utilizator, nume, prenume, cnp, telefon, adresa, status_activ)
                       VALUES (%s, %s, %s, %s, %s, %s, %s)""",
                    (
                        id_user,
                        nume,
                        prenume,
                        request.form["cnp"].strip(),
                        request.form["telefon"].strip(),
                        request.form.get("adresa", "").strip() or None,
                        True,
                    ),
                )
                conn.commit()
                flash(f"Șofer adăugat (cont generat: {username})!", "success")

            elif action == "update":
                cur.execute(
                    "UPDATE soferi SET telefon = %s, adresa = %s, status_activ = %s WHERE id_sofer = %s",
                    (
                        request.form["telefon"].strip(),
                        request.form.get("adresa", "").strip() or None,
                        1 if request.form.get("status_activ") == "1" else 0,
                        request.form["id_sofer"],
                    ),
                )
                conn.commit()
                flash("Datele șoferului au fost actualizate!", "success")

            elif action == "delete":
                cur.execute("DELETE FROM soferi WHERE id_sofer = %s", (request.form["id_sofer"],))
                conn.commit()
                flash("Șofer șters!", "success")

        except Error as e:
            conn.rollback()
            flash(format_db_error(e), "danger")

        cur.close()
        conn.close()
        return redirect(url_for("soferi"))

    cur.execute(
        """SELECT s.*, u.nume_utilizator, u.email
           FROM soferi s
           JOIN utilizatori u ON s.id_utilizator = u.id_utilizator
           ORDER BY s.id_sofer"""
    )
    lista = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("soferi.html", lista=lista)


# ==================== 3. CRUD DOCUMENTE (XOR) ====================
@app.route("/documente", methods=["GET", "POST"])
def documente():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)

    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "create":
                id_vehicul = request.form.get("id_vehicul") or None
                id_sofer = request.form.get("id_sofer") or None
                cur.execute(
                    """INSERT INTO documente (id_tip, id_vehicul, id_sofer, numar_document, data_emiterii, data_expirarii, cost)
                       VALUES (%s, %s, %s, %s, %s, %s, %s)""",
                    (
                        request.form["id_tip"],
                        id_vehicul,
                        id_sofer,
                        request.form.get("numar_document") or None,
                        request.form["data_emiterii"],
                        request.form.get("data_expirarii") or None,
                        request.form.get("cost") or None,
                    ),
                )
                conn.commit()
                flash("Document înregistrat cu succes!", "success")

            elif action == "delete":
                cur.execute("DELETE FROM documente WHERE id_document = %s", (request.form["id_document"],))
                conn.commit()
                flash("Document șters!", "success")

        except Error as e:
            conn.rollback()
            flash(format_db_error(e), "danger")

        cur.close()
        conn.close()
        return redirect(url_for("documente"))

    cur.execute(
        """SELECT d.*, td.denumire AS tip_nume, td.categorie,
                  a.nr_inmatriculare, CONCAT(s.nume, ' ', s.prenume) AS sofer_nume
           FROM documente d
           JOIN tipuri_document td ON d.id_tip = td.id_tip
           LEFT JOIN autovehicule a ON d.id_vehicul = a.id_vehicul
           LEFT JOIN soferi s ON d.id_sofer = s.id_sofer
           ORDER BY d.id_document DESC"""
    )
    lista = cur.fetchall()
    cur.execute("SELECT * FROM tipuri_document")
    tipuri = cur.fetchall()
    cur.execute("SELECT id_vehicul, nr_inmatriculare, marca, model FROM autovehicule")
    masini = cur.fetchall()
    cur.execute("SELECT id_sofer, nume, prenume FROM soferi")
    soferi_lista = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("documente.html", lista=lista, tipuri=tipuri, masini=masini, soferi=soferi_lista)


# ==================== 4. CRUD TURE LUCRU (TEST RB2) ====================
@app.route("/ture", methods=["GET", "POST"])
def ture():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)

    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "create":
                plecare = request.form["data_ora_plecare"].replace("T", " ") + ":00"
                cur.execute(
                    """INSERT INTO ture_lucru (id_vehicul, id_sofer, data_ora_plecare, km_plecare, stare_tura)
                       VALUES (%s, %s, %s, %s, 'Deschisa')""",
                    (
                        request.form["id_vehicul"],
                        request.form["id_sofer"],
                        plecare,
                        int(request.form["km_plecare"]),
                    ),
                )
                conn.commit()
                flash("Tură deschisă cu succes! Toate documentele sunt valide.", "success")

            elif action == "close":
                sosire = request.form["data_ora_sosire"].replace("T", " ") + ":00"
                cur.execute(
                    """UPDATE ture_lucru
                       SET data_ora_sosire = %s, km_sosire = %s, total_declarat = %s, stare_tura = 'Inchisa'
                       WHERE id_tura = %s""",
                    (
                        sosire,
                        int(request.form["km_sosire"]),
                        float(request.form["total_declarat"]),
                        request.form["id_tura"],
                    ),
                )
                conn.commit()
                flash("Tură închisă!", "success")

            elif action == "delete":
                cur.execute("DELETE FROM ture_lucru WHERE id_tura = %s", (request.form["id_tura"],))
                conn.commit()
                flash("Tură ștearsă!", "success")

        except Error as e:
            conn.rollback()
            flash(format_db_error(e), "danger")

        cur.close()
        conn.close()
        return redirect(url_for("ture"))

    cur.execute(
        """SELECT t.*, a.nr_inmatriculare, CONCAT(s.nume, ' ', s.prenume) AS sofer_nume
           FROM ture_lucru t
           JOIN autovehicule a ON t.id_vehicul = a.id_vehicul
           JOIN soferi s ON t.id_sofer = s.id_sofer
           ORDER BY t.id_tura DESC"""
    )
    lista = cur.fetchall()
    cur.execute("SELECT id_vehicul, nr_inmatriculare, marca, model, km_curenti FROM autovehicule")
    masini = cur.fetchall()
    cur.execute("SELECT id_sofer, nume, prenume FROM soferi")
    soferi_lista = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("ture.html", lista=lista, masini=masini, soferi=soferi_lista)


# ==================== 5. CRUD ATRIBUIRI M:N ====================
@app.route("/atribuiri", methods=["GET", "POST"])
def atribuiri():
    conn = get_connection()
    cur = conn.cursor(dictionary=True)

    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "create":
                cur.execute(
                    "INSERT INTO atribuiri_titulari (id_vehicul, id_sofer, data_inceput) VALUES (%s, %s, %s)",
                    (request.form["id_vehicul"], request.form["id_sofer"], request.form["data_inceput"]),
                )
                conn.commit()
                flash("Atribuire titular înregistrată!", "success")
            elif action == "close":
                cur.execute(
                    "UPDATE atribuiri_titulari SET data_sfarsit = CURDATE() WHERE id_atribuire = %s",
                    (request.form["id_atribuire"],),
                )
                conn.commit()
                flash("Atribuire încheiată!", "success")
            elif action == "delete":
                cur.execute("DELETE FROM atribuiri_titulari WHERE id_atribuire = %s", (request.form["id_atribuire"],))
                conn.commit()
                flash("Atribuire ștearsă!", "success")
        except Error as e:
            conn.rollback()
            flash(format_db_error(e), "danger")

        cur.close()
        conn.close()
        return redirect(url_for("atribuiri"))

    cur.execute(
        """SELECT atb.*, a.nr_inmatriculare, a.marca, a.model, CONCAT(s.nume, ' ', s.prenume) AS sofer_nume
           FROM atribuiri_titulari atb
           JOIN autovehicule a ON atb.id_vehicul = a.id_vehicul
           JOIN soferi s ON atb.id_sofer = s.id_sofer
           ORDER BY atb.id_atribuire DESC"""
    )
    lista = cur.fetchall()
    cur.execute("SELECT id_vehicul, nr_inmatriculare, marca, model FROM autovehicule")
    masini = cur.fetchall()
    cur.execute("SELECT id_sofer, nume, prenume FROM soferi")
    soferi_lista = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("atribuiri.html", lista=lista, masini=masini, soferi=soferi_lista)


# ==================== 6. RAPOARTE (CELE 20 DE INTEROGARI) ====================
@app.route("/rapoarte", methods=["GET", "POST"])
def rapoarte():
    files = sorted(glob.glob(os.path.join(QUERIES_DIR, "*.sql")))
    query_list = []
    for fpath in files:
        fname = os.path.basename(fpath)
        with open(fpath, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if not line.strip().upper().startswith("USE ")]
        title = fname
        sql_lines = []
        for line in lines:
            if line.startswith("--"):
                title = line.lstrip("- ").strip()
            else:
                sql_lines.append(line)
        query_list.append({"file": fname, "title": title, "sql": "\n".join(sql_lines).strip()})

    selected_file = request.form.get("query_file") or (query_list[0]["file"] if query_list else None)
    selected_query = next((q for q in query_list if q["file"] == selected_file), None)
    rows, columns, affected = [], [], None

    if request.method == "POST" and selected_query:
        conn = get_connection()
        cur = conn.cursor(dictionary=True)
        try:
            cur.execute(selected_query["sql"])
            if cur.with_rows:
                rows = cur.fetchall()
                columns = list(rows[0].keys()) if rows else [desc[0] for desc in cur.description]
            else:
                conn.commit()
                affected = cur.rowcount
                flash(f"Comandă executată cu succes ({affected} rânduri afectate).", "success")
        except Error as e:
            conn.rollback()
            flash(format_db_error(e), "danger")
        finally:
            cur.close()
            conn.close()

    return render_template(
        "rapoarte.html",
        query_list=query_list,
        selected_query=selected_query,
        rows=rows,
        columns=columns,
        affected=affected,
    )


if __name__ == "__main__":
    app.run(debug=True, port=5000)