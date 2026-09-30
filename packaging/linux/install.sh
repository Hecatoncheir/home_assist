#!/bin/sh
# Устанавливает Home Assist для текущего пользователя.
# Запускается самораспаковывающимся архивом home_assist-linux-x64.run.
# Каталог установки можно сменить: PREFIX=/opt/home-assist ./home_assist-linux-x64.run
set -eu

prefix="${PREFIX:-$HOME/.local}"
app_dir="$prefix/share/home-assist"
desktop_dir="$prefix/share/applications"
icon_dir="$prefix/share/icons/hicolor/256x256/apps"

rm -rf "$app_dir"
mkdir -p "$app_dir" "$prefix/bin" "$desktop_dir" "$icon_dir"
cp -R bundle/. "$app_dir/"
cp icon.png "$icon_dir/home-assist.png"
ln -sf "$app_dir/home_assist" "$prefix/bin/home-assist"

cat > "$desktop_dir/home-assist.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Home Assist
Comment=Устройства Xiaomi из всех регионов в одном списке
Exec=$app_dir/home_assist
Icon=home-assist
Categories=Utility;
Terminal=false
EOF

cat > "$app_dir/uninstall.sh" <<EOF
#!/bin/sh
rm -rf "$app_dir"
rm -f "$prefix/bin/home-assist" "$desktop_dir/home-assist.desktop" "$icon_dir/home-assist.png"
echo "Home Assist удалён."
EOF
chmod +x "$app_dir/uninstall.sh"

echo "Home Assist установлен в $app_dir"
echo "Запуск: меню приложений или команда home-assist"
echo "Удаление: $app_dir/uninstall.sh"
if ! ldconfig -p 2>/dev/null | grep -q libsecret-1; then
  echo "Внимание: нужна библиотека libsecret (пакет libsecret-1-0), без неё не сохранится вход."
fi
