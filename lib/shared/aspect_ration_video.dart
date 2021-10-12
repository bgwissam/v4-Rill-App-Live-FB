import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AspectRatioVideo extends StatefulWidget {
  AspectRatioVideo(this.controller, this.cameraController);

  final VideoPlayerController? controller;
  final CameraController? cameraController;

  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  VideoPlayerController? get controller => widget.controller;
  CameraController? get _cameraController => widget.cameraController;
  bool initialized = false;

  void _onVideoControllerUpdate() {
    if (!mounted) {
      return;
    }
    if (controller != null) {
      if (initialized != controller!.value.isInitialized) {
        initialized = controller!.value.isInitialized;
        setState(() {});
      }
    }
    if (_cameraController != null) {
      if (initialized != _cameraController!.value.isInitialized) {
        initialized = _cameraController!.value.isInitialized;
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    controller != null
        ? controller!.addListener(_onVideoControllerUpdate)
        : _cameraController!.addListener(_onVideoControllerUpdate);
  }

  @override
  void dispose() {
    controller != null
        ? controller!.removeListener(_onVideoControllerUpdate)
        : _cameraController!.removeListener(_onVideoControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller != null
              ? controller!.value.aspectRatio
              : _cameraController!.value.aspectRatio,
          child: controller != null
              ? VideoPlayer(controller!)
              : CameraPreview(_cameraController!),
        ),
      );
    } else {
      return Container();
    }
  }
}
