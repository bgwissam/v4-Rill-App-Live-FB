import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:path/path.dart' as Path;
import 'package:video_compress/video_compress.dart';

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
  Future<Map<String, dynamic>> uploadFile(
      {MediaInfo? mfile, XFile? xfile, String? folderName}) async {
    String fileUrl = '';
    String thumbnailUrl = '';
    Map<String, dynamic> result;
    try {
      if (mfile != null) {
        storageReferece = FirebaseStorage.instance;
        Reference ref = storageReferece
            .ref()
            .child('$folderName/${Path.basename(mfile.path!)}');

        UploadTask uploadTask = ref.putFile(File(mfile.path!));
        var downloadUrl = await (await uploadTask).ref.getDownloadURL();

        fileUrl = downloadUrl.toString();
        //generate thumnail
        var thumbnailImage = await generateThumbnailUrl(fileUrl);
        //upload image and get url
        if (thumbnailImage != null) {
          storageReferece = FirebaseStorage.instance;
          Reference ref = storageReferece
              .ref()
              .child('thumbnails/${Path.basename(thumbnailImage.path)}');

          UploadTask uploadTask = ref.putFile(File(thumbnailImage.path));
          var downloadUrlThumbnail =
              await (await uploadTask).ref.getDownloadURL();
          thumbnailUrl = downloadUrlThumbnail.toString();
        }
        result = {
          'videoUrl': fileUrl,
          'imageUrl': thumbnailUrl,
        };
        return result;
      }
      if (xfile != null) {
        storageReferece = FirebaseStorage.instance;
        Reference ref = storageReferece
            .ref()
            .child('$folderName/${Path.basename(xfile.path)}');

        UploadTask uploadTask = ref.putFile(File(xfile.path));
        var downloadUrl = await (await uploadTask).ref.getDownloadURL();
        fileUrl = downloadUrl.toString();

        result = {'imageUrl': fileUrl};
        return result;
      }
      //In case null value were received
      result = {
        'videoUrl': '',
        'imageUrl': '',
      };

      return result;
    } catch (e, stackTrace) {
      print('Error uploading file: $e');
      await Sentry.captureException(e, stackTrace: stackTrace);
      result = {'error': e.toString()};
      return result;
    }
  }

  //Generate thumbnail image from a video url
  Future<File?> generateThumbnailUrl(String videoUrl) async {
    final fileName = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 220,
        quality: 25);

    var file = File(fileName!);
    return file;
  }

  //Query from bucket
  Future<void> listAllItems() async {}

  //Upload profile photo
  Future<String> uploadProfilePhoto() async {
    return '';
  }
}
