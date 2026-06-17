# Amarna Club — Mobile Operations Management App

Amarna Club is a mobile-first, offline-first operational client application designed for activity center employees, supervisors, and operations managers. It serves as a field interface to manage daily operations, track assets, file incidents, perform checklist inspections, adjust stocks, and log maintenance activities, eventually synchronizing all data with Odoo ERP.

---

## 🚀 Key Features

* **Accueil (KPI Dashboard)**: Display of real-time metrics (open activities, active incidents, delayed maintenance, daily bookings) and connection indicators.
* **Activités (Specialized Modules)**:
  * 🏊 **Piscine**: Live water quality dials (pH, Chlorine, Temperature, Turbidity).
  * 🐎 **Écurie**: Grid of horses with veterinary fatigue bars, statuses, and profiles.
  * 🔫 **Stand de Tir**: Strict serial tracking and QR scan requirements for cleaning.
  * 🎯 **Paintball / Gym / Padel**: Interactive court schedules, session clocks, and clean sheets.
* **Suivi de Maintenance (Tab 3)**: Preventive and corrective intervention timelines, technician assignments, and checkoffs.
* **Signalement d'Incidents (Tab 4)**: Glove-friendly quick reporting flow (Type + Priority + Photo attachment in under 3 taps) with optional voice notes and detailed sheets.
* **Fiches d'inspection (Checklists)**: Gestural swipeable checklists card stack (Swipe Right for `Done`, Swipe Left for `Problem`) powered by responsive spring physics.
* **Moteur Hors-ligne (Offline DB)**: Built on Isar DB cache. In offline mode, the app buffers actions locally and prompts a reactive warning banner. Re-establishing connection automatically triggers the synchronization queue to sync Odoo ERP.

---

## 🛠️ Technology Stack

* **Frontend Framework**: Flutter (v3.10.0+ / stable channel)
* **Programming Language**: Dart 3.x
* **Navigation & Shell Routing**: GoRouter (indexed stateful stack branches)
* **State Management**: Riverpod (Notifier state containers)
* **Local Cache Database**: Isar 3.x (Object-oriented persistent database)
* **Integrations**: `mobile_scanner` (QR scanning), `nfc_manager` (NFC tag scanning), `path_provider`, `flutter_secure_storage`.

---

## 📂 Project Directory Structure

```
lib/
├── main.dart                  # App bootstrap, db initialization, and provider overrides
├── routes.dart                # GoRouter configuration with StatefulShellRoute branches
├── models/                    # Data models & Isar database collection schemas
│   ├── activity.dart          # Activity metadata and occupancy details
│   ├── asset.dart             # Equipment/asset serials, specs, and maintenance logs
│   ├── checklist_item.dart    # Daily checklist task schemas
│   ├── incident.dart          # Incident priorities, statuses, and reporting details
│   ├── inventory_item.dart    # Consumables, stock levels, and threshold warnings
│   └── maintenance_task.dart  # Preventive and corrective work orders
├── providers/                 # State management (Riverpod Notifiers & DB caches)
│   ├── activities_provider.dart
│   ├── assets_provider.dart
│   ├── checklist_provider.dart
│   ├── incidents_provider.dart
│   ├── inventory_provider.dart
│   ├── maintenance_provider.dart
│   └── sync_provider.dart     # Offline transaction queue and network simulator
├── services/                  # Infrastructure and database layers
│   └── database_service.dart  # Isar instance builder & seed data migrator
├── theme/                     # Styling system
│   └── app_theme.dart         # Dark theme rules, palettes, and typography tokens
├── widgets/                   # Shared reusable UI component library (Touch targets >= 48px)
│   ├── activity_tile.dart     # Grid activity selector
│   ├── app_filter_chip.dart   # List state selection filters
│   ├── gauge_card.dart        # Radial quality arcs
│   ├── inventory_stepper.dart # Stock adjusters (48x48px targets)
│   ├── offline_banner.dart    # Connection status banner
│   ├── priority_indicator.dart# Priority borders & pulse glows
│   ├── swipe_card.dart        # Gestural checklist cards
│   └── ...
└── screens/                   # Page screens and layouts
    ├── dashboard_screen.dart  # Core KPI dashboard
    ├── offline_dashboard_screen.dart # Sync status & Connection simulator
    ├── activity_detail_screen.dart # Tabbed details (Consumables, Equipment, Logs)
    └── activities/            # Activity-specific custom modules (Pool, Horses, Padel...)
```

---

## 💻 Local Setup & Run Instructions

To run the application locally on your computer without Docker:

### 1. Prerequisites
Ensure you have the Flutter SDK and dependencies installed locally:
* **Flutter SDK**: Stable channel (v3.10.0+ / Dart 3.x)
* **Android Development**: Android Studio and SDK (for emulation/mobile debugging)
* **iOS Development**: Xcode (macOS only, for iPhone debugging)
* **Windows Desktop Development**: Visual Studio with the "Desktop development with C++" workload installed.

### 2. Install Dependencies
Navigate to the project directory and pull Dart packages:
```bash
flutter pub get
```

### 3. Generate Database Schemas
Generate the Isar adapters and model schemas (`.g.dart` files):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the Application
Start debugging the app on your connected device or local emulator:
```bash
# List all active devices
flutter devices

# Run on a target device
flutter run -d <device_id>

# Run natively on Windows Desktop
flutter run -d windows
```

---

## ⚙️ Offline Synchronization Simulation

To verify the offline transaction buffering:
1. Navigate to **Plus** -> **Mode hors-ligne** inside the application.
2. Toggle the **Simulation Réseau** switch to **Hors-ligne**. The amber warning banner will slide down.
3. Make changes inside the app (e.g. increase stock quantities, file a quick incident report, or check off inspection cards).
4. Notice the **Modifications En attente** count updates and logs the actions in the terminal interface.
5. Toggle the network back to **Connecté**. The synchronization queue will run, clear database transaction flags, reload views, and display a green success banner (`Synchronisé ✓`).
