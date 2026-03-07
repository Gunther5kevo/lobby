import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Handles all Firebase Storage uploads and downloads.
///
/// Storage structure:
///   /avatars/{uid}.jpg             — profile pictures
///   /messages/{chatId}/{msgId}.jpg — image messages
///   /groups/{groupId}/icon.jpg     — group icons
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  // ── Avatar ─────────────────────────────────────────────────────

  /// Uploads a profile avatar and returns the public download URL.
  /// Reports upload progress via [onProgress] (0.0 – 1.0).
  Future<String> uploadAvatar({
    required String uid,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref('avatars/$uid.jpg');

    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
    }

    await task;
    return ref.getDownloadURL();
  }

  // ── Image message ──────────────────────────────────────────────

  /// Uploads an image attachment for a chat message.
  /// Returns the download URL.
  Future<String> uploadMessageImage({
    required String chatId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final msgId = _uuid.v4();
    final ref   = _storage.ref('messages/$chatId/$msgId.jpg');

    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
    }

    await task;
    return ref.getDownloadURL();
  }

  // ── Voice message ──────────────────────────────────────────────

  /// Uploads a recorded voice note and returns the download URL.
  Future<String> uploadVoiceNote({
    required String chatId,
    required File file,
  }) async {
    final msgId = _uuid.v4();
    final ref   = _storage.ref('voiceNotes/$chatId/$msgId.aac');

    await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/aac'),
    );

    return ref.getDownloadURL();
  }

  // ── Group icon ─────────────────────────────────────────────────

  Future<String> uploadGroupIcon({
    required String groupId,
    required File file,
  }) async {
    final ref = _storage.ref('groups/$groupId/icon.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  // ── Delete ─────────────────────────────────────────────────────

  /// Deletes a file at the given Storage path (e.g. 'avatars/uid.jpg').
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      // Ignore not-found errors — file may already be gone
      if (e.code != 'object-not-found') rethrow;
    }
  }
}