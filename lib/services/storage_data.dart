import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:path/path.dart' as Path;

class StorageData {
  final ImagePicker _picker = ImagePicker();
  late FirebaseStorage storageReferece;
  //Get the url of the file in the database
  Future<String?> getFileUrl({String? key}) async {
    return '';
  }

  //Get all images and videos
  Future<void> getImageVideoFiles({String? key}) async {}

  //Upload and image or video file
  Future<XFile?> uploadImageFile({String? fileType}) async {
    final XFile? file;
    switch (fileType) {
      case 'imageGallery':
        // Pick an image
        file = await _picker.pickImage(
            source: ImageSource.gallery,
            preferredCameraDevice: CameraDevice.front,
            imageQuality: 25,
            maxHeight: 400,
            maxWidth: 400);
        return file;
      case 'imageCamera':
        // Capture a photo
        file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 10,
        );
        return file;
      case 'videoGallery':
        file = await _picker.pickVideo(source: ImageSource.gallery);

        return file;
      case 'videoCamera':
        file = await _picker.pickVideo(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
        );
        return file;
      default:
        print('Could not find your request!');
        return null;
    }
  }

  //Upload file to firebase storage
  Future<String> uploadFile(XFile? file, String folderName) async {
    String fileUrl;

    try {
      if (file != null) {
        storageReferece = FirebaseStorage.instance;
        Reference ref = storageReferece
            .ref()
            .child('$folderName/${Path.basename(file.path)}');

        UploadTask uploadTask = ref.putFile(File(file.path));
        var downloadUrl = await (await uploadTask).ref.getDownloadURL();
        fileUrl = downloadUrl.toString();
      } else {
        fileUrl = '';
      }
      return fileUrl;
    } catch (e, stackTrace) {
      print('Error uploading file: $e');
      await Sentry.captureException(e, stackTrace: stackTrace);
      return e.toString();
    }
  }

  //Query from bucket
  Future<void> listAllItems() async {}

  //Upload profile photo
  Future<String> uploadProfilePhoto() async {
    return '';
  }
}
