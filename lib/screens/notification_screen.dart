import 'package:flutter/material.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key, this.title, this.content, this.type})
      : super(key: key);
  final String? title;
  final String? content;
  final String? type;
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color_4,
        title: Text('Notifications'),
      ),
      body: _buildMessageScreen(),
    );
  }

  Widget _buildMessageScreen() {
    var size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.all(15),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        height: size.height,
        child: Column(
          children: [
            ListTile(
                title: Text(widget.title!), subtitle: Text(widget.content!)),
          ],
        ),
      ),
    );
  }
}
