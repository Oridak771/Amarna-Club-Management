# Amarna Club — Tablette de gestion opérationnelle

Application Flutter pour le personnel du club (accueil, moniteurs, responsables).
Elle travaille en ligne avec le serveur Odoo `amarna` : chaque salarié se connecte
avec son propre compte Odoo.

Le backend (modèles et règles métier) se trouve dans le dépôt Odoo :
`odoo17/custom_addons/` — modules `abonnement_amarna`, `amarna_club_*`.

---

## Fonctionnalités

- **Ma journée** : interventions prioritaires, réservations du jour avec check-in,
  alertes (stocks bas, activités en maintenance), occupation des activités.
- **Interventions** : incidents et maintenances, créés sur la tablette et
  synchronisés avec Odoo (`amarna.club.intervention`).
- **Réservations** : planning du jour lu dans Odoo, création, check-in
  (séances décomptées et occupation gérées par Odoo).
- **Activités** : piscine (relevés de qualité), écurie, stand de tir (armurerie),
  gymnase, padel, paintball — statuts et occupation synchronisés.
- **Stocks**, **abonnements** (lecture et mise à jour du solde).
- Thème clair / sombre.

---

## Configuration

La tablette ne contient **aucun secret**. Par défaut elle se connecte au serveur
du club (`http://10.20.10.49:8069`, base `hasnaoui_amarna`). Pour viser un autre
serveur, passez son adresse au moment de la compilation ou du lancement :

```bash
cp config/dart_define.example.json config/dart_define.local.json   # puis adapter
```

```json
{
  "AMARNA_ODOO_BASE_URL": "https://odoo.exemple.fr",
  "AMARNA_ODOO_DB": "amarna"
}
```

`config/dart_define.local.json` est ignoré par git. En production, l'adresse doit
être en HTTPS (la version release refuse le HTTP en clair).

---

## Lancer l'application

```bash
flutter pub get
flutter run -d <id_appareil> --dart-define-from-file=config/dart_define.local.json
```

Sur émulateur Android, l'adresse du poste hôte est `10.0.2.2`.
Les builds de debug utilisent le moteur de rendu Skia (plus stable sur émulateur).

Compiler un APK de production :

```bash
flutter build apk --release --dart-define-from-file=config/dart_define.prod.json
```

---

## Tests

```bash
# Analyse statique
flutter analyze

# Tests unitaires et tests du service Odoo (le second groupe demande un Odoo joignable)
flutter test test/ --dart-define-from-file=config/dart_define.local.json \
  --dart-define=AMARNA_TEST_LOGIN=<compte_staff> --dart-define=AMARNA_TEST_PASSWORD=<mot_de_passe>

# Parcours complets sur émulateur ou tablette (connexion, incident, check-in)
flutter test integration_test/staff_flow_test.dart -d <id_appareil> \
  --dart-define-from-file=config/dart_define.local.json \
  --dart-define=AMARNA_TEST_LOGIN=<compte_staff> --dart-define=AMARNA_TEST_PASSWORD=<mot_de_passe>
```

Le compte de test doit être un compte **staff** (pas administrateur) : les tests
vérifient ce qu'un salarié peut voir et faire. Les enregistrements créés par les
tests sont nommés `TEST …` pour être supprimés côté Odoo.

---

## Synchronisation avec Odoo

- Lecture au démarrage et après chaque action ; les modifications (occupation,
  statut, stock, intervention, relevé piscine, réservation) sont envoyées
  immédiatement.
- Les dates sont stockées en UTC dans Odoo et converties sur la tablette.
- Une intervention modifiée sur la tablette alors que l'envoi a échoué reste
  « en attente » et n'est jamais écrasée par une lecture Odoo.
- Un échec de synchronisation s'affiche dans un bandeau sur « Ma journée ».
- Le cache local (Isar) est purgé à la mise à jour de version (`DatabaseService`).

---

## Structure

```
lib/
├── main.dart                 démarrage (Isar, locale fr_FR, Riverpod)
├── config/app_environment.dart   adresse Odoo (--dart-define)
├── services/                 client JSON-RPC Odoo, sync (club, réservations,
│                             interventions), conversions de dates
├── providers/                état Riverpod (auth, tickets, check-in…)
├── models/                   modèles Isar et domaine
├── screens/ widgets/ ui/     écrans et composants
integration_test/             parcours de bout en bout
test/                         tests unitaires et tests du service Odoo
config/                       exemple de configuration (sans secret)
```

---

## Avant la mise en production

1. Mettre Odoo derrière HTTPS et renseigner l'adresse dans `config/dart_define.prod.json`.
2. Changer `applicationId` (`com.example.amarna_club`) et la signature de l'APK.
3. Faire tourner les mots de passe qui ont été embarqués dans des APK précédents
   (base PostgreSQL et compte administrateur Odoo) et supprimer ces APK.
4. Mettre à jour la base Odoo : `-u abonnement_amarna,amarna_club_interventions,amarna_club_inventory,amarna_club_ecurie,amarna_club_reservations`.
   La migration des tickets `maintenance.request` vers `amarna.club.intervention`
   est idempotente.
5. Créer un compte Odoo par salarié (groupe « Amarna Club / Utilisateur »).
