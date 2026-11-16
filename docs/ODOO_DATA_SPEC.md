# Amarna Club — Odoo Data Specification

> **Current state (Nov 2026).** The backend is the `amarna_club_*` addons and
> `abonnement_amarna` in `odoo17/custom_addons`. The planned names below
> (`amarna.reservation`, `amarna.stock.item`, `maintenance.request`, …) are
> historical. The live contract is the one in `lib/services/` and in
> `odoo17/custom_addons/README.md`:
>
> | App service | Odoo model |
> |---|---|
> | `odoo_club_service.dart` | `amarna.club.activity`, `amarna.club.asset`, `amarna.club.inventory.item`, `amarna.club.horse`, `amarna.club.pool.reading`, `amarna.club.intervention` |
> | `odoo_reservation_service.dart` | `amarna.club.reservation` (`status`: pending, confirmed, checkedin, cancelled) |
> | `odoo_subscription_service.dart` | `amarna.subscription` (`subscription_status`, `billing_state`, `amount_due`) |
>
> Billing lives in accounting: invoices (`account.move`) linked to the
> subscription or reservation, paid through the standard payment wizard.
>
> The tables below are kept for the original design rationale.

Goal: make **Odoo the single backend/database** for the mobile app. Every screen
should read (and where relevant write) its data from an Odoo model over JSON-RPC,
replacing the app's local Isar seed data and hardcoded demo data.

This document lists, per app feature, the Odoo model required — existing, needs
extension, or new — with the exact fields the app consumes and their types.

Legend: **[R]** app reads it · **[W]** app writes it · `x_` = custom field.

---

## Status overview

| App feature                              | Odoo model                       | Exists?     | Action                        |
| ------------------------------------------| ----------------------------------| -------------| -------------------------------|
| Subscriptions (abonnements)              | `amarna.subscription`            | ✅           | Done — live R/W               |
| Interventions / tickets                  | `maintenance.request`            | ✅ installed | Add fields + let app **read** |
| Equipment (assets, gym, weapons, courts) | `maintenance.equipment`          | ✅ installed | Add fields                    |
| Activities (master)                      | `amarna.activity`                | ✅ (minimal) | **Extend** with fields below  |
| Clients                                  | `res.partner`                    | ✅           | Use as-is                     |
| Reservations / bookings                  | `amarna.reservation`             | ❌           | **Create**                    |
| Inventory / stock                        | `amarna.stock.item`              | ❌           | **Create** (or map `product`) |
| Horses (écurie)                          | `amarna.horse` (+ `.ride`)       | ❌           | **Create**                    |
| Pool water readings                      | `amarna.pool.reading`            | ❌           | **Create**                    |
| Staff activity assignment                | `res.users` (+ `x_activity_ids`) | ✅           | Add field (optional)          |
| Notifications                            | `amarna.notification`            | ❌           | Optional                      |

---

## Tier 1 — Core (required for the app to be Odoo-backed)

### 1. `amarna.activity` — Activity master  **(EXTEND)**
Drives the Activités grid, home occupancy strip, and links everything else.
Currently has only `name`, `code`. Add:

| Field               | Type                 | App field               | Notes                                                |
| ---------------------| ----------------------| -------------------------| ------------------------------------------------------|
| `code`              | Char                 | `id` **[R]**            | `pool`,`horses`,`paintball`,`shooting`,`gym`,`padel` |
| `name`              | Char                 | `name` **[R]**          |                                                      |
| `icon_key`          | Char                 | `iconKey` **[R]**       | same as code is fine                                 |
| `state`             | Selection **[R][W]** | `status`                | `open`,`closed`,`warning`,`maintenance`              |
| `current_occupancy` | Integer **[R][W]**   | `currentOccupancy`      | app +/- writes this                                  |
| `max_capacity`      | Integer              | `maxCapacity` **[R]**   |                                                      |
| `staff_id`          | Many2one `res.users` | `assignedStaff` **[R]** | or `assigned_staff` Char                             |

Seed one record per activity (6 total).

### 2. `amarna.reservation` — Bookings  **(CREATE)**
Backs "Réservations du jour", the reservations planner, and check-in.

| Field | Type | App field | Notes |
|---|---|---|---|
| `partner_id` | Many2one `res.partner` **[R]** | `clientName` | or `client_name` Char |
| `activity_id` | Many2one `amarna.activity` **[R]** | `activityId`/`Name` | |
| `people_count` | Integer **[R]** | `peopleCount` | |
| `start_datetime` | Datetime **[R]** | `startAt` | **must be datetime** (day filter) |
| `end_datetime` | Datetime **[R]** | `endAt` | |
| `state` | Selection **[R][W]** | `status` | `confirmed`,`pending`,`cancelled`,`checkedin` |
| `note` | Text **[R]** | `notes` | |

Check-in writes `state = checkedin`. `.env` then points
`AMARNA_ODOO_RESERVATION_MODEL=amarna.reservation` with the matching field names.

### 3. `maintenance.request` — Interventions/tickets  **(EXTEND + expose)**
Already receives writes from the app. To make it a full two-way source, add:

| Field | Type | App field | Notes |
|---|---|---|---|
| `name` | Char (native) | `title` **[R][W]** | |
| `description` | Text (native) | `description` **[R][W]** | app tags `[Mobile ID: ...]` |
| `x_ticket_type` | Selection **[R][W]** | `type` | `anomaly`,`preventive`,`corrective` |
| `x_priority` | Selection **[R][W]** | `priority` | `low`,`medium`,`high`,`critical` |
| `x_mobile_status` | Selection **[R][W]** | `status` | `open`,`inProgress`,`resolved` |
| `x_activity_id` | Many2one `amarna.activity` **[R][W]** | `activityId` | |
| `equipment_id` | Many2one `maintenance.equipment` (native) | `assetId` **[R][W]** | |
| `schedule_date` | Datetime (native) | `dateDue` **[R][W]** | mapped already |
| `x_assigned_technician` | Char (or `user_id` native) **[R][W]** | `assignedTechnician` | |

Photos → use the native chatter attachments (`message_ids` / `ir.attachment`).
Timeline events → native chatter (`mail.message`) can back the history view.

### 4. `maintenance.equipment` — Equipment  **(EXTEND)**
One model backs the "Équipement" tab, gym machines, weapons/armory, padel courts.

| Field | Type | App field | Notes |
|---|---|---|---|
| `name` | Char (native) | `name` **[R]** | |
| `serial_no` | Char (native) | `serialNumber` **[R]** | armory serial tracking |
| `x_activity_id` | Many2one `amarna.activity` **[R]** | `activityId` | |
| `x_category` | Char | `category` **[R]** | or native `category_id` |
| `x_status` | Selection **[R][W]** | `status` | `available`,`inuse`,`maintenance`,`broken` |
| `x_last_maintenance` | Date | `lastMaintenance` **[R]** | or native `effective_date` |
| `x_next_maintenance` | Date | `nextMaintenance` **[R]** | |
| `x_specs` | Text (JSON or key:val) | `technicalSpecs` **[R]** | technical sheet |
| `x_is_cleaned` | Boolean **[R][W]** | gym cleaning flag | gym/weapons |
| `x_last_cleaned` | Datetime **[R][W]** | weapon last-cleaned | armory |

### 5. `amarna.stock.item` — Inventory  **(CREATE)** *(or map `product.template`)*
Backs the inventory steppers (global + per-activity).

| Field | Type | App field | Notes |
|---|---|---|---|
| `name` | Char **[R]** | `name` | |
| `activity_id` | Many2one `amarna.activity` **[R]** | `activityId`/`Name` | |
| `current_stock` | Integer **[R][W]** | `currentStock` | steppers write this |
| `low_threshold` | Integer **[R]** | `lowThreshold` | low-stock alerts |
| `unit_name` | Char **[R]** | `unitName` | "boîtes","kg"… |

*Alternative*: use real `product.product` + `stock.quant` and a reordering rule for
the threshold. Heavier but gives true stock accounting. The lightweight custom model
matches the app 1:1 and is simpler to start with.

---

## Tier 2 — Activity-specific richness

### 6. `amarna.horse` — Stable  **(CREATE)**
Backs the écurie grid + horse profile.

| Field | Type | App field |
|---|---|---|
| `name` | Char **[R]** | `name` |
| `breed` | Char **[R]** | `breed` |
| `age` | Integer **[R]** | `age` |
| `box_number` | Char **[R]** | `boxNumber` |
| `state` | Selection **[R][W]** | `status` (`available`,`resting`,`injured`) |
| `fatigue` | Float (0–1) **[R]** | `fatigue` |
| `diet` | Text **[R]** | `diet` |
| `vet_note` | Text **[R]** | `vetNote` |
| `next_vet_visit` | Datetime **[R]** | `nextVetVisit` |
| `last_farrier` | Date **[R]** | `lastFarrier` |
| `last_vaccine` | Date **[R]** | `lastVaccine` |
| `last_deworming` | Date **[R]** | `lastDeworming` |
| `ride_ids` | One2many `amarna.horse.ride` **[R]** | `ridesToday` |

**`amarna.horse.ride`** (child): `horse_id` (m2o), `time_range` (char), `label` (char), `rider` (char), `date` (date).

### 7. `amarna.pool.reading` — Water quality  **(CREATE)**
Backs the pool gauges + reading history; new readings are **written** from the app.

| Field | Type | App field |
|---|---|---|
| `activity_id` | Many2one `amarna.activity` **[R]** | pool |
| `temperature` | Float **[R][W]** | `temperature` |
| `chlorine` | Float **[R][W]** | `chlorine` |
| `ph` | Float **[R][W]** | `ph` |
| `turbidity` | Float **[R][W]** | `turbidity` |
| `recorded_at` | Datetime **[R][W]** | `recordedAt` |
| `recorded_by` | Many2one `res.users` **[W]** | operator |

---

## Tier 3 — Optional / later

### 8. `res.users` — Staff  *(add field)*
`x_activity_ids` Many2many → `amarna.activity` for the profile's "assigned activities"
and to filter each user's home to their activities.

### 9. `amarna.notification` — Notifications *(optional)*
`title` (char), `body` (text), `type` (selection), `activity_id` (m2o),
`is_read` (bool) **[R][W]**, `create_date`. Or reuse native `mail.activity`.

---

## Cross-cutting requirements

1. **API user + access rights.** Create a dedicated user (e.g. `tablet@amarna.club`)
   and grant **read/write** on every model above. Without ACLs, JSON-RPC returns
   "Access Denied".
2. **Seed the reference data.** Activities (6), equipment, inventory items, at least a
   few reservations/horses so screens aren't empty. Subscriptions/plans/types too.
3. **Datetime, not date, for reservations & readings** — the app filters "today" by a
   datetime range.
4. **Stable `code` on `amarna.activity`** — the whole app keys activities by
   `pool/horses/paintball/shooting/gym/padel`. Everything links back to this.

---

## App-side work (my side, once models exist)

Wiring each new model is the same small pattern already used for subscriptions —
a model class, a JSON-RPC service, a provider — then swap the screen from local/demo
data to the provider. Order I'd tackle it:

1. `amarna.activity` (read) → replaces the seeded activity list; unlocks everything else.
2. `amarna.reservation` (read + check-in write) → replaces demo reservations.
3. `maintenance.equipment` (read) → replaces seeded assets + gym/weapons/courts.
4. `amarna.stock.item` (read + write) → replaces seeded inventory.
5. `maintenance.request` read-back → true two-way ticket sync.
6. `amarna.horse` + `amarna.pool.reading` → replace the last hardcoded modules.

After that, the app holds **no local business data** — Odoo is the sole backend, and
the Isar cache is used only for offline resilience (currently disabled).
