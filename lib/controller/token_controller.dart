import 'dart:convert';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:rillliveapp/shared/parameters.dart';

class TokenGenerator {
  late String apiToken;
  String baseUrl =
      'https://app.rilllive.com/public/services/agora/rtc-token.php';
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
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic $encoded'
        },
        body: jsonEncode(
          <String, dynamic>{
            'appID': appId,
            'appCertificate': appCertification,
            'channelName': channelName,
            'userId': userId,
            'role': role,
            'privilegeExpiredTs': 24
          },
        ),
      );

      var rawToken = json.decode(response.body);
      token =
          '006d480c821a2a946d6a4d29292462a3d6fIABb2uf++rfbA4aVyMrCp09FtFll4wDxkkN1d0b3rmVvWwx+f9gAAAAAIgCTNRpOQQ1PYQQAAQBBDU9hAgBBDU9hAwBBDU9hBABBDU9h';
      //rawToken['token'];
      print('The token generated: $rawToken');
      print('uid: $userId channel: $channelName');
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
