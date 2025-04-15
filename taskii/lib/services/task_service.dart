import 'package:firebase_database/firebase_database.dart';
import '../models/task.dart';

class TaskService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _tasksPath = 'tasks';

  // Create a new task
  Future<void> createTask(Task task) async {
    await _database.child(_tasksPath).child(task.id).set(task.toJson());
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    await _database.child(_tasksPath).child(task.id).update(task.toJson());
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _database.child(_tasksPath).child(taskId).remove();
  }

  // Get all tasks for a specific user
  Stream<List<Task>> getUserTasks(String userId) {
    return _database
        .child(_tasksPath)
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> tasksMap = event.snapshot.value as Map<dynamic, dynamic>;
      return tasksMap.values
          .map((taskData) => Task.fromJson(Map<String, dynamic>.from(taskData)))
          .toList();
    });
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _database
        .child(_tasksPath)
        .child(taskId)
        .update({'isCompleted': isCompleted});
  }
} 