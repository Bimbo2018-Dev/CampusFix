import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report_model.dart';
import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/report_image_helper.dart';
import '../widgets/app_shell.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _category;
  String? _priority;
  ReportImageResult? _selectedImage;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final state = AppStateScope.read(context);
    final duplicates = state.findPotentialDuplicates(
      title: _titleController.text,
      category: _category!,
      location: _locationController.text,
    );
    if (duplicates.isNotEmpty) {
      final shouldContinue = await _showDuplicateWarning(duplicates);
      if (shouldContinue != true) {
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      await state.addReport(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category!,
        location: _locationController.text,
        priority: _priority!,
        imagePath: _selectedImage?.dataUrl,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.apiError ?? 'Could not submit the report.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(state.lastInfoMessage ?? 'Report submitted successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pushReplacementNamed(CampusFixRoutes.dashboard);
  }

  Future<bool?> _showDuplicateWarning(List<ReportModel> reports) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.content_copy_outlined),
        title: const Text('Possible duplicate report'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CampusFix found similar active reports. Review them before submitting another one.',
              ),
              const SizedBox(height: 12),
              for (final report in reports.take(3))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(report.title),
                  subtitle: Text('${report.location} - ${report.status}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) {
      return;
    }

    ImageSource source = ImageSource.gallery;
    if (!kIsWeb && _isNativeMobilePlatform()) {
      final selectedSource = await _showNativeMobileImageSourceSheet();
      if (selectedSource == null) {
        return;
      }
      source = selectedSource;
    }

    _isPickingImage = true;
    try {
      final image = await ReportImageHelper.pickAndPrepareImage(
        source: source,
      );
      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() => _selectedImage = image);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${image.name} attached.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ReportImageTooLargeException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That photo is too large. Choose another image.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ReportImageReadException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read that image. Try another photo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ReportImageUnsupportedException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a JPG, PNG, or WebP photo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      debugPrint('Report image upload failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open that photo. Try another image.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      } else {
        _isPickingImage = false;
      }
    }
  }

  Future<ImageSource?> _showNativeMobileImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isNativeMobilePlatform() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _showQrLocationDialog() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.qr_code_scanner_outlined),
        title: const Text('QR Room Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Scan or paste room QR code',
            hintText: 'Example: LOCATION=Room 204;CATEGORY=Classroom',
          ),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              'LOCATION=Room 204, Main Building;CATEGORY=Classroom',
            ),
            child: const Text('Use Sample'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (code == null || code.trim().isEmpty) {
      return;
    }

    final parsed = _parseQrLocation(code);
    setState(() {
      _locationController.text = parsed.location;
      _category = parsed.category ?? _category;
      _priority = parsed.priority ?? _priority;
    });
  }

  ({String location, String? category, String? priority}) _parseQrLocation(
    String raw,
  ) {
    final values = <String, String>{};
    for (final part in raw.split(RegExp(r'[;\n|]'))) {
      final separator = part.contains('=') ? '=' : ':';
      final pieces = part.split(separator);
      if (pieces.length >= 2) {
        values[pieces.first.trim().toUpperCase()] =
            pieces.sublist(1).join(separator).trim();
      }
    }

    final category = values['CATEGORY'];
    final priority = values['PRIORITY'];
    return (
      location: values['LOCATION'] ?? values['ROOM'] ?? raw.trim(),
      category: ReportCategories.all.contains(category) ? category : null,
      priority: ReportPriorities.all.contains(priority) ? priority : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 2,
      title: 'New Issue',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit a Campus Report',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide clear details so the right campus team can respond quickly.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: 'Title',
                        hint: 'Example: Projector not working',
                        icon: Icons.title,
                        controller: _titleController,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Title is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Description',
                        hint: 'Describe what happened and who is affected.',
                        icon: Icons.description_outlined,
                        controller: _descriptionController,
                        maxLines: 5,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Description is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 640;
                          final fields = [
                            CustomDropdown(
                              label: 'Category',
                              icon: Icons.category_outlined,
                              items: ReportCategories.all,
                              value: _category,
                              onChanged: (value) =>
                                  setState(() => _category = value),
                              validator: (value) =>
                                  value == null ? 'Category is required' : null,
                            ),
                            CustomDropdown(
                              label: 'Priority',
                              icon: Icons.flag_outlined,
                              items: ReportPriorities.all,
                              value: _priority,
                              onChanged: (value) =>
                                  setState(() => _priority = value),
                              validator: (value) =>
                                  value == null ? 'Priority is required' : null,
                            ),
                          ];

                          if (!wide) {
                            return Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 16),
                                fields[1],
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: fields[0]),
                              const SizedBox(width: 16),
                              Expanded(child: fields[1]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Location',
                        hint: 'Example: Room 204, Main Building',
                        icon: Icons.location_on_outlined,
                        controller: _locationController,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Location is required'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _showQrLocationDialog,
                          icon: const Icon(Icons.qr_code_scanner_outlined),
                          label: const Text('Scan QR Location'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ImageUploadBox(
                        image: _selectedImage,
                        isPicking: _isPickingImage,
                        onPickImage: _pickImage,
                        onRemoveImage: _selectedImage == null
                            ? null
                            : () => setState(() => _selectedImage = null),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label:
                            _isSubmitting ? 'Submitting...' : 'Submit Report',
                        icon: Icons.send_outlined,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  const _ImageUploadBox({
    required this.image,
    required this.isPicking,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final ReportImageResult? image;
  final bool isPicking;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final selectedImage = image;

    final frame = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 214),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: selectedImage == null
          ? _EmptyImagePrompt(isPicking: isPicking)
          : _SelectedImagePreview(
              image: selectedImage,
              isPicking: isPicking,
              onPickImage: onPickImage,
              onRemoveImage: onRemoveImage,
            ),
    );

    return Material(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(16),
      child: selectedImage == null
          ? InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isPicking ? null : onPickImage,
              child: frame,
            )
          : frame,
    );
  }
}

class _EmptyImagePrompt extends StatelessWidget {
  const _EmptyImagePrompt({required this.isPicking});

  final bool isPicking;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: isPicking
              ? const Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(height: 12),
        Text(
          'Upload image',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Tap here to select a photo from your device.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _UploadActionPill(
          icon: Icons.photo_library_outlined,
          label: isPicking ? 'Opening photos...' : 'Choose Photo',
        ),
      ],
    );
  }
}

class _UploadActionPill extends StatelessWidget {
  const _UploadActionPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({
    required this.image,
    required this.isPicking,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final ReportImageResult image;
  final bool isPicking;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(
              image.bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: const Icon(Icons.image_outlined, size: 18),
              label: Text(
                image.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OutlinedButton.icon(
              onPressed: isPicking ? null : onPickImage,
              icon: const Icon(Icons.swap_horiz_outlined),
              label: Text(isPicking ? 'Opening...' : 'Change Photo'),
            ),
            if (onRemoveImage != null)
              TextButton.icon(
                onPressed: onRemoveImage,
                icon: const Icon(Icons.close),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
