import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/models/user_model.dart';
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
              print('users followed: ${widget.userFollowed[index]!.avatarUrl}');

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: widget.userFollowed[index]?.avatarUrl != null
                      ? SizedBox(
                          height: 50,
                          width: 75,
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
                          width: 75,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                  title: Text(
                      '${widget.userFollowed[index]!.firstName} ${widget.userFollowed[index]!.lastName}'),
                ),
              );
            }),
      );
    }
    if (widget.usersFollowing.isNotEmpty) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
            itemCount: widget.usersFollowing.length,
            itemBuilder: (context, index) {
              print(
                  'users followed: ${widget.usersFollowing[index]!.firstName}');

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: widget.usersFollowing[index]?.avatarUrl != null
                      ? SizedBox(
                          height: 50,
                          width: 75,
                          child: FittedBox(
                            child: Image.network(
                                widget.usersFollowing[index]!.avatarUrl!),
                            fit: BoxFit.fill,
                          ),
                        )
                      : Container(
                          height: 50,
                          width: 75,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                  title: Text(
                      '${widget.usersFollowing[index]!.firstName} ${widget.usersFollowing[index]!.lastName}'),
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
