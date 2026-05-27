#!/usr/bin/env bash
# Empacota os 4 entregáveis em zips/mcpacks na pasta fex-private/dist/.
set -euo pipefail

cd "$(dirname "$0")/.."
DIST=dist
mkdir -p "$DIST"
rm -f "$DIST"/*.zip "$DIST"/*.mcpack "$DIST"/*.mcaddon

echo "[1/5] Gerando texturas..."
python3 tools/gen_textures.py
python3 tools/gen_subpacks.py

echo "[2/5] Bedrock Resource Pack (.mcpack)..."
( cd bedrock/resource_pack && zip -qr "../../$DIST/FexPrivate_RP_1.26.21.mcpack" . )

echo "[3/5] Bedrock Behavior Pack (.mcpack)..."
( cd bedrock/behavior_pack && zip -qr "../../$DIST/FexPrivate_BP_1.26.21.mcpack" . )

echo "[4/5] Bedrock Addon combo (.mcaddon)..."
TMP=$(mktemp -d)
cp -r bedrock/resource_pack "$TMP/resource_pack"
cp -r bedrock/behavior_pack "$TMP/behavior_pack"
( cd "$TMP" && zip -qr fex_combo.zip resource_pack behavior_pack )
mv "$TMP/fex_combo.zip" "$DIST/FexPrivate_Addon_1.26.21.mcaddon"
rm -rf "$TMP"

echo "[5/5] Java Resource Packs (.zip)..."
( cd java/1_21_4/resource_pack && zip -qr "../../../$DIST/FexPrivate_Java_1.21.4.zip" . )
( cd java/1_8_9/resource_pack && zip -qr "../../../$DIST/FexPrivate_Java_1.8.9.zip" . )

echo
echo "Distribuíveis em $DIST/:"
ls -lh "$DIST"
