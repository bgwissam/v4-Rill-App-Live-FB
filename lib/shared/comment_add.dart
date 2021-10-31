import 'package:flutter/material.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class CommentAdd extends StatefulWidget {
  const CommentAdd({Key? key, this.userModel, this.collection, this.fileId})
      : super(key: key);
  final UserModel? userModel;
  final String? collection;
  final String? fileId;
  @override
  _CommentAddState createState() => _CommentAddState();
}

class _CommentAddState extends State<CommentAdd> {
  late String _newComment;
  TextEditingController _commentController = TextEditingController();
  //services
  DatabaseService db = DatabaseService();
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            right: 10,
            left: 10),
        child: SizedBox(
          height: 80,
          width: double.infinity,
          child: Row(
            children: [
              //TextField
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Image.asset('assets/icons/send_rill.png',
                          color: color_4),
                      onPressed: () async {
                        await db.addComment(
                            uid: widget.fileId,
                            userId: widget.userModel!.userId,
                            comment: _newComment,
                            collection: widget.collection,
                            dateTime: DateTime.now(),
                            fullName:
                                '${widget.userModel!.firstName} ${widget.userModel!.lastName}');
                        setState(() {
                          _newComment = '';
                          _commentController.clear();
                          FocusScopeNode currentFocus = FocusScope.of(context);
                          if (!currentFocus.hasPrimaryFocus) {
                            currentFocus.unfocus();
                          }
                        });
                      },
                    ),
                    prefixIcon: Image.asset(
                      'assets/icons/pop_rill_icon_light.png',
                      height: 17,
                      color: color_4,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
              // Expanded(
              //   flex: 1,
              //   child: ElevatedButton(
              //       style: ElevatedButton.styleFrom(
              //         primary: color_4,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(25.0),
              //         ),
              //       ),
              //       onPressed: () async {
              //         await db.addComment(
              //             uid: widget.fileId,
              //             userId: widget.userModel!.userId,
              //             comment: _newComment,
              //             collection: widget.collection,
              //             dateTime: DateTime.now(),
              //             fullName:
              //                 '${widget.userModel!.firstName} ${widget.userModel!.lastName}');
              //         setState(() {
              //           _newComment = '';
              //           _commentController.clear();
              //           FocusScopeNode currentFocus = FocusScope.of(context);
              //           if (!currentFocus.hasPrimaryFocus) {
              //             currentFocus.unfocus();
              //           }
              //         });
              //       },
              //       child: Text(
              //         'Send',
              //         style: button_1,
              //       )),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
