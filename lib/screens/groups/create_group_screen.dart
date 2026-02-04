import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final GroupService _groupService = GroupService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPublic = false;
  bool _isLoading = false;
  int _maxMembers = 50;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.takePhotoAction),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGalleryAction),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  l10n.removePhotoAction,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final group = await _groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        isPublic: _isPublic,
        maxMembers: _maxMembers,
        avatar: _selectedImage,
      );

      if (mounted) {
        Helpers.showSuccessSnackBar(context, l10n.groupCreatedSuccess);
        context.pop();
        context.push('/group/${group.id}');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, l10n.errorMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createGroupTitle),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.createAction),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Avatar
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: _selectedImage == null
                            ? AppColors.primaryGradient
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? const Icon(
                              Icons.groups,
                              size: 48,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Group Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.groupNameLabel,
                hintText: l10n.groupNameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.groupNameRequiredError;
                }
                if (value.trim().length < 3) {
                  return l10n.groupNameMinLengthError(3);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l10n.groupDescriptionLabel,
                hintText: l10n.groupDescriptionHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),

            // Max Members
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.people),
              title: Text(l10n.maxMembersTitle),
              subtitle: Text(l10n.membersCount(_maxMembers)),
              trailing: SizedBox(
                width: 200,
                child: Slider(
                  value: _maxMembers.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: '$_maxMembers',
                  onChanged: (value) {
                    setState(() => _maxMembers = value.toInt());
                  },
                ),
              ),
            ),
            const Divider(),

            // Public/Private Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.publicGroupTitle),
              subtitle: Text(
                _isPublic
                    ? l10n.publicGroupSubtitle
                    : l10n.privateGroupSubtitle,
              ),
              value: _isPublic,
              onChanged: (value) {
                setState(() => _isPublic = value);
              },
              secondary: Icon(
                _isPublic ? Icons.public : Icons.lock,
                color: _isPublic ? AppColors.success : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.groupInviteCodeInfo,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
