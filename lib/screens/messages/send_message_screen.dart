import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import '../../widgets/voice/voice_recorder_widget.dart';
import '../../services/voice_effects_service.dart';

class SendMessageScreen extends StatefulWidget {
  final String recipientUsername;

  const SendMessageScreen({
    super.key,
    required this.recipientUsername,
  });

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isAnonymous = true;
  bool _isSending = false;
  bool _showVoiceRecorder = false;
  File? _selectedImage;
  File? _voiceFile;
  VoiceEffect _selectedEffect = VoiceEffect.none;

  // For recipient search mode
  String? _selectedRecipient;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.recipientUsername.isNotEmpty) {
      _selectedRecipient = widget.recipientUsername;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final userService = UserService();
      final users = await userService.searchUsers(query);
      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _onVoiceRecorded(File file, VoiceEffect effect) {
    setState(() {
      _voiceFile = file;
      _selectedEffect = effect;
      _showVoiceRecorder = false;
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (_selectedRecipient == null || _selectedRecipient!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un destinataire')),
      );
      return;
    }

    if (message.isEmpty && _selectedImage == null && _voiceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un message')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _messageService.sendAnonymousMessage(
        recipientUsername: _selectedRecipient!,
        content: message,
        isAnonymous: _isAnonymous,
        image: _selectedImage,
        voice: _voiceFile,
        voiceEffect: _selectedEffect != VoiceEffect.none
            ? _selectedEffect.name
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message envoy avec succs!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show search screen if no recipient selected
    if (_selectedRecipient == null || _selectedRecipient!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Envoyer un message'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _searchUsers,
              ),
            ),
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Recherchez un utilisateur pour\nlui envoyer un message',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Envoyer à @$_selectedRecipient'),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _sendMessage,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Envoyer'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Anonymous toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAnonymous ? Icons.visibility_off : Icons.visibility,
                          color: _isAnonymous ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAnonymous ? 'Mode anonyme' : 'Mode public',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isAnonymous
                                    ? 'Votre identit sera cache'
                                    : 'Votre nom sera visible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAnonymous,
                          onChanged: (value) {
                            setState(() {
                              _isAnonymous = value;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Message input
                  TextField(
                    controller: _messageController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'crivez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selected image preview
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Voice message preview
                  if (_voiceFile != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Message vocal enregistr',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_selectedEffect != VoiceEffect.none)
                                  Text(
                                    'Effet: ${VoiceEffectsService.getEffectName(_selectedEffect)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _voiceFile = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  // Voice recorder
                  if (_showVoiceRecorder)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: VoiceRecorderWidget(
                        onRecordingComplete: _onVoiceRecorded,
                        showEffectSelector: true,
                        selectedEffect: _selectedEffect,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.image_outlined,
                    color: _selectedImage != null ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(
                    Icons.mic_outlined,
                    color: _showVoiceRecorder || _voiceFile != null
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showVoiceRecorder = !_showVoiceRecorder;
                    });
                  },
                ),
                const Spacer(),
                // Voice effect selector (if voice recorder is shown)
                if (_showVoiceRecorder)
                  PopupMenuButton<VoiceEffect>(
                    icon: const Icon(Icons.tune),
                    onSelected: (effect) {
                      setState(() {
                        _selectedEffect = effect;
                      });
                    },
                    itemBuilder: (context) => VoiceEffect.values.map((effect) {
                      return PopupMenuItem(
                        value: effect,
                        child: Row(
                          children: [
                            Icon(
                              _selectedEffect == effect
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: _selectedEffect == effect
                                  ? AppColors.primary
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(VoiceEffectsService.getEffectName(effect)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
