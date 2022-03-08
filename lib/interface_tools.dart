import 'package:flutter/material.dart';


// convert string to boolean
bool string2Bool(String targetString) {
  if (targetString == 'true') {
    return true;
  }
  return false;
}


// scroll glow effect deleted scroll behavior
class GlowRemovedBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}