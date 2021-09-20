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

class StreamingModel {
  String? uid;
  String? userId;
  String? url;
  List<dynamic>? tags;
  String? channelName;
  String? token;
  String? thumbnailUrl;
  String? resourceId;
  String? sid;
  StreamingModel(
      {this.uid,
      this.userId,
      this.url,
      this.tags,
      this.channelName,
      this.token,
      this.thumbnailUrl,
      this.resourceId,
      this.sid});
}
