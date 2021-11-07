import 'dart:io';
import 'package:amplify_flutter/amplify.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

class AWSstorage {
  AmplifyStorageS3 storage = AmplifyStorageS3();
  Parameters param = Parameters();

  Future<dynamic> downloadFile(String key) async {
    final documentDir = await getApplicationDocumentsDirectory();
    final filePath = documentDir.path + '/' + key;
    final file = File(filePath);

    // try {

    //   // var result = await Amplify.Storage.downloadFile(key: key, local: file)
    //   //     .catchError((onError) {
    //   //   print('error getting file 1: $onError');
    //   // }).then((value) => value.file);
    //   // print('the result of file download: $result');
    //   // return result;
    // } catch (e, stackTrace) {
    //   print('error getting file 2: $e');
    //   await Sentry.captureException(e, stackTrace: stackTrace);
    // }
  }

  Future<void> list() async {
    try {
      print('In list');
      S3ListOptions options =
          S3ListOptions(accessLevel: StorageAccessLevel.guest);
      ListResult result = await Amplify.Storage.list(options: options);
      print('List Result:');
      for (StorageItem item in result.items) {
        print(
            'Item: { key:${item.key}, eTag:${item.eTag}, lastModified:${item.lastModified}, size:${item.size}');
      }
    } catch (e) {
      print('List Err: ' + e.toString());
    }
  }
}
