import 'dart:convert';
import 'package:http/http.dart' as http;

class MessaginService {
  String? token;
  String? senderId;
  String? senderName;
  String? receiverId;
  String? messageType;
  String? messageTitle;
  String? messageBody;

  Future<void> sendPushMessage() async {
    //_firebaseMessaging.onTokenRefresh;
    if (token == null) {
      print('token is null, message could not be sent');
    }
    try {
      switch (messageType) {
        case 'follow':
          _sendFollowNotification();
          break;
        default:
          print('unable to process notification');
          break;
      }
    } catch (e) {
      print('An error occured: $e');
    }
  }

  _sendFollowNotification() async {
    print('sending notification for user followed');
    var msg = jsonEncode({
      'data': {
        // 'from': senderName,
        'title': messageTitle,
        'body': '$senderName $messageBody',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK'
      },
      'to': token,
      'notification': {
        // 'from': senderName,
        'title': messageTitle,
        'body': '$senderName $messageBody',
        'click_action': '/notifications'
      },
    });
    var response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'content-type': 'application/json',
        'Authorization':
            'key=AAAAHU02sbg:APA91bE-eLuEktG3pkC3KzvObDc7pGgtPKMwRPXkxjcdrFbQFEEJUSMZSp7aDHYLrGPtHwv-vhkxyEG_YKj3IsrdL12m7PB7sgo1BwAiNoyLwlTz848ilsULqpkex-sEY0gKWEmBXAh3'
      },
      encoding: Encoding.getByName('utf-8'),
      body: msg,
    );
    print('FCM send status: ${response.statusCode}');
    return response.statusCode.toString();
  }
}
