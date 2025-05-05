import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class TaskService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _tasksPath = 'tasks';
  // ignore: unused_field
  final FirebaseAuth _auth;

  TaskService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    try {
      // Enable offline persistence only for non-web platforms
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
        FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
          10000000,
        ); // 10MB cache
      }
    } catch (e) {
      debugPrint('Error setting up Firebase persistence: $e');
    }
  }

  // Validate task data before saving
  void _validateTask(Task task, {bool isCompletionUpdate = false}) {
    if (task.title.isEmpty) {
      throw Exception('Task title cannot be empty');
    }
    if (task.userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }
  }

  // Create a new task
  Future<void> createTask(Task task) async {
    try {
      _validateTask(task);
      final taskData = task.toJson();
      await _database.child(_tasksPath).child(task.id).set(taskData);
    } catch (e) {
      throw Exception('Failed to create task: ${e.toString()}');
    }
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    try {
      // Check if we're only updating the completion status
      final existingTask = await getTaskById(task.id);
      final isCompletionUpdate =
          existingTask != null &&
          existingTask.title == task.title &&
          existingTask.description == task.description &&
          existingTask.dueDate == task.dueDate &&
          existingTask.priority == task.priority &&
          existingTask.isCompleted != task.isCompleted;

      _validateTask(task, isCompletionUpdate: isCompletionUpdate);
      final taskData = task.toJson();
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

            final Map<dynamic, dynamic> tasksMap =
                event.snapshot.value as Map<dynamic, dynamic>;
            return tasksMap.values.map((taskData) {
              // Convert the data to a proper Map<String, dynamic>
              final Map<String, dynamic> data = Map<String, dynamic>.from(
                taskData,
              );
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
      await _database.child(_tasksPath).child(taskId).update({
        'isCompleted': isCompleted,
      });
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
