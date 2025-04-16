class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority;
  final bool isCompleted;
  final String userId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted,
      'userId': userId,
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

    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: parsedDueDate,
      priority: json['priority'] ?? 'Low',
      isCompleted: json['isCompleted'] ?? false,
      userId: json['userId'] ?? '',
    );
  }
} 