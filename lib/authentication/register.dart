import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:rillliveapp/authentication/email_confirmation.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';

enum ImageSourceType { gallery, camera }

class Register extends StatefulWidget {
  const Register({Key? key, this.userModel}) : super(key: key);
  final UserModel? userModel;
  @override
  RegisterState createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController(text: "");

  final ImagePicker _picker = ImagePicker();

  //image picker
  Future _imgFromCamera() async {
    final pickedImage =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 25);

    setState(() {
      if (pickedImage != null) {
        image = File(pickedImage.path);
      }
    });
  }

  Future _imgFromGallery() async {
    final pickedImage =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 25);

    setState(() {
      if (pickedImage != null) {
        image = File(pickedImage.path);
      }
    });
  }

  bool showPassword = true;

  @override
  void initState() {
    showPassword = false;
  }

  //datcPicker

  //Method for showing the date picker
  void _pickDateDialog() {
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            //which date will display when user open the picker
            firstDate: DateTime(1950),
            //what will be the previous supported year in picker
            lastDate: DateTime
                .now()) //what will be the up to supported date in picker
        .then((pickedDate) {
      //then usually do the future job
      if (pickedDate == null) {
        //if user tap cancel then this function will stop
        return;
      }
      setState(() {
        //for rebuilding the ui
        _selectedDate = pickedDate;
      });
    });
  }

  late String username;
  DateTime? _selectedDate;
  File? image;

  String? password;
  late String emailAddress;
  String? firstname;
  String? lastname;
  String? address;
  String? mobile;
  String? avatarUrl;
  String? phoneNumber;
  String? bioDescription;

  late String errorMessage = '';
  //Services
  AuthService as = AuthService();
  DatabaseService db = DatabaseService();

  //Show Image Picker

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(35),
              ),
              child: Wrap(
                children: <Widget>[
                  ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Gallery'),
                      onTap: () {
                        _imgFromGallery();
                        Navigator.of(context).pop();
                      }),
                  ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Camera'),
                    onTap: () {
                      _imgFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var _size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: widget.userModel == null
            ? Text('Create Account')
            : Text('Update Account'),
        backgroundColor: color_4,
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                //in case it's a new user
                if (widget.userModel == null) {
                  var result = await as.signUp(
                      userName: username,
                      password: password,
                      firstName: firstname,
                      lastName: lastname,
                      emailAddress: emailAddress,
                      avatarUrl: avatarUrl,
                      bioDescription: bioDescription,
                      mobileNumber: mobile,
                      address: address);
                  print('the result of registering is: $result');
                  if (result.isNotEmpty) {
                    //Navigatore to verification page in order to enter OTP
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (builder) => EmailConfirmation(),
                      ),
                    );
                  } else {
                    setState(() {
                      errorMessage = 'Email address already exists';
                    });
                  }
                }
              }
              //In case we are updating a current user
              else {}
            },
            child: Text(
              widget.userModel == null ? 'Save' : 'Update',
              style: TextStyle(color: color_9),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: SizedBox(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _showPicker(context);
                        print("Add an Image");
                      },
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.black12,
                        child: image == null
                            ? const Icon(
                                Icons.add_a_photo_outlined,
                                size: 40,
                                color: Colors.white,
                              )
                            : const Text('Image selected'),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Username
                          widget.userModel == null
                              ? TextFormField(
                                  initialValue: '',
                                  decoration: const InputDecoration(
                                      hintText: 'User Name', filled: false),
                                  validator: (val) => val != null
                                      ? null
                                      : 'User name is required',
                                  onChanged: (val) {
                                    setState(() {
                                      username = val;
                                    });
                                  },
                                )
                              : SizedBox.shrink(),
                          //Password
                          widget.userModel == null
                              ? TextFormField(
                                  keyboardType: TextInputType.text,
                                  controller: passwordController,
                                  enableInteractiveSelection: true,
                                  obscureText: !showPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          showPassword = !showPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (val) => val != null
                                      ? null
                                      : 'Password is required',
                                  onChanged: (val) {
                                    setState(() {
                                      password = val;
                                    });
                                  },
                                )
                              : SizedBox.shrink(),
                          //Email address
                          widget.userModel == null
                              ? TextFormField(
                                  initialValue: '',
                                  decoration: const InputDecoration(
                                      hintText: 'Email Address', filled: false),
                                  validator: (val) => val != null
                                      ? null
                                      : 'Email address is required',
                                  onChanged: (val) {
                                    setState(() {
                                      emailAddress = val;
                                    });
                                  },
                                )
                              : SizedBox.shrink(),
                          const SizedBox(
                            height: 15,
                          ),
                          const Divider(
                            height: 5,
                            thickness: 2,
                            color: Colors.transparent,
                          ),

                          const Text(
                            "Personal Details",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 15),
                          //FirstName
                          TextFormField(
                            initialValue: widget.userModel?.firstName,
                            decoration: const InputDecoration(
                                hintText: 'First Name', filled: false),
                            validator: (val) =>
                                val != null ? null : 'First Name is required',
                            onChanged: (val) {
                              setState(() {
                                firstname = val;
                              });
                            },
                          ),
                          //Last name
                          TextFormField(
                            initialValue: widget.userModel?.lastName,
                            decoration: const InputDecoration(
                                hintText: 'Last Name', filled: false),
                            validator: (val) =>
                                val != null ? null : 'Last name is required',
                            onChanged: (val) {
                              setState(() {
                                lastname = val;
                              });
                            },
                          ),
                          SizedBox(
                            height: 12,
                          ),

                          //Address
                          TextFormField(
                            initialValue: '',
                            decoration: const InputDecoration(
                                hintText: 'Address', filled: false),
                            validator: (val) =>
                                val != null ? null : 'Address is required',
                            onChanged: (val) {
                              setState(() {
                                address = val;
                              });
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),

                          //Contact number
                          IntlPhoneField(
                            decoration: InputDecoration(
                              focusColor: Colors.grey,
                              labelText: 'Phone Number',
                            ),
                            initialCountryCode: 'IN',
                            onChanged: (phone) {
                              print(phone.completeNumber);
                              mobile = phone.toString();
                            },
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          //DateOfBirth
                          Row(
                            children: [
                              const Text(
                                'Date Of Birth :',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16),
                              ),
                              const SizedBox(height: 15),
                              TextButton(
                                child: Text(
                                  _selectedDate ==
                                          null //ternary expression to check if date is null
                                      ? 'Pick A Date!'
                                      : '${DateFormat.yMMMd().format(_selectedDate!)}',
                                  style: TextStyle(fontSize: 18),
                                ),
                                onPressed: _pickDateDialog,
                              ),
                            ],
                          ),

                          errorMessage.isNotEmpty
                              ? Expanded(
                                  child: Text(errorMessage, style: errorText),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
