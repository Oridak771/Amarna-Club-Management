import 'package:isar/isar.dart';

part 'checklist_item.g.dart';

enum ChecklistStatus {
  open,
  done,
  problem,
}

@collection
class ChecklistItem {
  Id isarId;

  @Index(unique: true, replace: true)
  final String id;
  final String title;
  final String category;
  final String activityId;
  final bool requiresPhoto;
  
  @enumerated
  final ChecklistStatus status;
  
  final String? comment;
  final String? photoPath;

  ChecklistItem({
    this.isarId = Isar.autoIncrement,
    required this.id,
    required this.title,
    required this.category,
    required this.activityId,
    required this.requiresPhoto,
    this.status = ChecklistStatus.open,
    this.comment,
    this.photoPath,
  });

  ChecklistItem copyWith({
    Id? isarId,
    String? id,
    String? title,
    String? category,
    String? activityId,
    bool? requiresPhoto,
    ChecklistStatus? status,
    String? comment,
    String? photoPath,
  }) {
    return ChecklistItem(
      isarId: isarId ?? this.isarId,
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      activityId: activityId ?? this.activityId,
      requiresPhoto: requiresPhoto ?? this.requiresPhoto,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
