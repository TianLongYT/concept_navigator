import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/ConceptDecoration.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/StatefulComponentManagerModel.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 负责给概念添加修饰词的编辑组件。
/// 具备聚焦视觉中心、动画展开提示栏、修饰词冲突检测等功能。

class NodeDecorationEditorComponent extends StatefulWidget {
  const NodeDecorationEditorComponent({super.key});

  @override
  State<NodeDecorationEditorComponent> createState() => _NodeDecorationEditorComponentState();
}

class _NodeDecorationEditorComponentState extends State<NodeDecorationEditorComponent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _matchQuery = "";

  // 获取继承组件，用于控制滚动锁定和位置
  StlessScrollablePositionedListItem? _inheritedItem;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inheritedItem = context.dependOnInheritedWidgetOfExactType<StlessScrollablePositionedListItem>();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final selection = context.read<SelectionViewData>();
    final manager = context.read<StatefulComponentManagerModelForProvider>();

    if (_focusNode.hasFocus) {
      _lateSetFocusState(true, selection, manager);
    } else {
      _lateSetFocusState(false, selection, manager);
    }
    setState(() {});
  }

  /// 延迟触发聚焦状态更新，确保动画和滚动顺滑
  void _lateSetFocusState(
    bool focus,
    SelectionViewData selection,
    StatefulComponentManagerModelForProvider manager,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setFocusState(
        focus,
        selection,
        manager,
      );
    });
  }

  /// 切换聚焦状态：锁定父列表滚动，并将组件滚动到视觉中心
  void _setFocusState(
    bool focus,
    SelectionViewData selection,
    StatefulComponentManagerModelForProvider manager,
  ) {
    if (_inheritedItem == null) return;

    // 1. 通知父级列表停止/恢复滚动 (取消拖拽功能)
    _inheritedItem!.needStopScroll?.call(focus);

    // 2. 更新 Manager 中的状态 (2 为 Focus 状态)
    final model = selection.IsSelectedDomain ? manager.editingDomainPanel : manager.editingConceptPanel;
    manager.setComponentState(
      model,
      _inheritedItem!.index,
      focus ? 2 : 0,
    );

    // 3. 聚焦时滚动到视觉中心 (alignment: 0.1 约在视口顶部 10% 处)
    if (focus) {
      _inheritedItem!.controller.scrollTo(
        index: _inheritedItem!.index,
        alignment: 0.1,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  /// 构建高亮匹配文本的 RichText (参考 CreatingConceptPanel)
  List<TextSpan> _getHighlightedSpans(
    String text,
    String highlight,
    TextStyle style,
    ColorScheme colorScheme,
  ) {
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

  /// 构建当前节点的修饰词管理按钮列表
  Widget _buildCurrentDecorations(
    String domainNodeKey,
    ConceptDecoration? decoration,
    NodeDrawingData drawingData,
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic,
    ConceptTree2ConceptDecorationDic decorationDic,
    ConceptTreeModel treeModel,
    ColorScheme colorScheme,
  ) {
    if (decoration == null || decoration.modifiers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: decoration.modifiers.entries.map((entry) {
          String mod = entry.key;
          bool isActive = entry.value;

          return Container(
            decoration: BoxDecoration(
              color: isActive ? colorScheme.primaryContainer : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? colorScheme.primary : colorScheme.outline,
                width: 1,
              ),
            ),
            child: IntrinsicWidth(
              child: Row(
                children: [
                  // 主体部分：点击切换状态
                  GestureDetector(
                    onTap: () {
                      bool nextState = !isActive;
                      decorationDic.setEnable(
                        domainNodeKey,
                        mod,
                        enable: nextState,
                      );
                      if (nextState) {
                        drawingData.decoration.add(mod);
                      } else {
                        drawingData.decoration.remove(mod);
                      }

                      nodeDrawingDataDic.repaint();
                      decorationDic.repaint();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        mod,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  // 分割线
                  Container(
                    width: 1,
                    height: 20,
                    color: isActive ? colorScheme.primary.withOpacity(0.3) : colorScheme.outline.withOpacity(0.3),
                  ),
                  // 删除按钮
                  GestureDetector(
                    onTap: () {
                      decorationDic.removeModifier(
                        domainNodeKey,
                        mod,
                        treeModel,
                      );
                      drawingData.decoration.remove(mod);
                      drawingData.repaint();
                      nodeDrawingDataDic.repaint();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<SelectionViewData>();
    final treeModel = context.watch<ConceptTreeModel>();
    final decorationDic = context.watch<ConceptTree2ConceptDecorationDic>();
    final nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    final commandManager = context.read<CommandManagerForProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!selection.IsSelectedConceptNode) return const SizedBox.shrink();

    final selectedNode = selection.SelectedConceptNode!;
    final String domainNodeKey = selectedNode.GetDomainNodeKey();
    final currentDecoration = decorationDic.getDecoration(
      domainNodeKey,
    );

    // 获取对应的 drawingData
    final NodeDrawingData? selectedNodeDrawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNodeKey);

    // 确认按钮状态检查：非空且不与现有修饰词一致（即没有重复）
    final String inputText = _controller.text.trim();
    final bool isDuplicate = currentDecoration?.modifiers.containsKey(inputText) ?? false;
    final bool hasChange = inputText.isNotEmpty && !isDuplicate;

    // 获取提示数据并按优先级分组 (模板 > 实例 > normal)
    final Map<ConceptStatus, ConceptDecoration> hintsMap = decorationDic.getSearchHints(treeModel);
    List<Widget> hintWidgets = [];
    int matchItemCount = 0;

    void addGroup(
      ConceptStatus status,
      String label,
      Color color,
    ) {
      final decoration = hintsMap[status];
      if (decoration != null) {
        final matches = decoration.modifiers.keys
            .where((m) => m.contains(_matchQuery) && _matchQuery.isNotEmpty)
            .toList();

        if (matches.isNotEmpty) {
          hintWidgets.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ));
          for (var mod in matches) {
            matchItemCount++;
            hintWidgets.add(ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: RichText(
                text: TextSpan(
                  children: _getHighlightedSpans(
                    mod,
                    _matchQuery,
                    TextStyle(color: colorScheme.onSurface, fontSize: 14),
                    colorScheme,
                  ),
                ),
              ),
              onTap: () {
                setState(() {
                  _controller.text = mod;
                  _matchQuery = mod;
                  _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                });
              },
            ));
          }
        }
      }
    }

    // 不再受 _focusNode.hasFocus 限制。只要 _matchQuery 不为空且匹配到建议，就生成 Widget
    addGroup(
      ConceptStatus.template,
      "模板修饰词建议",
      colorScheme.primary,
    );
    addGroup(
      ConceptStatus.instance,
      "实例修饰词建议",
      colorScheme.secondary,
    );
    addGroup(
      ConceptStatus.normal,
      "普通修饰词建议",
      colorScheme.tertiary,
    );

    // 动态计算展开高度：解耦焦点依赖。只要有匹配项且查询字符串不为空，就显示面板。
    const double itemHeight = 45.0;
    const double maxHeightLimit = 180.0;
    final double expandedHeight = (matchItemCount > 0 && _matchQuery.isNotEmpty)
        ? (matchItemCount * itemHeight + 20).clamp(0.0, maxHeightLimit)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 0. 当前已添加修饰词列表
          if (selectedNodeDrawingData != null)
            _buildCurrentDecorations(
              domainNodeKey,
              currentDecoration,
              selectedNodeDrawingData,
              nodeDrawingDataDic,
              decorationDic,
              treeModel,
              colorScheme,
            ),

          // 1. 输入框
          TextField(
            controller: _controller,
            focusNode: _focusNode, // 重新绑定以支持视觉中心滚动逻辑
            decoration: InputDecoration(
              labelText: "编辑/添加修饰词",
              hintText: "请输入修饰词字符串",
              prefixIcon: const Icon(Icons.style_outlined),
              errorText: isDuplicate ? "该修饰词已存在" : null,
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                            _controller.clear();
                            _matchQuery = "";
                          }))
                  : null,
            ),
            onChanged: (val) {
              setState(() {
                _matchQuery = val;
              });
            },
          ),

          // 2. 提示栏 (动画展开)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: expandedHeight,
            margin: EdgeInsets.only(top: expandedHeight > 0 ? 8 : 0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: expandedHeight > 0 ? Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: expandedHeight > 0 ? ListView(shrinkWrap: true, children: hintWidgets) : null,
            ),
          ),

          const SizedBox(height: 12),

          // 3. 确认按钮
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text("确认添加"),
            onPressed: (hasChange && selectedNodeDrawingData != null)
                ? () {
                    final String modToAdd = _controller.text.trim();
                    void doChange(){
                      decorationDic.addModifier(
                        domainNodeKey,
                        modToAdd,
                        treeModel,
                      );
                      // 同步修改 drawingData
                      selectedNodeDrawingData.decoration.add(modToAdd);
                      nodeDrawingDataDic.repaint();
                    }
                    // 提交更改指令
                    commandManager.PushCommand(
                        commandManager.editInstance,
                        Command(
                            function: doChange,
                            undoFunction: () {
                              decorationDic.removeModifier(
                                domainNodeKey,
                                modToAdd,
                                treeModel,
                              );
                              // 同步撤回 drawingData
                              selectedNodeDrawingData.decoration.remove(modToAdd);
                              nodeDrawingDataDic.repaint();
                            }));
                    doChange();
                    setState(() {
                      _controller.clear();
                      _matchQuery = "";
                    });
                    _focusNode.unfocus();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
