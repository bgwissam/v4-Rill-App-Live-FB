import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class DatabaseService {
  DatabaseService({this.userId});
  final String? userId;

  //Define collections
  final CollectionReference userModelCollection =
      FirebaseFirestore.instance.collection('user_model');
  final CollectionReference liveStreamingCollection =
      FirebaseFirestore.instance.collection('live_streaming');

  //Create a new a user
  Future<String> createUser({
    String? userId,
    String? userName,
    String? emailAddress,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bioDescription,
    String? mobileNumber,
    String? dob,
    String? address,
    bool? isActive,
    List<String>? roles,
  }) async {
    try {
      return await userModelCollection.add({
        UserParams.USER_ID: userId,
        UserParams.EMAIL_ADDRESS: emailAddress,
        UserParams.FIRST_NAME: firstName,
        UserParams.LAST_NAME: lastName,
        UserParams.AVATAR: avatarUrl,
        UserParams.BIO_DESC: bioDescription,
        UserParams.PHONE: mobileNumber,
        UserParams.DOB: dob,
        UserParams.ADDRESS: address,
        UserParams.IS_ACTIVE: true,
        UserParams.ROLES: ['normalUser']
      }).then((value) => value.id);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e;
    }
  }

  //update a selected user
  Future<String?> updateUser({
    String? userId,
    String? userName,
    String? emailAddress,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bioDescription,
    String? mobileNumber,
    String? dob,
    String? address,
    bool? isActive,
    List<String>? roles,
  }) async {
    try {
      return await userModelCollection.doc(userId).update({
        UserParams.USER_ID: userId,
        UserParams.EMAIL_ADDRESS: emailAddress,
        UserParams.FIRST_NAME: firstName,
        UserParams.LAST_NAME: lastName,
        UserParams.AVATAR: avatarUrl,
        UserParams.BIO_DESC: bioDescription,
        UserParams.PHONE: mobileNumber,
        UserParams.DOB: dob,
        UserParams.ADDRESS: address,
        UserParams.IS_ACTIVE: true,
        UserParams.ROLES: ['normalUser']
      }).then((value) => 'user was successfully updated');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e;
    }
  }

  //Map user data
  List<UserModel> _userDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return UserModel(
          userId: (doc.data()! as Map)[UserParams.USER_ID],
          userName: (doc.data()! as Map)[UserParams.USER_NAME],
          emailAddress: (doc.data()! as Map)[UserParams.EMAIL_ADDRESS],
          firstName: (doc.data()! as Map)[UserParams.FIRST_NAME],
          lastName: (doc.data()! as Map)[UserParams.LAST_NAME],
          dob: (doc.data()! as Map)[UserParams.DOB],
          avatarUrl: (doc.data()! as Map)[UserParams.AVATAR],
          bioDescription: (doc.data()! as Map)[UserParams.BIO_DESC],
          phoneNumber: (doc.data()! as Map)[UserParams.PHONE],
          isActive: (doc.data()! as Map)[UserParams.IS_ACTIVE],
          roles: (doc.data()! as Map)[UserParams.ROLES]);
    }).toList();
  }

  //Stream data
  Stream<List<UserModel>> get userData {
    return userModelCollection.snapshots().map(_userDataFromSnapshot);
  }

  //get a user by user id
  Future<UserModel> getUserByUserId({String? userId}) async {
    return UserModel();
  }

  //delete a user
  Future<void> deleteUserByUserId({String? userId}) async {}

  //This section will handle uploading and retreiving data streams
  //Create a new data stream
  Future<dynamic> createNewDataStream(
      {String? channelName,
      String? token,
      String? userId,
      String? userName}) async {}

  //Delete data stream
  Future<void> deleteStreamingVideo({String? streamId}) async {}

  //Fetch streaming video per id
  Future<void> fetchStreamingVideobyId({String? id}) async {}

  //fetch all streaming videos
  Future<String> fetchStreamingVideoUrl() async {
    return '';
  }
}
