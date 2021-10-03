import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/shared/parameters.dart';

class LiveMessaging {
  var _client;
  List<String> _log = [];
  void createClient() async {
    _client = await AgoraRtmClient.createInstance(Parameters().app_ID);
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      _log.add('user: $peerId message: ${message.text}');
    };

    _client.onConnectionStateChanged = (int state, int reason) {
      if (state == 5) {
        _client.logout();
      }
    };
  }
}
