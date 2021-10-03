import 'dart:convert';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:rillliveapp/shared/parameters.dart';

class TokenGenerator {
  late String apiToken;
  String baseUrl = 'https://192.168.8.117:8080/access-token';
  //'https://app.rilllive.com/public/services/agora/rtc-token.php';
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
      // final response = await http.post(
      //   Uri.parse(baseUrl),
      //   headers: <String, String>{
      //     'Content-Type': 'application/json',
      //     //'Authorization': 'Basic $encoded'
      //   },
      //   body: jsonEncode(
      //     <String, dynamic>{
      //       'appID': appId,
      //       'appCertificate': appCertification,
      //       'channelName': channelName,
      //       'uid': userId,
      //       'role': role,
      //       'expireTime': 24
      //     },
      //   ),
      // );

      //var rawToken = json.decode(response.body);
      //print('raw token: $rawToken}');
      token =
          '006d480c821a2a946d6a4d29292462a3d6fIACmVvx02d81nPDfcQI+7u/jZ+bXCXfQHH4cYIErG9gc/Qx+f9gAAAAAEAC+Mu48JnRaYQEAAQC2MFlh';
      //rawToken['token'];

      // print('The token generated: $rawToken');
      // print('uid: $userId channel: $channelName');
      // if (response.statusCode == 200) {
      //   return token;
      // } else {
      //   return 'failed';
      // }
      return token;
    } catch (e, stackTrace) {
      print('An error occured: $e, Stack: $stackTrace');
      return '006d480c821a2a946d6a4d29292462a3d6fIACmVvx02d81nPDfcQI+7u/jZ+bXCXfQHH4cYIErG9gc/Qx+f9gAAAAAEAC+Mu48JnRaYQEAAQC2MFlh';
    }
  } //End of post function

}
