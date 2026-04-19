import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MultiImagePickHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<List<XFile>> pickImages(
    BuildContext context, {
    int maxImages = 5,
  }) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Tomar una foto'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Elegir varias de galería'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return [];

    if (source == 'camera') {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image == null ? [] : [image];
    }

    final images = await _picker.pickMultiImage(imageQuality: 80);

    if (images.isEmpty) return [];

    return images.take(maxImages).toList();
  }
}
