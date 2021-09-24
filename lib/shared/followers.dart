import 'package:flutter/material.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class Followers extends StatefulWidget {
  const Followers({Key? key, this.userModel, this.followers}) : super(key: key);
  final UserModel? userModel;
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
    return provider != null
        ? Container(
            height: _size.height / 10,
            child: ListView.builder(
                itemCount: provider.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: provider[index].avatarUrl,
                    title: Text(
                        '${provider[index].firstName} ${provider[index].lastName}'),
                  );
                }),
          )
        : Center(
            child: Text(
            'Data could not be obtained!',
            style: textStyle_3,
          ));
  }
}
