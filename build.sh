#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/dist"
VERSION=$(grep "version=" "${SCRIPT_DIR}/module.prop" | cut -d= -f2)
ZIP_NAME="s20fe-stock-tune-${VERSION}.zip"

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}/${ZIP_NAME}"

chmod 755 "${SCRIPT_DIR}/service.sh"
chmod 755 "${SCRIPT_DIR}/META-INF/com/google/android/update-binary"

cd "${SCRIPT_DIR}"
zip -r -9 "${OUTPUT_DIR}/${ZIP_NAME}" module.prop service.sh META-INF -x "*.git*"

echo "Pacote flashável gerado com sucesso:"
echo "-> ${OUTPUT_DIR}/${ZIP_NAME}"
