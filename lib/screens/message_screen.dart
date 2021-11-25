import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/messaging/conversation_screen.dart';
import 'package:rillliveapp/models/message_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
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
  String? _searchWord = '';
  late List<Map<String, dynamic>> messageList = [];
  var unread;
  late List<Map<String, dynamic>> chatList = [];
  List<UserModel> _userFollowingMe = [];
  var _searchedList;
  var _size;
  //Controllers
  DatabaseService db = DatabaseService();
  ChatRoomModel chatRoomMap = ChatRoomModel();

  //Streams
  late Stream<QuerySnapshot> messageStream;
  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return widget.userId != null
        ? SizedBox(
            height: _size.height - 100,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
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
                            icon: Image.asset(
                              'assets/icons/add_rill.png',
                              color: color_4,
                              height: 30,
                            ),
                            onPressed: () {
                              //show buttom modal
                              _buildFollowersList();
                            },
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
    chatRoomMap = ChatRoomModel(userId: '', users: []);
    unread = _getUnreadMessages();
  }

  //Search Box
  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
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

  _buildSearchListFilter(String text) {
    var result = [];
    //wait for stream to populate
    if (text.isEmpty) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _searchedList = messageStream;
        });
      });
      return;
    }
    if (messageStream != null) {
      // .where(
      //   (_user) => _user.firstName
      //       .toString()
      //       .toLowerCase()
      //       .contains(text.toString().toLowerCase()),
      // )
      // .toList();
      setState(() {
        _searchedList = result;
      });
    }
  }

  _getFollowers() {
    var result = db.getFollowersList(userId: widget.userId);

    return result;
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
                          leading: SizedBox(
                            height: 60,
                            width: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: snapshot.data?.docs[index]
                                                [UserParams.AVATAR] !=
                                            null
                                        ? NetworkImage(
                                            snapshot.data?.docs[index]
                                                [UserParams.AVATAR],
                                          )
                                        : Image.asset(
                                                'assets/images/empty_profile_photo.png')
                                            .image,
                                    fit: BoxFit.fill),
                              ),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
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

  _buildFollowersList() async {
    showModalBottomSheet<dynamic>(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (builder) {
          return Wrap(children: [
            Container(
                padding: EdgeInsets.all(10),
                height: 5 * _size.height / 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: FutureBuilder(
                    future: _getFollowers(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          padding: EdgeInsets.all(10),
                          height: 80,
                          child: ListView.builder(
                              itemCount: snapshot.data.length,
                              itemBuilder: (builder, index) {
                                //Fill the list of users following
                                _userFollowingMe.add(UserModel(
                                  userId: snapshot.data[index].id,
                                  firstName: snapshot.data[index]
                                      [UserParams.FIRST_NAME],
                                  lastName: snapshot.data[index]
                                      [UserParams.LAST_NAME],
                                  avatarUrl: snapshot.data[index]
                                      [UserParams.AVATAR],
                                ));

                                return GestureDetector(
                                  onTap: () async {
                                    if (_userFollowingMe.isNotEmpty) {
                                      await _openMessageConversation(
                                          userFollowingMe:
                                              _userFollowingMe[index]);
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.grey,
                                            spreadRadius: 3,
                                            blurRadius: 2,
                                            offset: Offset(0, 2),
                                          )
                                        ]),
                                    child: ListTile(
                                      leading: Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: snapshot.data[index]
                                                          [UserParams.AVATAR] !=
                                                      null
                                                  ? NetworkImage(
                                                      snapshot.data[index]
                                                          [UserParams.AVATAR])
                                                  : Image.asset(
                                                          'assets/images/empty_profile_photo.png')
                                                      .image,
                                              fit: BoxFit.fill),
                                        ),
                                      ),
                                      title: Text(
                                          '${snapshot.data[index][UserParams.FIRST_NAME]} ${snapshot.data[index][UserParams.LAST_NAME]}'),
                                    ),
                                  ),
                                );
                              }),
                        );
                      } else {
                        return const Center(
                          child: LoadingAmination(
                            animationType: 'ThreeInOut',
                          ),
                        );
                      }
                    })),
          ]);
        });
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
    return chatList;
  }

  Future _openMessageConversation({UserModel? userFollowingMe}) async {
    if (chatRoomMap.users!.isNotEmpty) {
      chatRoomMap.users!.clear();
    }

    var chatRoomId = '${widget.userId}${userFollowingMe?.userId}';

    chatRoomMap.users!.add(widget.userId!);
    chatRoomMap.users!.add(userFollowingMe!.userId!);
    //check if chatroom exists
    var result = await db.getChatRoom(
        chattingWith: userFollowingMe.userId, userId: widget.userId);
    if (result.isEmpty) {
      await db.createChatRoom(
          userTwoId: userFollowingMe.userId,
          userNameTwo: userFollowingMe.userName ?? '',
          firstNameTwo: userFollowingMe.firstName,
          lastNameTwo: userFollowingMe.lastName,
          avatarUrlTwo: userFollowingMe.avatarUrl,
          userOneId: widget.userModel!.userId,
          userNameOne: widget.userModel!.userName ?? '',
          firstNameOne: widget.userModel!.firstName,
          lastNameOne: widget.userModel!.lastName,
          avatarUrlOne: widget.userModel!.avatarUrl,
          chatRoomId: chatRoomId,
          chatRoomMap: chatRoomMap);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => ConversationScreen(
          otherUser: userFollowingMe.userId,
          currentUser: widget.userModel,
          chatRoomId: result.isEmpty ? chatRoomId : result,
        ),
      ),
    );
  }
}
