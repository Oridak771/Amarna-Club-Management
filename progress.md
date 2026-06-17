# Amarna Club — Suivi de Progression du Projet

Ce document sert de feuille de route et de tableau de suivi pour le développement de l'application de gestion opérationnelle d'**Amarna Club**. Il sera mis à jour à chaque étape majeure du projet.

---

## 📊 État Global du Projet

| Module / Phase | Avancement | Statut |
| :--- | :---: | :---: |
| **Phase 1 : Configuration & Initialisation** | 100% | ✅ Terminé |
| **Phase 2 : Système de Design & Thème** | 100% | ✅ Terminé |
| **Phase 3 : Bibliothèque de Composants** | 100% | ✅ Terminé |
| **Phase 4 : Écrans Communs & Navigation** | 100% | ✅ Terminé |
| **Phase 5 : Modules Spécifiques aux Activités** | 100% | ✅ Terminé |
| **Phase 6 : Moteur Hors-ligne & Base de Données (Isar)** | 100% | ✅ Terminé |
| **Phase 7 : API Gateway (FastAPI) & Odoo** | 0% | ⏳ En attente |
| **Phase 8 : Intégration, Notifications & Tests** | 0% | ⏳ En attente |

**Progression Globale :** `█████████████████░░░` **85%**

---

## 🗺️ Phases de Développement

### ✅ Phase 1 : Configuration de l'Environnement & Initialisation
- [x] Structurer et approuver le plan d'implémentation (`implementation_plan.md`)
- [x] Initialiser le projet Flutter (Squelette Mobile + Tablette responsive)
- [x] Configurer la configuration de base (`pubspec.yaml`, `.gitignore`, `analysis_options.yaml`, `docker-compose.yml`)
- [x] Configurer les dépendances initiales (`riverpod`, `go_router`, `isar`, etc.)
- [x] Mettre en place la structure de dossiers standard (Clean Architecture / Feature-first)

### ✅ Phase 2 : Système de Design & Tokens (Dart)
- [x] Créer la palette de couleurs sombres et vibrantes (Pool, Horses, Gym, etc. dans `app_theme.dart`)
- [x] Configurer les polices de caractères (`Inter` via Google Fonts)
- [x] Définir les tokens d'espacement, bordures, ombres et contraintes de tailles tactiles (min 48x48px)
- [x] Implémenter le thème global `ThemeData` (Dark mode natif obligatoire)

### ✅ Phase 3 : Bibliothèque de Composants Génériques (UI)
- [x] **StatusBadge** (Ouvert, Fermé, Attention, Maintenance dans `status_badge.dart`)
- [x] **KPITile** (Tuile KPI du Dashboard dans `kpi_tile.dart`)
- [x] **ActivityTile** (Tuile carrée pour la grille des activités dans `activity_tile.dart`)
- [x] **QuickActionButton** (Bouton d'action rapide coloré et tactile dans `quick_action_button.dart`)
- [x] **FilterChip** (Chips de filtrage pour les listes dans `app_filter_chip.dart`)
- [x] **InventoryStepper** (Contrôle – / Qty / + pour les consommables dans `inventory_stepper.dart`)
- [x] **PriorityIndicator** (Bordure de couleur selon la priorité + pulsation sur Critique dans `priority_indicator.dart`)
- [x] **GaugeCard** (Jauge circulaire de qualité / niveau dans `gauge_card.dart`)
- [x] **SwipeCard** (Carte de checklist glissable gauche/droite dans `swipe_card.dart`)
- [x] **TimelineItem** (Événement chronologique pour le profil d'équipement dans `timeline_item.dart`)
- [x] **OfflineBanner** (Bandeau de synchronisation et de perte de connexion dans `offline_banner.dart`)

### ✅ Phase 4 : Écrans Communs & Navigation de Base
- [x] **Navigation** : Configurer GoRouter avec le Bottom Tab Bar (5 onglets)
- [x] **S02** : Login Screen (Interface de connexion stylisée)
- [x] **S04** : Accueil (Dashboard complet avec KPI Grid et statut des activités)
- [x] **S05** : Activities Grid (Grille responsive des activités)
- [x] **S06** : Fiche détaillée d'activité (avec 5 sous-onglets fonctionnels : Vue d'ensemble, Inventaire, Équipement, Maintenance, Incidents)
- [x] **S09** : Maintenance List (Liste filtrée avec alertes de dépassement)
- [x] **S10** : Fiche détaillée de maintenance (Suivi d'intervention complet)
- [x] **S10b** : Create Maintenance Task Screen (Formulaire de planification d'interventions)
- [x] **S11** : Incidents List (Liste filtrée avec signalement rapide)
- [x] **S12a** : Quick Incident Report Form (Grille de priorité tactile 2x2 et attachement de photo)
- [x] **S13** : Incident Detail Screen (Suivi et résolution d'incidents)
- [x] **S14** : Plus Menu Grid (Menu de navigation secondaire)
- [x] **S01** : Splash Screen (Logo + détection biométrique automatique)
- [x] **S03** : Onboarding Carousel (Carrousel d'intégration en 3 slides)
- [x] **S12b** : Detailed Incident Report Form (intégré de manière extensible au formulaire S12a)

### ✅ Phase 5 : Écrans & Flux Spécifiques aux 6 Activités
- [x] **🏊 Piscine (S07)** : Gauges de qualité de l'eau (Température, Chlore, pH, Turbidité)
- [x] **🐎 Chevaux (S08a/b)** : Grille des chevaux et fiches de profil (Heures de monte, alimentation, repos)
- [x] **🔫 Tir (S08c)** : Liste stricte des armes avec scannage de code-barres/QR obligatoire pour nettoyage
- [x] **🎯 Paintball (S08d)** : Statut du terrain, contrôle de session et suivi des lanceurs
- [x] **🏋️ Gym (S08e)** : Liste des machines, rapports de panne et statut de nettoyage
- [x] **🏸 Padel (S08f)** : Disponibilité des terrains, réservations journalières et suivi du matériel

### 🛠️ Phase 6 : Persistance & Moteur Hors-ligne (Isar DB)
- [x] Définir les modèles de données de base en Dart (`Activity`, `Incident`, `MaintenanceTask`, `Asset`, `InventoryItem`)
- [x] Configurer la gestion d'état de synchronisation réactive et la simulation de réseau (`syncProvider`)
- [x] Définir les modèles de données locaux (Isar Schemas) : Assets, Incidents, Maintenance, Stock, Checklists
- [x] Implémenter le Repository local et les services de cache
- [x] Mettre en place le bandeau d'état de connexion (`OfflineBanner`)
- [x] Implémenter le mécanisme de file d'attente de synchronisation locale (Sync Queue)
- [x] Créer l'écran de statut de synchronisation manuelle (**S17**)

### ⏳ Phase 7 : API Gateway (FastAPI) & Intégration Odoo
- [ ] Configurer le projet FastAPI (Python)
- [ ] Implémenter l'authentification JWT sécurisée
- [ ] Développer les endpoints pour les modules :
  - Odoo Inventory (Ajustements de stocks)
  - Odoo Maintenance (Création et mise à jour de tickets)
  - Odoo HR / Assignations
  - Odoo Bookings / Réservations
- [ ] Gérer les conflits de synchronisation hors-ligne au niveau de la passerelle

### ⏳ Phase 8 : Notifications, Validation & Polissage
- [ ] Intégrer Firebase Cloud Messaging (FCM) pour les notifications push
- [ ] Configurer Firebase Crashlytics pour le suivi des erreurs
- [ ] Tester les transitions et animations (Shared elements, glissements de cartes checklist)
- [ ] Valider l'adaptabilité sur tablette (Grilles adaptatives, colonnes élargies)
- [ ] Effectuer des tests de validation manuels en français

---

## 📋 Inventaire détaillé des Écrans (Suivi de Statut)

Voici la liste des **42 écrans** spécifiés pour l'application avec leur état d'avancement.

| Réf | Écran | Module | Priorité | Statut |
| :--- | :--- | :--- | :---: | :---: |
| **S01** | Splash Screen | Connexion / Démarrage | Haute | ✅ Terminé |
| **S02** | Login Screen | Connexion | Critique | ✅ Terminé |
| **S03** | Onboarding Carousel (3 slides) | Démarrage | Moyenne | ✅ Terminé |
| **S04** | Dashboard (Accueil) | Dashboard | Critique | ✅ Terminé |
| **S05** | Activities Grid | Activités (Liste) | Haute | ✅ Terminé |
| **S06** | Activity Detail (Base) | Activités (Détail) | Critique | ✅ Terminé |
| **S06a**| Sub-tab : Vue d'ensemble | Activités (Détail) | Haute | ✅ Terminé |
| **S06b**| Sub-tab : Inventaire | Activités (Détail) | Haute | ✅ Terminé |
| **S06c**| Sub-tab : Équipement | Activités (Détail) | Moyenne | ✅ Terminé |
| **S06d**| Sub-tab : Maintenance | Activités (Détail) | Moyenne | ✅ Terminé |
| **S06e**| Sub-tab : Incidents | Activités (Détail) | Moyenne | ✅ Terminé |
| **S07** | Pool Water Quality Gauges | 🏊 Piscine | Haute | ✅ Terminé |
| **S08a**| Horse Card Grid | 🐎 Chevaux | Haute | ✅ Terminé |
| **S08b**| Horse Profile | 🐎 Chevaux | Haute | ✅ Terminé |
| **S08c**| Weapon Strict List & Scan | 🔫 Tir | Haute | ✅ Terminé |
| **S08d**| Paintball Field Control | 🎯 Paintball | Moyenne | ✅ Terminé |
| **S08e**| Gym Equipment List | 🏋️ Gym | Moyenne | ✅ Terminé |
| **S08f**| Padel Courts Status | 🏸 Padel | Moyenne | ✅ Terminé |
| **S09** | Maintenance List | 🔧 Maintenance | Critique | ✅ Terminé |
| **S10** | Maintenance Detail | 🔧 Maintenance | Haute | ✅ Terminé |
| **S10b**| Create Maintenance Task | 🔧 Maintenance | Haute | ✅ Terminé |
| **S11** | Incidents List | ⚠️ Incidents | Critique | ✅ Terminé |
| **S12a**| Quick Incident Report Form | ⚠️ Incidents | Critique | ✅ Terminé |
| **S12b**| Detailed Incident Report Form | ⚠️ Incidents | Moyenne | ✅ Terminé |
| **S13** | Incident Detail | ⚠️ Incidents | Haute | ✅ Terminé |
| **S14** | Plus Menu Grid | ••• Plus | Haute | ✅ Terminé |
| **S15** | Global Inventory Deduct | ••• Plus | Haute | ⏳ En attente |
| **S15b**| Reports Dashboard (Manager) | ••• Plus | Moyenne | ⏳ En attente |
| **S16** | Reservations Timeline | ••• Plus | Haute | ⏳ En attente |
| **S17** | Sync Dashboard (Offline) | ••• Plus | Critique | ✅ Terminé |
| **S18** | Help & FAQs | ••• Plus | Basse | ⏳ En attente |
| **S19** | User Profile & Settings | ••• Plus | Moyenne | ⏳ En attente |
| **S20** | Checklist - Swipeable Stack | 📋 Checklists | Critique | ⏳ En attente |
| **S21** | Checklist Summary & Validation | 📋 Checklists | Haute | ⏳ En attente |
| **S22** | QR / NFC Scanner Screen | 📷 QR Scan | Critique | ⏳ En attente |
| **S23** | Asset Profile | 📷 QR Scan | Haute | ⏳ En attente |
| **S24** | Notification Center | 🔔 Notifications | Moyenne | ⏳ En attente |
| **S25** | Success Overlay (Checkmark) | Overlays / Modals | Haute | ⏳ En attente |
| **S26** | Error Overlay (Cross + Retry) | Overlays / Modals | Haute | ⏳ En attente |
| **S27** | Offline State Top Banner | Overlays / Modals | Critique | ✅ Terminé |
| **S28** | Action Confirmation Dialog | Overlays / Modals | Moyenne | ⏳ En attente |

---

## 🪵 Journal des Mises à Jour

### [14/06/2026]
- Validation finale du plan d'implémentation (`implementation_plan.md`) avec 42 écrans cibles.
- Création du fichier de suivi de progression (`progress.md`).
- Initialisation de la structure du projet Flutter : création de `pubspec.yaml`, `.gitignore`, `analysis_options.yaml`, `lib/main.dart` et `lib/routes.dart`.
- Configuration de l'environnement conteneurisé avec la création de `docker-compose.yml` pour le support d'exécution Flutter en Docker (version 3.22.1 / Dart 3.x).
- Configuration complète du **système de design et du thème sombre** (`lib/theme/app_theme.dart`) avec les jetons de couleurs personnalisés pour chaque activité.
- Implémentement des 5 modèles de données principaux (`Activity`, `Incident`, `MaintenanceTask`, `Asset`, `InventoryItem`).
- Création des fournisseurs d'état réactifs sous **Riverpod** avec les données d'initialisation simulées (`activitiesProvider`, `incidentsProvider`, `maintenanceProvider`, `inventoryProvider`, `syncProvider`).
- Configuration de l'architecture de navigation via **GoRouter** avec la persistance de l'état des onglets (`StatefulShellRoute`).
- **Création de la bibliothèque de composants UI génériques (100% validée par analyse statique)** :
  - `StatusBadge` (Pillule de statut d'activité ou d'asset)
  - `KPITile` (Tuiles de métriques clés pour la page d'accueil)
  - `ActivityTile` (Tuiles de sélection d'activités avec jauges d'occupation)
  - `QuickActionButton` (Boutons d'action rapide tactiles, min 56px)
  - `InventoryStepper` (Stepper de stock avec alertes de seuil critique, min 48px)
  - `PriorityIndicator` (Indicateur visuel de priorité avec animation pulsée de lueur pour les états Critiques)
  - `OfflineBanner` (Bandeau d'état réseau et de suivi de file d'attente de synchronisation)
  - `GaugeCard` (Jauge circulaire personnalisée de mesure de qualité/limite d'eau)
  - `AppFilterChip` (Chips de filtrage d'état pour les listes d'incidents et de maintenance)
  - `SwipeCard` (Cartes de checklist glissables avec indicateurs de problème/succès)
  - `TimelineItem` (Nœuds d'historique chronologiques pour le profil d'asset)

### [14/06/2026 - Suite]
- Implémentation des 6 écrans principaux de la Phase 4 :
  - `LoginScreen` (S02) : Interface de connexion stylisée, formulaire validé et navigation.
  - `DashboardScreen` (S04) : Tableau de bord principal connecté aux providers Riverpod avec grille KPI récursive et liste de statut d'activité.
  - `ActivitiesGridScreen` (S05) : Grille d'activités réactive avec filtres d'affichage.
  - `MaintenanceListScreen` (S09) : Liste filtrée des ordres de maintenance avec alerte de dépassement de délai.
  - `IncidentsListScreen` (S11) : Liste filtrée des incidents avec bouton de signalement rapide et couleur de priorité.
  - `PlusMenuScreen` (S14) : Menu secondaire avec options d'administration, stock et FAQ.
- Intégration de tous les écrans dans le routeur GoRouter et retrait des stubs correspondants.
- Validation complète et sans avertissements par l'analyseur Flutter.

### [14/06/2026 - Suite 2]
- Implémentation de 5 écrans supplémentaires pour enrichir les flux opérationnels de la Phase 4 :
  - `ActivityDetailScreen` (S06) : Fiche détaillée d'activité immersive avec en-tête dégradé, bandeau de statut, barre d'actions rapides contextuelles (Piscine, Chevaux, Tir, Padel, Paintball, Gym) et 5 sous-onglets fonctionnels :
    - *Vue d'ensemble* : Occupation en temps réel, personnel en service et réservations.
    - *Inventaire* : Ajustement interactif des consommables (avec stepper et alertes stock bas).
    - *Équipement* : Cartes de statut des équipements (mock local par activité).
    - *Maintenance* & *Incidents* : Listes filtrées dynamiques réutilisant les indicateurs de priorité.
  - `CreateMaintenanceScreen` (S10b) : Formulaire complet de planification avec sélecteur de technicien, priorité et simulation de scannage QR.
  - `MaintenanceDetailScreen` (S10) : Détails et actions d'intervention (Prise en charge / Clôture).
  - `QuickIncidentReportScreen` (S12a) : Formulaire rapide de signalement avec grille de priorité tactile 2x2 et attachement de photo.
  - `IncidentDetailScreen` (S13) : Détails de l'incident avec historique et actions de résolution.
- Suppression de tous les stubs correspondants dans `stub_screens.dart` et mise à jour de la configuration de routage.
- Validation finale complète et propre par l'analyseur statique de Flutter.
