#!/usr/bin/env bash
# Happ 4.3.0: скачать, распаковать в выбранную папку, ярлык + служба happd для VPN.
# Запуск одной командой (без sudo), папку выберешь в окне:
#   bash <(curl -fsSL https://raw.githubusercontent.com/k0kfjjfkdjf/decke_happ/main/happ-setup.sh)
# Или сразу указать папку (Happ появится в <папка>/happ):
#   bash <(curl -fsSL .../happ-setup.sh) /run/media/deck/SDCARD/Apps
set -euo pipefail
[ "$EUID" -eq 0 ] && { echo "Запусти без sudo — пароль скрипт спросит сам."; exit 1; }

# На Steam Deck у пользователя deck по умолчанию нет пароля, а sudo без него не работает.
PW_STATUS=$(passwd -S "$USER" 2>/dev/null | awk '{print $2}' || true)
if [ "$PW_STATUS" = "NP" ] || [ "$PW_STATUS" = "L" ]; then
  echo ">> У пользователя $USER нет пароля. Придумай его сейчас (нужен для sudo):"
  passwd
fi

URL="https://github.com/Happ-proxy/happ-desktop/releases/download/4.3.0/Happ.linux.x64.pkg.tar.zst"
DEFAULT_PARENT="$HOME/Applications"

# --- выбор папки установки ---
PARENT="${1:-${HAPP_DIR:-}}"
if [ -z "$PARENT" ]; then
  mkdir -p "$DEFAULT_PARENT"
  TITLE="Куда установить Happ? (будет создана подпапка happ)"
  if command -v kdialog >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    PARENT=$(kdialog --title "$TITLE" --getexistingdirectory "$DEFAULT_PARENT" 2>/dev/null || true)
  elif command -v zenity >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    PARENT=$(zenity --file-selection --directory --title="$TITLE" --filename="$DEFAULT_PARENT/" 2>/dev/null || true)
  else
    read -rp "Папка для установки [$DEFAULT_PARENT]: " PARENT </dev/tty || true
  fi
  [ -z "$PARENT" ] && { echo ">> Папка не выбрана, ставлю по умолчанию: $DEFAULT_PARENT"; PARENT="$DEFAULT_PARENT"; }
fi
PARENT="${PARENT/#\~/$HOME}"
mkdir -p "$PARENT"
PARENT=$(cd "$PARENT" && pwd -P)
[ -w "$PARENT" ] || { echo "Нет прав на запись в $PARENT"; exit 1; }

# FAT/exFAT/NTFS не умеют симлинки и права на запуск — Happ там работать не будет
FSTYPE=$(findmnt -no FSTYPE --target "$PARENT" 2>/dev/null || true)
case "$FSTYPE" in
  vfat|exfat|ntfs|ntfs3|fuseblk)
    echo "Файловая система $FSTYPE в $PARENT не подходит (нужна ext4/btrfs, как у SD-карты, отформатированной в Steam Deck)."
    exit 1;;
esac
if findmnt -no OPTIONS --target "$PARENT" 2>/dev/null | grep -qw noexec; then
  echo "$PARENT смонтирована с noexec — запускать программы оттуда нельзя."; exit 1
fi

DEST="$PARENT/happ"
echo ">> Устанавливаю в: $DEST"
BINDIR="$DEST/opt/happ/bin"
ICON="$DEST/usr/share/icons/hicolor/256x256/apps/happ.png"

echo ">> Скачиваю пакет..."
mkdir -p "$DEST"
TMP=$(mktemp --suffix=.pkg.tar.zst)
curl -fL --progress-bar -o "$TMP" "$URL"
echo ">> Распаковываю в $DEST"
tar --zstd -xf "$TMP" -C "$DEST" --exclude='.PKGINFO' --exclude='.MTREE'
rm -f "$TMP"
chmod +x "$BINDIR"/{Happ,happd,happ-diag,happ-tcping} "$BINDIR"/core/xray \
         "$BINDIR"/tun/sing-box "$BINDIR"/tun2/tun2proxy-bin "$BINDIR"/antifilter/antifilter

echo ">> Создаю ярлыки"
DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
mkdir -p "$DESKTOP_DIR" "$HOME/.local/share/applications"
for f in "$DESKTOP_DIR/Happ.desktop" "$HOME/.local/share/applications/Happ.desktop"; do
cat > "$f" <<EOF
[Desktop Entry]
Type=Application
Name=Happ
Comment=VLESS/Xray клиент
Exec="$BINDIR/Happ" %f
Path=$BINDIR
Icon=$ICON
Terminal=false
Categories=Network;Utility;
EOF
chmod +x "$f"
done

echo ">> Ставлю службу happd (нужен пароль sudo)"
sudo tee /etc/systemd/system/happd.service >/dev/null <<EOF
[Unit]
Description=Happ Process Control Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart="$BINDIR/happd"
Restart=always
RestartSec=5s
TimeoutStopSec=10s
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable happd.service
sudo systemctl restart happd.service

# запомнить путь (для удаления/обновления)
mkdir -p "$HOME/.config"
echo "HAPP_DEST=\"$DEST\"" > "$HOME/.config/happ-setup.conf"

echo
systemctl is-active --quiet happd && echo "Служба happd: работает" || echo "Служба happd НЕ запустилась: systemctl status happd"
echo "Готово. Happ установлен в $DEST"
echo "Ярлык: $DESKTOP_DIR и меню приложений."
