# Metrica — публікація в App Store

Чек-лист для першого релізу **1.0.0 (1)**.

## 1. Apple Developer

1. [developer.apple.com](https://developer.apple.com) → **Identifiers** → App ID `com.metrica.app`
2. Увімкнути capabilities:
   - **Sign in with Apple**
   - **Push Notifications**
3. Створити **Distribution** сертифікат (Xcode з Automatic Signing зробить сам).
4. App Store Connect → **My Apps** → **+** → New App:
   - Name: **Metrica**
   - Primary language: Ukrainian або English
   - Bundle ID: `com.metrica.app`
   - SKU: `metrica-ios-001`

## 2. Локальна підготовка

```bash
cd Metrica
export DEVELOPMENT_TEAM=YOUR_TEAM_ID   # 10 символів
# У project.yml або Xcode: DEVELOPMENT_TEAM
xcodegen generate
open Metrica.xcodeproj
```

### Обов’язково перед архівом

| Пункт | Де |
|---|---|
| **App Icon 1024×1024** | ✅ `Resources/Assets.xcassets/AppIcon.appiconset/` |
| **Hub API URL (prod)** | `HUB_BASE_URL` у CI / xcconfig; `USE_MOCKS=0` у Release |
| **Privacy Policy URL** | ✅ `https://malkovych.github.io/metrica/privacy.html` |
| **Support URL** | ✅ `https://malkovych.github.io/metrica/support.html` |
| **APNs ключ (.p8)** | Hub бекенд + Apple Developer → Keys |

## 3. Archive + Upload

```bash
chmod +x Scripts/archive.sh
export DEVELOPMENT_TEAM=YOUR_TEAM_ID
./Scripts/archive.sh
```

Або в Xcode: **Product → Archive** → **Distribute App → App Store Connect**.

Завантаження IPA:

```bash
xcrun altool --upload-app -f build/export/Metrica.ipa \
  -t ios -u YOUR_APPLE_ID -p @keychain:AC_PASSWORD
```

Або **Transporter** (macOS).

## 4. Метадані App Store Connect

### Назва та підзаголовок (uk)

- **Назва:** Metrica
- **Підзаголовок:** Дашборд для ресторанів та e-commerce
- **Категорія:** Business
- **Віковий рейтинг:** 4+

### Опис (uk, скорочено)

Metrica — мобільний дашборд для власників закладів харчування та інтернет-магазинів. Один акаунт, кілька бізнесів: виручка сьогодні, аналітика, звіти PDF, push-сповіщення про аномалії. Підключення Poster, WooCommerce та OpenCart через єдиний Hub API.

### Ключові слова (en, ≤100 символів)

restaurant,dashboard,analytics,ecommerce,revenue,woocommerce,poster,reports,KPI

### Скріншоти

Мінімум для iPhone 6.7":
1. Сьогодні (resto)
2. Аналітика
3. Сповіщення
4. Налаштування / теми

Запуск на симуляторі iPhone 17 → **Cmd+S** у Simulator або `xcrun simctl io booted screenshot`.

## 5. App Privacy (Connect)

| Дані | Призначення |
|---|---|
| Email, ім’я | Обліковий запис |
| Device ID (APNs) | Push-сповіщення |
| Analytics (in-app events) | Покращення продукту, без трекінгу |

У застосунку: `PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption = NO`.

## 6. Review notes для Apple

```
Demo account (sandbox Hub):
Email: owner@metrica.app
Password: password

Notes: App requires Hub API backend. Review build uses mock data when USE_MOCKS=1.
Sign in with Apple is supported alongside email login.
```

Якщо Review без бекенду — зберіть **Release** з `USE_MOCKS=1` лише для review (окремий build) або надайте staging Hub URL.

## 7. Deep links і push

- URL scheme: `metrica://business/{id}/dashboard/{key}`
- Legacy: `bizpulse://` (backward compatible у клієнті)
- Universal Links (опційно): `applinks:app.metrica.io` — Associated Domains у entitlements + apple-app-site-association на домені

## 8. Після схвалення

- Phased Release (7 днів) — рекомендовано для 1.0
- Увімкнути **Production** APNs на Hub
- Моніторинг crash logs у Xcode Organizer / Metrica dashboard
