#!/usr/bin/env sh
# Builds the standalone page for GitHub Pages from the artifact page.
# web/ragpit.html holds the game, web/head.html the document head.
set -e
cd "$(dirname "$0")"
{ cat head.html; cat ragpit.html; printf '\n</body>\n</html>\n'; } > ../docs/index.html
echo "docs/index.html updated"
