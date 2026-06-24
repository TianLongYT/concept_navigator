import 'dart:io';

import 'package:concept_navigator/logic/Analysis/AnalysisPanel.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptDecoration.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/GlobalAlgorithm/PersistenceLogic.dart';
import 'package:concept_navigator/logic/UI/FloatingActionButton/MFloatingButton.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/SaveLogic.dart';
import 'package:concept_navigator/logic/UI/NodePanel.dart';
import 'package:concept_navigator/logic/UI/PopInspector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Node {
  double x;
  double y;
  Node({required this.x, required this.y});
}

class Mainmenu extends StatefulWidget {
  const Mainmenu({super.key});

  @override
  State<Mainmenu> createState() => _MainmenuState();
}

class _MainmenuState extends State<Mainmenu> {
  List<Node> nodes = [];
  double dx = 0,dy = 0;

  bool _isAnalysisMode = false; // 模式切换状态

  //如何广播事件。

  @override
  Widget build(BuildContext context) {

    // if(stateModel.State == GlobalState.creatingNode){
    //   showModalBottomSheet(context: context, builder: (context)
    //     {
    //       return SizedBox(
    //         height: 400,
    //         child: Center(
    //           //
    //           // child: ElevatedButton(onPressed: (){
    //           //   //Navigator.pop(context);
    //           // }, child: const Text("Close")),
    //         ),
    //       );
    //     });
    // }

    AppBar bar = AppBar(
      // TRY THIS: Try changing the color here to a specific color (to
      // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
      // change color while the other colors stay the same.
      backgroundColor: _isAnalysisMode ? Colors.indigo : Theme.of(
        context,
      ).colorScheme.inversePrimary,
      foregroundColor: _isAnalysisMode ? Colors.white : null,
      // Here we take the value from the MyHomePage object that was created by
      // the App.build method, and use it to set our appbar title.
      title: Text(_isAnalysisMode ? "概念分析" : "概念编辑"),
      
    );
    //print("top ${MediaQuery.of(context).padding.top}");
    return Scaffold(
      appBar: bar,
      body: _isAnalysisMode ? const AnalysisPanel() : Nodepanel(),

      drawerEnableOpenDragGesture: false,
      drawer: Drawer(
        child:  ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: Text(
                  "概念导航器",style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              )
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_rounded),
              title: const Text("概念编辑",style: TextStyle(fontSize: 24),),
              onTap: (){
                setState(() {
                  _isAnalysisMode = false;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text("概念分析",style: TextStyle(fontSize: 24),),
              onTap: (){
                setState(() {
                  _isAnalysisMode = true;
                });
                Navigator.pop(context);
              },
            ),
            // --- 数据持久化功能按钮 ---
            const Divider(),
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text("新建 (New)", style: TextStyle(fontSize: 20)),
              onTap: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("确认新建"),
                    content: const Text("是否新建项目？未保存的更改将丢失。"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("取消"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("确认"),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {

                  // 清除当前打开的项目路径，确保下次保存时触发“另存为”
                  PersistenceLogic.currentFilePath = null;

                  final treeModel = context.read<ConceptTreeModel>();

                  // 重置树结构
                  treeModel.rootTree = DomainTree()..name = "root";
                  treeModel.GenerateDic();

                  // 重置绘图与视图数据字典
                  context.read<ConceptTree2NodeDrawingDataDic>().data = {};
                  context.read<ConceptTree2DomainDrawingDataDic>().data = {
                    "root": DomainDrawingData(
                      nodeAppearance: NodeAppearance(),
                    )
                  };
                  context.read<ConceptTree2NodeViewDataDic>().data = {
                    "root": NodeViewData(),
                  };
                  context.read<ConceptTree2ConceptDecorationDic>().clear();


                  // 重置 UI 选择状态
                  final selection = context.read<SelectionViewData>();
                  selection.ResetSelection(
                    context.read<AddressBarModel>(),
                    treeModel,
                  );
                  context.read<GlobalStateModel>().State = GlobalState.normal;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("新项目已创建")),
                  );
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text("另存为 (Save As)", style: TextStyle(fontSize: 20)),
              onTap: () async {
                await SaveLogic.performSaveAs(context);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text("保存数据 (Save)", style: TextStyle(fontSize: 20)),
              onTap: () async {
                await SaveLogic.performSave(context);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text("读取数据 (Load)", style: TextStyle(fontSize: 20)),
              onTap: () async {
                LoadResult result;

                if (Platform.isAndroid || Platform.isIOS) {
                  File? selectedFile = await _showFileSelectDialog(context);
                  if (selectedFile != null) {
                    result = await PersistenceLogic.load(
                      treeModel: context.read<ConceptTreeModel>(),
                      nodeDrawingDic: context.read<ConceptTree2NodeDrawingDataDic>(),
                      domainDrawingDic: context.read<ConceptTree2DomainDrawingDataDic>(),
                      nodeViewDic: context.read<ConceptTree2NodeViewDataDic>(),
                      decorationDic: context.read<ConceptTree2ConceptDecorationDic>(),
                      path: selectedFile.path,
                    );
                  } else {
                    result = LoadResult.cancelled;
                  }
                } else {
                  result = await PersistenceLogic.loadWithPicker(
                    treeModel: context.read<ConceptTreeModel>(),
                    nodeDrawingDic: context.read<ConceptTree2NodeDrawingDataDic>(),
                    domainDrawingDic: context.read<ConceptTree2DomainDrawingDataDic>(),
                    nodeViewDic: context.read<ConceptTree2NodeViewDataDic>(),
                    decorationDic: context.read<ConceptTree2ConceptDecorationDic>(),
                  );
                }

                if (context.mounted) {
                  switch (result) {
                    case LoadResult.success:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("数据已加载")),
                      );
                      context.read<SelectionViewData>().ResetSelection(context.read<AddressBarModel>(),context.read<ConceptTreeModel>());
                      Navigator.pop(context); // 只有成功才关闭侧边栏
                      break;
                    case LoadResult.cancelled:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("加载已取消")),
                      );
                      break;
                    case LoadResult.failure:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("加载失败：文件可能已损坏或不存在")),
                      );
                      break;
                  }

                }

                context.read<SelectionViewData>().CancelSelection();
                context.read<GlobalStateModel>().State = GlobalState.normal;
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.output),
              title: const Text("导出初始文件", style: TextStyle(fontSize: 20)),
              onTap: () async {
                await SaveLogic.performExportOrigin(context);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.input),
              title: const Text("加载初始文件", style: TextStyle(fontSize: 20)),
              onTap: () async {
                await SaveLogic.performLoadOrigin(context);
                if (context.mounted){
                  final selection = context.read<SelectionViewData>();

                  selection.ResetSelection(context.read<AddressBarModel>(),context.read<ConceptTreeModel>());

                  context.read<GlobalStateModel>().State = GlobalState.normal;
                  Navigator.pop(context);
                }

              },

            ),
          ],
        )
      ),

      floatingActionButton:
      /// * `backgroundColor`
      ///   * disabled - Theme.colorScheme.onSurface(0.12)
      ///   * others - Theme.colorScheme.secondaryContainer
      /// * `foregroundColor`
      ///   * disabled - Theme.colorScheme.onSurface(0.38)
      ///   * others - Theme.colorScheme.onSecondaryContainer

      //   FilledButton(onPressed: false? null: (){print("aaaa");},
      //   clipBehavior: Clip.none,
      //   //style: ButtonStyle(shape: WidgetStateProperty<OutlinedBorder>()),
      //
      //   child: Container(
      //     width: 56,
      //     height: 56,
      //     //color: Theme.of(context).colorScheme.surfaceTint,
      //   ),
      // ),

      _isAnalysisMode ? null : MFloatingButton(),// This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<File?> _showFileSelectDialog(BuildContext context) async {
    List<File> files = await PersistenceLogic.getSavedFiles();
    return showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("请选择存档"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              String name = files[index].path.split('/').last;
              return ListTile(
                title: Text(name),
                onTap: () => Navigator.pop(context, files[index]),
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _testFunc(){
    return Stack(
      children:[Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey,),
        ...nodes.map((node){

          return Positioned(
            left: node.x,
            top: node.y,
            child: GestureDetector(
              onPanStart: (details){

                setState(() {
                  dx = node.x - details.localPosition.dx;
                  dy = node.y - details.localPosition.dy;
                });
                //print(dy);
                //print(dy);
              },
              onPanUpdate: (details) {
                setState(() {
                  node.x = details.localPosition.dx + dx;
                  node.y = details.localPosition.dy + dy;
                  //print(context.size!.height*0.5);
                  //print(details.localPosition.dy);
                });
              },
              child: CustomPaint(
                size: Size(100, 100),
                painter: NodePainter(),
              ),
            ),
          );
        })],
    );
  }
  void _testAddNewNode() {
    setState(() {
      // 创建一个新节点，位置为屏幕中心
      nodes.add(Node(x: MediaQuery.of(context).size.width / 2 - 50, y: MediaQuery.of(context).size.height / 2 - 50));
    });
  }


}
class NodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制一个圆形节点
    Paint paint = Paint()
      ..color = Colors.blue;
    canvas.drawRect(Rect.fromCenter(center:  Offset(size.width / 2, size.height / 2),width:  100,height: 100), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
