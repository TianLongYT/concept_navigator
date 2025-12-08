import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MFloatingButton extends StatefulWidget {
  const MFloatingButton({super.key});

  @override
  State<MFloatingButton> createState() => _MFloatingButtonState();
}

class _MFloatingButtonState extends State<MFloatingButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    if(selection.IsInDomain){
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 10,
        children: [

          // 第一个新悬浮按钮
          if (_isExpanded)
            FloatingActionButton(
              onPressed: () {
                // 执行你希望的操作
                stateModel.State = GlobalState.creatingNode;
              },
              child: Icon(Icons.add),
              backgroundColor: Colors.green,
            ),
          // 第二个新悬浮按钮
          if (_isExpanded)
            FloatingActionButton(
              onPressed: () {
                // 执行你希望的操作
                stateModel.State = GlobalState.creatingDomain;

              },
              child: Icon(Icons.add),
              backgroundColor: Colors.red,
            ),

          // 主悬浮按钮
          FloatingActionButton(
            onPressed: (){setState(() {
              _isExpanded = !_isExpanded;
            });},
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
            ),
            backgroundColor: Colors.blue,
          ),
        ],

      );
    }
    else{
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 10,
        children: [

          // 第一个新悬浮按钮
          if (_isExpanded)
            FloatingActionButton(
              onPressed: () {
                // 执行你希望的操作
                stateModel.State = GlobalState.creatingNode;
              },
              child: Icon(Icons.add),
              backgroundColor: Colors.green,
            ),
          // 主悬浮按钮
          FloatingActionButton(
            onPressed: (){setState(() {
              _isExpanded = !_isExpanded;
            });},
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
            ),
            backgroundColor: Colors.blue,
          ),
        ],

      );
    }
  }
}
