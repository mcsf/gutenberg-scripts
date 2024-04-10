#!/bin/sh

#########################################################
# SUPERSEDED BY SCRIPTS get-and-bisect AND get-plugin-zip
#########################################################

# Default arguments
COMMIT="HEAD"
OUT_FILE="gutenberg.zip"

usage() {
	cat <<EOD
usage: $(basename "$0") [...options]
 -o <file>      Write to output file (default: gutenberg.zip)
 -c <commit>    Fetch build corresponding to commit (default: HEAD)
 -h             Show this help screen
EOD
	exit 2
}

fail() {
	echo "error: $1" >&2
	exit 1
}

# shellcheck disable=2048 disable=2086
args=$(getopt ho:c: $*) || usage

# shellcheck disable=2086
set -- $args
for i; do
	case "$i" in
		-h) usage;;
		-o) shift; OUT_FILE="$1"; shift;;
		-c) shift; COMMIT="$1"; shift;;
	esac
done
[ -n "$OUT_FILE" ] || usage

which -s git || fail "git must be installed"
which -s gh  || fail "gh must be installed"

COMMIT=$(git rev-parse "$COMMIT") || exit 1

# Query GH workflow runs and retrieve workflow ID
ID=$(gh run list \
	--commit "$COMMIT" \
	--workflow 'Build Gutenberg Plugin Zip' \
	--status success \
	--limit 1 \
	--json databaseId \
	--template '{{range .}}{{printf "%.f\n" .databaseId}}{{end}}'
)
[ -n "$ID" ] || fail "no matching workflows found"

TMP_DIR=$(mktemp -dq) || fail "could not obtain temporary directory"
gh run download --dir "$TMP_DIR" "$ID" || exit 1

TEMP_FILE="$TMP_DIR/gutenberg-plugin/gutenberg.zip"
[ -s "$TEMP_FILE" ] || fail "could not find downloaded ZIP file"
mv "$TEMP_FILE" "$OUT_FILE" || fail "could not write file to $OUT_FILE"
rm -rf "$TMP_DIR"

echo "Downloaded $OUT_FILE"
