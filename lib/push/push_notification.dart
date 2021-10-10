import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationsManager {
  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance =
      PushNotificationsManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      //for ios request permission first
      _firebaseMessaging.requestPermission();

      //for testing purpose only print the token
      String? token = await _firebaseMessaging.getToken();
      print('firebase message token: $token');

      _isInitialized = true;
    }
  }
}
