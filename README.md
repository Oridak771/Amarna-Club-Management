# Amarna Club — Tablette de Gestion Opérationnelle

Amarna Club is a staff-facing tablet application for an activity/leisure club — employees, supervisors, and operations managers. It is a Flutter app (Android / iOS / Windows desktop) that acts as a field tool and syncs data with an Odoo ERP backend (direct JSON-RPC + PostgreSQL read access). The app assumes a permanent internet connection.

---

## 🚀 Key Features

* **Ma journée (Home)** — action-first staff home page: urgent interventions, today's reservations with one-tap **check-in**, live alerts (critical incidents, overdue work, low stock, activity warnings), quick actions and an activity occupancy strip.
* **Activités (Specialized Modules)**:
  * 🏊 **Piscine** — water-quality gauges (pH, chlorine, temperature, turbidity), conformity summary, reading log, open interventions.
  * 🐎 **Écurie** — horse grid with breed/age/status/fatigue, vet visit reminders, today's riding sessions (Odoo), status filters.
  * 🔫 **Stand de Tir** — armory summary, serial tracking, cleaning-due alerts with QR scan.
  * 🎯 **Paintball / Gym / Padel** — session clock & player counter, cleaning progress, court boards, live Odoo reservations per activity.
* **Interventions (unified module)** — incidents and maintenance merged in one flow: filterable list (type, overdue, status), photo attachments, comment & event **timeline**, technician assignment, one-tap status transitions. Every change is pushed directly to Odoo.
* **Réservations** — day planner fed by Odoo (`calendar.event` by default), creation and **check-in** which updates activity occupancy and writes back the status.
* **Thème clair / sombre** — full light & dark design system (emerald + gold), switchable from Profil → Apparence, persisted across launches.

---

## 🛠️ Technology Stack

* **Frontend**: Flutter (stable) / Dart 3.x
* **Navigation**: GoRouter (StatefulShellRoute branches)
* **State**: Riverpod
* **Local cache**: Isar 3.x
* **Integrations**: Odoo JSON-RPC (`http`), direct PostgreSQL reads (`postgres`), `mobile_scanner` (QR), `nfc_manager` (NFC), `flutter_dotenv` (secrets), `flutter_secure_storage` (preferences)

---

## 📂 Project Structure

```
lib/
├── main.dart                  # Bootstrap: .env load, Isar init, provider overrides
├── routes.dart                # GoRouter configuration
├── config/
│   └── app_environment.dart   # Reads runtime secrets from .env
├── models/                    # Isar collections & domain models
├── providers/                 # Riverpod state (tickets, activities, check-in, theme…)
├── repositories/              # Isar data-access layer
├── services/                  # Odoo JSON-RPC, Postgres, ticket push, database seed
├── theme/app_theme.dart       # Light + dark design system (semantic tokens)
├── ui/                        # Model → color/label adapters
├── widgets/                   # Shared components (gauges, panels, chips…)
└── screens/                   # Pages (home, activities/, tickets, reservations…)
tool/
└── check_db.dart              # CLI connectivity check for the Odoo PostgreSQL DB
```

---

## 💻 Setup & Run

### 1. Prerequisites
* **Flutter SDK** (stable channel, Dart 3.x)
* Android Studio / Xcode / Visual Studio ("Desktop development with C++") depending on target

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure credentials (.env)
Copy the template and fill in the real values — `.env` is gitignored and bundled at build time:
```bash
cp .env.example .env
```
```dotenv
AMARNA_DB_HOST=10.20.10.49
AMARNA_DB_PORT=5432
AMARNA_DB_NAME=<postgres_database_name>
AMARNA_DB_USERNAME=biuser
AMARNA_DB_PASSWORD=<postgres_password>

AMARNA_ODOO_BASE_URL=https://your-odoo-host
AMARNA_ODOO_DB=<odoo_database_name>
AMARNA_ODOO_USERNAME=<odoo_login>
AMARNA_ODOO_PASSWORD=<odoo_password>
```
Optional Odoo model/field mappings (reservations & tickets) are documented in `.env.example`.

Verify database connectivity at any time:
```bash
dart run tool/check_db.dart
```

### 4. Generate database schemas
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Run
```bash
flutter devices
flutter run -d <device_id>     # or: flutter run -d windows
```

---

## 🔄 Odoo Synchronization

The app is online-first: every ticket creation/update is pushed immediately to Odoo (`maintenance.request` by default), and reservations are read from / written to Odoo (`calendar.event` by default). If Odoo is not configured in `.env`, the app runs fully on the local Isar cache with seeded demo data — remote pushes are simply skipped.
