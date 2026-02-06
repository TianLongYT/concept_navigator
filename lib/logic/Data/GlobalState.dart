import 'package:flutter/material.dart';

enum GlobalState{
  normal,
  creatingNode,
  creatingDomain,
  selectedNode,
  selectedDomain,
  
}
class GlobalStateModel extends ChangeNotifier {
  GlobalState _state = GlobalState.normal;
  GlobalState get State => _state;
  set State (value) {
    _state = value;
    notifyListeners();
  }

}