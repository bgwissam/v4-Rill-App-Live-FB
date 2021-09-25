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
  var dob;
  String? address;
  String? bioDescription;
  bool? isActive;
  List<dynamic>? roles;
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
      this.dob,
      this.address,
      this.bioDescription,
      this.isActive,
      this.roles,
      this.error});
}
