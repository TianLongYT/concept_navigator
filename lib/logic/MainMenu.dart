import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
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
          ],
        )
      ),

      floatingActionButton:

      MFloatingButton(),// This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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