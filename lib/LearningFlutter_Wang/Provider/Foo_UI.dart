import 'package:flutter/material.dart';

import 'Foo_Model_Provider.dart';

class Foo extends StatelessWidget {

  const Foo({super.key});


  @override
  Widget build(BuildContext context) {
    final model = FooModelProvider.of(context).model;

    return ListenableBuilder(
      listenable: model,

      builder: (BuildContext context, Widget? child)
      =>Card(
        child: Transform.flip(
          flipX: model.flipX,
          flipY: model.flipY,
          child:  FlutterLogo(
            size: model.size,
          ),
        ),
      ),
    );
  }
}