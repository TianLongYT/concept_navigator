import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/StatefulComponentManagerModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeAppearanceEditorComponent/ColorPropertyEditorComponent.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodeColor.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NodeGroupEditorComponent extends StatefulWidget {
  const NodeGroupEditorComponent({super.key});

  @override
  State<NodeGroupEditorComponent> createState() => _NodeGroupEditorComponentState();
}

class _NodeGroupEditorComponentState extends State<NodeGroupEditorComponent> {
  StlessScrollablePositionedListItem? _inheritedItem;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inheritedItem = context.dependOnInheritedWidgetOfExactType<StlessScrollablePositionedListItem>();
  }

  void _lateSetFocusState(bool focus, StatefulComponentManagerModelForProvider manager, StatefulComponentManagerModel model, {double alignment = 0}){
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setFocusState(focus, manager, model, alignment: alignment);
    });
  }

  void _setFocusState(bool focus, StatefulComponentManagerModelForProvider manager, StatefulComponentManagerModel model, {double alignment = 0}) {
    if (_inheritedItem == null) return;
    _inheritedItem!.needStopScroll?.call(focus);
    manager.setComponentState(model, _inheritedItem!.index, focus ? 2 : 0);
    if (focus) {
      _inheritedItem!.controller.scrollTo(
        index: _inheritedItem!.index,
        alignment: alignment,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<SelectionViewData>();
    final nodeDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    final domainDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    final manager = context.read<StatefulComponentManagerModelForProvider>();
    final stateModel = context.read<EditingStateModel>();
    final commandManager = context.read<CommandManagerForProvider>();

    NodeDrawingData? parentData;
    StatefulComponentManagerModel model;
    bool isInDomain = selection.IsInDomain;
    if (isInDomain) {
      parentData = domainDic.GetDomainDrawingData(selection.currentDomain);
      model = manager.editingParentDomainPanel;
    } else {
      parentData = nodeDic.GetNodeDrawingData(selection.CurrentDomainNodeKey);
      model = manager.editingParentConceptPanel;
    }
    void notify() {
      if (isInDomain) domainDic.repaint(); else nodeDic.repaint();
    }
    if (parentData == null) return const Center(child: Text("无法获取节点组数据"));

    return Column(
      children: [
        // 默认概念背景颜色
        ColorPropertyEditor(
          title: "默认概念背景",
          icon: Icons.color_lens,
          color: parentData.defaultConceptNodeColor,
          displayColor: NodeColorHelper.GetDefaultNodeColor(false, parentData.defaultConceptNodeColor, context),
          onChanged: (color) {
            parentData!.defaultConceptNodeColor = color;
            notify();
          },
          onConfirm: (oldColor, newColor) {
            commandManager.PushCommand(commandManager.editInstance, Command(
              function: () { parentData!.defaultConceptNodeColor = newColor; notify(); },
              undoFunction: () { parentData!.defaultConceptNodeColor = oldColor; notify(); },
            ));
          },
          onReset: () {
            final oldColor = parentData!.defaultConceptNodeColor;
            commandManager.PushCommand(commandManager.editInstance, Command(
              function: () { parentData!.defaultConceptNodeColor = null;  notify(); },
              undoFunction: () { parentData!.defaultConceptNodeColor = oldColor;  notify(); },
            ));
            parentData.defaultConceptNodeColor = null;
            notify();
          },
          onStartEdit: () {
            stateModel.State = EditingState.coloringNode;
            _lateSetFocusState(true, manager, model, alignment: 0.0);
          },
          onEndEdit: () {
            stateModel.State = EditingState.none;
            _lateSetFocusState(false, manager, model, alignment: 0.0);
          },
        ),
        const Divider(height: 1, indent: 10, endIndent: 40),
        // 默认概念字体颜色
        ColorPropertyEditor(
          title: "默认概念字体",
          icon: Icons.text_fields,
          color: parentData.defaultConceptFontColor,
          displayColor: NodeColorHelper.GetDefaultFontColor(false, parentData.defaultConceptFontColor, context),
          onChanged: (color) {
            parentData!.defaultConceptFontColor = color;
            notify();
          },
          onConfirm: (oldColor, newColor) {
            commandManager.PushCommand(commandManager.editInstance, Command(
              function: () { parentData!.defaultConceptFontColor = newColor; notify(); },
              undoFunction: () { parentData!.defaultConceptFontColor = oldColor; notify(); },
            ));
          },
          onReset: () {
            final oldColor = parentData!.defaultConceptFontColor;
            commandManager.PushCommand(commandManager.editInstance, Command(
              function: () { parentData!.defaultConceptFontColor = null; notify(); },
              undoFunction: () { parentData!.defaultConceptFontColor = oldColor; notify(); },
            ));
            parentData.defaultConceptFontColor = null;
            notify();
          },
          onStartEdit: () {
            stateModel.State = EditingState.coloringNode;
            _lateSetFocusState(true, manager, model, alignment: -0.2);
          },
          onEndEdit: () {
            stateModel.State = EditingState.none;
            _lateSetFocusState(false, manager, model, alignment: -0.2);
          },
        ),

        if (parentData is DomainDrawingData) ...[
          const Divider(height: 1, indent: 10, endIndent: 40),
          // 默认域背景颜色
          ColorPropertyEditor(
            title: "默认域背景",
            icon: Icons.domain,
            color: parentData.defaultDomainNodeColor,
            displayColor: NodeColorHelper.GetDefaultNodeColor(true, parentData.defaultDomainNodeColor, context),
            onChanged: (color) {
              (parentData as DomainDrawingData).defaultDomainNodeColor = color;
              notify();
            },
            onConfirm: (oldColor, newColor) {
              commandManager.PushCommand(commandManager.editInstance, Command(
                function: () { (parentData as DomainDrawingData).defaultDomainNodeColor = newColor; notify(); },
                undoFunction: () { (parentData as DomainDrawingData).defaultDomainNodeColor = oldColor; notify(); },
              ));
            },
            onReset: () {
              final oldColor = (parentData as DomainDrawingData).defaultDomainNodeColor;
              commandManager.PushCommand(commandManager.editInstance, Command(
                function: () { (parentData as DomainDrawingData).defaultDomainNodeColor = null; notify(); },
                undoFunction: () { (parentData as DomainDrawingData).defaultDomainNodeColor = oldColor; notify(); },
              ));
              (parentData).defaultDomainNodeColor = null;
              notify();
            },
            onStartEdit: () {
              stateModel.State = EditingState.coloringNode;
              _lateSetFocusState(true, manager, model, alignment: -0.4);
            },
            onEndEdit: () {
              stateModel.State = EditingState.none;
              _lateSetFocusState(false, manager, model, alignment: -0.4);
            },
          ),
          const Divider(height: 1, indent: 10, endIndent: 40),
          // 默认域字体颜色
          ColorPropertyEditor(
            title: "默认域字体",
            icon: Icons.text_snippet,
            color: (parentData).defaultDomainFontColor,
            displayColor: NodeColorHelper.GetDefaultFontColor(true, parentData.defaultDomainFontColor, context),
            onChanged: (color) {
              (parentData as DomainDrawingData).defaultDomainFontColor = color;
              notify();
            },
            onConfirm: (oldColor, newColor) {
              commandManager.PushCommand(commandManager.editInstance, Command(
                function: () { (parentData as DomainDrawingData).defaultDomainFontColor = newColor; notify(); },
                undoFunction: () { (parentData as DomainDrawingData).defaultDomainFontColor = oldColor; notify(); },
              ));
            },
            onReset: () {
              final oldColor = (parentData as DomainDrawingData).defaultDomainFontColor;
              commandManager.PushCommand(commandManager.editInstance, Command(
                function: () { (parentData as DomainDrawingData).defaultDomainFontColor = null; notify(); },
                undoFunction: () { (parentData as DomainDrawingData).defaultDomainFontColor = oldColor; notify(); },
              ));
              (parentData).defaultDomainFontColor = null;
              notify();
            },
            onStartEdit: () {
              stateModel.State = EditingState.coloringNode;
              _lateSetFocusState(true, manager, model, alignment: -0.6);
            },
            onEndEdit: () {
              stateModel.State = EditingState.none;
              _lateSetFocusState(false, manager, model, alignment: -0.6);
            },
          ),
        ]
      ],
    );
  }
}
