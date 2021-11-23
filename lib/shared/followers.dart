import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/messaging/chat_room.dart';
import 'package:rillliveapp/messaging/conversation_screen.dart';
import 'package:rillliveapp/models/message_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class Followers extends StatefulWidget {
  const Followers(
      {Key? key,
      this.userModel,
      this.followers,
      required this.userFollowed,
      required this.usersFollowing})
      : super(key: key);
  final UserModel? userModel;
  final List<UsersFollowing?> usersFollowing;
  final List<UsersFollowed?> userFollowed;
  final bool? followers;
  @override
  _FollowersState createState() => _FollowersState();
}

class _FollowersState extends State<Followers> {
  late Size _size;
  //Providers
  var provider;
  DatabaseService db = DatabaseService();
  ChatRoomModel chatRoomMap = ChatRoomModel();
  @override
  void initState() {
    super.initState();
    chatRoomMap = ChatRoomModel(userId: '', users: []);
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color_4,
        title: widget.followers!
            ? Text(
                'Followers',
                style: textStyle_4,
              )
            : Text(
                'Following',
                style: textStyle_4,
              ),
      ),
      body: _buildFollowList(),
    );
  }

  //Build the list of followers or following
  Widget _buildFollowList() {
    if (widget.userFollowed.isNotEmpty) {
      return SizedBox(
        height: _size.height,
        child: ListView.builder(
            itemCount: widget.userFollowed.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: widget.userFollowed[index]?.avatarUrl != null
                      ? SizedBox(
                          height: 50,
                          width: 50,
                          child: FittedBox(
                            child: CachedNetworkImage(
                              imageUrl: widget.userFollowed[index]!.avatarUrl!,
                              progressIndicatorBuilder:
                                  (context, url, progress) => const Padding(
                                padding: const EdgeInsets.all(4.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                            ),
                            fit: BoxFit.fill,
                          ),
                        )
                      : Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${widget.userFollowed[index]!.firstName} ${widget.userFollowed[index]!.lastName}',
                          style: textStyle_1,
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith(
                                (states) => color_4),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25))),
                          ),
                          child: Text('Message', style: textStyle_4),
                          onPressed: () async {
                            if (chatRoomMap.users!.isNotEmpty) {
                              chatRoomMap.users!.clear();
                            }

                            var chatRoomId =
                                '${widget.userModel!.userId}${widget.userFollowed[index]!.userId}';

                            chatRoomMap.users!.add(widget.userModel!.userId!);
                            chatRoomMap.users!
                                .add(widget.userFollowed[index]!.userId!);

                            //check if chatroom exists
                            var result = await db.getChatRoom(
                                chattingWith:
                                    widget.userFollowed[index]!.userId!,
                                userId: widget.userModel!.userId);
                            print('the result of getting room: $result');
                            if (result.isEmpty) {
                              //create a chat room if it doesn't exist
                              await db.createChatRoom(
                                  userOneId: widget.userModel!.userId,
                                  // userNameOne: widget.userModel!.userName ?? '',
                                  firstNameOne: widget.userModel!.firstName,
                                  lastNameOne: widget.userModel!.lastName,
                                  avatarUrlOne: widget.userModel!.avatarUrl,
                                  userTwoId: widget.userFollowed[index]!.userId,
                                  userNameTwo:
                                      widget.userFollowed[index]!.userName ??
                                          '',
                                  firstNameTwo:
                                      widget.userFollowed[index]!.firstName,
                                  lastNameTwo:
                                      widget.userFollowed[index]!.lastName,
                                  avatarUrlTwo:
                                      widget.userFollowed[index]!.avatarUrl,
                                  chatRoomId: chatRoomId,
                                  chatRoomMap: chatRoomMap);
                            }

                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (builder) => ConversationScreen(
                                          currentUser: widget.userModel,
                                          chatRoomId: result.isEmpty
                                              ? chatRoomId
                                              : result,
                                        )));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      );
    }
    if (widget.usersFollowing.isNotEmpty) {
      return SizedBox(
        height: _size.height,
        child: ListView.builder(
            itemCount: widget.usersFollowing.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: widget.usersFollowing[index]?.avatarUrl != null
                      ? SizedBox(
                          height: 50,
                          width: 50,
                          child: FittedBox(
                            child: Image.network(
                                widget.usersFollowing[index]!.avatarUrl!),
                            fit: BoxFit.fill,
                          ),
                        )
                      : Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                  title: Text(
                      '${widget.usersFollowing[index]!.firstName} ${widget.usersFollowing[index]!.lastName}'),
                  subtitle: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(50)),
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateColor.resolveWith((states) => color_4),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25))),
                      ),
                      child: Text('Message', style: textStyle_4),
                      onPressed: () async {
                        if (chatRoomMap.users!.isNotEmpty) {
                          chatRoomMap.users!.clear();
                        }

                        var chatRoomId =
                            '${widget.userModel!.userId}${widget.usersFollowing[index]!.userId}';

                        chatRoomMap.users!.add(widget.userModel!.userId!);
                        chatRoomMap.users!
                            .add(widget.usersFollowing[index]!.userId!);
                        //check if chatroom exists
                        var result = await db.getChatRoom(
                            chattingWith: widget.usersFollowing[index]!.userId!,
                            userId: widget.userModel!.userId);
                        print('the result of getting room: $result');

                        if (result.isEmpty) {
                          await db.createChatRoom(
                              userOneId: widget.userModel!.userId,
                              // userNameOne: widget.userModel!.userName ?? '',
                              firstNameOne: widget.userModel!.firstName,
                              lastNameOne: widget.userModel!.lastName,
                              avatarUrlOne: widget.userModel!.avatarUrl,
                              userTwoId: widget.usersFollowing[index]!.userId,
                              userNameTwo:
                                  widget.usersFollowing[index]!.userName ?? '',
                              firstNameTwo:
                                  widget.usersFollowing[index]!.firstName,
                              lastNameTwo:
                                  widget.usersFollowing[index]!.lastName,
                              avatarUrlTwo:
                                  widget.usersFollowing[index]!.avatarUrl,
                              chatRoomId: chatRoomId,
                              chatRoomMap: chatRoomMap);
                        }

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => ConversationScreen(
                              currentUser: widget.userModel,
                              chatRoomId: result.isEmpty ? chatRoomId : result,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
      );
    }

    return Center(
        child: widget.followers!
            ? Text(
                'No followers were found :(',
                style: textStyle_3,
              )
            : Text(
                'You are not following anyone :(',
                style: textStyle_3,
              ));
  }
}
