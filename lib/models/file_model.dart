class ImageVideoModel {
  String? uid;
  String? userId;
  String? url;
  List<dynamic>? tags;
  String? name;
  String? type;
  String? videoThumbnailurl;

  ImageVideoModel(
      {this.uid,
      this.userId,
      this.url,
      this.tags,
      this.name,
      this.type,
      this.videoThumbnailurl});
}
