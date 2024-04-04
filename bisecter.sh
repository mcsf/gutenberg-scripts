#!/bin/sh

# Accept Git revision as first argument, otherwise default to HEAD
if ! COMMIT=$(git rev-parse "${1-HEAD}"); then
	exit 255 # Abort bisection
fi

if ! gh --version >/dev/null 2>&1; then
	echo "error: 'gh' must be installed'"
	exit 255 # Abort bisection
fi

if ! wp-now -h >/dev/null 2>&1; then
	echo "error: 'wp-now' must be globally installed'"
	printf "tip:\n\n    npm i -g @wp-now/wp-now\n"
	exit 255 # Abort bisection
fi

if ! unzip -h >/dev/null 2>&1; then
	echo "error: 'unzip' must be installed'"
	exit 255 # Abort bisection
fi

# Query GH workflow runs and retrieve workflow ID
ID=$(gh run list \
	--commit "$COMMIT" \
	--workflow 'Build Gutenberg Plugin Zip' \
	--status success \
	--limit 1 \
	--json databaseId \
	--template '{{range .}}{{printf "%.f\n" .databaseId}}{{end}}'
)

if [ -z "$ID" ]; then
	echo "error: No matching workflows found"
	exit 125 # Skip revision as untestable
fi

# Prepare download directory and download
DST=workflow-downloads
rm -rf "$DST"
gh run download --dir "$DST" "$ID"

# Verify file existence
FILE="$DST/gutenberg-plugin/gutenberg.zip"
if ! [ -s "$FILE" ]; then
	echo "error: could not find $FILE in $DST"
	exit 125 # Skip revision as untestable
fi

# Set up test site using wp-now
cd "$(dirname "$FILE")" || exit 255
unzip "$(basename "$FILE")" >/dev/null 2>&1
wp-now start >/dev/null 2>&1 &
WPNOW_PID=$!

# As a bonus, replace Zenity with a more portable prompt. Since `read -p` is
# not POSIX-compliant, use a combination of `printf` and `read`.
confirm() {
	while true; do
		printf "%s [y/n]: " "$*"
		read -r yn
		case $yn in
			[Yy]*) return 0 ;;
			[Nn]*) return 1 ;;
		esac
	done
}

echo "Please test this version and report back"
confirm "Is this version good?"
status=$?

# NOTE: Because wp-now spawns subsequent processes, the usual `kill %1` is not
# enough. To be safe, let's explicitly kill all descendants.

list_descendants() {
	children=$(pgrep -P "$1")
	for pid in $children; do
		list_descendants "$pid"
	done
	echo "$1"
}

# shellcheck disable=SC2046
kill $(list_descendants "$WPNOW_PID")

# Finally, feed result back to `git bisect`
exit $status
