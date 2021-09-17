import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class LoadingAmination extends StatelessWidget {
  const LoadingAmination({Key? key, this.animationType}) : super(key: key);
  final String? animationType;

  @override
  Widget build(BuildContext context) {
    return Container(height: 100, width: 100, child: _buildAnimation());
  }

  Widget _buildAnimation() {
    switch (animationType) {
      case 'ThreeInOut':
        return _threeInOut();
      default:
        return _default();
    }
  }

  Widget _default() {
    return Container(
      child: CircularProgressIndicator(),
    );
  }

  Widget _threeInOut() {
    var threeInOut = SpinKitThreeInOut(
      color: color_4,
      size: 50,
    );
    return Container(
      child: threeInOut,
    );
  }
}
