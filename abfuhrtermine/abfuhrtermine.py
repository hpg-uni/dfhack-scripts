#!/usr/bin/env python3
"""Abfuhrtermine für den Landkreis Tübingen schnell abrufen.

Statt jedes Mal mühsam über die Webseite
https://www.abfall-kreis-tuebingen.de/services/abfuhrtermine/online-abfuhrtermine/online-abfuhrtermine-kalender/
zu klicken, holt dieses Skript die Termine direkt vom AWIDO-Backend
(awido.cubefour.de), das hinter dem Online-Kalender und der "Tübinger
Abfall-App" steckt.

Standardmäßig:
  * Straße  = Pfleghofstraße
  * Ort     = Tübingen
  * Es werden nur kommende Termine angezeigt (vergangene werden ausgeblendet).

Beispiele:
  ./abfuhrtermine.py                      # nächste Termine Pfleghofstraße
  ./abfuhrtermine.py --tage 30            # nur die nächsten 30 Tage
  ./abfuhrtermine.py --strasse "Wilhelmstraße"
  ./abfuhrtermine.py --ort Dettenhausen   # Orte ohne Straßenauswahl
  ./abfuhrtermine.py --ics tuebingen.ics  # Kalenderdatei zum Abonnieren erzeugen
  ./abfuhrtermine.py --orte               # alle wählbaren Orte auflisten
  ./abfuhrtermine.py --strassen           # alle Straßen des Orts auflisten

Nur Python-Standardbibliothek nötig – kein pip install.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://awido.cubefour.de"
SVC = BASE + "/WebServices/Awido.Service.svc/secure"

WOCHENTAGE = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
MONATE = ["", "Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
          "August", "September", "Oktober", "November", "Dezember"]

# Standardwerte – genau das, was meistens gebraucht wird.
DEFAULT_CUSTOMER = "tuebingen"
DEFAULT_ORT = "Tübingen"
DEFAULT_STRASSE = "Pfleghofstraße"


def _get(url: str, params: dict | None = None) -> bytes:
    if params:
        url = url + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "abfuhrtermine.py (persoenliches Tool)",
            "Accept": "application/json, text/plain, */*",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.read()
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP-Fehler {e.code} bei {url}")
    except urllib.error.URLError as e:
        raise SystemExit(f"Netzwerkfehler bei {url}: {e.reason}")


def _get_json(url: str, params: dict | None = None):
    raw = _get(url, params)
    text = raw.decode("utf-8-sig").strip()
    if not text:
        return None
    return json.loads(text)


def get_places(customer: str) -> dict[str, str]:
    """Ort (lowercase) -> oid."""
    data = _get_json(f"{SVC}/getPlaces/client={customer}") or []
    return {p["value"].strip().lower(): p["key"] for p in data}


def get_streets(customer: str, place_oid: str) -> dict[str, str]:
    """Straße (lowercase) -> oid."""
    data = _get_json(
        f"{SVC}/getGroupedStreets/{place_oid}", {"client": customer}
    ) or []
    return {s["value"].strip().lower(): s["key"] for s in data}


def resolve_oid(customer: str, ort: str, strasse: str | None) -> str:
    places = get_places(customer)
    ort_key = ort.strip().lower()
    if ort_key not in places:
        _fail_with_suggestions("Ort", ort, places.keys())
    place_oid = places[ort_key]

    if strasse is None:
        # Manche Orte (z.B. Dettenhausen) haben keine Straßenauswahl –
        # dann ist der Ort selbst die "Straße".
        streets = get_streets(customer, place_oid)
        if not streets:
            return place_oid
        return next(iter(streets.values()))

    streets = get_streets(customer, place_oid)
    skey = strasse.strip().lower()
    if skey in streets:
        return streets[skey]
    # Toleranter Treffer per Teilstring (z.B. ohne "straße"-Suffix).
    treffer = [v for k, v in streets.items() if skey in k]
    if len(treffer) == 1:
        return treffer[0]
    _fail_with_suggestions("Straße", strasse, streets.keys())


def _fail_with_suggestions(label: str, value: str, options) -> None:
    options = sorted(options)
    vlow = value.strip().lower()
    near = [o for o in options if vlow in o or o in vlow][:15]
    msg = [f"{label} '{value}' nicht gefunden."]
    if near:
        msg.append("Meintest du eventuell:")
        msg += [f"  - {o}" for o in near]
    else:
        msg.append(f"Verfügbar sind {len(options)} Einträge. "
                   f"Liste anzeigen mit --orte bzw. --strassen.")
    raise SystemExit("\n".join(msg))


def fetch_collections(customer: str, oid: str) -> list[tuple[dt.date, str]]:
    """Liste von (Datum, Abfallart), chronologisch sortiert."""
    data = _get_json(
        f"{SVC}/getData/{oid}", {"fractions": "", "client": customer}
    )
    if not data:
        raise SystemExit("Keine Kalenderdaten erhalten (leere Antwort).")

    fractions = {f["snm"]: f["nm"] for f in data.get("fracts", [])}
    out: list[tuple[dt.date, str]] = []
    for item in data.get("calendar", []):
        # Einträge mit ad == None sind Feiertage, keine Abfuhr.
        if item.get("ad") is None:
            continue
        date = dt.datetime.strptime(item["dt"], "%Y%m%d").date()
        for code in item.get("fr") or []:
            out.append((date, fractions.get(code, str(code))))
    out.sort(key=lambda x: (x[0], x[1]))
    return out


def filter_window(
    collections, ab: dt.date, tage: int | None
) -> list[tuple[dt.date, str]]:
    bis = ab + dt.timedelta(days=tage) if tage else None
    res = []
    for date, art in collections:
        if date < ab:
            continue
        if bis and date > bis:
            continue
        res.append((date, art))
    return res


def fmt_date(d: dt.date, heute: dt.date) -> str:
    delta = (d - heute).days
    if delta == 0:
        rel = "heute"
    elif delta == 1:
        rel = "morgen"
    else:
        rel = f"in {delta} Tagen"
    return f"{WOCHENTAGE[d.weekday()]} {d.strftime('%d.%m.%Y')} ({rel})"


def print_schedule(collections, heute: dt.date, ort: str, strasse: str | None) -> None:
    titel = f"Abfuhrtermine {ort}" + (f", {strasse}" if strasse else "")
    print(titel)
    print("=" * len(titel))

    if not collections:
        print("Keine kommenden Termine im gewählten Zeitraum.")
        return

    # Nächster Termin je Abfallart (kompakte Übersicht).
    naechste: dict[str, dt.date] = {}
    for date, art in collections:
        naechste.setdefault(art, date)
    print("\nNächste Abfuhr je Tonne:")
    for art in sorted(naechste):
        print(f"  {art:<22} {fmt_date(naechste[art], heute)}")

    # Vollständige chronologische Liste.
    print("\nAlle kommenden Termine:")
    aktueller_monat = None
    for date, art in collections:
        monat = f"{MONATE[date.month]} {date.year}"
        if monat != aktueller_monat:
            print(f"\n  {monat}")
            aktueller_monat = monat
        print(f"    {WOCHENTAGE[date.weekday()]} {date.strftime('%d.%m.')}  {art}")


def write_ics(collections, pfad: str, ort: str, strasse: str | None) -> None:
    lab = ort + (f", {strasse}" if strasse else "")
    lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//abfuhrtermine.py//Landkreis Tuebingen//DE",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        f"X-WR-CALNAME:Abfuhr {lab}",
    ]
    for i, (date, art) in enumerate(collections):
        ds = date.strftime("%Y%m%d")
        de = (date + dt.timedelta(days=1)).strftime("%Y%m%d")
        uid = f"{ds}-{i}-{abs(hash(art)) % 100000}@abfuhrtermine"
        lines += [
            "BEGIN:VEVENT",
            f"UID:{uid}",
            f"DTSTART;VALUE=DATE:{ds}",
            f"DTEND;VALUE=DATE:{de}",
            f"SUMMARY:{art} ({lab})",
            "TRANSP:TRANSPARENT",
            # Erinnerung am Vorabend um 18:00.
            "BEGIN:VALARM",
            "ACTION:DISPLAY",
            f"DESCRIPTION:Morgen: {art}",
            "TRIGGER:-PT15H",
            "END:VALARM",
            "END:VEVENT",
        ]
    lines.append("END:VCALENDAR")
    with open(pfad, "w", encoding="utf-8") as f:
        f.write("\r\n".join(lines) + "\r\n")
    print(f"{len(collections)} Termine nach {pfad} geschrieben.")


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(
        description="Abfuhrtermine Landkreis Tübingen schnell abrufen.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--ort", default=DEFAULT_ORT, help=f"Ort (Standard: {DEFAULT_ORT})")
    p.add_argument(
        "--strasse",
        default=DEFAULT_STRASSE,
        help=f"Straße (Standard: {DEFAULT_STRASSE})",
    )
    p.add_argument("--kunde", default=DEFAULT_CUSTOMER, help=argparse.SUPPRESS)
    p.add_argument("--tage", type=int, default=None,
                   help="Nur die nächsten N Tage anzeigen.")
    p.add_argument("--alle", action="store_true",
                   help="Auch vergangene Termine einbeziehen.")
    p.add_argument("--ics", metavar="DATEI",
                   help="Termine als .ics-Kalenderdatei speichern.")
    p.add_argument("--json", action="store_true",
                   help="Ausgabe als JSON (zum Weiterverarbeiten).")
    p.add_argument("--orte", action="store_true",
                   help="Alle wählbaren Orte auflisten und beenden.")
    p.add_argument("--strassen", action="store_true",
                   help="Alle Straßen des gewählten Orts auflisten und beenden.")
    args = p.parse_args(argv)

    if args.orte:
        for ort in sorted(get_places(args.kunde)):
            print(ort.title())
        return 0

    if args.strassen:
        places = get_places(args.kunde)
        key = args.ort.strip().lower()
        if key not in places:
            _fail_with_suggestions("Ort", args.ort, places.keys())
        streets = get_streets(args.kunde, places[key])
        if not streets:
            print(f"{args.ort}: keine Straßenauswahl (ganzer Ort hat einen Plan).")
        for s in sorted(streets):
            print(s.title())
        return 0

    # "--strasse ''" erlaubt Orte ohne Straßenauswahl.
    strasse = args.strasse if args.strasse else None
    oid = resolve_oid(args.kunde, args.ort, strasse)
    collections = fetch_collections(args.kunde, oid)

    heute = dt.date.today()
    if not args.alle:
        collections = filter_window(collections, heute, args.tage)
    elif args.tage:
        collections = filter_window(
            collections, heute - dt.timedelta(days=10000), args.tage
        )

    if args.json:
        print(json.dumps(
            [{"datum": d.isoformat(), "art": a} for d, a in collections],
            ensure_ascii=False, indent=2,
        ))
        return 0

    if args.ics:
        write_ics(collections, args.ics, args.ort, strasse)
        return 0

    print_schedule(collections, heute, args.ort, strasse)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
