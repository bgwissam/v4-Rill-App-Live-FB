import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rillliveapp/shared/parameters.dart';

class RtcTokenGenerator {
  late String apiToken;
  String baseUrl =
      'https://us-central1-rill-app-live.cloudfunctions.net/tokenGenerator';
  String appId = Parameters().app_ID;
  String appCertification = Parameters().app_certificate;
  late String token;
  //Api post request to request Audio Video Token
  Future<String> createVideoAudioChannelToken(
      {required String channelName,
      required int userId,
      required String role}) async {
    try {
      // String credentials =
      //     '${Parameters().Customer_ID}:${Parameters().Customer_secret}';
      // Codec<String, String> stringToBase64 = utf8.fuse(base64);
      // String encoded = stringToBase64.encode(credentials);
      // print('the encoded: $encoded');
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          "Content-Type": "application/json",
          //'Authorization': 'Basic $encoded'
        },
        body: jsonEncode(
          <String, dynamic>{
            // "appID": appId,
            // "appCertificate": appCertification,
            "channelName": channelName,
            "uid": userId,
            "role": role,
            "expireTime": 3000
          },
        ),
      );

      var rawToken = json.decode(response.body);
      token = rawToken['token'];
      if (response.statusCode == 200) {
        return token;
      } else {
        return 'failed';
      }
    } catch (e, stackTrace) {
      print('An error occured: $e, Stack: $stackTrace');
      return 'failed';
    }
  } //End of post function

}
