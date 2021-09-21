import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:rillliveapp/shared/video_viewer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class DatabaseService {
  DatabaseService({this.userId});
  final String? userId;

  //Define collections
  final CollectionReference userModelCollection =
      FirebaseFirestore.instance.collection('user_model');
  final CollectionReference liveStreamingCollection =
      FirebaseFirestore.instance.collection('live_streaming');
  final CollectionReference imageVideoCollection =
      FirebaseFirestore.instance.collection('images_videos');

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
      String? userName,
      String? thumbnailUrl,
      String? resourceId,
      String? sid}) async {
    try {
      var result = await liveStreamingCollection.add({
        LiveStreamingParams.USER_ID: userId,
        LiveStreamingParams.CHANNEL_NAME: channelName,
        LiveStreamingParams.TOKEN: token,
        LiveStreamingParams.URL: thumbnailUrl,
        LiveStreamingParams.resouceId: resourceId,
        LiveStreamingParams.sid: sid,
      }).then((value) => value.id);

      return result;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  //Delete data stream
  Future<void> deleteStreamingVideo({String? streamId}) async {
    try {
      await liveStreamingCollection.doc(streamId).delete();
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //Map streaming video
  List<StreamingModel?> _mapStreamsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return StreamingModel(
          uid: doc.id,
          userId: (doc.data() as Map)[LiveStreamingParams.USER_ID],
          channelName: (doc.data() as Map)[LiveStreamingParams.CHANNEL_NAME],
          url: (doc.data() as Map)[LiveStreamingParams.URL],
          tags: (doc.data() as Map)[LiveStreamingParams.TAGS],
          token: (doc.data() as Map)[LiveStreamingParams.TOKEN],
          thumbnailUrl: (doc.data() as Map)[LiveStreamingParams.URL],
          resourceId: (doc.data() as Map)[LiveStreamingParams.resouceId],
          sid: (doc.data() as Map)[LiveStreamingParams.sid]);
    }).toList();
  }

  Stream<List<StreamingModel?>> getStreamingVidoes() {
    return liveStreamingCollection.snapshots().map(_mapStreamsFromSnapshot);
  }

  //fetch all streaming videos
  Future<String> fetchStreamingVideoUrl({String? uid}) async {
    try {
      return await liveStreamingCollection
          .doc(uid)
          .get()
          .then((value) => (value.data() as Map)[LiveStreamingParams.USER_ID]);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return '';
    }
  }

  //This section is to create, update and delete images in the database
  //Add Video
  Future<String> createImageVideo(
      {String? userId,
      String? name,
      String? url,
      List<String>? tags,
      String? type}) async {
    try {
      var result = await imageVideoCollection.add({
        ImageVideoParams.USER_ID: userId,
        ImageVideoParams.NAME: name,
        ImageVideoParams.URL: url,
        ImageVideoParams.TAGS: tags,
        ImageVideoParams.TYPE: type,
      }).then((value) => value.id);
      return result;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  //update image file by id
  Future<String?> updateImage(
      {String? uid,
      String? userId,
      String? name,
      String? url,
      List<String>? tags}) async {
    try {
      await imageVideoCollection.doc(uid).update({
        ImageVideoParams.USER_ID: userId,
        ImageVideoParams.NAME: name,
        ImageVideoParams.URL: url,
        ImageVideoParams.TAGS: tags,
      });
      print('$name has been updated');
      return '$name has been updated';
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  //Map image file
  List<ImageVideoModel?> _mapImageFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return ImageVideoModel(
        uid: doc.id,
        userId: (doc.data() as Map)[ImageVideoParams.USER_ID],
        name: (doc.data() as Map)[ImageVideoParams.NAME],
        url: (doc.data() as Map)[ImageVideoParams.URL],
        tags: (doc.data() as Map)[ImageVideoParams.TAGS],
        type: (doc.data() as Map)[ImageVideoParams.TYPE],
      );
    }).toList();
  }

  //Stream image file
  Stream<List<ImageVideoModel?>> getImageList() {
    return imageVideoCollection.snapshots().map(_mapImageFromSnapshot);
  }

  //Delete Image
  Future<String?> deleteImage({String? uid, String? name}) async {
    try {
      await imageVideoCollection.doc(uid).delete();
      return '$name has been deleted';
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }
}
