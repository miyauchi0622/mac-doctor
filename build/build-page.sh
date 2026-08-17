#!/bin/bash
# 配布ページを生成する。
#
# ダウンロードは GitHub Release の固定 URL を指す。
# 以前はページに zip を base64 で埋め込んでいたが、共有ページは制限付きの枠内で
# 表示されるためファイル保存がブロックされ、無反応になった。実体のある URL を
# 指すこと。ページ内にファイルを埋め込み直してはならない。
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Mac診断.app"
ZIP="$ROOT/build/Mac診断.zip"
TPL="$ROOT/build/page-template.html"
OUT="$ROOT/build/distribute.html"

# ダウンロード先。Release を作り直しても URL は変わらない。
DOWNLOAD_URL="${MACDOCTOR_DOWNLOAD_URL:-https://github.com/miyauchi0622/mac-doctor/releases/latest/download/Mac-Shindan.zip}"

# 常に最新のスクリプトを含んだアプリから作り直す
bash "$ROOT/build/build-app.sh" >/dev/null

rm -f "$ZIP"
# ditto は実行権限とリソースフォークを保ったまま圧縮する。
# zip コマンドではアプリの実行権限が失われる場合がある。
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

SIZE=$(awk -v b="$(wc -c < "$ZIP" | tr -d ' ')" 'BEGIN{printf "%.0f KB", b/1024}')
DATE=$(date '+%Y-%m-%d')

awk -v url="$DOWNLOAD_URL" -v size="$SIZE" -v d="$DATE" '
  { line=$0
    gsub(/__DOWNLOAD_URL__/, url,  line)
    gsub(/__ZIP_SIZE__/,     size, line)
    gsub(/__BUILD_DATE__/,   d,    line)
    print line }
' "$TPL" > "$OUT"

# 差し込み漏れがあれば失敗させる
if grep -q '__DOWNLOAD_URL__\|__ZIP_SIZE__\|__BUILD_DATE__' "$OUT"; then
  echo "エラー: プレースホルダが残っています" >&2
  exit 1
fi

echo "生成しました: $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"
echo "ダウンロード先: $DOWNLOAD_URL"
