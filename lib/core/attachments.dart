import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

/// Same limit as the backend (app/core/uploads.py).
const maxAttachmentBytes = 8 * 1024 * 1024;

class PickedImage {
  const PickedImage(this.dataUrl, this.bytes);

  /// Sent to the API as is (the backend stores files as data URLs).
  final String dataUrl;
  final Uint8List bytes;
}

class AttachmentTooLarge implements Exception {}

/// Picks a photo from the gallery. Null when the member cancels.
Future<PickedImage?> pickImage() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 82,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (bytes.length > maxAttachmentBytes) throw AttachmentTooLarge();
  final mime = file.mimeType ?? _mimeFromName(file.name);
  return PickedImage('data:$mime;base64,${base64Encode(bytes)}', bytes);
}

String _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}

/// The bytes of a `data:image/...;base64,` URL, null for anything else.
Uint8List? imageBytesFromDataUrl(String? url) {
  if (url == null || !url.startsWith('data:image/')) return null;
  final comma = url.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(url.substring(comma + 1));
  } on FormatException {
    return null;
  }
}

/// An image sent with a post or a message: a data URL, or a web address for older files.
class AttachmentImage extends StatelessWidget {
  const AttachmentImage({super.key, required this.url, this.maxHeight = 320});

  final String url;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytesFromDataUrl(url);
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _Broken());
    } else if (url.startsWith('http')) {
      image = Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _Broken());
    } else {
      // A PDF or another file: the website can open it
      image = const _Broken(icon: Icons.insert_drive_file_outlined);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, minWidth: double.infinity),
        child: image,
      ),
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken({this.icon = Icons.broken_image_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: AppColors.background,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.textMuted),
    );
  }
}
