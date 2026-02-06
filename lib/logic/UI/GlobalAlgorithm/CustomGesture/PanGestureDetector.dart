import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
class CustomScaleGestureRecognizer extends ScaleGestureRecognizer{

  @override
  void rejectGesture(int pointer) {
    // TODO: implement rejectGesture
    super.acceptGesture(pointer);
  }

}

class CustomScaleGestureDetector extends StatelessWidget{

  Widget? child;
  GestureScaleStartCallback? onStart;
  GestureScaleUpdateCallback? onUpdate;
  GestureScaleEndCallback? onEnd;

  CustomScaleGestureDetector({super.key,this.child,this.onStart,this.onUpdate,this.onEnd});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return RawGestureDetector(
      gestures: {
        CustomScaleGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<CustomScaleGestureRecognizer>(
              () => CustomScaleGestureRecognizer(),
              (detector) {
            detector.onStart = onStart;
            detector.onUpdate = onUpdate;
            detector.onEnd = onEnd;
          },
        )
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }

}