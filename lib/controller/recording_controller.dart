import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class RecordingController {
  Parameters param = Parameters();
  late String streamVideoUrlId = '';
  late int streamVideoVersion = 0;
  DatabaseService db = DatabaseService();
  //Acquire Id refernce
  //Initiate live stream reference id acquiring
  Future<http.Response> getVideoRecordingRefId(
      String channelName, String userId, String token) async {
    String credentials = '${param.Customer_ID}:${param.Customer_secret}';
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(credentials);
    var rtcAcquireUrl = Uri.parse(
        'https://api.agora.io/v1/apps/${param.app_ID}/cloud_recording/acquire');
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'authorization': 'Basic $encoded'
    };

    try {
      var result = await http.post(
        rtcAcquireUrl,
        headers: headers,
        body: jsonEncode(
          <String, dynamic>{
            "cname": channelName,
            "uid": userId,
            "clientRequest": <String, dynamic>{
              // "region": "CN",
              "scene": 0,
              "resourceExpiredHour": 24,
            },
          },
        ),
      );

      return result;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      print('Error acquiring resource Id: $e');
      rethrow;
    }
  }

  //Start recording
  Future<http.Response> startRecordingVideo(String referenceId, String mode,
      String channelName, String userId, String token) async {
    String credentials = '${param.Customer_ID}:${param.Customer_secret}';
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(credentials);
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'authorization': 'Basic $encoded'
    };
    try {
      var rtcStartUrl = Uri.parse(
          'https://api.agora.io/v1/apps/${param.app_ID}/cloud_recording/resourceid/$referenceId/mode/$mode/start');

      print('the userId start rec: $userId');
      //update streaming video data model with the current stream
      var result = await http.post(
        rtcStartUrl,
        headers: headers,
        body: jsonEncode(
          {
            "cname": channelName,
            "uid": userId,
            "clientRequest": <String, dynamic>{
              "token": token,
              "recordingConfig": <String, dynamic>{
                "maxIdleTime": 30,
                "streamTypes": 2,
                "audioProfile": 1,
                "channelType": 1,
                "videoStreamType": 0,
                "transcodingConfig": <String, dynamic>{
                  "height": 640,
                  "width": 360,
                  "bitrate": 500,
                  "fps": 15,
                  "mixedVideoLayout": 1,
                  "backgroundColor": "#FFFFFF",
                },
                "subscribeVideoUids": ["123", "456"],
                "subscribeAudioUids": ["123", "456"],
                "subscribeUidGroup": 0
              },
              "recordingFileConfig": <String, dynamic>{
                "avFileType": ["hls"]
              },
              "storageConfig": <String, dynamic>{
                "vendor": 6,
                "region": 0,
                "bucket": param.google_firebase_bucket_id,
                "accessKey": param.google_firebase_access_key,
                "secretKey": param.google_firebase_secret_key,
                "fileNamePrefix": ["streams", "recordings"]
              },
            },
          },
        ),
      );

      return result;
    } catch (e, stackTrace) {
      print('Error start recording: $e');
      await Sentry.captureException(e, stackTrace: stackTrace);

      rethrow;
    }
  }

  //Stop recording
  Future<http.Response> stopRecordingVideos(
      {required String channelName,
      required String userId,
      String? sid,
      String? resouceId,
      String? mode,
      String? streamId}) async {
    var rtcStopUrl = Uri.parse(
        'https://api.agora.io/v1/apps/${param.app_ID}/cloud_recording/resourceid/$resouceId/sid/$sid/mode/$mode/stop');
    String credentials = '${param.Customer_ID}:${param.Customer_secret}';
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(credentials);
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'authorization': 'Basic $encoded'
    };

    try {
      //delete stream from stream video url data store
      // if (streamVideoUrlId.isNotEmpty) {
      //   await db.deleteStreamingVideo(streamId: streamVideoUrlId);
      //   print('stream has been deleted');
      // }

      //stop recroding and save it
      var result = await http.post(
        rtcStopUrl,
        headers: headers,
        body: jsonEncode(
          <String, dynamic>{
            "cname": channelName,
            "uid": userId,
            "clientRequest": <String, dynamic>{},
          },
        ),
      );
      return result;
    } catch (e) {
      print('stop recording could not be processed: $e');
      rethrow;
    }
  }

  //Query recording
  Future<http.Response> queryRecoding(
      {String? resourceId, String? sid, String? mode}) async {
    var rtcQueryUrl = Uri.parse(
        'https://api.agora.io/v1/apps/${param.app_ID}/cloud_recording/resourceid/$resourceId/sid/$sid/mode/$mode/query');

    String credentials = '${param.Customer_ID}:${param.Customer_secret}';
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(credentials);
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'authorization': 'Basic $encoded'
    };
    try {
      var result = await http.get(rtcQueryUrl, headers: headers);
      return result;
    } catch (e) {
      print('the query result failed: $e');
      rethrow;
    }
  }
}
