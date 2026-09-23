"""Mirror the main namespace of dwarffortresswiki.org into wiki/ (wikitext only).

For a readable offline copy with images use the Kiwix ZIM from library.kiwix.org.

Usage: python tools/wiki_mirror.py
Resumable: already downloaded files are skipped. Delete a file to re-fetch it.
"""
import json
import os
import re
import time
import urllib.parse
import urllib.request

BASE = "https://dwarffortresswiki.org"
API = BASE + "/api.php"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "wiki")
DELAY = 0.5  # seconds between requests, keep load on the server low
UA = "DF-Hack offline mirror (personal use)"


def api(params):
    params = dict(params, format="json", formatversion="2")
    url = API + "?" + urllib.parse.urlencode(params)
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=120) as r:
                data = json.load(r)
            time.sleep(DELAY)
            return data
        except Exception as e:
            wait = 10 * (attempt + 1)
            print(f"  error {e!r}, retry in {wait}s")
            time.sleep(wait)
    raise RuntimeError("giving up on " + url)


def list_pages(redirects):
    titles, cont = [], {}
    while True:
        d = api(dict(action="query", list="allpages", apnamespace=0, aplimit=500,
                     apfilterredir="redirects" if redirects else "nonredirects", **cont))
        titles += [p["title"] for p in d["query"]["allpages"]]
        if "continue" not in d:
            return titles
        cont = d["continue"]


def redirect_map(redirect_titles):
    m = {}
    for i in range(0, len(redirect_titles), 50):
        d = api(dict(action="query", titles="|".join(redirect_titles[i:i + 50]), redirects=1))
        for r in d["query"].get("redirects", []):
            m[r["from"]] = r["to"]
    return m


def safe_name(title, used):
    name = re.sub(r'[<>:"/\\|?*]', "_", title).rstrip(". ")
    base, n = name, 2
    while name.lower() in used:  # Windows filesystem is case-insensitive
        name = f"{base}~{n}"
        n += 1
    used.add(name.lower())
    return name


def main():
    os.makedirs(os.path.join(OUT, "wikitext"), exist_ok=True)

    print("listing pages ...")
    pages = list_pages(False)
    redirects = redirect_map(list_pages(True))
    print(f"{len(pages)} pages, {len(redirects)} redirects")

    used, fname_of = set(), {}
    for t in pages:
        fname_of[t] = safe_name(t, used)
    for src, dst in redirects.items():
        if dst in fname_of:
            fname_of[src] = fname_of[dst]
    with open(os.path.join(OUT, "titles.json"), "w", encoding="utf-8") as f:
        json.dump({"pages": {t: fname_of[t] for t in pages}, "redirects": redirects},
                  f, ensure_ascii=False, indent=0)

    # wikitext, 50 pages per request
    todo = [t for t in pages
            if not os.path.exists(os.path.join(OUT, "wikitext", fname_of[t] + ".txt"))]
    print(f"wikitext: {len(todo)} to fetch")
    for i in range(0, len(todo), 50):
        d = api(dict(action="query", prop="revisions", rvprop="content", rvslots="main",
                     titles="|".join(todo[i:i + 50])))
        for p in d["query"]["pages"]:
            if "revisions" not in p:
                continue
            content = p["revisions"][0]["slots"]["main"]["content"]
            with open(os.path.join(OUT, "wikitext", fname_of[p["title"]] + ".txt"),
                      "w", encoding="utf-8") as f:
                f.write(content)
        print(f"  wikitext {min(i + 50, len(todo))}/{len(todo)}")

    print("done")


if __name__ == "__main__":
    main()
