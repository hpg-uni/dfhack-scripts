# Abfuhrtermine Landkreis Tübingen

Kleines Kommandozeilen-Tool, um die Abfuhrtermine (Restmüll, Bioabfall, Gelber
Sack, Altpapier …) schnell abzurufen – ohne sich jedes Mal durch den
[Online-Kalender](https://www.abfall-kreis-tuebingen.de/services/abfuhrtermine/online-abfuhrtermine/online-abfuhrtermine-kalender/)
zu klicken.

Standardmäßig fragt es die **Pfleghofstraße in Tübingen** ab und zeigt nur
**kommende** Termine.

## Wie es funktioniert

Hinter dem Online-Kalender und der „Tübinger Abfall-App" steckt das
AWIDO-Backend (`awido.cubefour.de`, Kunde `tuebingen`). Das Skript spricht
dessen JSON-Schnittstelle direkt an. Es braucht **nur Python 3** (Standard­
bibliothek), kein `pip install`.

## Benutzung

```bash
./abfuhrtermine.py                      # nächste Termine Pfleghofstraße
./abfuhrtermine.py --tage 30            # nur die nächsten 30 Tage
./abfuhrtermine.py --strasse "Wilhelmstraße"
./abfuhrtermine.py --ort Dettenhausen --strasse ""   # Orte ohne Straßenauswahl
./abfuhrtermine.py --orte               # alle wählbaren Orte auflisten
./abfuhrtermine.py --strassen           # alle Straßen des Orts auflisten
./abfuhrtermine.py --json               # maschinenlesbare Ausgabe
```

### Einmal abonnieren statt jedes Mal suchen

```bash
./abfuhrtermine.py --ics ~/Abfuhr-Tuebingen.ics
```

Die erzeugte `.ics`-Datei lässt sich in jeden Kalender (Apple Kalender,
Google Kalender, Thunderbird, Outlook …) importieren. Jeder Termin ist ein
Ganztagestermin mit Erinnerung am Vorabend um 18:00 Uhr.

Tipp: Per Cron/Task einmal pro Woche neu erzeugen lassen, dann ist der
Kalender immer aktuell:

```cron
0 6 * * 1  /pfad/zu/abfuhrtermine.py --ics /pfad/zu/Abfuhr-Tuebingen.ics
```

## Optionen

| Option        | Bedeutung                                            |
|---------------|------------------------------------------------------|
| `--ort`       | Ort (Standard: Tübingen)                             |
| `--strasse`   | Straße (Standard: Pfleghofstraße; `""` = ohne)       |
| `--tage N`    | nur die nächsten N Tage                              |
| `--alle`      | auch vergangene Termine einbeziehen                  |
| `--ics DATEI` | Termine als Kalenderdatei speichern                  |
| `--json`      | Ausgabe als JSON                                     |
| `--orte`      | alle wählbaren Orte auflisten                        |
| `--strassen`  | alle Straßen des gewählten Orts auflisten            |
