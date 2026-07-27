#!/usr/bin/env bash
# Створює публічний репо metrica на GitHub і вмикає Pages з /docs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_NAME="${REPO_NAME:-metrica}"
OWNER="${GITHUB_OWNER:-malkovych}"

cd "$ROOT"

if ! command -v gh >/dev/null; then
  echo "Встанови GitHub CLI: brew install gh && gh auth login"
  exit 1
fi

gh auth status >/dev/null 2>&1 || {
  echo "Спочатку: gh auth login"
  exit 1
}

if [[ ! -d .git ]]; then
  git init -b main
fi

git add README.md .gitignore docs/ Metrica/ .github/
git add BizPulse_*.md BizPulse_прототип.html 2>/dev/null || true

if git diff --cached --quiet; then
  echo "Немає змін для commit"
else
  git commit -m "$(cat <<'EOF'
Add Metrica iOS app and GitHub Pages for App Store.

Includes privacy policy, support, and terms pages.
EOF
)"
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "Remote origin вже існує"
else
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push --description "Metrica — iOS business dashboard"
fi

# GitHub Pages: deploy from /docs on main
gh api "repos/${OWNER}/${REPO_NAME}/pages" -X POST \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/docs 2>/dev/null || \
gh api "repos/${OWNER}/${REPO_NAME}/pages" -X PUT \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/docs 2>/dev/null || true

git push -u origin main 2>/dev/null || git push origin main

BASE="https://${OWNER}.github.io/${REPO_NAME}"
echo ""
echo "✅ Репозиторій: https://github.com/${OWNER}/${REPO_NAME}"
echo "📄 Privacy:     ${BASE}/privacy.html"
echo "🛟 Support:     ${BASE}/support.html"
echo "📋 Terms:       ${BASE}/terms.html"
echo "🏠 Home:        ${BASE}/"
echo ""
echo "Pages може оновлюватись 1–3 хв."
