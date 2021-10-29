import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/messaging/conversation_screen.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/parameters.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key, this.userId, this.userModel})
      : super(key: key);
  final String? userId;
  final UserModel? userModel;
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late String _searchWord;
  late List<Map<String, dynamic>> messageList = [];
  var unread;
  late List<Map<String, dynamic>> chatList = [];
  //Controllers
  DatabaseService db = DatabaseService();
  //Streams
  late Stream<QuerySnapshot> messageStream;
  @override
  Widget build(BuildContext context) {
    var _size = MediaQuery.of(context).size;
    return widget.userId != null
        ? SizedBox(
            height: _size.height - 100,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Build Search box
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _searchBox(),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: Image.asset('assets/icons/add_rill.png'),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      child: Text('Messages',
                          style: Theme.of(context).textTheme.headline6),
                    ),
                    //Build messages List
                    _messageList(_size),
                  ]),
            ),
          )
        : SizedBox(
            height: _size.height - 100,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: color_4),
                onPressed: () async {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (builder) {
                    return const SignInSignUp();
                  }), (route) => false);
                },
                child: Text('Sign In', style: button_1),
              ),
            ),
          );
  }

  @override
  void initState() {
    super.initState();
    _getMessageStream();
    unread = _getUnreadMessages();
  }

  //Search Box
  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color_7)),
      child: TextFormField(
        initialValue: '',
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search your message',
            focusColor: color_10),
        onChanged: (val) {
          setState(() {
            _searchWord = val;
          });
        },
      ),
    );
  }

  _getMessageStream() {
    messageStream = db.getChatRoomPerUser(userId: widget.userId);
  }

  //build messages list
  Widget _messageList(Size size) {
    chatList.clear();
    return StreamBuilder<QuerySnapshot>(
      stream: messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        return SizedBox(
          height: size.height - 260,
          child: snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) {
                    //var unreadMessage = _getUnreadMessages();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (builder) => ConversationScreen(
                                otherUser: snapshot.data?.docs[index]
                                    [ChatRoomParameters.chattingWith],
                                currentUser: widget.userModel,
                                chatRoomId: snapshot.data?.docs[index].id,
                                // markRead: markAsRead,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Container(
                            height: 60,
                            width: 60,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: CircleAvatar(
                                backgroundImage: snapshot.data?.docs[index]
                                            [UserParams.AVATAR] !=
                                        null
                                    ? NetworkImage(
                                        snapshot.data?.docs[index]
                                            [UserParams.AVATAR],
                                      )
                                    : Image.asset(
                                            'assets/images/empty_profile_photo.png')
                                        .image,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                width: size.width / 2,
                                child: Text(
                                  '${snapshot.data?.docs[index][UserParams.FIRST_NAME]} ${snapshot.data?.docs[index][UserParams.LAST_NAME]}',
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              FutureBuilder(
                                  future: unread,
                                  builder: (context, AsyncSnapshot snapshot) {
                                    if (snapshot.hasData) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (snapshot.data.isNotEmpty) {
                                          if (snapshot.data[index]['unread'] >
                                              0) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                  color: Colors.red),
                                              width: 35,
                                              height: 35,
                                              alignment: Alignment.center,
                                              child: Text(
                                                snapshot.data[index]['unread']
                                                    .toString(),
                                              ),
                                            );
                                          }
                                        }
                                        return SizedBox.shrink();
                                      }
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          width: 35,
                                          height: 35,
                                          alignment: Alignment.center,
                                          child: CircularProgressIndicator(
                                            color: color_4,
                                          ),
                                        );
                                      }
                                      return SizedBox.shrink();
                                    } else {
                                      return SizedBox.shrink();
                                    }
                                  }),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
              : Center(
                  child: Text(
                    'No Messages were found',
                    style: textStyle_13,
                  ),
                ),
        );
      },
    );
  }

  //Mark messages as read when chat is accessed
  markAsRead() async {
    unread = _getUnreadMessages();
    print('the unread: $unread');
  }

  Future<List<Map<String, dynamic>>> _getUnreadMessages() async {
    var userChats = await db.getChatRoomFuturePerUser(userId: widget.userId);

    for (var chat in userChats) {
      var unreadChats =
          await db.getUnreadMessages(chatRoomId: chat, userId: widget.userId);
      if (!chatList.contains(chat)) {
        chatList.add({'chatId': chat, 'unread': unreadChats});
      }
    }
    print('the chatList: $chatList');
    return chatList;
  }
}
