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
  });

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
      category: json['category'] ?? 'General',
      isCompleted: json['isCompleted'] ?? false,
      userId: json['userId'] ?? '',
      estimatedTime: json['estimatedTime'] ?? 30, // Default to 30 minutes
    );
  }
} 