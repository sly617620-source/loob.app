import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Service for handling file uploads to Firebase Storage.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Upload a file to Firebase Storage.
  Future<String?> uploadFile({
    required File file,
    required String path,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Upload failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected upload error: $e');
      return null;
    }
  }

  /// Pick and upload an image.
  Future<String?> pickAndUploadImage({
    required String userId,
    required String folder,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      final extension = pickedFile.path.split('.').last;
      final path = '$folder/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      return await uploadFile(
        file: file,
        path: path,
        contentType: 'image/$extension',
      );
    } catch (e) {
      debugPrint('Image pick/upload failed: $e');
      return null;
    }
  }

  /// Delete a file from storage.
  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Delete failed: $e');
      return false;
    }
  }
}
