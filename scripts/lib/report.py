"""Lee el informe JUnit de utPLSQL y escribe check.json. Solo usa la biblioteca estándar.

Uso:
  report.py junit INFORME.xml          -> imprime los hallazgos como TSV: comprobación, objeto, mensaje
  report.py json HALLAZGOS.tsv SALIDA.json RESULTADO SEGUNDOS
"""
import json
import re
import sys
import xml.etree.ElementTree as ET

ANSI = re.compile(r"\x1b\[[0-9;]*m")


def finding(obj, message):
    # Una línea por hallazgo; los tabuladores y saltos de línea del mensaje se aplanan
    print("\t".join(["tests", obj, " ".join(message.split())]))


def junit(path):
    try:
        text = ANSI.sub("", open(path, encoding="utf-8", errors="replace").read()).strip()
    except OSError as e:
        finding("-", f"No hay informe de tests: {e}")
        return
    start = text.find("<testsuites")
    if start < 0:
        finding("-", "El informe de tests no contiene <testsuites>: " + text[:300])
        return
    try:
        root = ET.fromstring(text[start:text.rindex("</testsuites>") + len("</testsuites>")])
    except (ValueError, ET.ParseError) as e:
        finding("-", f"El informe de tests no es XML válido: {e}")
        return
    cases = root.findall(".//testcase")
    if not cases:
        finding("-", "No hay ningún test")
    for case in cases:
        name = f"{case.get('classname', '')}.{case.get('name', '')}".strip(".")
        for kind, label in (("failure", "Falla"), ("error", "Error"), ("skipped", "Desactivado")):
            for node in case.findall(kind):
                detail = node.get("message") or (node.text or "")
                finding(name, f"{label}: {detail.strip()}" if detail.strip() else label)
    print(f"{len(cases)} tests en el informe", file=sys.stderr)


def to_json(tsv, out, result, seconds):
    findings = []
    for line in open(tsv, encoding="utf-8", errors="replace"):
        parts = line.rstrip("\n").split("\t", 2)
        if len(parts) == 3:
            findings.append({"check": parts[0], "object": parts[1], "message": ANSI.sub("", parts[2])})
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"result": result, "seconds": int(seconds), "findings": findings}, f, ensure_ascii=False, indent=2)
        f.write("\n")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "junit":
        junit(sys.argv[2])
    elif len(sys.argv) == 6 and sys.argv[1] == "json":
        to_json(*sys.argv[2:])
    else:
        sys.exit(__doc__)
