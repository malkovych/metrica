# Metrica (iOS)

Мобільний дашборд для закладів харчування та e-commerce. Клієнт — тонкий SwiftUI-застосунок; уся бізнес-логіка і метрики — на **Hub API**.

**Bundle ID:** `com.metrica.app` · **App Store name:** Metrica

## Швидкий старт

```bash
cd Metrica
xcodegen generate
open Metrica.xcodeproj
```

Демо (mock): `owner@metrica.app` / `password`

## App Store

Повний чек-лист: **[APPSTORE.md](APPSTORE.md)**

```bash
export DEVELOPMENT_TEAM=YOUR_TEAM_ID
./Scripts/archive.sh
```

## Архітектура

```
iOS (SwiftUI) ── HTTPS/JSON ── Hub API
                                  ├── Poster (RestoPro)
                                  ├── WooCommerce
                                  └── OpenCart
```

- Deep-link: `metrica://business/{id}/dashboard/{key}`
- JWT у Keychain; `PrivacyInfo.xcprivacy` для App Store
- Release **1.0.0** · iOS 17+

## Статус розробки

M0–M11 ✅ (див. попередні етапи в історії комітів)

## Локальний mock

```bash
python3 MockServer/serve.py
# USE_MOCKS=0 HUB_BASE_URL=http://127.0.0.1:8787/v1
```
