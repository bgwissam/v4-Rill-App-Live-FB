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
  final s3_access_key = 'AKIAQVDBZQTGZICDT4BW';
//S3 bucket secret key
  final s3_secret_key = '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';
//App certificate
  final app_certificate = '832101fbfa424e358854a936e4c13db8';
//rtc token base url
  final rtc_base_url =
      'https://app.rilllive.com/public/services/agora/rtc-token.php';
}

class UserParams {
  static String USER_ID = 'userId';
  static String USER_NAME = 'userName';
  static String EMAIL_ADDRESS = 'emailAddress';
  static String FIRST_NAME = 'firstName';
  static String LAST_NAME = 'lastName';
  static String PHONE = 'phoneNumber';
  static String DOB = 'dob';
  static String IS_ACTIVE = 'isActive';
  static String BIO_DESC = 'bioDescription';
  static String ROLES = 'roles';
  static String AVATAR = 'avatarUrl';
  static String ADDRESS = 'address';
}

class ImageVideoParams {
  static String IMAGE_ID = 'uid';
  static String USER_ID = 'userId';
  static String URL = 'imageUrl';
  static String TAGS = 'tags';
  static String NAME = 'imageName';
  static String TYPE = 'type';
}

class LiveStreamingParams {
  static String UID = 'uid';
  static String USER_ID = 'userId';
  static String URL = 'streamUrl';
  static String TAGS = 'tags';
  static String CHANNEL_NAME = 'channelName';
  static String TOKEN = 'Token';
}
