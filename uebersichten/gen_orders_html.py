# -*- coding: utf-8 -*-
"""Erzeugt die Orders-Uebersicht neu.

Nimmt die bestehende HTML als Template (Stil und JS bleiben unveraendert),
tauscht nur die eingebettete Datenzeile `const DATA = [...]` und das
Erzeugt-Datum in der Unterzeile aus.

    python gen_orders_html.py <quell-ordner> <ziel-html> [datum]

Beispiel:
    python gen_orders_html.py "C:\\...\\dfhack-config\\orders" orders-uebersicht.html
"""
import json, os, sys, glob, re, datetime

def build(src_dir, out_html, datum=None):
    datum = datum or datetime.date.today().isoformat()
    data = []
    for f in sorted(glob.glob(os.path.join(src_dir, "*.json"))):
        with open(f, encoding="utf-8-sig") as fh:
            orders = json.load(fh)
        if isinstance(orders, dict):
            orders = orders.get("orders", [orders])
        data.append({"name": os.path.splitext(os.path.basename(f))[0], "orders": orders})

    with open(out_html, encoding="utf-8") as fh:
        lines = fh.read().split("\n")

    line = "const DATA = " + json.dumps(data, ensure_ascii=False) + ";"
    hits = [i for i, l in enumerate(lines) if l.startswith("const DATA = ")]
    assert len(hits) == 1, f"const DATA nicht eindeutig gefunden ({len(hits)}x)"
    lines[hits[0]] = line

    for i, l in enumerate(lines):
        if "Erzeugt " in l and 'class="sub"' in l:
            lines[i] = re.sub(r"Erzeugt \d{4}-\d{2}-\d{2}", f"Erzeugt {datum}", l)

    with open(out_html, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))

    return len(data), sum(len(d["orders"]) for d in data)


if __name__ == "__main__":
    src, out = sys.argv[1], sys.argv[2]
    datum = sys.argv[3] if len(sys.argv) > 3 else None
    n_files, n_orders = build(src, out, datum)
    print(f"{out}: {n_files} Dateien, {n_orders} Orders")
