# Specification Document: Amarna Club Operations Management App

## Project Overview

**Amarna Club** is a mobile-first Operations Management Application designed for activity center employees and supervisors.

The application serves as a specialized operational interface connected to Odoo ERP and allows workers to manage activities, assets, maintenance, incidents, stock, reservations, inspections, and occupancy in real time.

### Main Objectives

* Simplify daily operations for field employees.
* Provide real-time operational visibility.
* Reduce paperwork and manual reporting.
* Improve maintenance tracking.
* Improve safety compliance.
* Synchronize all operational data with Odoo ERP.
* Support offline operation in areas with poor network coverage.

---

# 1. Architecture & Technology Stack

## High-Level Architecture

```text
Flutter Mobile App
        │
        ▼
API Gateway (FastAPI)
        │
        ▼
Odoo ERP
```

### Why API Gateway Instead of Direct Odoo Access

Benefits:

* Centralized authentication
* Better security
* Easier maintenance
* Request validation
* Activity logging
* Push notification management
* Future integration with external systems

---

## Mobile Frontend

### Framework

* Flutter (Latest Stable Version)

### State Management

* Riverpod (Recommended)

Alternative:

* BLoC

### Navigation

* GoRouter

### Local Storage (Offline Mode)

* Isar Database

Alternative:

* Hive

### Authentication

* JWT Authentication via API Gateway

### QR / Barcode Scanner

* mobile_scanner

### NFC Support

* nfc_manager

### Push Notifications

* Firebase Cloud Messaging (FCM)

### Crash Monitoring

* Firebase Crashlytics

---

## Backend Gateway

### Framework

* FastAPI (Python)

### Responsibilities

* Authentication
* Odoo communication
* Business rules
* Logging
* Notification triggers
* Offline synchronization management

---

## ERP System

### Odoo Modules

Required modules:

* Inventory
* Maintenance
* Human Resources
* Reservations / Bookings
* Events
* Documents

Optional modules:

* Fleet
* Project
* Quality
* Helpdesk

---

# 2. User Roles

## Lifeguard

Access:

* Pool Operations
* Pool Incidents
* Pool Inventory

---

## Stable Manager

Access:

* Horses
* Horse Equipment
* Horse Incidents

---

## Paintball Supervisor

Access:

* Paintball Operations
* Paintball Equipment
* Paintball Stock

---

## Shooting Range Supervisor

Access:

* Shooting Operations
* Weapon Management
* Ammunition Inventory

---

## Gym Supervisor

Access:

* Gym Operations
* Equipment Maintenance

---

## Operations Manager

Full Access

* All Activities
* Maintenance
* Inventory
* Reporting
* Dashboard

---

## Administrator

Full System Administration

---

# 3. Main Application Modules

## Dashboard

### Operational Overview

Display:

* Activity Status
* Current Occupancy
* Reservations
* Open Incidents
* Maintenance Requests
* Low Stock Alerts

Example:

```text
POOL              🟢 Open
HORSES            🟡 3 Unavailable
PAINTBALL         🟢 Open
SHOOTING RANGE    🔴 Maintenance
GYM               🟢 Open
```

---

## Activities Module

### Available Activities

* Pool
* Horses
* Paintball
* Shooting Range
* Gym

Each activity has:

* Status
* Occupancy
* Equipment
* Inventory
* Maintenance
* Incidents
* Staff Assignments

---

## Maintenance Module

Manage:

* Equipment maintenance
* Preventive maintenance
* Corrective maintenance

Integrated with Odoo Maintenance.

---

## Incident Module

Centralized incident reporting system.

Allows employees to report:

* Technical issues
* Safety issues
* Equipment failures
* Facility damage

Each incident includes:

* Title
* Description
* Priority
* Photos
* Voice Notes
* Assigned Technician
* Resolution Status

Priority Levels:

* Low
* Medium
* High
* Critical

Incident automatically creates:

* Odoo Maintenance Ticket

---

## Inventory Module

Track:

* Consumables
* Spare parts
* Safety equipment

One-click inventory deduction.

Examples:

* +1 chlorine container used
* +1 paintball box used
* +1 ammunition box used

---

## Reservations Module

View:

* Today's reservations
* Upcoming sessions
* Capacity utilization

Supports:

* Real-time availability

---

## Asset Management Module

Track all physical assets.

Every asset receives:

* QR Code
* NFC Tag (Optional)

Asset Profile:

* Asset ID
* Serial Number
* Purchase Date
* Current Status
* Last Maintenance
* Next Maintenance
* Photos

---

# 4. Activity Management

---

# 🏊 Pool Management

## Operational Information

* Pool Status
* Water Temperature
* Chlorine Level
* pH Level
* Turbidity
* Water Quality Score

## Capacity

* Current Swimmers
* Maximum Capacity
* Occupancy Percentage

## Staff

* Assigned Lifeguard
* Shift Information

## Inventory

* Chlorine
* pH Products
* First Aid Kits
* Rescue Equipment

## Equipment

* Pumps
* Filters
* Water Treatment Systems

## Maintenance

* Filter Cleaning
* Pump Maintenance

## Quick Actions

* Water Checked
* Cleaning Completed
* Add Chemicals
* Report Incident
* Open Pool
* Close Pool

---

# 🐎 Horse Management

## Horse Profile

* Name
* Breed
* Age
* Weight
* Health Status
* Vaccination Status

## Operational Data

* Availability
* Daily Riding Hours
* Fatigue Level
* Rest Requirement

## Assignment

* Assigned Trainer
* Assigned Stable

## Inventory

* Feed
* Supplements
* Ointments
* Horseshoes

## Equipment

* Saddles
* Helmets
* Reins

## Quick Actions

* Mark Available
* Mark Resting
* Report Injury
* Add Feeding Record

---

# 🎯 Paintball Management

## Field Information

* Field Status
* Safety Net Condition
* Obstacle Condition

## Capacity

* Current Players
* Maximum Players

## Equipment

* Marker Fleet
* Masks
* Air Tanks

## Inventory

* Paintballs
* CO2 Bottles
* Spare Parts

## Maintenance

* Marker Cleaning
* Marker Repair

## Quick Actions

* Start Session
* End Session
* Deduct Paintballs
* Report Damage

---

# 🔫 Shooting Range Management

## Range Information

* Operational Status
* Ventilation Status
* Safety Status

## Capacity

* Available Lanes
* Occupied Lanes

## Weapon Tracking

* Weapon Serial Number
* Weapon Status
* Cleaning Date
* Maintenance Date

## Inventory

* Ammunition
* Targets
* Ear Protection
* Eye Protection

## Maintenance

* Weapon Maintenance
* Ventilation Inspection

## Quick Actions

* Open Range
* Close Range
* Deduct Ammunition
* Report Weapon Issue

---

# 🏋️ Gym Management

## Facility Information

* Facility Status
* Cleaning Status
* Occupancy

## Equipment Tracking

* Machine Status
* Availability
* Maintenance Schedule

## Inventory

* Cleaning Supplies
* Spare Parts
* Towels

## Maintenance

* Machine Repairs
* Preventive Maintenance

## Quick Actions

* Report Machine Failure
* Complete Cleaning
* Open Gym
* Close Gym

---

# 5. Daily Operational Checklists

## Opening Checklist

Each activity must complete opening validation.

### Example: Pool

* Water inspected
* Chlorine checked
* pH checked
* Safety equipment checked
* Lifeguard present

Status:

* Open
* Blocked

---

### Example: Shooting Range

* Weapons inspected
* Ammunition counted
* Ventilation checked
* Safety equipment checked

Status:

* Open
* Blocked

---

## Closing Checklist

Examples:

* Facility cleaned
* Inventory counted
* Incidents reported
* Equipment secured

---

# 6. QR Code / NFC Workflow

Every major asset receives a QR code.

Examples:

* Horse Stall
* Weapon
* Gym Machine
* Paintball Marker
* Pool Pump
* Padel

Workflow:

1. Scan QR Code
2. Open Asset Profile
3. Update Status
4. Add Incident
5. Deduct Inventory
6. Create Maintenance Request

Target Time:

Less than 10 seconds.

---

# 7. Offline Mode

## Requirements

Application must continue operating when disconnected.

Supported Offline Actions:

* View assets
* Update status
* Create incidents
* Complete checklists

---

## Synchronization

When connection returns:

* Sync local changes
* Resolve conflicts
* Display sync report

---

## Booking Restrictions

If disconnected:

* Reservation changes become read-only

Warning banner:

```text
Data non synchronisée depuis X minutes
```

---

# 8. Notifications

Employees receive:

* New assignment
* Incident assigned
* Maintenance overdue
* Low inventory alerts

Managers receive:

* Critical incidents
* Facility closures
* Capacity alerts

---

# 9. Security

## Authentication

JWT Authentication

## Permissions

Role-based access control

## Odoo Security

Dedicated service accounts

Mobile app cannot access:

* Financial information
* Accounting data
* Payroll data
* Sensitive customer information

---

# 10. User Experience Requirements

## Language

Application UI must be entirely in French.

---

## Design Principles

* Modern UI
* Minimal clicks
* Large touch targets
* High contrast
* Glove-friendly controls

Preferred controls:

* Toggles
* Sliders
* Cards
* Quick actions

Avoid:

* Long forms
* Excessive typing

---



---

# Project Goal

Create a modern operational management platform that allows Amarna Club employees to manage activities, assets, inventory, incidents, maintenance, and occupancy from a single mobile application fully synchronized with Odoo ERP while remaining fast, intuitive, secure, and usable in the field.
