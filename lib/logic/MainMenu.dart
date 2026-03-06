import 'dart:io';

import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/GlobalAlgorithm/PersistenceLogic.dart';
import 'package:concept_navigator/logic/UI/FloatingActionButton/MFloatingButton.dart';
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
      backgroundColor: /*Colors.deepPurple,*/ Theme.of(
        context,
      ).colorScheme.inversePrimary,
      // Here we take the value from the MyHomePage object that was created by
      // the App.build method, and use it to set our appbar title.
      title: Text("概念编辑"),
      
    );
    //print("top ${MediaQuery.of(context).padding.top}");
    return Scaffold(
      appBar: bar,
      body: Nodepanel(),

      drawerEnableOpenDragGesture: false,
      drawer: Drawer(
        child:  ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  "AppDrawer",style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              )
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_rounded),
              title: const Text("概念编辑",style: TextStyle(fontSize: 24),),
              onTap: (){
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text("概念分析",style: TextStyle(fontSize: 24),),
              onTap: (){
                Navigator.pop(context);
              },
            ),
            // --- 数据持久化功能按钮 ---
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text("另存为 (Save As)", style: TextStyle(fontSize: 20)),
              onTap: () async {
                if (Platform.isAndroid || Platform.isIOS) {
                  // 移动端：弹窗输入文件名
                  String? fileName = await _showFileNameDialog(context);
                  if (fileName != null && fileName.isNotEmpty) {
                    await PersistenceLogic.saveToLocalWithName(
                      fileName: fileName,
                      treeModel: context.read<ConceptTreeModel>(),
                      nodeDrawingDic: context.read<ConceptTree2NodeDrawingDataDic>(),
                      domainDrawingDic: context.read<ConceptTree2DomainDrawingDataDic>(),
                      nodeViewDic: context.read<ConceptTree2NodeViewDataDic>(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                } else {
                  // PC端：使用 Picker 另存为
                  await PersistenceLogic.saveWithPicker(
                    treeModel: context.read<ConceptTreeModel>(),
                    nodeDrawingDic: context.read<ConceptTree2NodeDrawingDataDic>(),
                    domainDrawingDic: context.read<ConceptTree2DomainDrawingDataDic>(),
                    nodeViewDic: context.read<ConceptTree2NodeViewDataDic>(),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text("保存数据 (Save)", style: TextStyle(fontSize: 20)),
              onTap: () async {
                // 无论移动端还是PC，都保存到“当前已打开”的文件中
                await PersistenceLogic.save(
                  treeModel: context.read<ConceptTreeModel>(),
                  nodeDrawingDic: context.read<ConceptTree2NodeDrawingDataDic>(),
                  domainDrawingDic: context.read<ConceptTree2DomainDrawingDataDic>(),
                  nodeViewDic: context.read<ConceptTree2NodeViewDataDic>(),
                );

                if (context.mounted) {
                  String fileName = PersistenceLogic.currentFilePath?.split(Platform.pathSeparator).last ?? "默认存档";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("数据已保存至: $fileName")),
                  );
                  Navigator.pop(context);
                }
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
                  );
                }

                if (context.mounted) {
                  switch (result) {
                    case LoadResult.success:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("数据已加载")),
                      );
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

      MFloatingButton(),// This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  Future<String?> _showFileNameDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("请输入存档名称"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "例如: 我的笔记")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("确认")),
        ],
      ),
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