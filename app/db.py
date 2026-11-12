import os
import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER", "taxifleet_app"),
    "password": os.getenv("DB_PASS", ""),
    "database": os.getenv("DB_NAME", "taxifleet"),
    "charset": "utf8mb4",
}


def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


def format_db_error(err: Error) -> str:
    """Transforma erorile tehnice MariaDB/MySQL in mesaje clare pentru utilizator."""
    msg = str(err)
    if err.errno == 1644 or "RB2 Incalcat" in msg:
        return f"Regulă de business încălcată (RB2): {err.msg}"
    if err.errno in (3819, 4025):
        if "ck_doc_proprietar" in msg:
            return "Constrângere XOR încălcată (RB4): Un document trebuie asociat EXACT unei mașini SAU unui șofer (nu ambelor, nu niciunuia)."
        if "ck_tura_km" in msg:
            return "Validare eșuată: Kilometrajul de sosire nu poate fi mai mic decât kilometrajul de plecare."
        if "ck_sofer_cnp" in msg:
            return "Validare eșuată: CNP-ul trebuie să conțină exact 13 cifre."
        return f"Constrângere de integritate (CHECK) încălcată: {err.msg}"
    if err.errno == 1062:
        return f"Valoare duplicată: Există deja o înregistrare cu aceste date unice ({err.msg})."
    if err.errno == 1451:
        return "Ștergere blocată: Această înregistrare este referită în alte tabele (cheie externă activă)."
    if err.errno == 1452:
        return "Referință invalidă: Una dintre valorile selectate (cheie externă) nu există în baza de date."
    return f"Eroare bază de date [{err.errno}]: {err.msg}"