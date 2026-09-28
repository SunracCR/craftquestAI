#!/usr/bin/env python3
"""Genera el manual de usuario de CraftQuest en HTML y PDF."""

from __future__ import annotations

import argparse
import html
import os
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent
CHAPTERS = ROOT / "capitulos"
IMG_DIR = ROOT / "img"
ASSETS = ROOT / "assets"
DIST = ROOT / "dist"
CHECKLIST = ROOT / "CAPTURAS_PENDIENTES.md"
LOGO = (
    ROOT.parents[1]
    / "mobile"
    / "craftquest_app"
    / "assets"
    / "images"
    / "brand"
    / "craftquest_logo.png"
)
MERMAID_URL = "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js"
MERMAID_FILE = ASSETS / "vendor" / "mermaid.min.js"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}

CALLOUT_KINDS = {
    "Nota.": "note",
    "Consejo.": "tip",
    "Aviso.": "warn",
}


def read_chapters() -> str:
    parts: list[str] = []
    for path in sorted(CHAPTERS.glob("*.md")):
        parts.append(path.read_text(encoding="utf-8").strip())
    if not parts:
        raise SystemExit(f"No hay capítulos en {CHAPTERS}")
    return "\n\n".join(parts) + "\n"


def promote_mermaid(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        diagram = match.group(1).strip()
        return f'<div class="mermaid">\n{diagram}\n</div>\n'

    return re.sub(r"```mermaid\s*\n(.*?)```", repl, text, flags=re.DOTALL)


def replace_missing_images(text: str, missing: list[str]) -> str:
    def repl(match: re.Match[str]) -> str:
        alt = match.group(1).strip()
        name = Path(match.group(2)).name
        if (IMG_DIR / name).is_file():
            return match.group(0)
        missing.append(name)
        safe_alt = html.escape(alt)
        safe_name = html.escape(name)
        return (
            '<div class="shot-missing">'
            '<p class="kicker">Captura pendiente</p>'
            f'<p class="file">{safe_name}</p>'
            f'<p class="alt">{safe_alt}</p>'
            "</div>\n"
        )

    return re.sub(r"!\[([^\]]*)\]\((img/[^)]+)\)", repl, text)


def referenced_images(text: str) -> list[str]:
    return re.findall(r"!\[[^\]]*\]\(img/([^)]+)\)", text)


def figures_from_images(html_text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        alt = match.group(1)
        name = Path(match.group(2)).name
        return (
            '<figure class="shot">'
            f'<img alt="{alt}" src="../img/{html.escape(name)}">'
            f"<figcaption>{alt}</figcaption>"
            "</figure>"
        )

    return re.sub(
        r"<p>\s*<img alt=\"([^\"]*)\" src=\"([^\"]+)\"\s*/?>\s*</p>",
        repl,
        html_text,
    )


def style_callouts(html_text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        label = match.group(1)
        kind = CALLOUT_KINDS[label]
        body = match.group(2).strip()
        return (
            f'<div class="callout callout-{kind}">'
            f"<p><strong>{html.escape(label)}</strong> {body}</p>"
            "</div>"
        )

    pattern = (
        r"<blockquote>\s*<p><strong>(Nota\.|Consejo\.|Aviso\.)</strong>\s*"
        r"(.*?)</p>\s*</blockquote>"
    )
    return re.sub(pattern, repl, html_text, flags=re.DOTALL)


def render_body(source: str, missing: list[str]) -> tuple[str, str]:
    prepared = promote_mermaid(source)
    prepared = replace_missing_images(prepared, missing)
    converter = markdown.Markdown(
        extensions=["extra", "tables", "sane_lists", "toc", "md_in_html"],
        extension_configs={"toc": {"toc_depth": 2}},
    )
    body = converter.convert(prepared)
    body = figures_from_images(body)
    body = style_callouts(body)
    toc_html = converter.toc
    toc_inner = re.sub(r"^<div class=\"toc\">\s*", "", toc_html)
    toc_inner = re.sub(r"\s*</div>\s*$", "", toc_inner)
    return body, toc_inner


def cover_markup() -> str:
    if LOGO.is_file():
        logo = (
            '<img src="../../../mobile/craftquest_app/assets/images/brand/'
            'craftquest_logo.png" alt="CraftQuestAI">'
        )
    else:
        logo = ""
    return f"""
<section class="cover">
  <div>
    <div class="cover-brand">
      {logo}
      <p class="cover-kicker">CraftQuestAI</p>
    </div>
    <h1>Manual de usuario</h1>
    <p class="lead">Crear, practicar y compartir cuestionarios. Incluye el modo invitado, la generación con IA, Preparación+ y el aula del tutor.</p>
  </div>
  <div class="cover-meta">
    <p><span>Idioma</span>Español</p>
    <p><span>Edición</span>Septiembre 2026</p>
    <p><span>App</span>app.craftquestai.com</p>
    <p><span>Perfiles</span>Invitado, estudiante y tutor</p>
  </div>
</section>
"""


def page_html(body: str, toc_inner: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>CraftQuestAI — Manual de usuario</title>
  <link rel="stylesheet" href="../assets/manual.css">
</head>
<body>
{cover_markup()}
<nav class="toc">
  <h2>Contenido</h2>
  {toc_inner}
</nav>
<main>
{body}
</main>
<script src="../assets/vendor/mermaid.min.js"></script>
<script>
  if (window.mermaid) {{
    mermaid.initialize({{
      startOnLoad: false,
      theme: "neutral",
      securityLevel: "loose",
      fontFamily: "Segoe UI, sans-serif",
      flowchart: {{
        htmlLabels: true,
        nodeSpacing: 18,
        rankSpacing: 22,
        padding: 6
      }}
    }});
    mermaid.run().then(function () {{
      document.querySelectorAll(".mermaid svg").forEach(function (svg) {{
        svg.removeAttribute("height");
        svg.style.maxHeight = "155mm";
        svg.style.width = "100%";
        svg.style.height = "auto";
      }});
      document.body.setAttribute("data-mermaid-ready", "1");
    }});
  }} else {{
    document.body.setAttribute("data-mermaid-ready", "1");
  }}
</script>
</body>
</html>
"""


def parse_checklist(text: str) -> list[dict[str, str]]:
    parts = re.split(r"^### `([^`]+)`\s*$", text, flags=re.MULTILINE)
    entries: list[dict[str, str]] = []
    index = 1
    while index + 1 < len(parts):
        fields = {"archivo": parts[index].strip()}
        for match in re.finditer(
            r"^- \*\*([^*]+):\*\*\s*(.+)$", parts[index + 1], flags=re.MULTILINE
        ):
            fields[match.group(1).strip()] = match.group(2).strip()
        entries.append(fields)
        index += 2
    return entries


def captures_html(entries: list[dict[str, str]], unknown: list[str]) -> str:
    cards: list[str] = []
    for entry in entries:
        name = entry["archivo"]
        ready = (IMG_DIR / name).is_file()
        status = "Lista" if ready else "Pendiente"
        rows = []
        for key in (
            "Capítulo",
            "Pantalla",
            "Perfil",
            "Estado previo",
            "Qué debe verse",
            "Formato",
        ):
            value = entry.get(key, "")
            rows.append(
                f"<dt>{html.escape(key)}</dt><dd>{html.escape(value)}</dd>"
            )
        cards.append(
            f"""
<article class="card" data-file="{html.escape(name)}" data-ready="{str(ready).lower()}">
  <header>
    <code>{html.escape(name)}</code>
    <span class="status">{status}</span>
  </header>
  <dl>
    {''.join(rows)}
  </dl>
  <label><input type="checkbox" data-check="{html.escape(name)}"> Ya la guardé en img/</label>
</article>
"""
        )
    unknown_block = ""
    if unknown:
        items = "".join(f"<li><code>{html.escape(name)}</code></li>" for name in unknown)
        unknown_block = (
            "<h2>Nombres que no coinciden</h2>"
            "<p>Estos archivos están en img/ pero ningún capítulo los cita. "
            "Revisa el nombre: un carácter distinto deja el recuadro pendiente.</p>"
            f"<ul>{items}</ul>"
        )
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>Capturas del manual — CraftQuestAI</title>
  <style>
    body {{ margin: 0; font-family: "Segoe UI", sans-serif; background: #f6f1ea; color: #1a2f35; }}
    header.top {{ padding: 28px 32px 8px; }}
    h1 {{ margin: 0 0 8px; }}
    main {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; padding: 16px 32px 48px; }}
    .card {{ background: #fff; border-radius: 16px; padding: 16px; box-shadow: 0 8px 24px rgba(26,47,53,.06); }}
    .card header {{ display: flex; justify-content: space-between; gap: 12px; align-items: center; }}
    code {{ font-size: 13px; }}
    .status {{ font-size: 12px; letter-spacing: .06em; text-transform: uppercase; color: #c46b2c; }}
    .card[data-ready="true"] .status {{ color: #1f7a5c; }}
    dl {{ margin: 12px 0; }}
    dt {{ font-size: 12px; color: #4a6270; margin-top: 8px; }}
    dd {{ margin: 0; }}
    .extra {{ padding: 0 32px 48px; }}
  </style>
</head>
<body>
  <header class="top">
    <h1>Capturas del manual</h1>
    <p>Guarda cada PNG en <code>Documentacion/manual_usuario/img</code> con el nombre de la tarjeta. La casilla se recuerda en este navegador.</p>
  </header>
  <main>
    {''.join(cards)}
  </main>
  <section class="extra">{unknown_block}</section>
  <script>
    for (const box of document.querySelectorAll("[data-check]")) {{
      const key = "cq-manual-shot:" + box.dataset.check;
      box.checked = localStorage.getItem(key) === "1";
      box.addEventListener("change", () => {{
        localStorage.setItem(key, box.checked ? "1" : "0");
      }});
    }}
  </script>
</body>
</html>
"""


def ensure_mermaid() -> None:
    if MERMAID_FILE.is_file() and MERMAID_FILE.stat().st_size > 10000:
        return
    MERMAID_FILE.parent.mkdir(parents=True, exist_ok=True)
    print(f"Descargando Mermaid en {MERMAID_FILE.name}…")
    urllib.request.urlretrieve(MERMAID_URL, MERMAID_FILE)


def find_edge() -> Path | None:
    candidates = [
        Path(os.environ.get("PROGRAMFILES(X86)", r"C:\Program Files (x86)"))
        / "Microsoft/Edge/Application/msedge.exe",
        Path(os.environ.get("PROGRAMFILES", r"C:\Program Files"))
        / "Microsoft/Edge/Application/msedge.exe",
        Path(os.environ.get("LOCALAPPDATA", ""))
        / "Microsoft/Edge/Application/msedge.exe",
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return None


def print_pdf(html_path: Path, pdf_path: Path) -> None:
    edge = find_edge()
    if edge is None:
        raise SystemExit("No se encontró Microsoft Edge para imprimir el PDF.")
    if pdf_path.exists():
        pdf_path.unlink()
    command = [
        str(edge),
        "--headless=new",
        "--disable-gpu",
        "--no-first-run",
        "--no-pdf-header-footer",
        f"--print-to-pdf={pdf_path}",
        "--virtual-time-budget=25000",
        "--run-all-compositor-stages-before-draw",
        html_path.resolve().as_uri(),
    ]
    completed = subprocess.run(command, capture_output=True, text=True, timeout=120)
    if completed.returncode != 0 or not pdf_path.is_file():
        detail = (completed.stderr or completed.stdout or "").strip()
        raise SystemExit(f"Edge no generó el PDF ({completed.returncode}). {detail}")


def files_on_disk() -> list[str]:
    if not IMG_DIR.is_dir():
        return []
    return sorted(
        path.name
        for path in IMG_DIR.iterdir()
        if path.suffix.lower() in IMAGE_EXTENSIONS
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera el manual de usuario en PDF.")
    parser.add_argument(
        "--html-only",
        action="store_true",
        help="No llama a Edge. Deja el HTML en dist/.",
    )
    args = parser.parse_args()

    source = read_chapters()
    cited = referenced_images(source)
    checklist_text = CHECKLIST.read_text(encoding="utf-8")
    entries = parse_checklist(checklist_text)
    listed = [entry["archivo"] for entry in entries]

    cited_set = set(cited)
    listed_set = set(listed)
    only_chapters = sorted(cited_set - listed_set)
    only_list = sorted(listed_set - cited_set)
    if only_chapters or only_list:
        print("La lista de capturas no coincide con los capítulos.", file=sys.stderr)
        for name in only_chapters:
            print(f"  En un capítulo y no en la lista: {name}", file=sys.stderr)
        for name in only_list:
            print(f"  En la lista y no en un capítulo: {name}", file=sys.stderr)
        raise SystemExit(1)

    duplicates = sorted({name for name in cited if cited.count(name) > 1})
    if duplicates:
        print("Nombres de captura repetidos:", ", ".join(duplicates), file=sys.stderr)
        raise SystemExit(1)

    missing: list[str] = []
    body, toc_inner = render_body(source, missing)
    ensure_mermaid()
    DIST.mkdir(parents=True, exist_ok=True)

    html_path = DIST / "manual.html"
    html_path.write_text(page_html(body, toc_inner), encoding="utf-8")

    on_disk = files_on_disk()
    unknown = sorted(set(on_disk) - cited_set)
    (DIST / "capturas.html").write_text(
        captures_html(entries, unknown), encoding="utf-8"
    )

    ready = len(cited_set - set(missing))
    print(f"Capturas: {ready}/{len(cited)} listas")
    if missing:
        print("Faltan:")
        for name in missing:
            print(f"  {name}")
    if unknown:
        print("Archivos en img/ que no coinciden con el manual:")
        for name in unknown:
            print(f"  {name}")

    pdf_path = DIST / "CraftQuest_Manual_Usuario.pdf"
    if args.html_only:
        print(f"HTML: {html_path}")
        return

    print_pdf(html_path, pdf_path)
    print(f"PDF: {pdf_path}")


if __name__ == "__main__":
    main()
