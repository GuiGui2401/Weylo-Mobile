import 'dart:io';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../voice_effects_service.dart';
import '../voice/voice_recorder_widget.dart';

class StoryReplyInput extends StatefulWidget {
  final int storyId;
  final bool isExpanded;
  final VoidCallback onTap;
  final Function(
    String content, {
    bool isAnonymous,
    File? voiceFile,
    String? voiceEffect,
  })
  onSend;
  final VoidCallback onClose;

  const StoryReplyInput({
    super.key,
    required this.storyId,
    required this.isExpanded,
    required this.onTap,
    required this.onSend,
    required this.onClose,
  });

  @override
  State<StoryReplyInput> createState() => _StoryReplyInputState();
}

class _StoryReplyInputState extends State<StoryReplyInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnonymous = true;
  bool _isRecordingVoice = false;
  VoiceEffect _selectedEffect = VoiceEffect.none;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return _buildCollapsedInput();
    }

    return _buildExpandedInput();
  }

  Widget _buildCollapsedInput() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              l10n.storyReplyPlaceholder,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const Spacer(),
            // Quick emoji reactions
            ..._buildQuickEmojis(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickEmojis() {
    final emojis = ['❤️', '🔥', '😍', '😂'];
    return emojis.map((emoji) {
      return GestureDetector(
        onTap: () => widget.onSend(emoji, isAnonymous: _isAnonymous),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      );
    }).toList();
  }

  Widget _buildExpandedInput() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close and anonymous toggle
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
                Text(
                  l10n.replyAction,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // Anonymous toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAnonymous = !_isAnonymous;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isAnonymous
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isAnonymous
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 16,
                          color: _isAnonymous ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isAnonymous ? l10n.userAnonymous : l10n.visibleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isAnonymous
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Voice recording or text input
          if (_isRecordingVoice) _buildVoiceRecorder() else _buildTextInput(),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Voice message button
                IconButton(
                  icon: Icon(
                    _isRecordingVoice ? Icons.keyboard : Icons.mic,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isRecordingVoice = !_isRecordingVoice;
                    });
                  },
                ),
                // Image button
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: () {
                    // Pick image to reply
                  },
                ),
                const Spacer(),
                // Send button
                if (!_isRecordingVoice)
                  ElevatedButton(
                    onPressed: _controller.text.isNotEmpty
                        ? () => widget.onSend(
                            _controller.text,
                            isAnonymous: _isAnonymous,
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(l10n.sendAction),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _controller,
        maxLines: 3,
        minLines: 1,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: l10n.storyReplyHint,
          hintStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildVoiceRecorder() {
    return Column(
      children: [
        // Voice effect selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: VoiceEffect.values.map((effect) {
              final isSelected = _selectedEffect == effect;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEffect = effect;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    VoiceEffectsService.getEffectName(effect),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Recorder widget
        VoiceRecorderWidget(
          onRecordingComplete: (file, effect) {
            widget.onSend(
              '',
              isAnonymous: _isAnonymous,
              voiceFile: file,
              voiceEffect: VoiceEffectsService.effectToString(effect),
            );
          },
        ),
      ],
    );
  }
}
