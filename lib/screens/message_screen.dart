import 'package:flutter/material.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key, this.userId}) : super(key: key);
  final String? userId;
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late String _searchWord;
  late List<Map<String, dynamic>> messageList = [];
  @override
  Widget build(BuildContext context) {
    var _size = MediaQuery.of(context).size;

    return widget.userId != null
        ? Container(
            height: _size.height - 100,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Build Search box
                    _searchBox(),
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
                    return SignInSignUp();
                  }), (route) => false);
                },
                child: Text('Sign In', style: button_1),
              ),
            ),
          );
    ;
  }

  //Search Box
  Widget _searchBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

  //build messages list
  Widget _messageList(Size size) {
    return SizedBox(
      height: size.height - 260,
      child: messageList != null && messageList.isNotEmpty
          ? ListView.builder(
              itemCount: messageList.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {},
                  child: ListTile(
                    title: messageList[index]['messageFrom'],
                    subtitle: messageList[index]['messageContent'],
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
  }
}
