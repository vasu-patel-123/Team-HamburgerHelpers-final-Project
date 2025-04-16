import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/task.dart';

class TaskService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _tasksPath = 'tasks';

  TaskService() {
    // Enable offline persistence only for non-web platforms
    if (!kIsWeb) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000); // 10MB cache
    }
  }

  // Validate task data before saving
  void _validateTask(Task task) {
    if (task.title.isEmpty) {
      throw Exception('Task title cannot be empty');
    }
    if (task.userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }
    if (task.dueDate.isBefore(DateTime.now())) {
      throw Exception('Due date cannot be in the past');
    }
  }

  // Create a new task
  Future<void> createTask(Task task) async {
    try {
      _validateTask(task);
      final taskData = task.toJson();
      // Convert DateTime to milliseconds timestamp
      taskData['dueDate'] = task.dueDate.millisecondsSinceEpoch;
      await _database.child(_tasksPath).child(task.id).set(taskData);
    } catch (e) {
      throw Exception('Failed to create task: ${e.toString()}');
    }
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    try {
      _validateTask(task);
      final taskData = task.toJson();
      // Convert DateTime to milliseconds timestamp
      taskData['dueDate'] = task.dueDate.millisecondsSinceEpoch;
      await _database.child(_tasksPath).child(task.id).update(taskData);
    } catch (e) {
      throw Exception('Failed to update task: ${e.toString()}');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _database.child(_tasksPath).child(taskId).remove();
    } catch (e) {
      throw Exception('Failed to delete task: ${e.toString()}');
    }
  }

  // Get all tasks for a specific user
  Stream<List<Task>> getUserTasks(String userId) {
    try {
      return _database
          .child(_tasksPath)
          .orderByChild('userId')
          .equalTo(userId)
          .onValue
          .map((event) {
        if (event.snapshot.value == null) return [];
        
        final Map<dynamic, dynamic> tasksMap = event.snapshot.value as Map<dynamic, dynamic>;
        return tasksMap.values.map((taskData) {
          // Convert the data to a proper Map<String, dynamic>
          final Map<String, dynamic> data = Map<String, dynamic>.from(taskData);
          // Convert timestamp back to DateTime
          if (data['dueDate'] is num) {
            data['dueDate'] = DateTime.fromMillisecondsSinceEpoch(data['dueDate'] as int);
          }
          return Task.fromJson(data);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch tasks: ${e.toString()}');
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _database
          .child(_tasksPath)
          .child(taskId)
          .update({'isCompleted': isCompleted});
    } catch (e) {
      throw Exception('Failed to toggle task completion: ${e.toString()}');
    }
  }

  // Get a single task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final snapshot = await _database.child(_tasksPath).child(taskId).get();
      if (snapshot.exists) {
        return Task.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch task: ${e.toString()}');
    }
  }
} 