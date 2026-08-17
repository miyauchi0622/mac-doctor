#!/bin/bash
# 配布用の Mac診断.app を生成する。macOS標準の osacompile のみを使う。
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Mac診断.app"

rm -rf "$APP"

# path to me でアプリ自身の場所を得て、同梱したシェルスクリプトを実行する。
# do shell script はターミナルを開かない。
osacompile -o "$APP" <<'APPLESCRIPT'
set myPath to POSIX path of (path to me)
set runner to quoted form of (myPath & "Contents/Resources/macdoctor/mac-doctor.sh")
try
	do shell script "/bin/bash " & runner
on error errMsg
	display dialog "診断中に問題が発生しました。情シスに次の内容を伝えてください：" & return & return & errMsg buttons {"OK"} default button "OK" with icon caution
end try
APPLESCRIPT

# osacompile が作る Contents/Resources/Scripts と衝突しないよう別名にする。
# macOS の標準ファイルシステムは大文字小文字を区別しないため、"scripts" では
# Apple 側の "Scripts" と同じ場所になり main.scpt と混ざってしまう。
mkdir -p "$APP/Contents/Resources/macdoctor"
cp "$ROOT/src/"*.sh "$APP/Contents/Resources/macdoctor/"
chmod +x "$APP/Contents/Resources/macdoctor/"*.sh

echo "生成しました: $APP"
