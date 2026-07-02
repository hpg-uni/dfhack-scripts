# Abfuhrtermine Landkreis Tübingen

Kleines Tool, das mit **einem Aufruf den nächsten Biomüll-Termin** für die
Pfleghofstraße in Tübingen zeigt – statt sich jedes Mal durch den
[Online-Kalender](https://www.abfall-kreis-tuebingen.de/services/abfuhrtermine/online-abfuhrtermine/online-abfuhrtermine-kalender/)
zu klicken.

```
$ ./abfuhrtermine.py
Nächster Bioabfall:
  Mittwoch, 08.07.2026  (in 10 Tagen)
```

## Wie es funktioniert

Hinter dem Online-Kalender und der „Tübinger Abfall-App" steckt das
AWIDO-Backend (`awido.cubefour.de`, Kunde `tuebingen`). Das Skript spricht
dessen JSON-Schnittstelle direkt an. Es braucht **nur Python 3** (Standard­
bibliothek), kein `pip install`.

## Am Handy (Android)

1. **Pydroid 3** aus dem Play Store installieren (bringt Python mit).
2. `abfuhrtermine.py` in Pydroid öffnen.
3. Auf ▶︎ tippen → der nächste Biomüll-Termin steht da.

Optional einen Homescreen-Shortcut über das Pydroid-Widget anlegen, dann ist
es ein Tipp vom Startbildschirm.

## Weitere Optionen (falls doch mal nötig)

| Aufruf                          | Ergebnis                                  |
|---------------------------------|-------------------------------------------|
| `./abfuhrtermine.py`            | nächster **Biomüll**-Termin (Standard)    |
| `./abfuhrtermine.py --art Restmüll` | nächster Restmüll-Termin              |
| `./abfuhrtermine.py --liste`    | alle Tonnen, alle kommenden Termine       |
| `./abfuhrtermine.py --strasse "Wilhelmstraße"` | andere Straße              |
| `./abfuhrtermine.py --strassen` | exakte Straßennamen auflisten             |
| `./abfuhrtermine.py --orte`     | alle wählbaren Orte auflisten             |

`--art` trifft per Teilwort, Groß/Kleinschreibung egal (`bio`, `rest`, `papier`, `gelb`).
