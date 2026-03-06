import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/StatefulComponentManagerModel.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeAppearanceEditorComponent/ColorPropertyEditorComponent.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodeColor.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:concept_navigator/logic/testColorPicker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NodeAppearanceEditorComponent extends StatefulWidget {
  const NodeAppearanceEditorComponent({super.key});

  @override
  State<NodeAppearanceEditorComponent> createState() => _NodeAppearanceEditorComponentState();
}

class _NodeAppearanceEditorComponentState extends State<NodeAppearanceEditorComponent> {


  // 状态控制：0 为收缩列表态，1 为展开色轮编辑态
  int editorState = 0;
  Color? _originalColor; // 用于撤销记录
  late Color _tempSelectColor; // 正在编辑的颜色
  late CommandManagerForProvider commandManagerProvider;
// 获取 InheritedWidget 用于控制滚动锁定
  StlessScrollablePositionedListItem? _inheritedItem;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 缓存 InheritedWidget 引用
    _inheritedItem = context.dependOnInheritedWidgetOfExactType<StlessScrollablePositionedListItem>();
  }
  @override
  void initState() {
    super.initState();


    _tempSelectColor = Colors.white;
  }
  void _lateSetFocusState(bool focus, SelectionViewData selection, StatefulComponentManagerModelForProvider manager,{double alignment = 0}){

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration.zero,(){
        _setFocusState(focus, selection, manager,alignment: alignment);
      });
    });
    _setFocusState(focus, selection, manager,alignment: alignment);

  }
  /// 切换聚焦状态逻辑
  void _setFocusState(bool focus, SelectionViewData selection, StatefulComponentManagerModelForProvider manager,{double alignment = 0}) {
    if (_inheritedItem == null) return;

    // 1. 通知父级列表停止/恢复滚动
    _inheritedItem!.needStopScroll?.call(focus);

    // 2. 更新 Manager 中的状态 (2 为 Focus 状态)
    final model = selection.IsSelectedDomain ? manager.editingDomainPanel : manager.editingConceptPanel;
    manager.setComponentState(model, _inheritedItem!.index, focus ? 2 : 0);

    // 3. 如果是聚焦，自动滚动到中心偏上位置
    if (focus) {
      _inheritedItem!.controller.scrollTo(
        index: _inheritedItem!.index,
        alignment: alignment, // 0.1 约在视口顶部 10% 处，给展开的色轮留空间
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double wheelHeight = 170;


    //获取外观文件。修改。。。。
    commandManagerProvider = context.read<CommandManagerForProvider>();
    final manager = context.read<StatefulComponentManagerModelForProvider>();
    final stateModel = context.read<EditingStateModel>();

    SelectionViewData selection = context.watch<SelectionViewData>();

    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();

    NodeColorHelper nodeColorHelper = NodeColorHelper(nodeDrawingDataDic:nodeDrawingDataDic,domainDrawingDataDic: domainDrawingDataDic );
    nodeColorHelper.InitData(selection.IsInDomain, selection.CurrentDomainNodeKey, selection.IsSelectedDomain, selection.IsSelectedDomain?selection.SelectedDomain!.GetDomainNodeKey():(selection.IsSelectedConceptNode?selection.SelectedConceptNode!.GetDomainNodeKey():""));

    final appearance = nodeColorHelper.nodeAppearance!;
    final bool isDomain = selection.IsSelectedDomain;
    void notify() {
      if (isDomain) domainDrawingDataDic.repaint(); else nodeDrawingDataDic.repaint();
    }

    //目前支持的修改：
    //节点形状。
    //节点颜色。
    //字体颜色。
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          // 背景颜色编辑
          ColorPropertyEditor(
            title: "背景颜色",
            icon: Icons.color_lens_outlined,
            color: appearance.nodeColor,
            displayColor: nodeColorHelper.getNodeColor(context),
            onChanged: (color) {
              appearance.nodeColor = color;
              notify();
            },
            onConfirm: (oldColor, newColor) {
              commandManagerProvider.PushCommand(commandManagerProvider.editInstance, Command(
                function: () { appearance.nodeColor = newColor; notify(); },
                undoFunction: () { appearance.nodeColor = oldColor; notify(); },
              ));
            },
            onReset: () {
              final oldColor = appearance.nodeColor;
              commandManagerProvider.PushCommand(commandManagerProvider.editInstance, Command(
                function: () { appearance.nodeColor = null; notify(); },
                undoFunction: () { appearance.nodeColor = oldColor; notify(); },
              ));
              appearance.nodeColor = null;
              notify();
            },
            onStartEdit: () {
              stateModel.State = EditingState.coloringNode;
              _lateSetFocusState(true, alignment: 0.0, selection, manager);
            },
            onEndEdit: () {
              stateModel.State = EditingState.none;
              _lateSetFocusState(false, alignment: 0.0, selection, manager);
            },
          ),
          const Divider(height: 1, indent: 10,endIndent:40),
          // 字体颜色编辑
          ColorPropertyEditor(
            title: "字体颜色",
            icon: Icons.text_fields,
            color: appearance.fontColor,
            displayColor: nodeColorHelper.getFontColor(context),
            onChanged: (color) {
              appearance.fontColor = color;
              notify();
            },
            onConfirm: (oldColor, newColor) {
              commandManagerProvider.PushCommand(commandManagerProvider.editInstance, Command(
                function: () { appearance.fontColor = newColor; notify(); },
                undoFunction: () { appearance.fontColor = oldColor; notify(); },
              ));
            },
            onReset: () {
              final oldColor = appearance.fontColor;
              commandManagerProvider.PushCommand(commandManagerProvider.editInstance, Command(
                function: () { appearance.fontColor = null; notify(); },
                undoFunction: () { appearance.fontColor = oldColor; notify(); },
              ));
              appearance.fontColor = null;
              notify();
            },
            onStartEdit: (){
              stateModel.State = EditingState.coloringNode;
              _lateSetFocusState(true,alignment: -0.2, selection, manager);
            },
            onEndEdit: () {
              stateModel.State = EditingState.none;
              _lateSetFocusState(false,alignment: -0.2, selection, manager);
            },
          ),
        ],
      ),
    );

    // return AnimatedContainer(
    //   duration: const Duration(milliseconds: 200),
    //   curve: Curves.easeInOutCubic,
    //   width: double.infinity,
    //   padding: const EdgeInsets.only(bottom: 8),
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       _buildTopRow(nodeColorHelper.nodeAppearance!,nodeColorHelper.getNodeColor(context), selection, manager, stateModel, nodeDrawingDataDic, domainDrawingDataDic),
    //       _buildAnimatedColorWheel(wheelHeight, nodeColorHelper.nodeAppearance!, nodeDrawingDataDic, domainDrawingDataDic),
    //       if (editorState == 0) const Divider(height: 1, indent: 40),
    //     ],
    //   ),
    // );

    // return AnimatedContainer(
    //   duration: const Duration(milliseconds: 200),
    //   width: double.infinity,
    //   // 编辑态时高度增加，常态保持紧凑
    //   //height: editorState == 1 ? wheelHeight + 50 : 60,
    //   // 关键 1：不要使用 minHeight，直接根据状态控制高度或约束
    //   padding: const EdgeInsets.only(bottom: 8),
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       // 第一行：标题 + (常态下的指示器 / 编辑态下的按钮组)
    //       Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    //         child: Row(
    //           children: [
    //             const Icon(Icons.color_lens_outlined, size: 24),
    //             const SizedBox(width: 12),
    //             const Text("背景颜色", style: TextStyle(fontWeight: FontWeight.bold)),
    //             const Spacer(),
    //
    //             if (editorState == 0)
    //             // 常态：只显示颜色指示器，点击展开
    //               ColorIndicator(
    //                 width: 35,
    //                 height: 35,
    //                 borderRadius: 4,
    //                 color: appearance!.nodeColor ?? Colors.transparent,
    //                 onSelect: () {
    //                   stateModel.State = EditingState.coloringNode;
    //
    //                   setState(() {
    //                     _originalColor = appearance!.nodeColor;
    //                     _tempSelectColor = appearance.nodeColor ?? Colors.blue;
    //                     editorState = 1;
    //                   });
    //
    //                   // 关键：延迟到下一帧，此时 editorState 已经生效，
    //                   // AnimatedCrossFade 开始撑开高度，ListView 能计算出新的最大滚动范围。
    //                   WidgetsBinding.instance.addPostFrameCallback((_) {
    //                     Future.delayed(Duration.zero,(){
    //                       _setFocusState(true, selection, manager);
    //                     });
    //                   });
    //                   _setFocusState(true, selection, manager);
    //                 },
    //               )
    //             else
    //             // 编辑态：指示器 + 取消/确定按钮横向排布
    //               Row(
    //                 children: [
    //                   // 指示器展示当前预览色
    //                   ColorIndicator(
    //                     width: 30,
    //                     height: 30,
    //                     borderRadius: 4,
    //                     color: _tempSelectColor,
    //                   ),
    //                   const SizedBox(width: 8),
    //                   IconButton(
    //                     visualDensity: VisualDensity.compact,
    //                     icon: const Icon(Icons.close, color: Colors.red),
    //                     onPressed: () {
    //                       stateModel.State = EditingState.none;
    //                       appearance!.nodeColor = _originalColor;
    //                       nodeDrawingDataDic.repaint();
    //                       domainDrawingDataDic.repaint();
    //                       setState(() => editorState = 0);
    //                       _setFocusState(false, selection, manager);
    //                     },
    //                   ),
    //                   IconButton(
    //                     visualDensity: VisualDensity.compact,
    //                     icon: const Icon(Icons.check, color: Colors.green),
    //                     onPressed: () {
    //                       stateModel.State = EditingState.none;
    //                       final Color? oldColor = _originalColor;
    //                       final Color newColor = _tempSelectColor;
    //                       commandManagerProvider.PushCommand(
    //                         commandManagerProvider.editInstance,
    //                         Command(
    //                           function: () {
    //                             appearance!.nodeColor = newColor;
    //                             nodeDrawingDataDic.repaint();
    //                             domainDrawingDataDic.repaint();
    //                           },
    //                           undoFunction: () {
    //                             appearance!.nodeColor = oldColor;
    //                             nodeDrawingDataDic.repaint();
    //                             domainDrawingDataDic.repaint();
    //                           },
    //                         ),
    //                       );
    //                       setState(() => editorState = 0);
    //                       _setFocusState(false, selection, manager);
    //                     },
    //                   ),
    //                 ],
    //               ),
    //           ],
    //         ),
    //       ),
    //
    //       // 第二行：如果处于编辑态，展开色轮
    //       // --- 关键修改：移除外部的 if (editorState == 1) ---
    //       // 只有让 AnimatedCrossFade 始终在树中，它才能感知状态变化并做动画
    //       AnimatedCrossFade(
    //         // 状态为 0 时，显示这个空盒子，高度为 0
    //         firstChild: const SizedBox(width: double.infinity, height: 0),
    //
    //         // 状态为 1 时，显示色轮
    //         secondChild: Container(
    //           // 这里用 Container 增加一点间距，防止色轮贴着标题
    //           padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
    //           height: wheelHeight + 20, // 稍微多给一点点空间防止剪裁
    //           child: ColorWheelPicker(
    //             color: _tempSelectColor,
    //             onChanged: (Color color) {
    //               setState(() => _tempSelectColor = color);
    //               appearance!.nodeColor = color;
    //               nodeDrawingDataDic.repaint();
    //               domainDrawingDataDic.repaint();
    //             },
    //             onWheel: (bool value) { },
    //           ),
    //         ),
    //
    //         // 这里的判断逻辑决定了显示哪一个
    //         crossFadeState: editorState == 1
    //             ? CrossFadeState.showSecond
    //             : CrossFadeState.showFirst,
    //         duration: const Duration(milliseconds: 300),
    //         // 让高度变换更平滑
    //         sizeCurve: Curves.easeInOutCubic,
    //       ),
    //
    //       // 如果你之后要加“形状编辑”，直接在下方继续添加 Row 即可，维持了独立性
    //       if (editorState == 0)
    //         const Divider(height: 1, indent: 40),
    //     ],
    //   ),
    // );
  }
// --- 抽离出顶部UI构建方法，使 build 方法更清晰 ---
  Widget _buildTopRow(
      NodeAppearance appearance,
      Color actualColor,
      SelectionViewData selection,
      StatefulComponentManagerModelForProvider manager,
      EditingStateModel stateModel,
      ConceptTree2NodeDrawingDataDic nDic,
      ConceptTree2DomainDrawingDataDic dDic,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.color_lens_outlined, size: 24),
          const SizedBox(width: 12),
          const Text("背景颜色", style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 常驻的“复原”按钮
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: "复原为默认颜色",
                // 仅当有自定义颜色时才可点击
                onPressed: appearance.nodeColor == null ? null : () => _handleResetColor(appearance, selection, nDic, dDic),
              ),
              const SizedBox(width: 4),

              // 2. 状态切换区：色卡 或 确认/取消按钮
              if (editorState == 0)
                ColorIndicator(
                  width: 35,
                  height: 35,
                  borderRadius: 4,
                  color: actualColor, // 显示透明表示无设置
                  onSelect: () => _startEditing(appearance, selection, manager, stateModel),
                )
              else
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _cancelEditing(appearance, selection, manager, stateModel, nDic, dDic),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _confirmEditing(appearance, selection, manager, stateModel, nDic, dDic),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
  // --- 核心方法：构建带动画的色轮 ---
  Widget _buildAnimatedColorWheel(
      double wheelHeight,
      NodeAppearance appearance,
      ConceptTree2NodeDrawingDataDic nDic,
      ConceptTree2DomainDrawingDataDic dDic,
      ) {
    // 预先判定节点类型，用于闭包捕获，防止 Undo 时 Selection 已变
    final bool isDomainAtCapture = context.read<SelectionViewData>().IsSelectedDomain;

    return AnimatedCrossFade(
      // 状态为 0 时，显示这个空盒子，高度为 0
      firstChild: const SizedBox(width: double.infinity, height: 0),

      // 状态为 1 时，显示色轮
      secondChild: Container(
        padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
        height: wheelHeight + 20,
        child: ColorWheelPicker(
          color: _tempSelectColor,
          onChanged: (Color color) {
            setState(() => _tempSelectColor = color);

            // 实时预览更新数据
            appearance.nodeColor = color;

            // 实时预览重绘：根据捕获的类型精准刷新，避免双重刷新的性能浪费
            if (isDomainAtCapture) {
              dDic.repaint();
            } else {
              nDic.repaint();
            }
          },
          onWheel: (bool value) {
            // 防止色轮手势与外部滚动冲突（已在 _setFocusState 锁定滚动，此处可留空）
          },
        ),
      ),

      crossFadeState: editorState == 1
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
      sizeCurve: Curves.easeInOutCubic,
    );
  }
  void _startEditing(NodeAppearance appearance, SelectionViewData selection, StatefulComponentManagerModelForProvider manager, EditingStateModel stateModel) {
    stateModel.State = EditingState.coloringNode;

    setState(() {
      _originalColor = appearance!.nodeColor;
      _tempSelectColor = appearance.nodeColor ?? Colors.blue;
      editorState = 1;
    });

    // 关键：延迟到下一帧，此时 editorState 已经生效，
    // AnimatedCrossFade 开始撑开高度，ListView 能计算出新的最大滚动范围。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration.zero,(){
        _setFocusState(true, selection, manager);
      });
    });
    _setFocusState(true, selection, manager);
  }
  void _cancelEditing(NodeAppearance appearance, SelectionViewData selection, StatefulComponentManagerModelForProvider manager, EditingStateModel stateModel, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic) {
    stateModel.State = EditingState.none;
    appearance!.nodeColor = _originalColor;
    if (selection.IsSelectedDomain) dDic.repaint(); else nDic.repaint();
    setState(() => editorState = 0);
    _setFocusState(false, selection, manager);
  }

  // --- 补充逻辑：修正后的确认编辑方法 (解决你提到的撤销坑) ---
  void _confirmEditing(
      NodeAppearance appearance,
      SelectionViewData selection,
      StatefulComponentManagerModelForProvider manager,
      EditingStateModel stateModel,
      ConceptTree2NodeDrawingDataDic nDic,
      ConceptTree2DomainDrawingDataDic dDic,
      ) {
    stateModel.State = EditingState.none;

    // 1. 锁定当前选中的是 Domain 还是 Concept，用于闭包
    final bool isDomainAtRecord = selection.IsSelectedDomain;
    final Color? fromColor = _originalColor;
    final Color toColor = _tempSelectColor;

    // 2. 推入指令栈
    commandManagerProvider.PushCommand(
      commandManagerProvider.editInstance,
      Command(
        function: () {
          appearance.nodeColor = toColor;
          // 关键：这里不再看 selection，而是用那一刻锁定的类型执行重绘
          if (isDomainAtRecord) dDic.repaint(); else nDic.repaint();
        },
        undoFunction: () {
          appearance.nodeColor = fromColor;
          if (isDomainAtRecord) dDic.repaint(); else nDic.repaint();
        },
      ),
    );

    setState(() => editorState = 0);
    _setFocusState(false, selection, manager);
  }

// --- 补充逻辑：修正后的复原颜色方法 ---
  void _handleResetColor(
      NodeAppearance appearance,
      SelectionViewData selection,
      ConceptTree2NodeDrawingDataDic nDic,
      ConceptTree2DomainDrawingDataDic dDic,
      ) {
    if (appearance.nodeColor == null) return;

    final bool isDomainAtRecord = selection.IsSelectedDomain;
    final Color? oldColor = appearance.nodeColor;

    commandManagerProvider.PushCommand(
      commandManagerProvider.editInstance,
      Command(
        function: () {
          appearance.nodeColor = null;
          if (isDomainAtRecord) dDic.repaint(); else nDic.repaint();
        },
        undoFunction: () {
          appearance.nodeColor = oldColor;
          if (isDomainAtRecord) dDic.repaint(); else nDic.repaint();
        },
      ),
    );

    // 立即执行界面反馈
    setState(() {
      appearance.nodeColor = null;
    });
    if (isDomainAtRecord) dDic.repaint(); else nDic.repaint();
  }

}

class ColorWheelTestState extends StatefulWidget {
  const ColorWheelTestState({super.key});

  @override
  State<ColorWheelTestState> createState() => _ColorWheelTestStateState();
}

class _ColorWheelTestStateState extends State<ColorWheelTestState> {
  // Color for the picker shown in Card on the screen.
  late Color screenPickerColor;
  // Color for the picker in a dialog using onChanged.
  late Color dialogPickerColor;
  // Color for picker using the color select dialog.
  late Color dialogSelectColor;

  late Color _mSelectColor;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    screenPickerColor = Colors.blue;  // Material blue.
    dialogPickerColor = Colors.red;   // Material red.
    dialogSelectColor = const Color(0xFFA239CA); // A purple color.
    _mSelectColor = Colors.white;
  }
  @override
  Widget build(BuildContext context) {
    return aaa();
  }
  Widget aaa(){
    return // Pick color in a dialog.
      // Pick color in a dialog.
      ListTile(
        title: const Text('Click this color to change it in a dialog'),
        subtitle: Text(
          '${ColorTools.materialNameAndCode(dialogPickerColor,
              colorSwatchNameMap: colorsNameMap)} '
              'aka ${ColorTools.nameThatColor(dialogPickerColor)}',
        ),
        trailing: ColorIndicator(
          width: 44,
          height: 44,
          borderRadius: 4,
          color: dialogPickerColor,
          onSelectFocus: false,
          onSelect: () async {
            // Store current color before we open the dialog.
            final Color colorBeforeDialog = dialogPickerColor;
            // Wait for the picker to close, if dialog was dismissed,
            // then restore the color we had before it was opened.
            if (!(await colorPickerDialog())) {
              setState(() {
                dialogPickerColor = colorBeforeDialog;
              });
            }
          },
        ),
      );
  }
  Widget bbb(){
    return ListTile(
      title: const Text('Click to select a new color from a dialog'),
      subtitle: Text(
        '${ColorTools.materialNameAndCode(dialogSelectColor, colorSwatchNameMap: colorsNameMap)} '
            'aka ${ColorTools.nameThatColor(dialogSelectColor)}',
      ),
      trailing: ColorIndicator(
          width: 40,
          height: 40,
          borderRadius: 0,
          color: dialogSelectColor,
          elevation: 1,
          onSelectFocus: false,
          onSelect: () async {
            // Wait for the dialog to return color selection result.
            final Color newColor = await showColorPickerDialog(
              // The dialog needs a context, we pass it in.
              context,
              // We use the dialogSelectColor, as its starting color.
              dialogSelectColor,
              title: Text('ColorPicker',
                  style: Theme.of(context).textTheme.titleLarge),
              width: 40,
              height: 40,
              spacing: 0,
              runSpacing: 0,
              borderRadius: 0,
              wheelDiameter: 165,
              enableOpacity: true,
              showColorCode: true,
              colorCodeHasColor: true,
              pickersEnabled: <ColorPickerType, bool>{
                ColorPickerType.wheel: true,
              },
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                copyButton: true,
                pasteButton: true,
                longPressMenu: true,
              ),
              actionButtons: const ColorPickerActionButtons(
                okButton: true,
                closeButton: true,
                dialogActionButtons: false,
              ),
              constraints: const BoxConstraints(
                  minHeight: 480, minWidth: 320, maxWidth: 320),
            );
            // We update the dialogSelectColor, to the returned result
            // color. If the dialog was dismissed it actually returns
            // the color we started with. The extra update for that
            // below does not really matter, but if you want you can
            // check if they are equal and skip the update below.
            setState(() {
              dialogSelectColor = newColor;
            });
          }),
    );
  }
  Future<bool> colorPickerDialog() async {
    return ColorPicker(
      // Use the dialogPickerColor as start and active color.
      color: dialogPickerColor,
      // Update the dialogPickerColor using the callback.
      onColorChanged: (Color color) =>
          setState(() => dialogPickerColor = color),
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subheading: Text(
        'Select color shade',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      wheelSubheading: Text(
        'Selected color and its shades',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
      customColorSwatchesAndNames: colorsNameMap,
    ).showPickerDialog(
      context,
      // New in version 3.0.0 custom transitions support.
      transitionBuilder: (BuildContext context,
          Animation<double> a1,
          Animation<double> a2,
          Widget widget) {
        final double curvedValue =
            Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(
              0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: widget,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      constraints:
      const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
    );
  }
  //一体化实时显示颜色？不用Dialog?
  //
  Widget ccc(){
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: ColorWheelPicker(
        color: _mSelectColor,
        onChanged: (Color value) {
          setState(() {
            _mSelectColor =value;
          });

          //print("OnWheelChanged$value");
        },
        onWheel: (bool value) {
          //print("OnWheel$value");

        },
      ),
    );
  }
}
