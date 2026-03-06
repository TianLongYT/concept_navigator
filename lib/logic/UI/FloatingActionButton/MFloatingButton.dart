import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/DeleteNodeLogic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MFloatingButton extends StatefulWidget {
  const MFloatingButton({super.key});

  @override
  State<MFloatingButton> createState() => _MFloatingButtonState();
}

class _MFloatingButtonState extends State<MFloatingButton> {
  bool _isExpanded = true;
  bool _isExpandedY = true;
  bool _isExpandedX = true;

  @override
  Widget build(BuildContext context) {
    //_isExpandedY = false ;
    GlobalStateModel globalStateModel = context.watch<GlobalStateModel>();
    EditingStateModel editingStateModel = context.watch<EditingStateModel>();

    SelectionViewData selection = context.watch<SelectionViewData>();
    CommandManagerForProvider commandManager = context.watch<CommandManagerForProvider>();
    CommandManager? chooseCommandMananger;

    bool disableUndo = false;
    chooseCommandMananger = commandManager.editInstance;//默认选择editInstance.
    commandManager.printCommandManager(chooseCommandMananger);
    //压缩Y方向。
    if(editingStateModel.State == EditingState.selectingMovingNode ||
        editingStateModel.State == EditingState.waitingMovingTarget ||
        editingStateModel.State == EditingState.squeezingNode
    ){
      chooseCommandMananger = commandManager.moveNodeInstance;
      commandManager.printCommandManager(chooseCommandMananger);
      _isExpandedY = false;
    }
    else{
      if(editingStateModel.State == EditingState.coloringNode){
        _isExpandedY = false;
      }

      _isExpandedY = true;
    }





    if(chooseCommandMananger == null){
      //禁用撤回重做功能。
      disableUndo = true;
    }

    bool hasCommand =disableUndo? false: commandManager.HasCommand(chooseCommandMananger!);
    bool hasPoppedCommand =disableUndo? false: commandManager.HasPoppedCommand(chooseCommandMananger!);
    //hasPoppedCommand = false;

    final double spacing = 10;
    final double buttonSize = 56;
    double deltaSize = spacing + buttonSize;


    return Container(
      //color: Colors.blue[100],
      height: double.infinity,

      child: Stack(
        //mainAxisAlignment: MainAxisAlignment.end,
        //crossAxisAlignment :CrossAxisAlignment.end,
        //spacing: 10,
        alignment: AlignmentGeometry.bottomRight,
        children: [

          //节点删除按钮
          if(selection.IsSelecting)
          AnimatedPositioned(
            key:Key("节点删除按钮"),
            bottom: _isExpanded && _isExpandedY? deltaSize * (selection.IsInDomain?3:2) : 0,
            duration: Duration(milliseconds: 200),
            child: FloatingActionButton(
              onPressed:_isExpanded && _isExpandedY?(){
                DeleteNodeLogic.deleteSelectedNode(context);
                globalStateModel.State = GlobalState.normal;
                selection.CancelSelection();
              }:null,
            
              backgroundColor: Colors.red,
              child: Icon(Icons.delete),
            ),
          ),
          // 创建概念
          AnimatedPositioned(
            key:Key("创建概念按钮"),
            bottom: _isExpanded && _isExpandedY? deltaSize *(selection.IsInDomain?2:1):0,
            duration: Duration(milliseconds: 200),
            child: FloatingActionButton(
              onPressed:_isExpanded && _isExpandedY? () {
                // 执行你希望的操作
                globalStateModel.State = GlobalState.creatingConcept;
              }:null,
              backgroundColor: Colors.green,
              child: Icon(Icons.add),
            ),
          ),


          // 创建域
          if(selection.IsInDomain)
          AnimatedPositioned(
            key:Key("创建域按钮"),
            bottom:_isExpanded && _isExpandedY?deltaSize*(selection.IsInDomain ? 1:0):0,
            duration: Duration(milliseconds: 200),
            child: FloatingActionButton(
              onPressed:_isExpanded && _isExpandedY ? () {
                // 执行你希望的操作
                globalStateModel.State = GlobalState.creatingDomain;

              }:null,
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.add),
            ),
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

                      commandManager.Undo(chooseCommandMananger!);
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
                      commandManager.Redo(chooseCommandMananger!);
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
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Stack(
                  //clipBehavior: Clip.none,
                  alignment: AlignmentGeometry.center,
                  children:[
                    Align(
                      alignment: AlignmentGeometry.center,
                      child: Icon(_isExpanded ? Icons.close : Icons.add,)
                    ),
                    Positioned(
                      top: 0,
                      //bottom: buttonSize-56, // 紧贴FAB上方
                     // right: 0,
                      child: AnimatedOpacity(
                        opacity: !_isExpandedY && _isExpanded? 1:0,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeIn,
                        child: Container(
                          width: buttonSize * 0.85, // 与FAB同宽
                          height: buttonSize * 0.1,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    )
                  ]
                ),
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
                globalStateModel.State = GlobalState.creatingConcept;
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
