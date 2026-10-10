# Happ на Steam Deck

Установка VLESS/Xray-клиента [Happ](https://happ.su) на Steam Deck (SteamOS) без pacman и без отключения read-only.

Скрипт `happ-setup.sh`:
- скачивает пакет Happ 4.3.0 с GitHub-релизов;
- распаковывает его в `~/Applications/happ` (переживает обновления SteamOS);
- создаёт ярлык на рабочем столе и в меню приложений;
- ставит и запускает службу `happd` (root), без которой не работает TUN/VPN-режим.

## Установка

В Desktop Mode, в Konsole (**без sudo**, пароль скрипт спросит сам):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/k0kfjjfkdjf/decke_happ/main/happ-setup.sh)
```

Если у пользователя `deck` ещё нет пароля, скрипт сам предложит его задать.

## Обновление

Поменяй ссылку в строке `URL=` на новую версию и запусти скрипт ещё раз.

## Удаление

```bash
sudo systemctl disable --now happd.service
sudo rm /etc/systemd/system/happd.service
rm -rf ~/Applications/happ ~/.local/share/applications/Happ.desktop "$(xdg-user-dir DESKTOP)/Happ.desktop"
rm -rf ~/.config/happ ~/.local/share/happ   # настройки и профили
```
