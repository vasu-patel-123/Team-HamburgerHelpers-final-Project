class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority;
  final String category;
  final bool isCompleted;
  final String userId;
  final int estimatedTime; // in minutes
  final DateTime creationDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.category,
    this.isCompleted = false,
    required this.userId,
    required this.estimatedTime,
    DateTime? creationDate,
  }) : creationDate = creationDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'category': category,
      'isCompleted': isCompleted,
      'userId': userId,
      'estimatedTime': estimatedTime,
      'creationDate': creationDate.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    var dueDateValue = json['dueDate'];
    DateTime parsedDueDate;

    if (dueDateValue is String) {
      parsedDueDate = DateTime.parse(dueDateValue);
    } else if (dueDateValue is int) {
      parsedDueDate = DateTime.fromMillisecondsSinceEpoch(dueDateValue);
    } else {
      parsedDueDate = DateTime.now();
    }

    var creationDateValue = json['creationDate'];
    DateTime parsedCreationDate;

    if (creationDateValue is String) {
      try {
        parsedCreationDate = DateTime.parse(creationDateValue);
      } catch (e) {
        // If parsing fails, try to get the date from the task ID or due date
        // This is a fallback for existing tasks that might have invalid creation dates
        parsedCreationDate = parsedDueDate;
      }
    } else if (creationDateValue is int) {
      parsedCreationDate = DateTime.fromMillisecondsSinceEpoch(
        creationDateValue,
      );
    } else {
      // If no valid creation date is found, use the due date as a fallback
      parsedCreationDate = parsedDueDate;
    }

    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: parsedDueDate,
      priority: json['priority'] ?? 'Low',
      category: json['category'] ?? 'General',
      isCompleted: json['isCompleted'] ?? false,
      userId: json['userId'] ?? '',
      estimatedTime: json['estimatedTime'] ?? 30, // Default to 30 minutes
      creationDate: parsedCreationDate,
    );
  }
}
