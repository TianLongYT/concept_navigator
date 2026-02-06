
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/LevelNodePresentation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class LevelDomain extends StatelessWidget {

  LevelDomain({super.key,double scale = 1.0, required this.drawingData, required this.domainTree}):
    _scale = scale;
  final NodeDrawingData drawingData;
  final DomainTree domainTree;

  final double _scale;

  @override
  Widget build(BuildContext context) {

    Size deltaSize = drawingData.nodeAppearance.nodeSize * (drawingData.nodeAppearance.emptySize - 1);
    SelectionViewData selection = context.watch<SelectionViewData>();
    AddressBarModel addressBarModel = context.watch<AddressBarModel>();
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();

    return
      Padding(

        padding: EdgeInsetsGeometry.only(
          left: deltaSize.width * 0.5 * _scale,
          right : deltaSize.width * 0.5 * _scale,
          top:  deltaSize.height *0.5 * _scale,
          bottom:  deltaSize.height*0.5 * _scale,
        ),
        child: GestureDetector(
          onTap: (){
            print("clicked domain ${domainTree.name}");
            selection.SelectedDomain = domainTree;
            stateModel.State = GlobalState.selectedDomain;

          },
          onDoubleTap: (){
            print("double clicked domain ${domainTree.name}");

            addressBarModel.AddDomainAddress(domainTree);

            selection.CancelSelection();
            selection.currentDomain = ConceptTreeModel.AppendDomainKey(selection.currentDomain,  domainTree!.name);
            stateModel.State = GlobalState.normal;


          },
          child: LevelNodePresentation(scale: _scale,isInDomain: true,drawingData: drawingData, nodeTree: null,domainTree: domainTree,),
        ),
      );
  }
}
