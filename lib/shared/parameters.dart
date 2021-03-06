// ignore_for_file: non_constant_identifier_names

class Parameters {
//App id is required for all backend request
  final app_ID = 'd480c821a2a946d6a4d29292462a3d6f';
//customer id is required for restful api
  final Customer_ID = '353239d4b6db4e38a0bb1d883b49c76b';
//customer secret is required for restful api
  final Customer_secret = 'ad741edbce324792bd7b648c42dc5dde';
//S3 bucket ARN or ID
  final s3_bucket_id = 'videos165240-dev';
//S3 bucket access key
  final s3_access_key = 'AKIAQVDBZQTGVH5RQ62C';
//S3 bucket secret key
  final s3_secret_key = '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';
//App certificate
  final app_certificate = '832101fbfa424e358854a936e4c13db8';
//rtc token base url
  final rtc_base_url =
      'https://app.rilllive.com/public/services/agora/rtc-token.php';

//Google storage id
  final google_bucket_id = 'rill_live_streaming';
  final google_access_key =
      'GOOG1E47QY2T5WCQ77LIGTWH45WTSJADRRG45KCTD6JQJCNHBPCA7EUVXDQ3Y';
  final google_secret_key = 'NwdwQ3v6df/IZnYUaUx1jx5Xilb5F7fj2BI+f2ut';

//Google firebase storage param
  final google_firebase_bucket_id = 'rill-app-live.appspot.com';
  final google_firebase_access_key =
      'GOOG1ERTOYWFTGCYT7ZR2R5CZIKOJ2RSROCIXZKBUXO5T3GDUIYKYIZZMI6EA';
  final google_firebase_secret_key = 'UabDTW904t+7htzhPIlpYzl3Z/bjDRueAgsthqMB';
}

class UserParams {
  static String USER_ID = 'userId';
  static String USER_NAME = 'userName';
  static String EMAIL_ADDRESS = 'emailAddress';
  static String FIRST_NAME = 'firstName';
  static String LAST_NAME = 'lastName';
  static String PHONE = 'phoneNumber';
  static String PHONE_ISO = 'phoneIsoCode';
  static String PHONE_FULL = 'phoneFullNumber';
  static String DOB = 'dob';
  static String IS_ACTIVE = 'isActive';
  static String BIO_DESC = 'bioDescription';
  static String INTERESTS = 'interests';
  static String ROLES = 'roles';
  static String AVATAR = 'avatarUrl';
  static String ADDRESS = 'address';
  static String FCM_TOKEN = 'fcmToken';
  static String COINS = 'coins';
  static String FRONT_ID = 'frontIdUrl';
  static String BACK_ID = 'backIdUrl';
  static String IS_VERIFIED = 'verifiedById';
  static String ADMIN_COMMENTS = 'AdminComments';
  static String UNREAD_MESSAGE = 'unreadMessage';
}

class ImageVideoParams {
  static String IMAGE_ID = 'uid';
  static String USER_ID = 'userId';
  static String URL = 'imageUrl';
  static String TAGS = 'tags';
  static String NAME = 'imageName';
  static String TYPE = 'type';
  static String THUMBNAIL = 'thumbnailUrl';
  static String DESCRIPTION = 'description';
  static String TIME = 'time';
}

class LiveStreamingParams {
  static String UID = 'uid';
  static String USER_ID = 'userId';
  static String STREAMER_ID = 'streamerId';
  static String URL = 'streamUrl';
  static String TAGS = 'tags';
  static String CHANNEL_NAME = 'channelName';
  static String RTC_TOKEN = 'rtc_Token';
  static String RTM_TOKEN = 'rtm_token';
  static String resouceId = 'resourceId';
  static String sid = 'sid';
  static String PAYMENT_VIEW = 'paymentView';
  static String DESCRETION = 'descretion';
  static String DESCRIPTION = 'description';
  static String ALLOW_JOINING = 'allowJoining';
}

class CommentParameters {
  static String UID = 'uid';
  static String USER_ID = 'userId';
  static String FULL_NAME = 'fullName';
  static String COMMENT = 'comment';
  static String DATE_TIME = 'dateTime';
  static String AVATAR = 'avatarUrl';
}

class FollowParameters {
  static String? followers = 'followers';
  static String? following = 'following';
}

class ChatRoomParameters {
  static String userId = 'uid';
  static String users = 'users';
  static String chattingWith = 'chattingWith';
  static String read = 'read';
}

class ConversationRoomParam {
  static String senderId = 'senderId';
  static String message = 'message';
  static String time = 'time';
  static String type = 'type';
}

class AnalyticParam {
  static String ownerId = 'owner_id';
  static String viewerId = 'viewer_id';
  static String likerId = 'liker_id';
  static String time = 'time';
  static String fileId = 'file_id';
}
