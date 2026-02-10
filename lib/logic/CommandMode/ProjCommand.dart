import 'dart:collection';

import 'package:flutter/material.dart';

//使用枚举标记指令类型。辅助处理。
enum CommandType{
  None,
  AddNode,
  RemoveNode,
  MoveNode,
  RenameNode,

}

class Command{
  CommandType specialType = CommandType.None;//方便后续还原？暂时没任何作用。


  Function function;
  Function undoFunction;
  Command({required this.function,required this.undoFunction});

}
//指令分为几种类型。编辑型，预览型。
//只记录编辑型指令。

class CommandManager{
  List<Command> commandStack = [];
  bool get HasCommand => commandStack.isNotEmpty;

  void PushCommand(Command command){
    commandStack.add(command);
  }
  Command? PopCommand(){
    if(commandStack.isEmpty) {
      return null;
    }
    return commandStack.removeLast();
  }

  List<Command> poppedCommandStack = [];
  bool get HasPoppedCommand => poppedCommandStack.isNotEmpty;

  void Undo(){
    Command? command = PopCommand();
    if(command == null){
      print("历史操作库中已无操作");
      return;
    }
    command.undoFunction();
    poppedCommandStack.add(command);
  }
  void Redo(){
    if(poppedCommandStack.isEmpty){
      print("必须重做一次后才能再做");
      return;
    }
    Command command = poppedCommandStack.removeLast();
    command.function();
    PushCommand(command);
  }
}

class SingletonCommandManager extends CommandManager{
  static SingletonCommandManager? _editInstance;
  static SingletonCommandManager? _naviInstance;
  SingletonCommandManager._privateConstructor();

  static SingletonCommandManager get EditInstance {
    _editInstance ??= SingletonCommandManager._privateConstructor();
    return _editInstance!;
  }
  static SingletonCommandManager get NaviInstance {
    _naviInstance ??= SingletonCommandManager._privateConstructor();
    return _naviInstance!;
  }
}



class CommandManagerForProvider extends ChangeNotifier{
  CommandManagerForProvider():
    _editInstance = CommandManager(),
    naviInstance = CommandManager();



  final CommandManager _editInstance;

  final CommandManager naviInstance;

  bool get HasCommand =>_editInstance.HasCommand;
  bool get HasPoppedCommand => _editInstance.HasPoppedCommand;

  void PushCommand(Command command){
    _editInstance.PushCommand(command);
    notifyListeners();
  }
  Command? PopCommand(){
    notifyListeners();
    return _editInstance.PopCommand();
  }

  void Undo(){
    _editInstance.Undo();
    notifyListeners();
  }
  void Redo(){
    _editInstance.Redo();
    notifyListeners();
  }


}



class MoveNodeCommand extends Command{
  MoveNodeCommand({required super.function, required super.undoFunction});
  //初始位置。
  //目标位置。
  //移动节点ID。

  //使用toString查看操作说明。
}
class MoveViewCommand extends Command{
  MoveViewCommand({required super.function, required super.undoFunction});
  //初始位置。
  //目标位置。
}