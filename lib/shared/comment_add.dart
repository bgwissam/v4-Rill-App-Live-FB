import 'package:flutter/material.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class CommentAdd extends StatefulWidget {
  const CommentAdd({Key? key}) : super(key: key);

  @override
  _CommentAddState createState() => _CommentAddState();
}

class _CommentAddState extends State<CommentAdd> {
  late String _newComment;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: 80,
          width: double.infinity,
          child: Row(
            children: [
              //TextField
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: '',
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: color_4)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _newComment = val.trim();
                    });
                  },
                ),
              ),
              SizedBox(width: 4),
              //Send comment
              Expanded(
                flex: 1,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: color_4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'Send',
                      style: button_1,
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
