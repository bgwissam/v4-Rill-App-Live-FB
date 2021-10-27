import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rillliveapp/shared/parameters.dart';

class RtcTokenGenerator {
  late String apiToken;
  String baseUrl =
      'https://us-central1-rill-app-live.cloudfunctions.net/tokenGenerator';
  String appId = Parameters().app_ID;
  String appCertification = Parameters().app_certificate;
  late Map<String, dynamic> token;
  //Api post request to request Audio Video Token
  Future<Map> createVideoAudioChannelToken(
      {required String channelName, required String role}) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          "Content-Type": "application/json",
        },
        body: jsonEncode(
          <String, dynamic>{
            "channelName": channelName,
            "role": role,
            "expireTime": 3000
          },
        ),
      );

      var rawToken = json.decode(response.body);
      token = rawToken;
      if (response.statusCode == 200) {
        return token;
      } else {
        return {'token': 'failed', 'uid': 'no id'};
      }
    } catch (e, stackTrace) {
      print('An error occured: $e, Stack: $stackTrace');
      return {'token': 'failed', 'uid': 'no id'};
    }
  }
} //End of post function


