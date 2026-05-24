"""Terminal UI — formatted output for CLI."""
import shutil


def _term_width() -> int:
    try:
        return shutil.get_terminal_size().columns
    except Exception:
        return 80


def header(text: str):
    w = _term_width()
    print("=" * w)
    print(f"  {text}")
    print("=" * w)


def subheader(text: str):
    print(f"--- {text} ---")


def result(text: str, status: str = "ok"):
    prefix = {"ok": "[OK]", "fail": "[FAIL]", "skip": "[SKIP]", "info": "[INFO]"}.get(status, "[*]")
    print(f"  {prefix} {text}")


def table(headers: list, rows: list):
    if not rows:
        return
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(cell)))
    fmt = " | ".join(f"{{:<{w}}}" for w in col_widths)
    sep = "-+-".join("-" * w for w in col_widths)
    print(fmt.format(*headers))
    print(sep)
    for row in rows:
        print(fmt.format(*[str(c) for c in row]))


def section(title: str):
    print()
    print(f">>> {title}")


def done(msg: str = "Done"):
    print(f"[+] {msg}")
