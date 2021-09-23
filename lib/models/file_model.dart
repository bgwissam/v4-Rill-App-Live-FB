import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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

class ThumbnailRequest {
  String video;
  String thumbnailPath;
  ImageFormat imageFormat;
  int maxHeight;
  int maxWidth;
  int timeMs;
  int quality;
  ThumbnailRequest({
    required this.video,
    required this.thumbnailPath,
    required this.imageFormat,
    required this.maxHeight,
    required this.maxWidth,
    required this.timeMs,
    required this.quality,
  });
}

class ThumbnailResult {
  Image? image;
  int? dataSize;
  int? height;
  int? width;

  ThumbnailResult({this.image, this.dataSize, this.height, this.width});
}
