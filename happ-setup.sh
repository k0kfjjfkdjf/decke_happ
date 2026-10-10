#!/usr/bin/env bash
# Happ 4.3.0: скачать, распаковать в ~/Applications/happ, ярлык + служба happd для VPN.
# Запуск одной командой (без sudo):
#   bash <(curl -fsSL https://raw.githubusercontent.com/k0kfjjfkdjf/decke_happ/main/happ-setup.sh)
set -euo pipefail
[ "$EUID" -eq 0 ] && { echo "Запусти без sudo — пароль скрипт спросит сам."; exit 1; }

# На Steam Deck у пользователя deck по умолчанию нет пароля, а sudo без него не работает.
if [ "$(passwd -S "$USER" 2>/dev/null | awk '{print $2}')" != "P" ]; then
  echo ">> У пользователя $USER нет пароля. Придумай его сейчас (нужен для sudo):"
  passwd
fi

URL="https://github.com/Happ-proxy/happ-desktop/releases/download/4.3.0/Happ.linux.x64.pkg.tar.zst"
DEST="$HOME/Applications/happ"
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
ExecStart=$BINDIR/happd
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

echo
systemctl is-active --quiet happd && echo "Служба happd: работает" || echo "Служба happd НЕ запустилась: systemctl status happd"
echo "Готово. Ярлык Happ: $DESKTOP_DIR и меню приложений."
