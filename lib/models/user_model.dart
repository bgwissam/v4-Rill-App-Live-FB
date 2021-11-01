class UserModel {
  String? userId;
  String? userName;
  String? emailAddress;
  String? firstName;
  String? lastName;
  String? avatarUrl;
  String? phoneNumber;
  String? phoneIsoCode;
  String? phoneFullNumber;
  int? coins;
  var dob;
  String? address;
  String? bioDescription;
  bool? isActive;
  List<dynamic>? roles;
  String? fcmToken;
  String? frontIdUrl;
  String? backIdUrl;
  bool? isIdVerified;
  String? adminComments;
  String? error;
  UserModel(
      {this.userId,
      this.userName,
      this.emailAddress,
      this.firstName,
      this.lastName,
      this.avatarUrl,
      this.phoneNumber,
      this.phoneIsoCode,
      this.phoneFullNumber,
      this.coins,
      this.dob,
      this.address,
      this.bioDescription,
      this.isActive,
      this.roles,
      this.frontIdUrl,
      this.backIdUrl,
      this.isIdVerified,
      this.adminComments,
      this.fcmToken,
      this.error});
}

class UsersFollowed {
  String? userId;
  String? userName;
  String? followerId;
  String? firstName;
  String? lastName;
  String? avatarUrl;

  UsersFollowed(
      {this.userId,
      this.userName,
      this.followerId,
      this.firstName,
      this.lastName,
      this.avatarUrl});
}

class UsersFollowing {
  String? userId;
  String? userName;
  String? followerId;
  String? firstName;
  String? lastName;
  String? avatarUrl;

  UsersFollowing(
      {this.userId,
      this.userName,
      this.followerId,
      this.firstName,
      this.lastName,
      this.avatarUrl});
}
