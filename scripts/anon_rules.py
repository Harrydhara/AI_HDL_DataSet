"""Personal-data rules for the AI-HDL 2026 release. Names are replaced per team with stable pseudonyms."""
import re, unicodedata

# team -> list of people (each a list of spellings); order fixes the pseudonym letter.
PEOPLE = {}  # withheld: per-team lists of participant names

# names glued to neighbouring text in web-page captures (replaced as plain substrings)
GLUED = {}  # withheld
# organizers / mentors (all teams)
STAFF = []  # withheld

# distinctive first names used on their own in reports; each maps to the person's pseudonym
FIRST_NAMES = {}  # withheld: per-team lists of participant names

# single-word first names that only appear next to a student email in member tables
TABLE_ONLY_NAMES = {"Ly", "Khanh", "Minh", "Giang", "Thien", "Quang", "Long", "Dung", "Hai", "Kien"}

# student / mentor handles (GitHub, home directories, LinkedIn, email local parts)
HANDLES = []  # withheld

EMAIL_KEEP = re.compile(r"(@yosyshq\.com|clifford@clifford\.at|alavin@acm\.org|sgray@nervanasys\.com|^aihdl-[a-z]+@arizona\.edu|"
                        r"@example\.com|@cocotb\.test|git@github\.com|action@v)", re.I)
EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
HOME = re.compile(r"(/home/|/Users/|/mnt/c/Users/|C:\\\\Users\\\\|C:\\Users\\|C:/Users/)([A-Za-z0-9._ -]+?)(?=[/\\>$\s'\"]|$)", re.I | re.M)
SHELL_PROMPT = re.compile(r"(?<![\w.@-])[A-Za-z0-9._-]+@[A-Za-z0-9._-]+(?=:\s?[~/$])")


_FIRST = re.compile(r"(?<![\w])(?:" + "|".join(sorted(TABLE_ONLY_NAMES)) + r")(?![\w])")


def _variants(s):
    out = {s}
    nfkd = "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c)).replace("đ", "d").replace("Đ", "D")
    out.add(nfkd)
    for v in list(out):
        out.add(v.replace(" ", "_"))
        out.add(v.replace(" ", "-"))
    return out


def build(team):
    """Return (one combined regex, lookup dict) for one team: a single pass over the text."""
    table = {}
    for i, spellings in enumerate(PEOPLE.get(team, [])):
        for s in spellings:
            for v in _variants(s):
                table.setdefault(v.lower(), f"Member {chr(65 + i)}")
    for spellings in STAFF:
        for s in spellings:
            for v in _variants(s):
                table.setdefault(v.lower(), "[mentor]")
    for n, i in FIRST_NAMES.get(team, {}).items():
        for v in _variants(n):
            table.setdefault(v.lower(), f"Member {chr(65 + i)}")
    for h in HANDLES:
        table.setdefault(h.lower(), "[user]")
    alts = "|".join(re.escape(k) for k in sorted(table, key=len, reverse=True))
    rx = re.compile(r"(?<![^\W_])(?:" + alts + r")(?![^\W_])", re.I)  # "_" separates words
    return rx, table


def anonymize(text, rules):
    rx, table = rules
    for k, v in GLUED.items():
        if k in text:
            text = text.replace(k, v)
    text = re.sub(r"https?://(?:chat\.openai\.com|chatgpt\.com|claude\.ai|gemini\.google\.com|g\.co/gemini)/share/[\w-]+"
                  r"|httpschatgpt\.comshare[\w-]+", "[shared-chat link removed]", text)
    text = HOME.sub(lambda m: m.group(1) + "user", text)
    text = SHELL_PROMPT.sub("user@host", text)
    text = EMAIL.sub(lambda m: m.group(0) if EMAIL_KEEP.search(m.group(0)) else "[email]", text)
    text = rx.sub(lambda m: table[m.group(0).lower()], text)
    # first-name-only cells in member tables (a row that had a student email)
    if "[email]" in text:
        lines = text.split("\n")
        for k, l in enumerate(lines):
            if "[email]" in l:
                lines[k] = _FIRST.sub("[member]", l)
        text = "\n".join(lines)
    text = re.sub(r"linkedin\.com/in/[\w-]+", "linkedin.com/in/[user]", text, flags=re.I)
    return text


def anonymize_name(name, rules):
    return anonymize(name, rules)
