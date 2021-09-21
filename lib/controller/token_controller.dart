import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rillliveapp/shared/parameters.dart';

class TokenGenerator {
  late String apiToken;
  String baseUrl =
      'https://app.rilllive.com/public/services/agora/rtc-token.php';
  String appId = Parameters().app_ID;
  String appCertification = Parameters().app_certificate;

  //Api post request to request Audio Video Token
  Future<String> createVideoAudioChannelToken(
      {required String channelName,
      required String userId,
      required String role}) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          <String, dynamic>{
            'appID': appId,
            'appCertificate': appCertification,
            'channelName': channelName,
            'userId': userId,
            'role': role,
            'privilegeExpiredTs': 0
          },
        ),
      );
      String token;
      var rawToken = json.decode(response.body);
      token = rawToken['token'];
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
