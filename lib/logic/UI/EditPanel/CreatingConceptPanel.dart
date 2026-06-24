import 'dart:io';

import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeConflictCheck.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodePosition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'NodeRenameComponent/UsePathAsAliasComponent.dart'; // 引入公共组件

class CreatingConceptPanel extends StatefulWidget {
  const CreatingConceptPanel({super.key});

  @override
  State<CreatingConceptPanel> createState() => _CreatingConceptPanelState();
}

class _CreatingConceptPanelState extends State<CreatingConceptPanel> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController aliasController = TextEditingController();

  bool _usePathAsAlias = false;

  bool hasError = true;
  String? nameError = "概念名不能为空";
  String? aliasError = null;

  // 搜索建议分组
  List<ConceptNodeTree> _templateGroup = [];
  List<ConceptNodeTree> _instanceGroup = [];
  List<ConceptNodeTree> _normalGroup = [];
  String _searchQuery = "";

  ConceptErrorCheck errorCheckHelper = ConceptErrorCheck();

  void nameErrorCheck(ConceptTreeModel treeModel, SelectionViewData selection, String textValue, String alias) {
    String? errorText = errorCheckHelper.NameErrorCheck(treeModel, selection, textValue, alias);
    setState(() {
      hasError = errorText != null;
      nameError = errorText;
      if (!hasError) aliasError = null;
    });
    // 触发建议更新
    _updateSuggestions(textValue, treeModel, selection);
  }

  void aliasErrorCheck(ConceptTreeModel treeModel, SelectionViewData selection, String textValue, String alias) {
    String? errorText = errorCheckHelper.AliasErrorCheck(treeModel, selection, textValue, alias);
    setState(() {
      hasError = errorText != null;
      aliasError = errorText;
      if (!hasError) nameError = null;
    });
  }

  /// 更新同名概念建议列表
  void _updateSuggestions(String query, ConceptTreeModel treeModel, SelectionViewData selection) {
    if (query.isEmpty) {
      setState(() {
        _templateGroup = [];
        _instanceGroup = [];
        _normalGroup = [];
        _searchQuery = "";
      });
      return;
    }

    List<ConceptNodeTree> templates = [];
    List<ConceptNodeTree> instances = [];
    List<ConceptNodeTree> normals = [];

    // 在当前域中寻找匹配节点
    DomainTree? domain = treeModel.GetDomainTree(selection.currentDomain);
    if (domain != null) {
      List<ConceptNodeTree> allMatches = [];
      void traverse(NodeTree node) {
        if (node is ConceptNodeTree) {
          if (node.name.contains(query)) allMatches.add(node);
          for (var child in node.children) traverse(child);
        } else if (node is DomainTree) {
          for (var c in node.conceptNodeTree) traverse(c);
        }
      }
      for (var concept in domain.conceptNodeTree) traverse(concept);

      for (var node in allMatches) {
        ConceptStatus status = node.getStatus(treeModel);
        if (status == ConceptStatus.template) {
          templates.add(node);
        } else if (status == ConceptStatus.instance) {
          instances.add(node);
        } else if(status == ConceptStatus.normal) {
          normals.add(node);
        }
      }
    }

    setState(() {
      _templateGroup = templates;
      _instanceGroup = instances;
      _normalGroup = normals;
      _searchQuery = query;
    });
  }

  String _getNodePath(ConceptNodeTree node) {
    List<String> pathParts = [];
    NodeTree? current = node.parent;
    while (current != null) {
      pathParts.insert(0, current.name);
      if (current is DomainTree) current = current.parent;
      else if (current is ConceptNodeTree) current = current.parent;
      else break;
    }
    String sep = kIsWeb ? "/" : Platform.pathSeparator;
    return pathParts.join(sep);
  }

  /// 构建高亮的单条建议项 (紧凑版)
  Widget _buildSuggestionItem(ConceptNodeTree node, ColorScheme colorScheme, ConceptTreeModel treeModel, SelectionViewData selection) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      onTap: () {
        setState(() {
          controller.text = node.name;
          controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        });
        nameErrorCheck(treeModel, selection, node.name, aliasController.text);
      },
      title: _buildFormattedRichName(node, _searchQuery, colorScheme),
      subtitle: Text(
        "路径: ${_getNodePath(node)}",
        style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant, height: 1.1),
      ),
    );
  }

  Widget _buildFormattedRichName(ConceptNodeTree node, String query, ColorScheme colorScheme) {
    List<TextSpan> spans = _getHighlightedSpans(
      node.name,
      query,
      TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12),
      colorScheme,
    );

    if (node.alias.isNotEmpty) {
      spans.add(TextSpan(
        text: " (${node.alias})",
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.normal),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  List<TextSpan> _getHighlightedSpans(String text, String highlight, TextStyle style, ColorScheme colorScheme) {
    if (highlight.isEmpty || !text.contains(highlight)) {
      return [TextSpan(text: text, style: style)];
    }
    List<TextSpan> spans = [];
    int start = 0;
    int index;
    while ((index = text.indexOf(highlight, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + highlight.length),
        style: style.copyWith(
          backgroundColor: colorScheme.primaryContainer,
          color: colorScheme.onPrimaryContainer,
        ),
      ));
      start = index + highlight.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    CommandManagerForProvider commandManager = context.read<CommandManagerForProvider>();
    AddressBarModel addressBar = context.read<AddressBarModel>();
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    FocusNodeHelper focusNodeHelper = FocusNodeHelper.lateInit(context);

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        children: [
          const Center(child: Text("新建概念")),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.dashboard_customize_rounded),
              hintText: "请输入概念名",
              labelText: "请输入概念名",
              helperText: "概念名区别不同概念，同概念名的概念相同",
              errorText: nameError,
            ),
            onChanged: (value) => nameErrorCheck(treeModel, selection, value, aliasController.text),
          ),

          if (_searchQuery.isNotEmpty && (_templateGroup.isNotEmpty || _instanceGroup.isNotEmpty || _normalGroup.isNotEmpty))
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_templateGroup.isNotEmpty) ...[
                    _buildGroupHeader("模板节点", colorScheme.primary, colorScheme),
                    ..._templateGroup.map((n) => _buildSuggestionItem(n, colorScheme, treeModel, selection)),
                  ],
                  if (_instanceGroup.isNotEmpty) ...[
                    _buildGroupHeader("引用实例", colorScheme.secondary, colorScheme),
                    ..._instanceGroup.map((n) => _buildSuggestionItem(n, colorScheme, treeModel, selection)),
                  ],
                  if (_normalGroup.isNotEmpty) ...[
                    _buildGroupHeader("普通概念", colorScheme.tertiary, colorScheme),
                    ..._normalGroup.map((n) => _buildSuggestionItem(n, colorScheme, treeModel, selection)),
                  ],
                ],
              ),
            ),

          UsePathAsAliasComponent(
            value: _usePathAsAlias,
            onChanged: (bool value) {
              setState(() {
                _usePathAsAlias = value;
                // 暂时不手动计算，而是通过 GenerateDic 自动同步
                // 需要通过当前路径获取父概念层级。
                nameErrorCheck(treeModel, selection, controller.text, aliasController.text);
              });
            },
          ),

          TextField(
            controller: aliasController,
            enabled: !_usePathAsAlias,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.nest_cam_wired_stand),
              hintText: "请输入别名",
              labelText: "概念的别名,默认为空",
              helperText: "取不同别名以区别同名概念",
              errorText: aliasError,
            ),
            onChanged: (value) => aliasErrorCheck(treeModel, selection, controller.text, value),
          ),
          OutlinedButton(
            onPressed: hasError ? null : () {
              ConceptNodeTree node2Add = ConceptNodeTree()
                ..name = controller.text
                ..alias = aliasController.text
                ..autoAlias = _usePathAsAlias; // 应用自动别名设置

              NodeDrawingData newDrawingData = NodeDrawingData(nodeAppearance: NodeAppearance())..text = controller.text;
              NodeViewData newViewData = NodeViewData();

              // 提前从 selection 中提取并固化数据，确保 Undo/Redo 时不受当前 UI 状态影响
              final bool isParentDomain = selection.IsInDomain;
              final String parentKey = selection.IsInDomain ? selection.currentDomain : selection.CurrentDomainNodeKey;
              final String currentDomain = selection.currentDomain;
              final String controllerText = controller.text;

              void doCreate() {
                //final String parentKey = selection.IsInDomain ? selection.currentDomain : selection.CurrentDomainNodeKey;
                //final bool isParentDomain = selection.IsInDomain;

                if (isParentDomain) {
                  if (!treeModel.AddNewConceptInDomain(parentKey, node2Add)) {
                    throw Exception("错误：找不到当前界面的domainTree");
                  }
                  domainDrawingDataDic.GetDomainDrawingData(parentKey)?.AddNodeDrawingData();
                } else {
                  if (!treeModel.AddNewConceptInConceptNode(parentKey, node2Add)) {
                    throw Exception("错误：找不到当前界面的nodeTree");
                  }
                  nodeDrawingDataDic.GetNodeDrawingData(parentKey)?.AddNodeDrawingData();
                }

                // 重新同步 UI 显示的 Alias (因为 AddNew... 会触发 GenerateDic)
                if(node2Add.autoAlias){
                  aliasController.text = node2Add.alias;
                }

                String newKey = ConceptTreeModel.GenerateDomainNodeKey(currentDomain, controllerText, node2Add.alias);
                nodeDrawingDataDic.putIfAbsent(newKey, () => newDrawingData);
                viewDataDic.putIfAbsent(newKey, () => newViewData);

                selection.SelectAndFocusNode(
                  selectedNode: node2Add,
                  parent: node2Add.parent!,
                  globalState: stateModel,
                  addressBar: addressBar,
                  treeModel: treeModel,
                  nodeDrawingDataDic: nodeDrawingDataDic,
                  domainDrawingDataDic: domainDrawingDataDic,
                  viewDrawingDataDic: viewDataDic,
                );
              }

              void undoCreate() {
                //final String parentKey = selection.IsInDomain ? selection.currentDomain : selection.CurrentDomainNodeKey;
                //final bool isParentDomain = selection.IsInDomain;
                String currentAlias = node2Add.alias;
                String currentKey = ConceptTreeModel.GenerateDomainNodeKey(currentDomain, controllerText, currentAlias);

                if (isParentDomain) {
                  treeModel.RemoveConceptFromDomain(parentKey, node2Add);
                  domainDrawingDataDic.GetDomainDrawingData(parentKey)?.RemoveAtNodeDrawingDataSqueeze(
                    treeModel.GetDomainTree(parentKey)!.conceptNodeTree.length
                  );
                } else {
                  treeModel.RemoveConceptFromConcept(parentKey, node2Add);
                  nodeDrawingDataDic.GetNodeDrawingData(parentKey)?.RemoveAtNodeDrawingDataSqueeze(
                    treeModel.GetConceptNodeByDic(parentKey)!.children.length
                  );
                }
                if (!treeModel.ContainConceptNode(currentKey)) {
                  nodeDrawingDataDic.remove(currentKey);
                  viewDataDic.remove(currentKey);
                }
                selection.CancelSelectionAndJumpOutParent(
                  selectedNode: node2Add,
                  parent: node2Add.parent!,
                  globalState: stateModel,
                  addressBar: addressBar,
                  treeModel: treeModel,
                  nodeDrawingDataDic: nodeDrawingDataDic,
                  domainDrawingDataDic: domainDrawingDataDic,
                  viewDrawingDataDic: viewDataDic,
                );
              }

              doCreate();
              commandManager.PushCommand(commandManager.editInstance, Command(
                function: doCreate,
                undoFunction: undoCreate,
              ));

              controller.clear();
              aliasController.clear();
              nameErrorCheck(treeModel, selection, "", "");
              aliasErrorCheck(treeModel, selection, "", "");
            },
            child: const Text("新建概念"),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, Color textColor, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 8, 0),
      child: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
