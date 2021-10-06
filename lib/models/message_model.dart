class ChatRoomModel {
  String? userId;
  List<String>? users;
  ChatRoomModel({
    this.userId,
    this.users,
  });
}

class MessageMap {
  String? senderId;
  String? message;

  MessageMap({this.senderId, this.message});
}
