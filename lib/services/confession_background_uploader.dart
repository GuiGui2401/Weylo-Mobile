import 'package:flutter/foundation.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import '../core/constants/api_constants.dart';
import 'confession_upload_queue.dart';
import 'local_notification_service.dart';
import 'storage_service.dart';

class ConfessionBackgroundUploader {
  static final FlutterUploader _uploader = FlutterUploader();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _uploader.result.listen((result) async {
      final taskId = result.taskId;
      final queue = ConfessionUploadQueue();
      final jobId = await queue.popJobIdForTask(taskId);
      if (jobId != null) {
        await queue.remove(jobId);
      }
      if (result.status == UploadTaskStatus.complete) {
        await LocalNotificationService.showPostUploaded();
      }
    });
    _initialized = true;
  }

  static Future<void> enqueue(ConfessionUploadJob job) async {
    await initialize();
    final token = await StorageService().getToken();
    final url = '${ApiConstants.baseUrl}${ApiConstants.confessions}';
    final files = <FileItem>[];
    if (job.imagePath != null && job.imagePath!.isNotEmpty) {
      files.add(FileItem(path: job.imagePath!, field: 'image'));
    }
    if (job.videoPath != null && job.videoPath!.isNotEmpty) {
      files.add(FileItem(path: job.videoPath!, field: 'video'));
    }
    final task = MultipartFormDataUpload(
      url: url,
      method: UploadMethod.POST,
      files: files,
      data: _buildFormData(job),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      tag: job.id,
    );

    try {
      final taskId = await _uploader.enqueue(task);
      await ConfessionUploadQueue().mapTask(taskId, job.id);
    } catch (e) {
      debugPrint('[ConfessionBackgroundUploader] enqueue failed: $e');
    }
  }

  static Map<String, String> _buildFormData(ConfessionUploadJob job) {
    final data = <String, String>{
      'type': job.type,
      'is_anonymous': job.isAnonymous ? '1' : '0',
    };
    if (job.content != null && job.content!.isNotEmpty) {
      data['content'] = job.content!;
    }
    if (job.recipientUsername != null && job.recipientUsername!.isNotEmpty) {
      data['recipient_username'] = job.recipientUsername!;
    }
    return data;
  }
}
