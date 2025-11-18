import 'package:flutter/cupertino.dart';

class FooModel extends ChangeNotifier{
  bool _flipX = false;
  bool get flipX => _flipX;
  set flipX(value){
    _flipX = value;
    notifyListeners();
  }
  bool _flipY = false;
  bool get flipY => _flipY;
  set flipY(value){
    _flipY = value;
    notifyListeners();
  }
  double _size = 200.0;
  double get size => _size;
  set size(value){
    _size = value;
    notifyListeners();
  }

}