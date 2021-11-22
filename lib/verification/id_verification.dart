import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:path/path.dart' as Path;

class IdVerification extends StatefulWidget {
  const IdVerification({Key? key, this.userModel}) : super(key: key);
  final UserModel? userModel;

  @override
  _IdVerificationState createState() => _IdVerificationState();
}

class _IdVerificationState extends State<IdVerification> {
  final _formKey = GlobalKey<FormState>();
  var size;
  File? profileImage;
  File? frontId;
  File? backId;
  String? frontIdUrl;
  String? backIdUrl;
  String? fullName;
  String? address;
  //Services
  final ImagePicker _picker = ImagePicker();
  late FirebaseStorage storageReferece;
  DatabaseService db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(child: _buildIdVerification()));
  }

  Widget _buildIdVerification() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
      child: SizedBox(
          height: size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //will build the title UI text
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('Profile Verification',
                    textAlign: TextAlign.left, style: textStyle_3),
              ),
              //Will build the seciont that should show if profile is verified
              widget.userModel != null
                  ? Container(child: _buildProfileVerification())
                  : const SizedBox.shrink(),
              //UI text apply for profile
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('Apply for Profile Verification',
                    textAlign: TextAlign.left, style: textStyle_3),
              ),
              //Build full name and location text
              _buildUserDetailsForm(),

              //Will build the section for uploading front and back ids
              widget.userModel != null
                  ? SizedBox(
                      height: 180,
                      width: size.width,
                      child: _supportingDocuments())
                  : const SizedBox.shrink(),

              //Apply for verification button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: size.width,
                  child: TextButton(
                      style: TextButton.styleFrom(backgroundColor: color_4),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        if (frontId != null && backId != null) {
                          storageReferece = FirebaseStorage.instance;
                          Reference refFront = storageReferece.ref().child(
                              'verification_id/${Path.basename(frontId!.path)}');
                          Reference refBack = storageReferece.ref().child(
                              'verification_id/${Path.basename(backId!.path)}');
                          UploadTask uploadTaskFront =
                              refFront.putFile(File(frontId!.path));
                          UploadTask uploadTaskBack =
                              refBack.putFile(File(backId!.path));

                          var downloadFrontImageUrl =
                              await (await uploadTaskFront)
                                  .ref
                                  .getDownloadURL();
                          var downloadBackImageUrl =
                              await (await uploadTaskBack).ref.getDownloadURL();
                          frontIdUrl = downloadFrontImageUrl.toString();
                          backIdUrl = downloadBackImageUrl.toString();
                          if (frontIdUrl != null && backIdUrl != null) {
                            await db.verifyUser(
                                userId: widget.userModel!.userId,
                                frontIdUrl: frontIdUrl,
                                backIdUrl: backIdUrl);
                          }
                        }
                      },
                      child: Text(
                        'Apply',
                        style: textStyle_20,
                      )),
                ),
              ),
            ],
          )),
    );
  }

  //User details form
  Widget _buildUserDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //full name
          TextFormField(
            initialValue: '',
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Full name',
              hintStyle: textStyle_22,
            ),
            validator: (val) {
              if (val != null && val.isEmpty) {
                return 'full name is required';
              }
              return null;
            },
            onChanged: (val) {
              setState(() {
                fullName = val.trim().toString();
              });
            },
          ),

          //address
          TextFormField(
            initialValue: '',
            decoration:
                InputDecoration(hintText: 'Address', hintStyle: textStyle_22),
            validator: (val) {
              if (val != null && val.isEmpty) {
                return 'address is required';
              }
              return null;
            },
            onChanged: (val) {
              setState(() {
                address = val.trim().toString();
              });
            },
          )
        ],
      ),
    );
  }

  //Shows if the profile is verified
  Widget _buildProfileVerification() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Image.asset(
                      'assets/icons/verified_rill_icon.png',
                      color: color_4,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ListTile(
                        title: Text('Status'),
                        subtitle: widget.userModel?.isIdVerified != null
                            ? Text('${widget.userModel?.isIdVerified}')
                            : Text('Not Applied')),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                          'Verification bade helps you distinguish yourself from scammers and fake profiles',
                          style: textStyle_16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportingDocuments() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Supporting Documents', style: textStyle_18),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                //Front id side
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        _showPicker(context, 'frontId');
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        height: 120,
                        decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey[100]),
                        child: frontId == null &&
                                widget.userModel?.frontIdUrl == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                    Expanded(
                                      child: Image.asset(
                                          'assets/icons/add_rill.png',
                                          color: color_4),
                                    ),
                                    Expanded(
                                        child: Text(
                                            'Upload Front Side of a recognised ID proof',
                                            textAlign: TextAlign.center,
                                            style: textStyle_17)),
                                  ])
                            : frontId != null
                                ? Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: FileImage(frontId!),
                                          fit: BoxFit.fill),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: NetworkImage(
                                                widget.userModel!.frontIdUrl!),
                                            fit: BoxFit.fill)),
                                  ),
                      ),
                    ),
                  ),
                ),
                //Back id side
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        _showPicker(context, 'backId');
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        height: 120,
                        decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey[100]),
                        child: backId == null &&
                                widget.userModel?.backIdUrl == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                    Expanded(
                                      child: Image.asset(
                                          'assets/icons/add_rill.png',
                                          color: color_4),
                                    ),
                                    Expanded(
                                        child: Text(
                                            'Upload Back Side of a recognised ID proof',
                                            textAlign: TextAlign.center,
                                            style: textStyle_17)),
                                  ])
                            : backId != null
                                ? Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: FileImage(backId!),
                                          fit: BoxFit.fill),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: NetworkImage(
                                                widget.userModel!.backIdUrl!),
                                            fit: BoxFit.fill)),
                                  ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  File? _showPicker(context, String imageType) {
    showModalBottomSheet(
        backgroundColor: color_4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        context: context,
        builder: (BuildContext bc) {
          return Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Gallery'),
                    onTap: () {
                      _imgFromGallery(imageType);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text('Camera'),
                  onTap: () {
                    _imgFromCamera(imageType);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  //Image picker from Gallery
  Future _imgFromGallery(String imageType) async {
    final pickedImage =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 25);

    setState(() {
      if (pickedImage != null) {
        switch (imageType) {
          case 'profilePic':
            profileImage = File(pickedImage.path);
            break;
          case 'frontId':
            frontId = File(pickedImage.path);
            break;
          case 'backId':
            backId = File(pickedImage.path);
            break;
        }
      }
    });
  }

  //image picker from camera
  Future _imgFromCamera(String imageType) async {
    final pickedImage =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 25);

    setState(() {
      if (pickedImage != null) {
        switch (imageType) {
          case 'profilePic':
            profileImage = File(pickedImage.path);
            break;
          case 'frontId':
            frontId = File(pickedImage.path);
            break;
          case 'backId':
            backId = File(pickedImage.path);
            break;
        }
      }
    });
  }
}
