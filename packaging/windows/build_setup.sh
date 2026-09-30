#!/usr/bin/env bash
# Собирает home_assist-windows-setup.exe из результата `flutter build windows`.
# Запускается из корня репозитория в Git Bash.
set -euo pipefail

release=build/windows/x64/runner/Release
iscc="/c/Program Files (x86)/Inno Setup 6/ISCC.exe"

# Библиотеки Visual C++: без них приложение не запустится на чистой Windows.
for dll in msvcp140.dll vcruntime140.dll vcruntime140_1.dll; do
  cp "/c/Windows/System32/$dll" "$release/"
done

if [[ ! -x "$iscc" ]]; then
  choco install innosetup -y --no-progress
fi

"$iscc" "//DAppVersion=$(bash packaging/version.sh)" packaging/windows/installer.iss
