import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StoryUploadJob {
  final String id;
  final String type;
  final String? mediaPath;
  final String? text;
  final String? backgroundColor;
  final int durationSeconds;

  StoryUploadJob({
    required this.id,
    required this.type,
    required this.durationSeconds,
    this.mediaPath,
    this.text,
    this.backgroundColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'media_path': mediaPath,
        'text': text,
        'background_color': backgroundColor,
        'duration_seconds': durationSeconds,
      };

  factory StoryUploadJob.fromJson(Map<String, dynamic> json) {
    return StoryUploadJob(
      id: json['id'] ?? '',
      type: json['type'] ?? 'text',
      mediaPath: json['media_path'],
      text: json['text'],
      backgroundColor: json['background_color'],
      durationSeconds: json['duration_seconds'] ?? 5,
    );
  }
}

class StoryUploadQueue {
  static const String _queueKey = 'story_upload_queue';
  static const String _taskMapKey = 'story_upload_task_map';

  Future<String> enqueue(StoryUploadJob job) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_queueKey) ?? <String>[];
    final updated = [...existing, jsonEncode(job.toJson())];
    await prefs.setStringList(_queueKey, updated);
    return job.id;
  }

  Future<List<StoryUploadJob>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_queueKey) ?? <String>[];
    return rawList
        .map((value) => StoryUploadJob.fromJson(jsonDecode(value)))
        .toList();
  }

  Future<StoryUploadJob?> getById(String id) async {
    final jobs = await getAll();
    for (final job in jobs) {
      if (job.id == id) return job;
    }
    return null;
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
