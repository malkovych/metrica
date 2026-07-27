# Metrica — iOS + GitHub Pages

Репозиторій застосунку **Metrica** та публічних сторінок для App Store Connect.

## Структура

- `Metrica/` — iOS застосунок (SwiftUI)
- `docs/` — GitHub Pages (Privacy, Support, Terms)

## App Store URLs (після публікації Pages)

| Призначення | URL |
|---|---|
| Marketing / Support | `https://malkovych.github.io/metrica/` |
| Privacy Policy | `https://malkovych.github.io/metrica/privacy.html` |
| Support | `https://malkovych.github.io/metrica/support.html` |
| Terms | `https://malkovych.github.io/metrica/terms.html` |

## Публікація Pages

```bash
# 1. Увійти в GitHub (один раз)
gh auth login

# 2. Створити репо та запушити
cd /Users/pm/dev/appecom
./scripts/publish-github.sh
```

Pages увімкнуться автоматично з гілки `main`, папка `/docs`.
