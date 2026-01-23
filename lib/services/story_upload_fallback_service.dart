import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'story_background_uploader.dart';
import 'story_service.dart';
import 'story_upload_queue.dart';

class StoryUploadFallbackService {
  final StoryService _storyService = StoryService();

  Future<void> resumePendingUploads() async {
    final queue = StoryUploadQueue();
    final jobs = await queue.getAll();

    if (jobs.isNotEmpty && !kIsWeb) {
      Fluttertoast.showToast(
        msg: 'Reprise des uploads en attente...',
        toastLength: Toast.LENGTH_SHORT,
      );
    }

    for (final job in jobs) {
      try {
        if (job.mediaPath == null || job.mediaPath!.isEmpty) {
          await _storyService.createStory(
            media: null,
            text: job.text,
            backgroundColor: job.backgroundColor,
            type: 'text',
            duration: job.durationSeconds,
          );
          await queue.remove(job.id);
          continue;
        }

        if (!kIsWeb) {
          await StoryBackgroundUploader.enqueue(job);
        }
      } catch (_) {
        // Leave in queue for next retry.
        continue;
      }
    }
  }
}
