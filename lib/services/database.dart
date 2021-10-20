import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/message_model.dart';
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
  final CollectionReference followersCollection =
      FirebaseFirestore.instance.collection('followers');
  final CollectionReference followingCollection =
      FirebaseFirestore.instance.collection('following');
  final CollectionReference messagesCollection =
      FirebaseFirestore.instance.collection('messages');

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
    String? phoneIsoCode,
    String? phoneFullNumber,
    var dob,
    String? address,
    bool? isActive,
    List<String>? roles,
  }) async {
    try {
      return await userModelCollection.doc(userId).set({
        UserParams.USER_ID: userId,
        UserParams.USER_NAME: userName,
        UserParams.EMAIL_ADDRESS: emailAddress,
        UserParams.FIRST_NAME: firstName,
        UserParams.LAST_NAME: lastName,
        UserParams.AVATAR: avatarUrl,
        UserParams.BIO_DESC: bioDescription,
        UserParams.PHONE: mobileNumber,
        UserParams.PHONE_ISO: phoneIsoCode,
        UserParams.PHONE_FULL: phoneFullNumber,
        UserParams.DOB: dob,
        UserParams.ADDRESS: address,
        UserParams.IS_ACTIVE: true,
        UserParams.ROLES: ['normalUser']
      }).then((value) => 'user has been saved successfully');
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
    String? phoneIsoCode,
    String? phoneFullNumber,
    var dob,
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
        UserParams.PHONE_ISO: phoneIsoCode,
        UserParams.PHONE_FULL: phoneFullNumber,
        UserParams.DOB: dob,
        UserParams.ADDRESS: address,
        UserParams.IS_ACTIVE: true,
        UserParams.ROLES: ['normalUser']
      }).then((value) => 'user was successfully updated');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      print('Could not update: $e: $stackTrace');
      throw e;
    }
  }

  //Future to get users details
  Future<UserModel> getSelectedUserById({String? uid}) async {
    try {
      return await userModelCollection.doc(uid).get().then((doc) {
        return UserModel(
            userId: (doc.data()! as Map)[UserParams.USER_ID],
            userName: (doc.data()! as Map)[UserParams.USER_NAME],
            emailAddress: (doc.data()! as Map)[UserParams.EMAIL_ADDRESS],
            firstName: (doc.data()! as Map)[UserParams.FIRST_NAME],
            lastName: (doc.data()! as Map)[UserParams.LAST_NAME],
            dob: (doc.data()! as Map)[UserParams.DOB],
            address: (doc.data()! as Map)[UserParams.ADDRESS],
            avatarUrl: (doc.data()! as Map)[UserParams.AVATAR],
            bioDescription: (doc.data()! as Map)[UserParams.BIO_DESC],
            phoneNumber: (doc.data()! as Map)[UserParams.PHONE],
            phoneIsoCode: (doc.data()! as Map)[UserParams.PHONE_ISO],
            fcmToken: (doc.data()! as Map)[UserParams.FCM_TOKEN],
            phoneFullNumber: (doc.data()! as Map)[UserParams.PHONE_FULL],
            isActive: (doc.data()! as Map)[UserParams.IS_ACTIVE],
            roles: (doc.data()! as Map)[UserParams.ROLES]);
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return UserModel();
    }
  }

  //Map users data
  List<UserModel> _userDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return UserModel(
          userId: (doc.data()! as Map)[UserParams.USER_ID],
          userName: (doc.data()! as Map)[UserParams.USER_NAME],
          emailAddress: (doc.data()! as Map)[UserParams.EMAIL_ADDRESS],
          firstName: (doc.data()! as Map)[UserParams.FIRST_NAME],
          lastName: (doc.data()! as Map)[UserParams.LAST_NAME],
          dob: (doc.data()! as Map)[UserParams.DOB],
          address: (doc.data()! as Map)[UserParams.ADDRESS],
          avatarUrl: (doc.data()! as Map)[UserParams.AVATAR],
          bioDescription: (doc.data()! as Map)[UserParams.BIO_DESC],
          phoneNumber: (doc.data()! as Map)[UserParams.PHONE],
          phoneIsoCode: (doc.data()! as Map)[UserParams.PHONE_ISO],
          fcmToken: (doc.data()! as Map)[UserParams.FCM_TOKEN],
          phoneFullNumber: (doc.data()! as Map)[UserParams.PHONE_FULL],
          isActive: (doc.data()! as Map)[UserParams.IS_ACTIVE],
          roles: (doc.data()! as Map)[UserParams.ROLES]);
    }).toList();
  }

  //Map follower data
  List<UsersFollowing?> _followedDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return UsersFollowing(
        userId: doc.id,
        followerId: (doc.data()! as Map)[UserParams.USER_ID],
        firstName: (doc.data()! as Map)[UserParams.FIRST_NAME],
        lastName: (doc.data()! as Map)[UserParams.LAST_NAME],
        avatarUrl: (doc.data()! as Map)[UserParams.AVATAR],
      );
    }).toList();
  }

  //map following data
  List<UsersFollowed?> _followingDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return UsersFollowed(
        userId: doc.id,
        followerId: (doc.data()! as Map)[UserParams.USER_ID],
        firstName: (doc.data()! as Map)[UserParams.FIRST_NAME],
        lastName: (doc.data()! as Map)[UserParams.LAST_NAME],
        avatarUrl: (doc.data()! as Map)[UserParams.AVATAR],
      );
    }).toList();
  }

  //Stream data
  Stream<List<UserModel>> get userData {
    return userModelCollection.snapshots().map(_userDataFromSnapshot);
  }

  //Stream user by id
  Stream<UserModel> streamUserById({String? userId}) {
    return userModelCollection.doc(userId).snapshots().map((doc) {
      return UserModel(
          userId: (doc.data()! as Map)[UserParams.USER_ID],
          userName: (doc.data()! as Map)[UserParams.USER_NAME],
          emailAddress: (doc.data()! as Map)[UserParams.EMAIL_ADDRESS],
          firstName: (doc.data()! as Map)[UserParams.FIRST_NAME],
          lastName: (doc.data()! as Map)[UserParams.LAST_NAME],
          dob: (doc.data()! as Map)[UserParams.DOB],
          address: (doc.data()! as Map)[UserParams.ADDRESS],
          avatarUrl: (doc.data()! as Map)[UserParams.AVATAR],
          bioDescription: (doc.data()! as Map)[UserParams.BIO_DESC],
          phoneNumber: (doc.data()! as Map)[UserParams.PHONE],
          phoneIsoCode: (doc.data()! as Map)[UserParams.PHONE_ISO],
          fcmToken: (doc.data()! as Map)[UserParams.FCM_TOKEN],
          phoneFullNumber: (doc.data()! as Map)[UserParams.PHONE_FULL],
          isActive: (doc.data()! as Map)[UserParams.IS_ACTIVE],
          roles: (doc.data()! as Map)[UserParams.ROLES]);
    });
  }

  //get a user by user id
  Future<UserModel> getUserByUserId({String? userId}) async {
    var result = await userModelCollection.doc(userId).get().then(
          (doc) => UserModel(
              userId: (doc.data()! as Map)[UserParams.USER_ID],
              userName: (doc.data()! as Map)[UserParams.USER_NAME],
              emailAddress: (doc.data()! as Map)[UserParams.EMAIL_ADDRESS],
              firstName: (doc.data()! as Map)[UserParams.FIRST_NAME],
              lastName: (doc.data()! as Map)[UserParams.LAST_NAME],
              dob: (doc.data()! as Map)[UserParams.DOB],
              address: (doc.data()! as Map)[UserParams.ADDRESS],
              avatarUrl: (doc.data()! as Map)[UserParams.AVATAR],
              bioDescription: (doc.data()! as Map)[UserParams.BIO_DESC],
              phoneNumber: (doc.data()! as Map)[UserParams.PHONE],
              phoneIsoCode: (doc.data()! as Map)[UserParams.PHONE_ISO],
              fcmToken: (doc.data()! as Map)[UserParams.FCM_TOKEN],
              phoneFullNumber: (doc.data()! as Map)[UserParams.PHONE_FULL],
              isActive: (doc.data()! as Map)[UserParams.IS_ACTIVE],
              roles: (doc.data()! as Map)[UserParams.ROLES]),
        );
    return result;
  }

  //delete a user
  Future<void> deleteUserByUserId({String? userId}) async {}

  //Add followers
  Future<void> addFollowers(
      {String? followerId,
      String? userId,
      String? followerFirstName,
      String? followerLastName,
      String? avatarUrl}) async {
    try {
      await userModelCollection
          .doc(userId)
          .collection('followers')
          .doc(followerId)
          .set({
        UserParams.FIRST_NAME: followerFirstName,
        UserParams.LAST_NAME: followerLastName,
        UserParams.AVATAR: avatarUrl
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //Stream followers or followers
  Stream<List<UserModel>> getFollowsPerUser(
      {String? userId, String? collection}) {
    return userModelCollection
        .doc(userId)
        .collection(collection!)
        .snapshots()
        .map(_userDataFromSnapshot);
  }

  //will stream the users followed by a certain user
  Stream<List<UsersFollowing?>> getUsersBeingFollowed(
      {String? userId, String? collection}) {
    return userModelCollection
        .doc(userId)
        .collection(collection!)
        .snapshots()
        .map(_followedDataFromSnapshot);
  }

  //will stream the user following a certain user
  Stream<List<UsersFollowed?>> getUsersFollowingUser(
      {String? userId, String? collection}) {
    return userModelCollection
        .doc(userId)
        .collection(collection!)
        .snapshots()
        .map(_followingDataFromSnapshot);
  }

  //Fetch followed users
  Future<List<String>> checkUserFollowed(
      {String? userId, String? followedId, String? collection}) async {
    try {
      var result = await userModelCollection
          .doc(userId)
          .collection(collection!)
          .get()
          .then((value) => value.docs.map((e) => e.id).toList());

      return result;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  //Add following
  Future<void> addFollowing(
      {String? followerId,
      String? userId,
      String? followerFirstName,
      String? followerLastName,
      String? avatarUrl}) async {
    try {
      //add following
      await userModelCollection
          .doc(userId)
          .collection(FollowParameters.following!)
          .doc(followerId)
          .set({
        UserParams.FIRST_NAME: followerFirstName,
        UserParams.LAST_NAME: followerLastName,
        UserParams.AVATAR: avatarUrl,
      });

      //add followers
      await userModelCollection
          .doc(followerId)
          .collection(FollowParameters.followers!)
          .doc(userId)
          .set({
        UserParams.FIRST_NAME: followerFirstName,
        UserParams.LAST_NAME: followerLastName,
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //delete follower
  Future<void> deleteFollowing({String? userId, String? followerId}) async {
    print('deleting follower: $userId : $followerId');
    try {
      //delete following
      await userModelCollection
          .doc(userId)
          .collection(FollowParameters.following!)
          .doc(followerId)
          .delete();
      //delete follower
      await userModelCollection
          .doc(followerId)
          .collection(FollowParameters.followers!)
          .doc(userId)
          .delete();
      print('deleting follower was successfull');
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      print('an error occured trying to delete: $e');
    }
  }

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

  //Streaming video per user
  //stream image video files as per user
  Stream<List<StreamingModel?>> getUserStreamingList({String? userId}) {
    return imageVideoCollection
        .where(UserParams.USER_ID, isEqualTo: userId)
        .snapshots()
        .map(_mapStreamsFromSnapshot);
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
      String? type,
      String? thumbnailUrl}) async {
    try {
      var result = await imageVideoCollection.add({
        ImageVideoParams.USER_ID: userId,
        ImageVideoParams.NAME: name,
        ImageVideoParams.URL: url,
        ImageVideoParams.TAGS: tags,
        ImageVideoParams.TYPE: type,
        ImageVideoParams.THUMBNAIL: thumbnailUrl,
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
      List<String>? tags,
      String? thumbnailUrl}) async {
    try {
      await imageVideoCollection.doc(uid).update({
        ImageVideoParams.USER_ID: userId,
        ImageVideoParams.NAME: name,
        ImageVideoParams.URL: url,
        ImageVideoParams.TAGS: tags,
        ImageVideoParams.THUMBNAIL: thumbnailUrl,
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
          videoThumbnailurl: (doc.data() as Map)[ImageVideoParams.THUMBNAIL]);
    }).toList();
  }

  //Stream image file
  Stream<List<ImageVideoModel?>> getImageList() {
    return imageVideoCollection.snapshots().map(_mapImageFromSnapshot);
  }

  //stream image video files as per user
  Stream<List<ImageVideoModel?>> getUserImageVideoList({String? userId}) {
    return imageVideoCollection
        .where(UserParams.USER_ID, isEqualTo: userId)
        .snapshots()
        .map(_mapImageFromSnapshot);
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

  //This section is for adding comment for images and videos
  //Add comment
  Future<void> addComment(
      {String? uid,
      String? comment,
      String? userId,
      String? fullName,
      String? collection,
      DateTime? dateTime}) async {
    try {
      await imageVideoCollection.doc(uid).collection(collection!).add({
        CommentParameters.USER_ID: userId,
        CommentParameters.COMMENT: comment,
        CommentParameters.FULL_NAME: fullName,
        CommentParameters.DATE_TIME: dateTime,
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      print('an error occured trying to add comment: $e, $stackTrace');
    }
  }

  //update comment
  Future<void> updateComment(
      {String? uid,
      String? commentId,
      String? comment,
      String? userId,
      DateTime? dateTime}) async {
    try {
      await imageVideoCollection
          .doc(uid)
          .collection('comments')
          .doc(commentId)
          .update({
        CommentParameters.COMMENT: comment,
        CommentParameters.DATE_TIME: dateTime,
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //Map Comments
  List<CommentModel?> _mapCommentFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return CommentModel(
        uid: (doc.data() as Map)[CommentParameters.UID],
        userId: (doc.data() as Map)[CommentParameters.USER_ID],
        fullName: (doc.data() as Map)[CommentParameters.FULL_NAME],
        comment: (doc.data() as Map)[CommentParameters.COMMENT],
        dateTime: (doc.data() as Map)[CommentParameters.DATE_TIME],
      );
    }).toList();
  }

  //Stream comment for a selected file
  Stream<List<CommentModel?>> streamCommentForFile(
      {String? fileId, String? collection}) {
    return imageVideoCollection
        .doc(fileId)
        .collection(collection!)
        .snapshots()
        .map(_mapCommentFromSnapshot);
  }

  //This section will handle the chat option

  //stream all chat rooms per user
  getChatRoomPerUser({String? userId}) {
    try {
      return userModelCollection.doc(userId).collection('chats').snapshots();
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //get all chat rooms per user
  getChatRoomFuturePerUser({String? userId}) async {
    try {
      return userModelCollection
          .doc(userId)
          .collection('chats')
          .get()
          .then((value) => value.docs.map((e) => e.id).toList());
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //Get chat room
  Future<String> getChatRoom({
    String? chattingWith,
    String? userId,
  }) async {
    try {
      return await userModelCollection
          .doc(userId)
          .collection('chats')
          .where(ChatRoomParameters.chattingWith, isEqualTo: chattingWith)
          .get()
          .then((value) {
        return value.docs.map((e) {
          print('the value: ${e.id}');
          return e.id;
        }).first;
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      print('An error creating chat room: $e');
      return '';
    }
  }

  //create a chat room
  Future<void> createChatRoom(
      {String? userOneId,
      String? userTwoId,
      String? chatRoomId,
      String? userNameOne,
      String? userNameTwo,
      String? firstNameOne,
      String? lastNameOne,
      String? firstNameTwo,
      String? lastNameTwo,
      String? avatarUrlOne,
      String? avatarUrlTwo,
      ChatRoomModel? chatRoomMap}) async {
    try {
      messagesCollection.doc(chatRoomId).set({
        ChatRoomParameters.users: chatRoomMap!.users,
      });
      userModelCollection
          .doc(userOneId)
          .collection('chats')
          .doc(chatRoomId)
          .set({
        ChatRoomParameters.userId: userId,
        ChatRoomParameters.chattingWith: userTwoId,
        UserParams.USER_NAME: userNameTwo,
        UserParams.FIRST_NAME: firstNameTwo,
        UserParams.LAST_NAME: lastNameTwo,
        UserParams.AVATAR: avatarUrlTwo
      });
      userModelCollection
          .doc(userTwoId)
          .collection('chats')
          .doc(chatRoomId)
          .set({
        ChatRoomParameters.userId: userId,
        ChatRoomParameters.chattingWith: userOneId,
        UserParams.USER_NAME: userNameOne,
        UserParams.FIRST_NAME: firstNameOne,
        UserParams.LAST_NAME: lastNameOne,
        UserParams.AVATAR: avatarUrlOne
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      print('An error creating chat room: $e');
    }
  }

  //Create a conversation
  Future<void> addConversationMessage(
      {String? chatRoomId, MessageMap? messageMap}) async {
    try {
      await messagesCollection.doc(chatRoomId).collection('chats').add({
        ConversationRoomParam.senderId: messageMap!.senderId,
        ConversationRoomParam.message: messageMap.message,
        ConversationRoomParam.type: messageMap.type,
        ConversationRoomParam.time: messageMap.time,
        ChatRoomParameters.read: false,
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //update conversation
  Future<void> updateConversationRead(
      {String? docId, String? chatRoomId, bool? read}) async {
    try {
      print('chatroom param: ${ChatRoomParameters.read} - $read');
      await messagesCollection
          .doc(chatRoomId)
          .collection('chats')
          .doc(docId)
          .update({
        ChatRoomParameters.read: true,
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //get conversation message
  getConversationMessages({String? chatRoomId}) {
    try {
      return messagesCollection.doc(chatRoomId).snapshots();
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //get unread messages
  getUnreadMessages({String? chatRoomId, String? userId}) async {
    try {
      return messagesCollection
          .doc(chatRoomId)
          .collection('chats')
          .where(ConversationRoomParam.senderId, isNotEqualTo: userId)
          .where(ChatRoomParameters.read, isEqualTo: false)
          .get()
          .then((value) {
        return value.docs.length;
      });
    } catch (e, stackTrace) {
      print('error reading chats: $e');
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }
}
