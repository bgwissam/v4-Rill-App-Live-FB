class UserModel {
  String? userId;
  String? userName;
  String? emailAddress;
  String? firstName;
  String? lastName;
  String? avatarUrl;
  String? phoneNumber;
  String? dob;
  String? bioDescription;
  bool? isActive;
  List<String>? roles;
  String? error;
  UserModel(
      {this.userId,
      this.userName,
      this.emailAddress,
      this.firstName,
      this.lastName,
      this.avatarUrl,
      this.phoneNumber,
      this.dob,
      this.bioDescription,
      this.isActive,
      this.roles,
      this.error});
}
