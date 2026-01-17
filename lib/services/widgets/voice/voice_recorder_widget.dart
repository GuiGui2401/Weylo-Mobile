import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../voice_effects_service.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File file, VoiceEffect effect) onRecordingComplete;
  final VoiceEffect? selectedEffect;
  final bool showEffectSelector;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.selectedEffect,
    this.showEffectSelector = false,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  String? _recordPath;
  VoiceEffect _currentEffect = VoiceEffect.none;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentEffect = widget.selectedEffect ?? VoiceEffect.none;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      // Handle permission denied
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordPath =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordPath!,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });

        _pulseController.repeat(reverse: true);

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration = Duration(seconds: timer.tick);
          });
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      _pulseController.stop();
      _pulseController.reset();

      final path = await _recorder.stop();

      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        final file = File(path);
        // Pass both the file and the selected effect
        // Effect will be applied during playback using just_audio
        widget.onRecordingComplete(file, _currentEffect);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    await _recorder.stop();

    if (_recordPath != null) {
      final file = File(_recordPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Effect selector
        if (widget.showEffectSelector && !_isRecording)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: VoiceEffect.values.map((effect) {
                final isSelected = _currentEffect == effect;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentEffect = effect;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEffectIcon(effect),
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          VoiceEffectsService.getEffectName(effect),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 16),

        // Recording controls
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel button (only when recording)
              if (_isRecording)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _cancelRecording,
                  iconSize: 32,
                ),

              const SizedBox(width: 16),

              // Record button
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording
                                      ? Colors.red
                                      : AppColors.primary)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Duration display (only when recording)
              SizedBox(
                width: 48,
                child: _isRecording
                    ? Text(
                        _formatDuration(_recordDuration),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          ),

        if (!_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Appuyez pour enregistrer',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),

        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Effet: ${VoiceEffectsService.getEffectName(_currentEffect)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getEffectIcon(VoiceEffect effect) {
    switch (effect) {
      case VoiceEffect.none:
        return Icons.mic;
      case VoiceEffect.pitchUp:
        return Icons.arrow_upward;
      case VoiceEffect.pitchDown:
        return Icons.arrow_downward;
      case VoiceEffect.robot:
        return Icons.smart_toy;
      case VoiceEffect.chipmunk:
        return Icons.pets;
      case VoiceEffect.deep:
        return Icons.graphic_eq;
    }
  }
}
