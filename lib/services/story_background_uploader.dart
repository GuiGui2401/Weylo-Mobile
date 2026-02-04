import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import 'local_notification_service.dart';
import 'storage_service.dart';
import 'story_upload_queue.dart';

class StoryBackgroundUploader {
  static final FlutterUploader _uploader = FlutterUploader();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _uploader.result.listen(
      (result) async {
        debugPrint(
          '[StoryBackgroundUploader] Upload Result: taskId=${result.taskId}, status=${result.status}, statusCode=${result.statusCode}, response=${result.response}',
        );

        final taskId = result.taskId;
        final queue = StoryUploadQueue();
        final jobId = await queue.popJobIdForTask(taskId);

        if (result.status == UploadTaskStatus.complete) {
          if (jobId != null) {
            await queue.remove(jobId);
          }
          await LocalNotificationService.showStoryUploaded();
        } else if (result.status == UploadTaskStatus.failed) {
          debugPrint(
            '[StoryBackgroundUploader] Upload FAILED: taskId=${result.taskId}, statusCode=${result.statusCode}, response=${result.response}',
          );
          if (jobId != null) {
            await queue.remove(jobId);
          }
        } else if (result.status == UploadTaskStatus.running) {
          debugPrint('[StoryBackgroundUploader] Upload RUNNING: taskId=${result.taskId}');
        } else if (result.status == UploadTaskStatus.enqueued) {
          debugPrint('[StoryBackgroundUploader] Upload ENQUEUED: taskId=${result.taskId}');
        }
      },
      onError: (ex, stacktrace) {
        debugPrint('[StoryBackgroundUploader] Upload Stream ERROR: $ex');
        debugPrint(stacktrace.toString());
      },
    );
    _initialized = true;
  }

  static Future<void> enqueue(StoryUploadJob job) async {
    await initialize();
    final token = await StorageService().getToken();
    final url = '${ApiConstants.baseUrl}${ApiConstants.stories}';
    final task = MultipartFormDataUpload(
      url: url,
      method: UploadMethod.POST,
      files: [
        FileItem(
          path: job.mediaPath ?? '',
          field: 'media',
        ),
      ],
      data: _buildFormData(job),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      tag: job.id,
    );

    final taskId = await _uploader.enqueue(task);
    await StoryUploadQueue().mapTask(taskId, job.id);
  }

  static Map<String, String> _buildFormData(StoryUploadJob job) {
    final data = <String, String>{
      'type': job.type,
      'duration': job.durationSeconds.toString(),
    };
    if (job.text != null && job.text!.isNotEmpty) {
      data['content'] = job.text!;
    }
    if (job.backgroundColor != null && job.backgroundColor!.isNotEmpty) {
      data['background_color'] = job.backgroundColor!;
    }
    return data;
  }
}
