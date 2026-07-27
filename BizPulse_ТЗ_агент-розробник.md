# ТЗ для агента-розробника: BizPulse (iOS MVP + API-контракт)

> Ти — агент-розробник. Це ТЗ самодостатнє: виконуй послідовно, не вигадуй функціонал поза scope. Джерела правди наведені нижче; за конфлікту пріоритет: це ТЗ → прототип → документ концепції.

## 0. Артефакти (джерела правди)

| Файл | Що містить |
|---|---|
| `BizPulse_прототип.html` | Еталон UI/UX: усі 5 екранів, обидва режими, UA/EN, тема A, демо-дані. Верстку і поведінку відтворювати 1:1 |
| `BizPulse_теми_правила.md` | Дизайн-токени і правила тем B/C/D. Реалізація тем — окремий етап (M5) |
| `BizPulse_концепція_і_ТЗ.docx` | Продуктова логіка, персони, повний склад дашбордів, roadmap |

## 1. Продукт одним абзацом

Мобільний додаток для власників закладів харчування та інтернет-магазинів. Один акаунт → кілька бізнесів → у кожного джерело даних (Poster через RestoPro-конектор; WooCommerce/OpenCart через Аналітичний хаб). Режим інтерфейсу (resto/ecom) визначається типом джерела обраного бізнесу. Дві мови (uk, en), масштабовано до N. Додаток спілкується з ЄДИНИМ бекендом — API Аналітичного хаба.

## 2. Scope MVP (що будуєш)

**In:** iOS 16+ (SwiftUI), автентифікація (email+пароль, Sign in with Apple), мультибізнес, 5 табів (Сьогодні, Аналітика, Звіти, Сповіщення, Налаштування), режими resto/ecom, i18n uk/en, тема A, пуш-сповіщення (APNs), офлайн-кеш останніх даних, deep-link з пуша на відповідний екран.

**Out (не роби):** Android, теми B/C/D (лише перемикач-заглушка «Незабаром»), генерація PDF на клієнті (PDF віддає бекенд), план/цілі, ролі Інвестор/Керівник (модель ролей закладаєш, UI — тільки Власник), Shopify.

## 3. Архітектура і стек

```
iOS (SwiftUI, MVVM) ── HTTPS/JSON ── Hub API (єдина точка)
                                        ├── конектор Poster (код RestoPro)
                                        ├── конектор WooCommerce
                                        └── конектор OpenCart
```

- **Клієнт:** SwiftUI + async/await, без сторонніх DI/Rx. Мережа — URLSession-обгортка `APIClient`. Кеш — SwiftData (останні відповіді summary/metrics per business). Графіки — Swift Charts. Локалізація — String Catalogs. Секрети — Keychain.
- **Контракт-перший підхід:** до готовності Хаба працюєш проти mock-сервера (див. §5, приклади відповідей). Постав фіче-флаг `USE_MOCKS`.
- **Токени джерел (Poster/Woo) НІКОЛИ не потрапляють у клієнт.** Клієнт знає тільки JWT Хаба.

## 4. Модель даних клієнта (DTO)

```swift
Business { id, name, emoji, sourceType: .poster|.woocommerce|.opencart, mode: .resto|.ecom, currency, locations:[Location] }
Summary  { revenue, revenueDelta, hourly:[HourPoint], profit, marginPct, extraKPIs:[KPI], blocks:[Block] }
KPI      { key, title, value, delta, trend: .up|.down|.neutral|.warn }
Block    // поліморфний контент-блок екрана: .shiftStatus | .topList(items) | .paymentSplit | .stockAlert | .sourceList
Metric   // відповідь дашборда: заголовок, csub, елементи (bars | list | matrix | funnel)
Alert    { id, icon, title, body, severity: .critical|.warning|.positive, deepLink, createdAt }
Report   { id, type: .weekly|.monthly|.investor, period, status, pdfURL }
```

`Block`-и і KPI приходять з бекенда **вже сформовані під режим** — клієнт не містить бізнес-логіки «resto vs ecom», лише рендерери типів блоків. Це критично: нові дашборди додаються без релізу застосунку.

## 5. API-контракт (Hub API v1)

Base: `https://api.hub.example/v1`. Auth: `Authorization: Bearer <JWT>`. Помилки: `{error:{code,message}}`, 401 → refresh flow.

| Метод | Ендпоінт | Призначення |
|---|---|---|
| POST | `/auth/register`, `/auth/login`, `/auth/apple`, `/auth/refresh` | автентифікація |
| GET | `/me` | профіль + `businesses:[Business]` |
| GET | `/businesses/{id}/summary?date=` | екран «Сьогодні» одним запитом |
| GET | `/businesses/{id}/metrics/{dashboard}?period=day|week|month&from=&to=&location=` | дашборд Аналітики |
| GET | `/businesses/{id}/alerts?cursor=` | стрічка сповіщень |
| GET | `/businesses/{id}/reports` | список звітів (+`pdfURL`) |
| POST | `/businesses/{id}/sources` | підключення джерела |
| POST | `/devices` | реєстрація APNs-токена |

`{dashboard}`: resto → `revenue|menu-abc|foodcost|staff|control|locations`; ecom → `sales|products|customers|orders|channels`.

Приклад `/summary` (resto, скорочено):
```json
{
  "revenue": {"value": 4825000, "currency": "UAH", "deltaPct": 12, "compareLabelKey": "vs_last_same_weekday"},
  "hourly": [{"h": 10, "v": 18}, {"h": 20, "v": 100}],
  "kpis": [
    {"key": "receipts", "value": "312", "deltaPct": 8, "trend": "up"},
    {"key": "guests", "value": "428", "deltaPct": 5, "trend": "up"},
    {"key": "avg_receipt", "value": "₴155", "deltaPct": 3, "trend": "up"},
    {"key": "service_time", "value": "14", "unitKey": "min", "delta": "+2", "trend": "down"}
  ],
  "blocks": [
    {"type": "shiftStatus", "state": "open", "openedAt": "09:58", "register": "1", "lead": "Iryna K."},
    {"type": "topList", "titleKey": "top_dishes", "items": [{"name": "Піца Маргарита", "sub": {"sold": 58, "marginPct": 64}, "value": 870000, "trend": "up"}]},
    {"type": "paymentSplit", "card": 68, "cash": 32}
  ]
}
```
Усі суми — у мінорних одиницях (копійки), формат — на клієнті через локаль. Текстові підписи — **ключами** (`compareLabelKey`), клієнт перекладає; довільні рядки даних (назви страв) — як є.

## 6. Екрани (acceptance criteria)

### 6.1 Сьогодні
- Селектор бізнесів (горизонтальні чипи) → зміна бізнесу міняє режим, акцент (resto `#FF6B35`, ecom `#6366F1`) і дані без перезапуску.
- Герой: виручка, дельта-пігулка, погодинні бари (пікові — виділені), нижній рядок 3 показники (resto: прибуток/маржа/готівка; ecom: валовий прибуток/маржа/замовлення).
- Сітка 2×2 KPI + рендер `blocks[]` по типах (порядок — як прийшов).
- Pull-to-refresh + позначка «оновлено о HH:MM», haptic при оновленні.
- AC: скелетони при завантаженні; офлайн → останній кеш + банер «офлайн»; будь-який стан рендериться без порожніх «дірок».

### 6.2 Аналітика
- Сегмент-контрол День/Тиждень/Місяць + чипи дашбордів (склад залежить від режиму, ключі з §5).
- MVP повністю: resto `revenue`, `menu-abc` (матриця 4 квадранти + топ); ecom `sales` (динаміка + воронка), `customers` (new vs returning + RFM). Решта — екран-заглушка «У розробці» (як у прототипі), але з робочим запитом і обробкою `501`.
- AC: зміна періоду/чипа — один запит, кеш на 5 хв, стан скролу чипів зберігається.

### 6.3 Звіти
- Список з `/reports`; тап «Поділитись» → завантажити PDF → системний share sheet.
- AC: статуси ready/generating; investor-звіт позначений підзаголовком.

### 6.4 Сповіщення
- Стрічка алертів, кольоровий лівий бордер за severity, пагінація курсором, тап → deep-link (`bizpulse://business/{id}/dashboard/{key}`).
- Пуш APNs відкриває той самий deep-link. AC: badge на табі = кількість непрочитаних.

### 6.5 Налаштування
- Джерела (список + «Додати джерело» → веб-флоу підключення в SFSafariViewController, callback через universal link).
- Тема: A активна; B/C/D — disabled з бейджем «Незабаром» (ключ `soon`).
- Мова: системна за замовчуванням + ручний перемикач uk/en (перезастосування без перезапуску).
- Команда: список read-only у MVP.

## 7. Теми та дизайн-токени

- Усі кольори/радіуси/тіні — ТІЛЬКИ через семантичні токени (`Color.bg`, `Color.card`, `Color.accent`…), визначені в одному файлі `Theme.swift`. Хардкод hex у в'юхах заборонений — це вимога до code review.
- `Theme` — протокол; `ThemeA` реалізуєш, `ThemeB/C/D` — заготовки за таблицею з `BizPulse_теми_правила.md` (етап M5).
- Акцент залежить від `business.mode`, решта токенів — від теми.

## 8. i18n

- Жодного літерального рядка в UI: усе через String Catalog, ключі — snake_case, як у прототипі (`rev_today`, `top_dishes`…).
- Плюрали через ICU (`%lld замовлення/замовлень`). Числа/валюти/дати — `FormatStyle` з локаллю; валюта — з `business.currency`, НЕ з мови.
- Довжина: макети мають витримувати +30% тексту; тестуй uk та en на кожному екрані.

## 9. Правила алертів (обчислює бекенд; для mock-сервера і тестів)

| Ключ | Умова | Severity |
|---|---|---|
| `revenue_drop` | виручка дня < −20% від середньої за той самий день тижня (4 тижні) | warning |
| `voids_spike` | скасування чеків за зміну > 2 (resto) | warning |
| `returns_spike` | повернення за день > 2× середнього (ecom) | warning |
| `stock_out_forecast` | залишок топ-товару < продажі за 3 дні (ecom) | warning |
| `zero_sales` | 0 транзакцій ≥ 2 год у робочі години | critical |
| `record_day` | виручка дня — максимум за 90 днів | positive |
| `shift_closed` | закриття зміни: сума + розбіжність каси (resto) | positive |

## 10. Нефункціональні вимоги

- Будь-який екран з кешем < 200 мс; з мережі — TTI ≤ 2 с при 4G (summary — один запит).
- Краш-фрі ≥ 99.5%; аналітика подій: `screen_view`, `dashboard_open{key}`, `alert_tap`, `report_share`, `language_change`.
- Безпека: JWT у Keychain, TLS pinning (опційно за флагом), логи без PII.
- Доступність: Dynamic Type до XL без обрізань, VoiceOver-лейбли для KPI («Виручка 48 250 гривень, плюс 12 відсотків»), контраст AA.

## 11. Тестування (Definition of Done кожного етапу)

- Unit: форматери (гроші/дельти/плюрали), парсинг DTO (фікстури = приклади з §5), логіка кешу.
- Snapshot-тести ключових екранів: 2 режими × 2 мови × світла тема.
- UI-тест смоук: логін → вибір бізнесу → 5 табів → перемикання мови.
- Mock-сервер (локальний, з фікстурами) в репозиторії; CI: build + tests зелені.

## 12. Етапи виконання (строго по порядку, кожен — окремий PR)

| # | Етап | Зміст | Готово, коли |
|---|---|---|---|
| M0 | Каркас | проєкт, `Theme.swift`, `APIClient`, mock-сервер, String Catalog, навігація 5 табів | збірка + смоук-тест |
| M1 | Auth + бізнеси | реєстрація/логін/Apple, `/me`, селектор бізнесів, режими | UI-тест логіну |
| M2 | Сьогодні | §6.1 повністю, кеш, pull-to-refresh | snapshot 2×2 |
| M3 | Аналітика | §6.2: 4 повні дашборди + заглушки | snapshot дашбордів |
| M4 | Алерти + Звіти + Налаштування | §6.3–6.5, APNs, deep-links | e2e пуш → екран |
| M5 | Теми B/C/D | за `BizPulse_теми_правила.md`, перемикач у Налаштуваннях | чек-лист §7 гайда |
| M6 | Політура | порожні стани, доступність, перформанс-аудит | ✅ §10 |

## 13. Структура репозиторію

```
BizPulse/
├── App/            # entry, DI, навігація
├── Core/           # APIClient, Cache, Auth, Push, Analytics
├── Domain/         # DTO, formatters
├── Features/       # Today/ Analytics/ Reports/ Alerts/ Settings/ (View+ViewModel)
├── DesignSystem/   # Theme.swift, компоненти: HeroCard, KPICard, BarRow, ListRow, AlertCard, Chips, Segmented
├── Resources/      # Localizable.xcstrings, assets
└── MockServer/     # фікстури JSON + локальний сервер
```

## 14. Чого НЕ робити (анти-scope)

Не додавай: власні бібліотеки UI, обробку даних джерел на клієнті, локальні розрахунки метрик (усе рахує Хаб), більше двох мов, онбординг-туторіали, віджети/Watch. Не змінюй порядок етапів. Питання, що змінюють контракт §5, — виноси власнику продукту, а не вирішуй сам.
