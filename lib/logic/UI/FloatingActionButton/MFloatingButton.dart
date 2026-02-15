import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
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
    CommandManagerForProvider commandManager = context.watch<CommandManagerForProvider>();
    bool hasCommand = commandManager.HasCommand;
    bool hasPoppedCommand = commandManager.HasPoppedCommand;
    //hasPoppedCommand = false;

    return Container(
      //color: Colors.blue[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment :CrossAxisAlignment.end,
        spacing: 10,
        children: [

          // 第一个新悬浮按钮
          if (_isExpanded)
            FloatingActionButton(
              onPressed: () {
                // 执行你希望的操作
                stateModel.State = GlobalState.creatingConcept;
              },
              child: Icon(Icons.add),
              backgroundColor: Colors.green,
            ),
          // 第二个新悬浮按钮
          if (_isExpanded && selection.IsInDomain)
            FloatingActionButton(
              onPressed: () {
                // 执行你希望的操作
                stateModel.State = GlobalState.creatingDomain;

              },
              child: Icon(Icons.add),
              backgroundColor: Colors.red,
            ),

          // // 主悬浮按钮,弹出创建界面
          // FloatingActionButton(
          //   onPressed: (){setState(() {
          //     _isExpanded = !_isExpanded;
          //   });},
          //   child: Icon(
          //     _isExpanded ? Icons.close : Icons.add,
          //   ),
          //   backgroundColor: Colors.blue,
          // ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if(_isExpanded)
                SizedBox(
                  width: 56,
                  height: 56,
                  child:  FloatingActionButton(
                    onPressed: hasCommand ? (){

                      commandManager.Undo();
                    }:null,
                    disabledElevation: 0,
                    backgroundColor: hasCommand? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                    foregroundColor: hasCommand? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    child: Icon(Icons.arrow_back_rounded),
                  ),
                ),
              if(_isExpanded)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    //backgroundColor: Colors.green,
                    onPressed: hasPoppedCommand?(){
                      commandManager.Redo();
                    }:null,
                    disabledElevation: 0,
                    backgroundColor: hasPoppedCommand? Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                    foregroundColor: hasPoppedCommand? Theme.of(context).colorScheme.onPrimaryContainer:Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    child: Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              //主悬浮按钮,弹出创建界面

              FloatingActionButton(
                onPressed: (){setState(() {
                  _isExpanded = !_isExpanded;
                });},
                child: Icon(
                  _isExpanded ? Icons.close : Icons.add,
                ),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),

            ],
          )



        ],

      ),
    );


    if(selection.IsInDomain){

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
                stateModel.State = GlobalState.creatingConcept;
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
