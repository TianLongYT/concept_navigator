import 'package:flutter/material.dart';

import 'Foo_Model_Provider.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final model = FooModelProvider.of(context).model;

    return ListenableBuilder(
      listenable: model,

      builder: (BuildContext context, Widget? child)
      =>Card(
        margin: const EdgeInsets.all(10),

        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("flipX"),
                  Switch(value:model.flipX, onChanged: (bool value)=>{model.flipX = value}),
                  Text("flipY"),
                  Switch(value: model.flipY, onChanged: (bool value)=>{model.flipY = value}),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("size"),
                  Slider(
                      min: 50,
                      max: 300,
                      value: model.size,
                      onChanged: (value)=>{model.size = value}),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ;
  }
}