import os, re, zipfile


def decode_text(data):
    """UTF-8 if valid, else Windows-1258 (Vietnamese; a superset of the Latin range in the few legacy files)."""
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return data.decode("cp1258", errors="replace")


def read_text(full):
    ext = os.path.splitext(full)[1].lower()
    if ext == ".pdf":
        import pypdf
        try:
            r = pypdf.PdfReader(full)
            return "\n".join((p.extract_text() or "") for p in r.pages)
        except Exception as e:  # noqa
            return ""
    if ext == ".docx":
        with zipfile.ZipFile(full) as z:
            x = z.read("word/document.xml").decode("utf8", "replace")
        x = re.sub(r"</w:p>", "\n", x)
        x = re.sub(r"<[^>]+>", "", x)
        return x.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"').replace("&apos;", "'")
    return open(full, "rb").read().decode("utf8", "replace")
