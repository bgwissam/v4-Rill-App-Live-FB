import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class TokenGenerator {
  late String apiToken;
  String baseUrl =
      'https://app.rilllive.com/public/services/agora/rtc-token.php';
  String appId = 'd480c821a2a946d6a4d29292462a3d6f';
  String appCertification = '832101fbfa424e358854a936e4c13db8';

  //Api post request to request Audio Video Token
  Future<String> createVideoAudioChannelToken(
      {required String channelName,
      required String userId,
      required String role}) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(
          <String, String>{
            'appID': appId,
            'appCertificate': appCertification,
            'channelName': channelName,
            'userId': userId,
            'role': role
          },
        ),
      );
      String token;
      var rawToken = json.decode(response.body);
      token = rawToken['token'];
      print('The token generated: $token');
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
