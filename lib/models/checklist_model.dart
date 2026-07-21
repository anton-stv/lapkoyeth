class ChecklistItemModel {
  final String title;
  final bool isDone;

  const ChecklistItemModel({required this.title, this.isDone = false});

  Map<String, dynamic> toMap() => {'title': title, 'is_done': isDone};

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) =>
      ChecklistItemModel(
        title: map['title'] as String? ?? '',
        isDone: map['is_done'] as bool? ?? false,
      );

  ChecklistItemModel copyWith({String? title, bool? isDone}) =>
      ChecklistItemModel(
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
      );
}

class ChecklistModel {
  final int? id;
  final int petId;
  final String petName;
  final String title;
  final String? description;
  final String scheduledDate;
  final String? deadlineDate;
  final List<int> repeatWeekdays;
  final String durationType;
  final String? endDate;
  final int? repeatCount;
  final bool isPinned;
  final bool isException;
  final List<String> excludedDates;
  final List<ChecklistItemModel> items;

  const ChecklistModel({
    this.id,
    required this.petId,
    required this.petName,
    required this.title,
    required this.scheduledDate,
    required this.items,
    this.description,
    this.deadlineDate,
    this.repeatWeekdays = const [],
    this.durationType = 'forever',
    this.endDate,
    this.repeatCount,
    this.isPinned = true,
    this.isException = false,
    this.excludedDates = const [],
  });

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int get doneCount => items.where((item) => item.isDone).length;
  int get totalCount => items.length;
  double get progress => totalCount == 0 ? 0 : doneCount / totalCount;
  int get remainingCount => totalCount > 3 ? totalCount - 3 : 0;
  List<ChecklistItemModel> get previewItems => items.take(3).toList();

  bool occursOn(DateTime date) {
    final dateOnly = dateKey(date);
    if (excludedDates.contains(dateOnly)) return false;
    if (scheduledDate == dateOnly) return true;
    if (repeatWeekdays.isEmpty) return false;

    final start = DateTime.tryParse(scheduledDate);
    if (start == null) return false;
    final current = DateTime(date.year, date.month, date.day);
    final first = DateTime(start.year, start.month, start.day);
    if (current.isBefore(first)) return false;

    if (durationType == 'until_date' && endDate != null) {
      final end = DateTime.tryParse(endDate!);
      if (end != null &&
          current.isAfter(DateTime(end.year, end.month, end.day))) {
        return false;
      }
    }

    if (durationType == 'repeat_count' && repeatCount != null) {
      var occurrences = 0;
      for (
        var cursor = first;
        !cursor.isAfter(current);
        cursor = cursor.add(const Duration(days: 1))
      ) {
        if (repeatWeekdays.contains(cursor.weekday) &&
            !excludedDates.contains(dateKey(cursor))) {
          occurrences++;
        }
      }
      if (occurrences > repeatCount!) return false;
    }

    return repeatWeekdays.contains(date.weekday);
  }

  ChecklistModel toggleItem(int index) {
    final nextItems = List<ChecklistItemModel>.of(items);
    final item = nextItems[index];
    nextItems[index] = item.copyWith(isDone: !item.isDone);
    return copyWith(items: nextItems);
  }

  ChecklistModel addItem(String title) {
    if (items.length >= 40) return this;
    return copyWith(
      items: [
        ...items,
        ChecklistItemModel(title: title),
      ],
    );
  }

  ChecklistModel removeItem(int index) {
    final nextItems = List<ChecklistItemModel>.of(items)..removeAt(index);
    return copyWith(items: nextItems);
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'pet_id': petId,
    'pet_name': petName,
    'title': title,
    'description': description,
    'scheduled_date': scheduledDate,
    'deadline_date': deadlineDate,
    'repeat_weekdays': repeatWeekdays,
    'duration_type': durationType,
    'end_date': endDate,
    'repeat_count': repeatCount,
    'is_pinned': isPinned,
    'is_exception': isException,
    'excluded_dates': excludedDates,
    'items': items.map((item) => item.toMap()).toList(),
  };

  factory ChecklistModel.fromMap(Map<String, dynamic> map) => ChecklistModel(
    id: map['id'] as int?,
    petId: map['pet_id'] as int,
    petName: map['pet_name'] as String? ?? '',
    title: map['title'] as String? ?? 'Чек-лист',
    description: map['description'] as String?,
    scheduledDate: map['scheduled_date'] as String? ?? dateKey(DateTime.now()),
    deadlineDate: map['deadline_date'] as String?,
    repeatWeekdays: (map['repeat_weekdays'] as List? ?? const [])
        .map((v) => (v as num).toInt())
        .toList(),
    durationType: map['duration_type'] as String? ?? 'forever',
    endDate: map['end_date'] as String?,
    repeatCount: (map['repeat_count'] as num?)?.toInt(),
    isPinned: map['is_pinned'] as bool? ?? true,
    isException: map['is_exception'] as bool? ?? false,
    excludedDates: (map['excluded_dates'] as List? ?? const [])
        .map((v) => v.toString())
        .toList(),
    items: (map['items'] as List? ?? const [])
        .map((v) => ChecklistItemModel.fromMap(Map<String, dynamic>.from(v)))
        .toList(),
  );

  ChecklistModel copyWith({
    int? id,
    int? petId,
    String? petName,
    String? title,
    String? description,
    String? scheduledDate,
    String? deadlineDate,
    List<int>? repeatWeekdays,
    String? durationType,
    String? endDate,
    int? repeatCount,
    bool? isPinned,
    bool? isException,
    List<String>? excludedDates,
    List<ChecklistItemModel>? items,
  }) => ChecklistModel(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    petName: petName ?? this.petName,
    title: title ?? this.title,
    description: description ?? this.description,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    deadlineDate: deadlineDate ?? this.deadlineDate,
    repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
    durationType: durationType ?? this.durationType,
    endDate: endDate ?? this.endDate,
    repeatCount: repeatCount ?? this.repeatCount,
    isPinned: isPinned ?? this.isPinned,
    isException: isException ?? this.isException,
    excludedDates: excludedDates ?? this.excludedDates,
    items: items ?? this.items,
  );

  ChecklistModel withNullableFields({
    String? description,
    String? deadlineDate,
    String? endDate,
    int? repeatCount,
  }) => ChecklistModel(
    id: id,
    petId: petId,
    petName: petName,
    title: title,
    description: description,
    scheduledDate: scheduledDate,
    deadlineDate: deadlineDate,
    repeatWeekdays: repeatWeekdays,
    durationType: durationType,
    endDate: endDate,
    repeatCount: repeatCount,
    isPinned: isPinned,
    isException: isException,
    excludedDates: excludedDates,
    items: items,
  );
}
