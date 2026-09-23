# DF-Hack

Heinrich arbeitet an diesem Projekt auf zwei Rechnern (Desktop und Laptop), abgeglichen über GitHub.

## Beim Start jeder Sitzung prüfen

Bevor du auf Heinrichs erste Anfrage eingehst, prüfe diese zwei Dinge und erinnere ihn, wenn etwas zu tun ist:

1. **Ist GitHub neuer als der lokale Stand?** `git fetch` und dann `git status -sb`. Steht dort `behind`, erinnere an `git pull`. Steht dort `ahead`, erinnere an `git push`.
2. **Sind die Orders und Stockpiles von Spiel und Repo gleich?** Führe `python tools/sync_dfhack_config.py status` aus. Liegt DF nicht im Standard-Steam-Pfad, frag nach dem DF-Ordner und gib ihn als zweites Argument mit.
   - `new` unter "push would copy": Die Datei fehlt im Spiel. Erinnere an `python tools/sync_dfhack_config.py push`.
   - `new` unter "pull would copy": Die Datei wurde im Spiel exportiert und fehlt im Repo. Erinnere an `python tools/sync_dfhack_config.py pull`, danach committen und pushen.
   - `changed` steht immer in beiden Richtungen, das Script weiß nicht, welche Seite neuer ist. Nenn die Dateien und frag. Hinweis: Kam die Änderung gerade per `git pull`, ist meist das Repo neuer.

Erinnere nur. Führe `pull`, `push` oder Git-Befehle erst aus, wenn Heinrich es sagt. Wenn alles gleich ist, reicht ein kurzer Satz.
