#!/usr/bin/env bash
# qr-secret.sh: show a secret as a QR code in the terminal. Nothing persisted.
#   * read silently (never in shell history)
#   * piped via printf (never in argv / ps)
#   * no file written; variable unset afterward
#   * window grown to fit the whole code (xterm/mintty resize sequence)
#   * screen + scrollback wiped on close
# Note: a QR is an encoding, not encryption - for showing a password to
# someone physically at the screen, not a secure transmission channel.

set -u

# --- locate a working Python ------------------------------------------------
PYCMD=""
for c in "python" "py -3" "python3"; do
  if $c -c 'import sys' >/dev/null 2>&1; then
    PYCMD="$c"
    break
  fi
done

if [ -z "$PYCMD" ]; then
  echo "No Python found (tried: python, py -3, python3)." >&2
  echo "Install Python, then 'pip install segno', and retry." >&2
  read -rp "Press Enter to close..."
  exit 1
fi

# --- check segno ------------------------------------------------------------
if ! $PYCMD -c 'import segno' >/dev/null 2>&1; then
  echo "The 'segno' module isn't installed for this Python." >&2
  echo "Run:  pip install segno" >&2
  read -rp "Press Enter to close..."
  exit 1
fi

# --- current terminal size --------------------------------------------------
# Asked from bash via /dev/tty because a native Windows Python running under
# mintty sees pipes, not a console, and can't query the size itself.
size=$(stty size </dev/tty 2>/dev/null) || size="0 0"
read -r cur_rows cur_cols <<<"$size"

# --- read + render ----------------------------------------------------------
# make_qr() forces a full QR Code (three finder squares); plain make() may
# emit a Micro QR (one finder, tiny, poorly supported) for short secrets.
# Rendered from the matrix with full-block glyphs (U+2588), two per module,
# because segno's ANSI terminal output shows as blank lines in some mintty
# setups.
# Before drawing, the window is grown (never shrunk) with CSI 8;rows;cols t
# so the full code plus the prompt below it fits without scrolling, and the
# screen is cleared so the code starts at the top line.
read -rs -p "Secret: " pw
echo
printf '%s' "$pw" | $PYCMD -c 'import sys, time, segno
qr = segno.make_qr(sys.stdin.read())
rows = [list(r) for r in qr.matrix_iter(border=4)]
cur_r, cur_c = int(sys.argv[1]), int(sys.argv[2])
need_r = len(rows) + 3          # code + blank line + prompt + spare
need_c = 2 * len(rows[0]) + 1   # +1 avoids auto-wrap at the right edge
if need_r > cur_r or need_c > cur_c:
    sys.stdout.write("\033[8;%d;%dt" % (max(need_r, cur_r), max(need_c, cur_c)))
    sys.stdout.flush()
    time.sleep(0.2)             # let the window finish resizing before drawing
sys.stdout.write("\033[H\033[2J")
for row in rows:
    print("".join("\u2588\u2588" if bit else "  " for bit in row))' "$cur_rows" "$cur_cols"
unset pw

echo
read -rp "Scan the code, then press Enter to wipe the screen and close..."

# --- wipe visible screen + scrollback ---------------------------------------
printf '\033[3J\033[H\033[2J'
