import 'package:image_picker/image_picker.dart';

class StorageData {
  final ImagePicker _picker = ImagePicker();

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
  Future<void> uploadFile(XFile? file) async {}

  //Query from bucket
  Future<void> listAllItems() async {}

  //Upload profile photo
  Future<String> uploadProfilePhoto() async {
    return '';
  }
}
