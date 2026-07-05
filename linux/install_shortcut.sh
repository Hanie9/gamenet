#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="${HOME}/.local/share/applications"
ICONS_DIR="${HOME}/.local/share/icons"

mkdir -p "${APPS_DIR}" "${ICONS_DIR}"

cp -a "${DIR}/share/icons/hicolor" "${ICONS_DIR}/"

cat > "${APPS_DIR}/com.example.gamenet.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=201
GenericName=مدیریت گیم‌نت
Comment=مدیریت گیم‌نت
Exec=${DIR}/bundle_launcher.sh
Icon=com.example.gamenet
StartupWMClass=com.example.gamenet
Terminal=false
Categories=Game;Utility;
EOF

chmod +x "${DIR}/bundle_launcher.sh"
update-desktop-database "${APPS_DIR}" 2>/dev/null || true
gtk-update-icon-cache -f -t "${ICONS_DIR}/hicolor" 2>/dev/null || true

echo "Shortcut installed. You can launch '201' from the app menu."
