import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ConfessionUploadJob {
  final String id;
  final String type;
  final String? content;
  final bool isAnonymous;
  final String? recipientUsername;
  final String? imagePath;
  final String? videoPath;

  ConfessionUploadJob({
    required this.id,
    required this.type,
    required this.isAnonymous,
    this.content,
    this.recipientUsername,
    this.imagePath,
    this.videoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'content': content,
        'is_anonymous': isAnonymous,
        'recipient_username': recipientUsername,
        'image_path': imagePath,
        'video_path': videoPath,
      };

  factory ConfessionUploadJob.fromJson(Map<String, dynamic> json) {
    return ConfessionUploadJob(
      id: json['id'] ?? '',
      type: json['type'] ?? 'public',
      content: json['content'],
      isAnonymous: json['is_anonymous'] ?? false,
      recipientUsername: json['recipient_username'],
      imagePath: json['image_path'],
      videoPath: json['video_path'],
    );
  }
}

class ConfessionUploadQueue {
  static const String _queueKey = 'confession_upload_queue';
  static const String _taskMapKey = 'confession_upload_task_map';

  Future<String> enqueue(ConfessionUploadJob job) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_queueKey) ?? <String>[];
    final updated = [...existing, jsonEncode(job.toJson())];
    await prefs.setStringList(_queueKey, updated);
    return job.id;
  }

  Future<List<ConfessionUploadJob>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_queueKey) ?? <String>[];
    return rawList
        .map((value) => ConfessionUploadJob.fromJson(jsonDecode(value)))
        .toList();
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_queueKey) ?? <String>[];
    final updated = rawList.where((value) {
      final data = jsonDecode(value) as Map<String, dynamic>;
      return data['id'] != id;
    }).toList();
    await prefs.setStringList(_queueKey, updated);
  }

  Future<void> mapTask(String taskId, String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_taskMapKey);
    final Map<String, dynamic> map = raw != null ? jsonDecode(raw) : {};
    map[taskId] = jobId;
    await prefs.setString(_taskMapKey, jsonEncode(map));
  }

  Future<String?> popJobIdForTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_taskMapKey);
    final Map<String, dynamic> map = raw != null ? jsonDecode(raw) : {};
    final jobId = map.remove(taskId) as String?;
    await prefs.setString(_taskMapKey, jsonEncode(map));
    return jobId;
  }
}
