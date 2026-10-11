# Happ на Steam Deck

Установка VLESS/Xray-клиента [Happ](https://happ.su) на Steam Deck (SteamOS) без pacman и без отключения read-only.

Скрипт `happ-setup.sh`:
- скачивает пакет Happ 4.3.0 с GitHub-релизов;
- спрашивает в окне, куда установить (по умолчанию `~/Applications`), и распаковывает в `<папка>/happ`;
- создаёт ярлык на рабочем столе и в меню приложений;
- ставит и запускает службу `happd` (root), без которой не работает TUN/VPN-режим.

## Установка

В Desktop Mode, в Konsole (**без sudo**, пароль скрипт спросит сам):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/k0kfjjfkdjf/decke_happ/main/happ-setup.sh)
```

Откроется окно выбора папки — Happ будет установлен в подпапку `happ` внутри неё. Нажмёшь «Отмена» — поставится в `~/Applications/happ`.

Папку можно указать и сразу, без окна:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/k0kfjjfkdjf/decke_happ/main/happ-setup.sh) /run/media/deck/SDCARD/Apps
```

Если у пользователя `deck` ещё нет пароля, скрипт сам предложит его задать.

**Про SD-карту:** подойдёт карта, отформатированная самим Steam Deck (ext4). Карты в FAT/exFAT/NTFS скрипт отклонит — там Happ не запустится. Учти, что без вставленной карты VPN работать не будет.

## Обновление

Поменяй ссылку в строке `URL=` на новую версию и запусти скрипт ещё раз, выбрав ту же папку.

## Удаление

```bash
sudo systemctl disable --now happd.service
sudo rm /etc/systemd/system/happd.service
source ~/.config/happ-setup.conf   # путь, куда ставил скрипт
rm -rf "$HAPP_DEST" ~/.local/share/applications/Happ.desktop "$(xdg-user-dir DESKTOP)/Happ.desktop" ~/.config/happ-setup.conf
rm -rf ~/.config/happ ~/.local/share/happ   # настройки и профили
```
