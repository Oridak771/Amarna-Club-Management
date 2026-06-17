import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/asset.dart';
import '../models/incident.dart';
import '../models/inventory_item.dart';
import '../models/maintenance_task.dart';
import '../models/checklist_item.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar database has not been initialized');
});

class DatabaseService {
  static Future<Isar> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        ActivitySchema,
        AssetSchema,
        IncidentSchema,
        InventoryItemSchema,
        MaintenanceTaskSchema,
        ChecklistItemSchema,
      ],
      directory: dir.path,
    );

    // Seed data if empty
    final activityCount = await isar.activitys.count();
    if (activityCount == 0) {
      await isar.writeTxn(() async {
        await _seedInitialData(isar);
      });
    } else {
      // Ensure 'padel' activity and its assets/inventory exist if missing
      final padelExists = await isar.activitys.filter().idEqualTo('padel').findFirst() != null;
      if (!padelExists) {
        await isar.writeTxn(() async {
          await isar.activitys.put(
            Activity(
              id: 'padel',
              name: 'Terrains de Padel',
              iconKey: 'padel',
              status: ActivityStatus.open,
              currentOccupancy: 8,
              maxCapacity: 16,
              assignedStaff: 'Antoine (Coordinateur Padel)',
            ),
          );
          
          // Seed Padel Asset
          await isar.assets.put(
            Asset(
              id: 'asset-padel-court-1',
              serialNumber: 'SN-PADEL-CT-01',
              name: 'Filet Court de Padel 1',
              category: 'Infrastructures Terrain',
              activityId: 'padel',
              status: AssetStatus.available,
              lastMaintenance: DateTime.now().subtract(const Duration(days: 10)),
            ),
          );

          // Seed Padel Inventory
          await isar.inventoryItems.put(
            InventoryItem(
              id: 'inv-padel-01',
              name: 'Balles de Padel (Tube de 3)',
              activityId: 'padel',
              activityName: 'Terrains de Padel',
              currentStock: 30,
              lowThreshold: 10,
              unitName: 'tubes',
            ),
          );

          // Seed Padel Maintenance Task
          await isar.maintenanceTasks.put(
            MaintenanceTask(
              id: 'maint-003',
              title: 'Remplacement filet court 3',
              description: 'Le filet de padel présente des déchirures importantes au milieu.',
              assetId: 'asset-padel-net-03',
              assetName: 'Filet Padel Court 3',
              activityId: 'padel',
              type: MaintenanceType.corrective,
              priority: IncidentPriority.low,
              status: MaintenanceStatus.todo,
              dateDue: DateTime.now().add(const Duration(days: 4)),
              assignedTechnician: 'Mourad (Technicien)',
            ),
          );
        });
      }
    }

    return isar;
  }

  static Future<void> _seedInitialData(Isar isar) async {
    // 1. Seed Activities
    final activities = [
      Activity(
        id: 'pool',
        name: 'Piscine',
        iconKey: 'pool',
        status: ActivityStatus.open,
        currentOccupancy: 45,
        maxCapacity: 60,
        assignedStaff: 'Jean (Maitre-Nageur)',
      ),
      Activity(
        id: 'horses',
        name: 'Équitation',
        iconKey: 'horses',
        status: ActivityStatus.warning,
        currentOccupancy: 12,
        maxCapacity: 20,
        assignedStaff: 'Marie (Responsable Écurie)',
      ),
      Activity(
        id: 'paintball',
        name: 'Paintball',
        iconKey: 'paintball',
        status: ActivityStatus.open,
        currentOccupancy: 8,
        maxCapacity: 30,
        assignedStaff: 'Thomas (Superviseur Field)',
      ),
      Activity(
        id: 'shooting',
        name: 'Stand de Tir',
        iconKey: 'shooting',
        status: ActivityStatus.maintenance,
        currentOccupancy: 0,
        maxCapacity: 12,
        assignedStaff: 'Lucas (Superviseur Armurerie)',
      ),
      Activity(
        id: 'gym',
        name: 'Salle de Gym',
        iconKey: 'gym',
        status: ActivityStatus.open,
        currentOccupancy: 18,
        maxCapacity: 40,
        assignedStaff: 'Sophie (Coach Gym)',
      ),
      Activity(
        id: 'padel',
        name: 'Terrains de Padel',
        iconKey: 'padel',
        status: ActivityStatus.open,
        currentOccupancy: 8,
        maxCapacity: 16,
        assignedStaff: 'Antoine (Coordinateur Padel)',
      ),
    ];
    await isar.activitys.putAll(activities);

    // 2. Seed Assets
    final now = DateTime.now();
    final assets = [
      Asset(
        id: 'asset-pool-filter-01',
        serialNumber: 'SN-POOL-FLTR-01',
        name: 'Filtre Principal A',
        category: 'Équipement Piscine',
        activityId: 'pool',
        status: AssetStatus.available,
        lastMaintenance: now.subtract(const Duration(days: 30)),
        nextMaintenance: now.add(const Duration(days: 60)),
        technicalSpecs: {'Débit': '50 m3/h', 'Pression': '1.5 bar', 'Média': 'Sable de silice'},
      ),
      Asset(
        id: 'asset-pool-pump-02',
        serialNumber: 'SN-POOL-PUMP-02',
        name: 'Pompe de Filtration 2',
        category: 'Équipement Piscine',
        activityId: 'pool',
        status: AssetStatus.maintenance,
        lastMaintenance: now.subtract(const Duration(days: 90)),
        nextMaintenance: now.add(const Duration(days: 10)),
        technicalSpecs: {'Puissance': '2.2 kW', 'Tension': '400V Triphasé'},
      ),
      Asset(
        id: 'asset-pool-robot',
        serialNumber: 'SN-POOL-ROBT-99',
        name: 'Robot Nettoyeur Dolphin',
        category: 'Équipement Piscine',
        activityId: 'pool',
        status: AssetStatus.available,
        lastMaintenance: now.subtract(const Duration(days: 15)),
        nextMaintenance: now.add(const Duration(days: 45)),
        technicalSpecs: {'Cycles': '1.5 / 2.5 / 3.5 h', 'Longueur câble': '18 m'},
      ),
      Asset(
        id: 'asset-horse-saddle-1',
        serialNumber: 'SN-SADDLE-01',
        name: 'Selle Cuir Tornade',
        category: 'Équipement Équitation',
        activityId: 'horses',
        status: AssetStatus.broken,
        lastMaintenance: now.subtract(const Duration(days: 120)),
        technicalSpecs: {'Taille': '17.5 pouces', 'Matière': 'Cuir de veau'},
      ),
      Asset(
        id: 'asset-horse-box-4',
        serialNumber: 'SN-BOX-04',
        name: 'Écurie Box 4',
        category: 'Infrastructures Écurie',
        activityId: 'horses',
        status: AssetStatus.available,
        lastMaintenance: now.subtract(const Duration(days: 180)),
        technicalSpecs: {'Dimensions': '4m x 4m', 'Matériau': 'Chêne et acier'},
      ),
      Asset(
        id: 'asset-shoot-pistol-9mm',
        serialNumber: 'SN-PISTOL-9MM-102',
        name: 'Pistolet 9mm Glock 17',
        category: 'Arme de Poing',
        activityId: 'shooting',
        status: AssetStatus.available,
        lastMaintenance: now.subtract(const Duration(days: 5)),
        nextMaintenance: now.add(const Duration(days: 25)),
        technicalSpecs: {'Calibre': '9x19mm', 'Capacité': '17 coups'},
      ),
      Asset(
        id: 'asset-shoot-vent-02',
        serialNumber: 'SN-VENT-SH-02',
        name: 'Extracteur Air Standard',
        category: 'Infrastructures Stand',
        activityId: 'shooting',
        status: AssetStatus.maintenance,
        lastMaintenance: now.subtract(const Duration(days: 150)),
        technicalSpecs: {'Débit': '12000 m3/h', 'Puissance': '4 kW'},
      ),
      Asset(
        id: 'asset-gym-treadmill-1',
        serialNumber: 'SN-GYM-TM-01',
        name: 'Tapis de course Matrix 1',
        category: 'Équipement Cardio',
        activityId: 'gym',
        status: AssetStatus.available,
        lastMaintenance: now.subtract(const Duration(days: 20)),
        nextMaintenance: now.add(const Duration(days: 70)),
      ),
      Asset(
        id: 'asset-padel-court-1',
        serialNumber: 'SN-PADEL-CT-01',
        name: 'Filet Court de Padel 1',
        category: 'Infrastructures Terrain',
        activityId: 'padel',
        status: AssetStatus.available,
        lastMaintenance: now.subtract(const Duration(days: 10)),
      ),
    ];
    await isar.assets.putAll(assets);

    // 3. Seed Incidents
    final incidents = [
      Incident(
        id: 'inc-001',
        title: 'Fuite filtre pompe 2',
        description: 'Une fuite mineure a été détectée sur le raccord d\'aspiration de la pompe de filtration 2.',
        activityId: 'pool',
        activityName: 'Piscine',
        priority: IncidentPriority.medium,
        status: IncidentStatus.inProgress,
        dateCreated: now.subtract(const Duration(hours: 4)),
        assignedTechnician: 'Karim (Technicien)',
      ),
      Incident(
        id: 'inc-002',
        title: 'Sangle selle déchirée',
        description: 'La sangle de la selle de "Tornado" est fissurée et présente un risque de rupture.',
        activityId: 'horses',
        activityName: 'Équitation',
        priority: IncidentPriority.high,
        status: IncidentStatus.open,
        dateCreated: now.subtract(const Duration(hours: 1)),
        assignedTechnician: 'Mourad (Technicien)',
      ),
      Incident(
        id: 'inc-003',
        title: 'Ventilation stand de tir HS',
        description: 'L\'extracteur d\'air principal ne démarre plus. Forte concentration de gaz. Fermeture obligatoire.',
        activityId: 'shooting',
        activityName: 'Stand de Tir',
        priority: IncidentPriority.critical,
        status: IncidentStatus.open,
        dateCreated: now.subtract(const Duration(minutes: 30)),
        assignedTechnician: 'Sami (Électricien)',
      ),
    ];
    await isar.incidents.putAll(incidents);

    // 4. Seed Inventory Items
    final inventory = [
      InventoryItem(
        id: 'inv-pool-01',
        name: 'Chlore Granulé',
        activityId: 'pool',
        activityName: 'Piscine',
        currentStock: 12,
        lowThreshold: 5,
        unitName: 'seaux',
      ),
      InventoryItem(
        id: 'inv-pool-02',
        name: 'Régulateur pH Moins',
        activityId: 'pool',
        activityName: 'Piscine',
        currentStock: 3,
        lowThreshold: 4,
        unitName: 'bidons',
      ),
      InventoryItem(
        id: 'inv-horse-01',
        name: 'Granulés de Foin Alfalfa',
        activityId: 'horses',
        activityName: 'Équitation',
        currentStock: 45,
        lowThreshold: 10,
        unitName: 'sacs',
      ),
      InventoryItem(
        id: 'inv-horse-02',
        name: 'Fers à Cheval de Rechange',
        activityId: 'horses',
        activityName: 'Équitation',
        currentStock: 8,
        lowThreshold: 10,
        unitName: 'paires',
      ),
      InventoryItem(
        id: 'inv-pb-01',
        name: 'Billes de Paintball (Boîte 2000)',
        activityId: 'paintball',
        activityName: 'Paintball',
        currentStock: 15,
        lowThreshold: 6,
        unitName: 'boîtes',
      ),
      InventoryItem(
        id: 'inv-pb-02',
        name: 'Cartouches CO2 12g',
        activityId: 'paintball',
        activityName: 'Paintball',
        currentStock: 120,
        lowThreshold: 50,
        unitName: 'unités',
      ),
      InventoryItem(
        id: 'inv-shoot-01',
        name: 'Munitions 9x19mm Parabellum',
        activityId: 'shooting',
        activityName: 'Stand de Tir',
        currentStock: 2500,
        lowThreshold: 1000,
        unitName: 'balles',
      ),
      InventoryItem(
        id: 'inv-shoot-02',
        name: 'Cibles en carton standard',
        activityId: 'shooting',
        activityName: 'Stand de Tir',
        currentStock: 85,
        lowThreshold: 100,
        unitName: 'feuilles',
      ),
      InventoryItem(
        id: 'inv-padel-01',
        name: 'Balles de Padel (Tube de 3)',
        activityId: 'padel',
        activityName: 'Terrains de Padel',
        currentStock: 30,
        lowThreshold: 10,
        unitName: 'tubes',
      ),
    ];
    await isar.inventoryItems.putAll(inventory);

    // 5. Seed Maintenance Tasks
    final maintenance = [
      MaintenanceTask(
        id: 'maint-001',
        title: 'Nettoyage des filtres à sable',
        description: 'Effectuer le lavage à contre-courant du filtre principal A.',
        assetId: 'asset-pool-filter-01',
        assetName: 'Filtre Principal A',
        activityId: 'pool',
        type: MaintenanceType.preventive,
        priority: IncidentPriority.medium,
        status: MaintenanceStatus.todo,
        dateDue: now.add(const Duration(days: 1)),
        assignedTechnician: 'Karim (Technicien)',
      ),
      MaintenanceTask(
        id: 'maint-002',
        title: 'Changement extracteur ventilation stand de tir',
        description: 'Remplacer le moteur électrique grillé de la hotte d\'aspiration.',
        assetId: 'asset-shoot-vent-02',
        assetName: 'Extracteur Air Standard',
        activityId: 'shooting',
        type: MaintenanceType.corrective,
        priority: IncidentPriority.critical,
        status: MaintenanceStatus.inProgress,
        dateDue: now.subtract(const Duration(days: 1)),
        assignedTechnician: 'Sami (Électricien)',
      ),
      MaintenanceTask(
        id: 'maint-003',
        title: 'Remplacement filet court 3',
        description: 'Le filet de padel présente des déchirures importantes au milieu.',
        assetId: 'asset-padel-net-03',
        assetName: 'Filet Padel Court 3',
        activityId: 'padel',
        type: MaintenanceType.corrective,
        priority: IncidentPriority.low,
        status: MaintenanceStatus.todo,
        dateDue: now.add(const Duration(days: 4)),
        assignedTechnician: 'Mourad (Technicien)',
      ),
    ];
    await isar.maintenanceTasks.putAll(maintenance);

    // 6. Seed Checklist Items
    final checklists = [
      // Pool
      ChecklistItem(
        id: 'chk-pool-1',
        title: 'Inspection visuelle de l\'eau (clarté)',
        category: 'Qualité',
        activityId: 'pool',
        requiresPhoto: false,
      ),
      ChecklistItem(
        id: 'chk-pool-2',
        title: 'Contrôle du niveau de Chlore libre',
        category: 'Chimie',
        activityId: 'pool',
        requiresPhoto: true,
      ),
      ChecklistItem(
        id: 'chk-pool-3',
        title: 'Contrôle de la valeur pH de l\'eau',
        category: 'Chimie',
        activityId: 'pool',
        requiresPhoto: true,
      ),
      ChecklistItem(
        id: 'chk-pool-4',
        title: 'Vérification de la bouée de sauvetage',
        category: 'Sécurité',
        activityId: 'pool',
        requiresPhoto: false,
      ),
      ChecklistItem(
        id: 'chk-pool-5',
        title: 'Validation de présence du Maître-Nageur',
        category: 'Staff',
        activityId: 'pool',
        requiresPhoto: false,
      ),
      // Horses
      ChecklistItem(
        id: 'chk-horse-1',
        title: 'Nettoyage des boxes',
        category: 'Écurie',
        activityId: 'horses',
        requiresPhoto: false,
      ),
      ChecklistItem(
        id: 'chk-horse-2',
        title: 'Inspection visuelle des sabots',
        category: 'Santé',
        activityId: 'horses',
        requiresPhoto: true,
      ),
      ChecklistItem(
        id: 'chk-horse-3',
        title: 'Ration alimentaire distribuée',
        category: 'Alimentation',
        activityId: 'horses',
        requiresPhoto: false,
      ),
      // Shooting Range
      ChecklistItem(
        id: 'chk-shoot-1',
        title: 'Vérification de l\'armurerie fermée',
        category: 'Sécurité',
        activityId: 'shooting',
        requiresPhoto: true,
      ),
      ChecklistItem(
        id: 'chk-shoot-2',
        title: 'Test ventilation',
        category: 'Technique',
        activityId: 'shooting',
        requiresPhoto: false,
      ),
    ];
    await isar.checklistItems.putAll(checklists);
  }
}
