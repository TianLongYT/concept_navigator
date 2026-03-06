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
  ///清理stack中的所有内容。
  void init(){
    commandStack.clear();
    poppedCommandStack.clear();
  }
  void undoAll(){
    Command? command = PopCommand();
    if(command == null){
      print("历史操作库中已无操作");
      return;
    }
    command.undoFunction();
    poppedCommandStack.add(command);
    undoAll();
  }
  void redoAll(){
    if(poppedCommandStack.isEmpty){
      print("必须重做一次后才能再做");
      return;
    }
    Command command = poppedCommandStack.removeLast();
    command.function();
    PushCommand(command);
    redoAll();
  }
  @override
  String toString() {
    return "commandStack:"+ commandStack.toString() +"  poppedCommandStack:"+ poppedCommandStack.toString();
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
    editInstance = CommandManager(),
    naviInstance = CommandManager(),
    moveNodeInstance = CommandManager();



  final CommandManager editInstance;//使用主方法会通知监听的widget。

  final CommandManager naviInstance;//使用具体的子方法就不会调用notifier。这样可以适当优化。
  final CommandManager moveNodeInstance;//其他只起辅助作用。

  bool HasCommand(CommandManager commandManager)=>commandManager.HasCommand;
  bool HasPoppedCommand(CommandManager commandManager)=>commandManager.HasPoppedCommand;

  //bool get HasCommand =>editInstance.HasCommand;
  //bool get HasPoppedCommand => editInstance.HasPoppedCommand;

  void PushCommand(CommandManager commandManager,Command command){
    commandManager.PushCommand(command);
    if(commandManager.poppedCommandStack.isNotEmpty){
      commandManager.poppedCommandStack.clear();
    }
    notifyListeners();
  }
  Command? PopCommand(CommandManager commandManager){
    notifyListeners();
    return commandManager.PopCommand();
  }

  void Undo(CommandManager commandManager){
    commandManager.Undo();
    notifyListeners();
  }
  void Redo(CommandManager commandManager){
    commandManager.Redo();
    notifyListeners();
  }
  void printCommandManager(CommandManager commandManager){
    print(commandManager.toString());
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