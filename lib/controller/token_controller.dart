import 'dart:convert';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:rillliveapp/shared/parameters.dart';

class TokenGenerator {
  late String apiToken;
  String baseUrl =
      'https://us-central1-rill-app-live.cloudfunctions.net/tokenController';
  String appId = Parameters().app_ID;
  String appCertification = Parameters().app_certificate;
  late String token;
  //Api post request to request Audio Video Token
  Future<String> createVideoAudioChannelToken(
      {required String channelName,
      required String userId,
      required String role}) async {
    try {
      String credentials =
          '${Parameters().Customer_ID}:${Parameters().Customer_secret}';
      Codec<String, String> stringToBase64 = utf8.fuse(base64);
      String encoded = stringToBase64.encode(credentials);
      print('the encoded: $encoded');
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          "Content-Type": "application/json",
          'Authorization': 'Basic $encoded'
        },
        body: jsonEncode(
          <String, dynamic>{
            "appID": appId,
            "appCertificate": appCertification,
            "channelName": channelName,
            "uid": "10034",
            "role": role,
            "expireTime": 24
          },
        ),
      );

      var rawToken = response.body; //json.decode(response.body);
      print('raw token: $rawToken}');

      // token = rawToken['token'];

      print('The token generated: $rawToken');
      if (response.statusCode == 200) {
        return token;
      } else {
        return 'failed';
      }
    } catch (e, stackTrace) {
      print('An error occured: $e, Stack: $stackTrace');
      return '006d480c821a2a946d6a4d29292462a3d6fIAC7+thsby5UajCcDv4cFa7h7N3lu/hOgaIAsj4qb30Hbgx+f9gAAAAAEAAEylysABBdYQEAAQCQzFth';
    }
  } //End of post function

}
