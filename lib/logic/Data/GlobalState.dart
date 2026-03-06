import 'dart:collection';
import 'package:flutter/material.dart';

abstract class StateModel<T extends Enum> extends ChangeNotifier {
  T _state;

  StateModel(T initialState) : _state = initialState;

  T get State => _state;

  set State(T value) {
    _state = value;
    notifyListeners();
  }
}
enum GlobalState{
  normal,
  creatingConcept,
  creatingDomain,
  editingConcept,
  editingDomain,
}

class GlobalStateModel extends StateModel<GlobalState> {
  GlobalStateModel():super(GlobalState.normal);
  //List<GlobalState> stateList = [];
}
enum EditingState{
  none,
  renamingNode,

  selectingMovingNode,
  waitingMovingTarget,
  squeezingNode,

  coloringNode,

}
class EditingStateModel extends StateModel<EditingState>{
  EditingStateModel():super(EditingState.none);

}