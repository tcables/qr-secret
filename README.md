# qr-secret

Show a password or other secret as a QR code right in your terminal. Nothing is saved anywhere, and the screen is wiped when you're done.

```
$ ./qr-secret.sh
Secret: ••••••••••••
```

The window grows to fit the whole code, the code is drawn, and you press Enter to wipe it.

## Why

Typing a long Wi-Fi key or generated password into a phone is tedious and error-prone. Writing it down or messaging it leaves a copy lying around. This script turns the secret into a QR code on screen for as long as it takes to scan it, then erases it.

## How the secret is protected

- **Hidden input:** the secret is read with `read -s`, so it never appears on screen or in your shell history.
- **Never in the process list:** it is piped to Python through `printf` on standard input, so it never shows up as a command-line argument in `ps` or Task Manager.
- **No files:** nothing is written to disk, and the shell variable is unset right after the code is drawn.
- **Screen wiped:** when you press Enter, the visible screen and the scrollback buffer are both cleared.

> **Note:** A QR code is an encoding, not encryption. Anyone who can see or photograph the screen can read the secret. Use this for showing a password to someone physically present, not as a way to send secrets over a network.

## Requirements

- Bash (Git Bash / mintty on Windows, or any Linux or macOS terminal)
- Python 3, available as `python`, `py -3`, or `python3`
- The [segno](https://pypi.org/project/segno/) QR code library

## Installation

```bash
git clone https://github.com/tcables/qr-secret.git
cd qr-secret
pip install segno
chmod +x qr-secret.sh
```

## Usage

```bash
./qr-secret.sh
```

1. Type or paste the secret at the `Secret:` prompt and press Enter. Nothing is echoed.
2. The window resizes if needed and the QR code appears.
3. Scan it with a phone camera or QR app.
4. Press Enter to wipe the screen and exit.

If Python or segno is missing, the script tells you what to install and waits for you to press Enter before closing, so the message isn't lost when launched from a shortcut.

## Desktop shortcut

You can launch the script by double-clicking an icon instead of opening a terminal first. In each example below, replace the path with wherever you cloned the repo.

### Windows (Git Bash)

1. Right-click an empty spot on the desktop and choose **New → Shortcut**.
2. For the location, paste the following (one line), adjusting the script path:

   ```
   "C:\Program Files\Git\usr\bin\mintty.exe" -h never -i "C:\Users\<you>\qr-secret\qr-secret.ico" /usr/bin/bash -l "/c/Users/<you>/qr-secret/qr-secret.sh"
   ```

   This opens the script directly in a mintty window, so the auto-resize works. The `-i` option gives that window (and its taskbar button) the repo's `qr-secret.ico` icon. Note that the script path at the end uses Git Bash style (`/c/Users/...`), not `C:\Users\...`.
3. Click **Next**, name it (for example *QR Secret*), and click **Finish**.
4. Set the shortcut's own icon: right-click the shortcut, choose **Properties → Change Icon → Browse…**, select `qr-secret.ico` from the repo folder, and click **OK** twice.
5. Optional: pin it to the taskbar or Start menu from the same right-click menu.

If Git is installed somewhere other than `C:\Program Files\Git`, adjust the `mintty.exe` path to match.

### macOS

macOS opens files ending in `.command` in Terminal when double-clicked. Create a small launcher on the desktop that runs the script from the repo, so updates you pull are picked up automatically:

```bash
cat > ~/Desktop/qr-secret.command <<'EOF'
#!/bin/bash
exec "$HOME/qr-secret/qr-secret.sh"
EOF
chmod +x ~/Desktop/qr-secret.command
```

- **First launch:** if macOS blocks it as coming from an unidentified developer, right-click the file, choose **Open**, then confirm. You only need to do this once.
- **Closing the window:** by default Terminal leaves the window open showing *[Process completed]*. To have it close automatically, go to **Terminal → Settings → Profiles → Shell** and set *When the shell exits* to **Close if the shell exited cleanly**.
- **Icon:** macOS can't point a file at an `.ico` directly, so copy and paste the image instead:
  1. Open `qr-secret.ico` from the repo in **Preview**, press **⌘A** to select all, then **⌘C** to copy.
  2. Select `qr-secret.command` on the desktop and press **⌘I** to open its Info window.
  3. Click the small icon at the top left of the Info window so it's highlighted, and press **⌘V**.

  To undo it later, select that same small icon and press **Delete**.

### Linux

Create a `.desktop` launcher. Use full paths, since `~` is not expanded in `Exec=`:

```bash
cat > ~/Desktop/qr-secret.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=QR Secret
Comment=Show a secret as a QR code
Exec=/home/<you>/qr-secret/qr-secret.sh
Icon=/home/<you>/qr-secret/qr-secret.png
Terminal=true
EOF
chmod +x ~/Desktop/qr-secret.desktop
```

`Terminal=true` makes it open in your desktop's default terminal. Then, depending on your desktop:

- **GNOME:** right-click the icon and choose **Allow Launching**. (Recent GNOME versions only show desktop icons with the *Desktop Icons NG* extension; alternatively save the file to `~/.local/share/applications/` instead, and it will appear in the app launcher, from where you can add it to your dock.)
- **KDE, Xfce, Cinnamon, MATE:** it usually works as soon as it's executable; if asked whether to trust or run the launcher, choose to mark it trusted/executable.

Linux launchers don't reliably display `.ico` files, so `Icon=` points to a PNG copy of the repo's icon. Create it once from the `.ico` (this uses Pillow, which picks the largest size stored in the file):

```bash
pip install pillow
cd ~/qr-secret
python3 -c "from PIL import Image; Image.open('qr-secret.ico').save('qr-secret.png')"
```

If the icon doesn't appear right away, log out and back in, or right-click the desktop and refresh.

## How it works

- `segno.make_qr()` always produces a full-size QR code. Plain `segno.make()` can pick a Micro QR for short inputs, which many phone scanners can't read.
- The code is drawn with full-block characters (`██`), two per module so it comes out roughly square. This avoids segno's ANSI color output, which renders as blank lines in some mintty setups.
- Before drawing, the script compares the code's size with the current window size (from `stty size`) and, if the window is too small, enlarges it with the xterm resize sequence `ESC[8;<rows>;<cols>t`. It only ever grows the window, never shrinks it.

## Compatibility

| Terminal | QR display | Auto-resize |
| --- | --- | --- |
| mintty (Git Bash, Cygwin, MSYS2) | ✅ | ✅ |
| xterm and most Linux terminals | ✅ | Usually; some ignore resize requests |
| macOS Terminal / iTerm2 | ✅ | ✅ (may depend on settings) |
| Windows Terminal | ✅ | ❌ resize request is ignored; enlarge the window by hand |

## Limitations

- A window can't grow beyond your monitor, so a very long secret may produce a code too tall to fit. Reducing the terminal font size helps.
- The secret passes through Python's memory and your terminal's display buffer while shown. The script clears what it can, but it can't guarantee the terminal emulator doesn't keep copies internally.
