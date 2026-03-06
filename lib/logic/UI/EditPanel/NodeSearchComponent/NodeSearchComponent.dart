
//-------Gemini生成--------
import 'dart:io';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodePosition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchResult {
  final NodeTree node;
  final String path;
  final bool isPriority; // 是否通过名称或别名匹配
  final NodeTree? parent; // 记录父节点以便于聚焦

  SearchResult({
    required this.node,
    required this.path,
    required this.isPriority,
    this.parent,
  });
}

class NodeSearchComponent extends StatefulWidget {
  const NodeSearchComponent({super.key});

  @override
  State<NodeSearchComponent> createState() => _NodeSearchComponentState();
}

class _NodeSearchComponentState extends State<NodeSearchComponent> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResult> _results = [];
  String _lastQuery = "";

  // 字体大小变量
  static const double _nameFontSize = 16.0;
  static const double _aliasFontSize = 14.0;
  static const double _pathFontSize = 12.0;

  // 根据平台获取路径分隔符
  String get _separator => kIsWeb ? "/" : Platform.pathSeparator;

  void _onSearch(String query, ConceptTreeModel treeModel) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = "";
      });
      return;
    }

    List<SearchResult> priorityMatches = [];
    List<SearchResult> pathMatches = [];

    // 区分显示路径和搜索路径，实现系统 root 排除逻辑
    void traverse(NodeTree node, NodeTree? parent, String currentDisplayPath, String currentSearchablePath) {
      // 初始 root 节点的特征是 parent 为空且为 DomainTree
      bool isSystemRoot = node is DomainTree && node.parent == null;

      if (!isSystemRoot) {
        String nodeName = node.name;
        String nodeAlias = (node is ConceptNodeTree) ? node.alias : "";

        // 用于显示的路径：包含 system root
        String displayPath = currentDisplayPath + _separator;
        // 用于搜索的路径：排除 system root 的名字
        String searchablePath = currentSearchablePath + _separator;

        bool nameMatched = nodeName.contains(query);
        bool aliasMatched = nodeAlias.contains(query);
        // 使用 searchablePath 进行路径模糊匹配
        bool pathMatched = searchablePath.contains(query);

        if (nameMatched || aliasMatched) {
          priorityMatches.add(SearchResult(
            node: node,
            parent: parent,
            path: displayPath,
            isPriority: true,
          ));
        } else if (pathMatched) {
          pathMatches.add(SearchResult(
            node: node,
            parent: parent,
            path: displayPath,
            isPriority: false,
          ));
        }
      }

      // 下一级显示路径总是包含当前节点名
      String nextDisplayPath = currentDisplayPath.isEmpty ? node.name : "$currentDisplayPath$_separator${node.name}";

      // 下一级搜索路径：如果是初始 root 节点，则不向下传递它的名字
      String nextSearchablePath;
      if (isSystemRoot) {
        nextSearchablePath = "";
      } else {
        nextSearchablePath = currentSearchablePath.isEmpty ? node.name : "$currentSearchablePath$_separator${node.name}";
      }

      if (node is DomainTree) {
        for (var child in node.children) {
          traverse(child, node, nextDisplayPath, nextSearchablePath);
        }
        for (var concept in node.conceptNodeTree) {
          traverse(concept, node, nextDisplayPath, nextSearchablePath);
        }
      } else if (node is ConceptNodeTree) {
        for (var child in node.children) {
          traverse(child, node, nextDisplayPath, nextSearchablePath);
        }
      }
    }

    if (treeModel.rootTree != null) {
      traverse(treeModel.rootTree!, null, "", "");
    }

    setState(() {
      _lastQuery = query;
      _results = [...priorityMatches, ...pathMatches];
    });
  }

  /// 构建带高亮和前缀标签的富文本：节点名：(名字) 别名：(别名)
  Widget _buildFormattedName(
      NodeTree node,
      String query, {
        required Color labelColor,
        required Color nameColor,
        required Color aliasColor,
        required Color highlightBg,
        required Color highlightText,
      }) {
    List<TextSpan> children = [];

    // 节点名部分
    children.add(TextSpan(
      text: "节点名：",
      style: TextStyle(color: labelColor, fontWeight: FontWeight.normal, fontSize: _nameFontSize),
    ));
    children.addAll(_getHighlightedSpans(
      node.name,
      query,
      TextStyle(color: nameColor, fontWeight: FontWeight.bold, fontSize: _nameFontSize),
      highlightBg: highlightBg,
      highlightText: highlightText,
    ));

    // 别名部分 (仅在 ConceptNode 且别名不为空时显示)
    if (node is ConceptNodeTree && node.alias.isNotEmpty) {
      children.add(TextSpan(
        text: "  别名：",
        style: TextStyle(color: labelColor, fontWeight: FontWeight.normal, fontSize: _aliasFontSize),
      ));
      children.addAll(_getHighlightedSpans(
        node.alias,
        query,
        TextStyle(color: aliasColor, fontSize: _aliasFontSize),
        highlightBg: highlightBg,
        highlightText: highlightText,
      ));
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: children),
    );
  }

  Widget _buildHighlightText(
      String text,
      String highlight, {
        required TextStyle style,
        required Color highlightBg,
        required Color highlightText,
      }) {
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: _getHighlightedSpans(
            text,
            highlight,
            style,
            highlightBg: highlightBg,
            highlightText: highlightText
        ),
      ),
    );
  }

  List<TextSpan> _getHighlightedSpans(
      String text,
      String highlight,
      TextStyle style, {
        required Color highlightBg,
        required Color highlightText,
      }) {
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
        style: style.copyWith(backgroundColor: highlightBg, color: highlightText),
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
    final treeModel = context.watch<ConceptTreeModel>();
    final addressBar = context.read<AddressBarModel>();
    final globalState = context.read<GlobalStateModel>();

    final nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>();
    final domainDrawingDataDic = context.read<ConceptTree2DomainDrawingDataDic>();
    final viewDrawingDataDic = context.read<ConceptTree2NodeViewDataDic>();
    final colorScheme = Theme.of(context).colorScheme;

    // 提取颜色变量，接入全局主题
    final Color labelColor = colorScheme.onSurfaceVariant;   // 标签颜色 (节点名：, 别名：)
    final Color nameColor = colorScheme.onSurface;           // 具体的节点名颜色
    final Color aliasColor = colorScheme.onSurfaceVariant;   // 具体的别名颜色
    final Color pathColor = colorScheme.onSurfaceVariant;    // 路径颜色
    final Color highlightBg = colorScheme.primaryContainer;  // 高亮背景色
    final Color highlightText = colorScheme.onPrimaryContainer; // 高亮文字颜色

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "搜索节点名、别名或路径...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _onSearch("", treeModel);
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => _onSearch(value, treeModel),
          ),
        ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _results.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final result = _results[index];
              return ListTile(
                onTap: () => _focusNode(result,globalState,addressBar,treeModel,nodeDrawingDataDic,domainDrawingDataDic,viewDrawingDataDic),
                title: _buildFormattedName(
                  result.node,
                  _lastQuery,
                  labelColor: labelColor,
                  nameColor: nameColor,
                  aliasColor: aliasColor,
                  highlightBg: highlightBg,
                  highlightText: highlightText,
                ),
                subtitle: _buildHighlightText(
                  result.path,
                  _lastQuery,
                  style: TextStyle(fontSize: _pathFontSize, color: pathColor),
                  highlightBg: highlightBg,
                  highlightText: highlightText,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _focusNode(SearchResult result,GlobalStateModel globalState,AddressBarModel addressBar,ConceptTreeModel treeModel,ConceptTree2NodeDrawingDataDic nodeDrawingDataDic,ConceptTree2DomainDrawingDataDic domainDrawingDataDic,ConceptTree2NodeViewDataDic viewDrawingDataDic,) {
    final selection = context.read<SelectionViewData>();
    final node = result.node;
    final parent = result.parent;
    if (parent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("错误: 无法找到节点 '${node.name}' 的父节点。")),
      );
      return;
    }
    selection.SelectAndFocusNode(
        selectedNode: node,
        parent: parent,
        globalState: globalState,
        addressBar: addressBar,
        treeModel: treeModel,
        nodeDrawingDataDic: nodeDrawingDataDic,
        domainDrawingDataDic: domainDrawingDataDic,
        viewDrawingDataDic: viewDrawingDataDic
    );
    // final addressBar = context.read<AddressBarModel>();
    // final treeModel = context.read<ConceptTreeModel>();
    //
    //
    //
    //
    // if (parent is DomainTree) {
    //   selection.currentDomain = parent.GetDomainKey();
    //   selection.currentConceptNodeName = "";
    //   selection.currentConceptNodeAlias = "";
    // } else if (parent is ConceptNodeTree) {
    //   selection.currentDomain = parent.domainKey;
    //   selection.currentConceptNodeName = parent.name;
    //   selection.currentConceptNodeAlias = parent.alias;
    // }
    //
    // if (node is DomainTree) {
    //   selection.SelectedDomain = node;
    //   selection.SelectedConceptNode = null;
    // } else if (node is ConceptNodeTree) {
    //   selection.SelectedConceptNode = node;
    //   selection.SelectedDomain = null;
    // }
    //
    // addressBar.updateAddressBar(parent, treeModel);
    // _animateToNode(result);
  }



  void _animateToNode(SearchResult result) {
    final parent = result.parent;
    final node = result.node;

    if (parent == null) return;

    final nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>();
    final domainDrawingDataDic = context.read<ConceptTree2DomainDrawingDataDic>();
    Size? nodeAllSize;

    if (node is ConceptNodeTree) {
      final drawingData = nodeDrawingDataDic.GetNodeDrawingData(node.GetDomainNodeKey());
      if (drawingData != null) {
        nodeAllSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
      }
    } else if (node is DomainTree) {
      final drawingData = domainDrawingDataDic.GetDomainDrawingData(node.GetDomainKey());
      if (drawingData != null) {
        nodeAllSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
      }
    }

    final focusHelper = FocusNodeHelper(
      context,
      parent.IsInDomain,
      parent.GetDomainKey(),
      parent.GetDomainNodeKey(),
      nodeAllSize: nodeAllSize,
    );

    if (node is ConceptNodeTree) {
      focusHelper.FocusNode(node, null);
    } else if (node is DomainTree) {
      focusHelper.FocusNode(null, node);
    }
  }
}