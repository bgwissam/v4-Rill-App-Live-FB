import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? description;

  ImageVideoModel(
      {this.uid,
      this.userId,
      this.url,
      this.tags,
      this.name,
      this.type,
      this.videoThumbnailurl,
      this.description});
}

class StreamingModel {
  String? uid;
  String? userId;
  String? streamerId;
  String? url;
  List<dynamic>? tags;
  String? channelName;
  String? rtcToken;
  String? rtmToken;
  String? thumbnailUrl;
  String? resourceId;
  int? paymentPerView;
  bool? descretion;
  String? sid;
  StreamingModel(
      {this.uid,
      this.userId,
      this.streamerId,
      this.url,
      this.tags,
      this.channelName,
      this.rtcToken,
      this.rtmToken,
      this.thumbnailUrl,
      this.resourceId,
      this.paymentPerView,
      this.descretion,
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

class CommentModel {
  String? uid;
  String? userId;
  String? fullName;
  String? comment;
  String? avatarUrl;
  var dateTime;

  CommentModel({
    this.uid,
    this.userId,
    this.fullName,
    this.comment,
    this.dateTime,
    this.avatarUrl,
  });
}
