class ChatRoomModel {
  String? userId;
  List<String>? users;
  ChatRoomModel({
    this.userId,
    this.users,
  });
}

class ChatModel {
  String? userId;
  String? chattingWith;
  String? userName;
  String? firstName;
  String? lastName;
  String? avatarUrl;
  ChatModel({
    this.userId,
    this.chattingWith,
    this.userName,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });
}

class MessageMap {
  String? senderId;
  String? message;
  int? time;

  MessageMap({this.senderId, this.message, this.time});
}
