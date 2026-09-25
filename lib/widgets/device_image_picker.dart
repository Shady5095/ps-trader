import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../theme/app_theme.dart';

class DeviceImagePicker extends StatelessWidget {
  final List<String> imagePaths;
  final ValueChanged<List<String>> onChanged;

  const DeviceImagePicker({
    super.key,
    required this.imagePaths,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final files = await picker.pickMultiImage();
      if (files.isNotEmpty) {
        final newPaths = files.map((f) => f.path).toList();
        onChanged([...imagePaths, ...newPaths]);
      }
    } else {
      final file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 82,
      );
      if (file != null) {
        onChanged([...imagePaths, file.path]);
      }
    }
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.primary),
              title: Text(AppStrings.takePhotoCamera.tr(ctx)),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text(AppStrings.pickFromGallery.tr(ctx)),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.gallery);
              },
            ),
            if (imagePaths.isNotEmpty)
              ListTile(
                leading:
                    const Icon(Icons.delete_sweep, color: AppColors.danger),
                title: Text(AppStrings.removeAllPhotos.tr(ctx)),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(const []);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return GestureDetector(
        onTap: () => _showSourceSheet(context),
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined,
                  color: AppColors.textSecondary, size: 32),
              const SizedBox(height: 8),
              Text(
                AppStrings.realDevicePhotos.tr(context),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.addPhotosSubtitle.tr(context),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppStrings.photosCount.tr(context)} (${imagePaths.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showSourceSheet(context),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(AppStrings.addPhotos.tr(context)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imagePaths.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == imagePaths.length) {
                return InkWell(
                  onTap: () => _showSourceSheet(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: AppColors.primary, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.addPhotos.tr(context),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final path = imagePaths[index];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 100,
                      height: 110,
                      color: AppColors.surfaceAlt,
                      child: path.startsWith('http://') ||
                              path.startsWith('https://')
                          ? Image.network(
                              path,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2));
                              },
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        final updated = List<String>.from(imagePaths)
                          ..removeAt(index);
                        onChanged(updated);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
