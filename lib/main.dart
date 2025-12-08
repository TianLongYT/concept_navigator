import 'package:concept_navigator/LearningFlutter_Wang/Provider/Foo_Model_Provider.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/MainMenu.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


//import 'LearningFlutter_Wang/Provider/Foo_ControlPanel_UI.dart';
//import 'LearningFlutter_Wang/Provider/Foo_Model.dart';
//import 'LearningFlutter_Wang/Provider/Foo_UI.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //P1.funcs();
    return MultiProvider(//看能不能做成文件存档。
      providers: [
        ChangeNotifierProvider<UserSettingAppearanceModel>(create: (_)=>UserSettingAppearanceModel()),
        ChangeNotifierProvider<ConceptTreeModel>(create: (_)=>ConceptTreeModel(rootTree: DomainTree()..name = "root")),
        ChangeNotifierProvider<ConceptTree2NodeDrawingDataDic>(create: (_)=>ConceptTree2NodeDrawingDataDic()),
        ChangeNotifierProvider<ConceptTree2DomainDrawingDataDic>(create: (_)=>ConceptTree2DomainDrawingDataDic()),

        ChangeNotifierProvider<ConceptTree2NodeViewDataDic>(create: (_)=>ConceptTree2NodeViewDataDic()),
        ChangeNotifierProvider<SelectionViewData>(create: (_)=>SelectionViewData()),
        ChangeNotifierProvider<GlobalStateModel>(create: (_)=>GlobalStateModel()),

        ChangeNotifierProvider<AddressBarModel>(create: (_)=>AddressBarModel()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a purple toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),

        ),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light,
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _counter = 0;
  double _height = 200;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _isLoadding = !_isLoadding;
      if (_isLoadding) {
        _controller!.repeat(reverse: false);
      } else {
        _controller!.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Mainmenu();
  }

  AnimationController? _controller;
  bool _isLoadding = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: false); //打两个点回传本身。
  }

  @override
  void dispose() {
    super.dispose();
    _controller!.dispose();
  }

  Widget MyWidget01() {
    return AnimatedPadding(
      duration: Duration(seconds: 1),
      padding: const EdgeInsetsGeometry.only(top: 0, left: 10),
      curve: Curves.bounceOut,
      child: TweenAnimationBuilder(
        duration: Duration(seconds: 1),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (BuildContext context, value, Widget? child) {
          return Opacity(
            opacity: value,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: 300,
              height: _height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.orange, Colors.white],
                  stops: [0.5, 0.7],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    spreadRadius: 10,
                    blurRadius: 15,
                  ),
                ],
                borderRadius: BorderRadius.circular(25),
              ),
              child: AnimatedSwitcher(
                //AnimatedCrossFade();双控件切换。
                duration: Duration(seconds: 1),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  );
                },
                child: Text(
                  "hello",
                  key: UniqueKey(),
                  style: TextStyle(fontSize: 72),
                ),
              ),
              //Center(child: ),
            ),
          );
        },
      ),
    );
  }

  Widget MyWidget02() {
    return Center(
      child: Row(
        children: [
          AnimatedCounter(duration: Duration(seconds: 1), count: 1),
          AnimatedCounter(duration: Duration(seconds: 1), count: 3),
          AnimatedCounter(duration: Duration(seconds: 1), count: 3),
        ],
      ),
    );
  }

  Widget MyWidget03() {
    print(_controller!.value);
    return Center(
      child: SlideTransition(
        //position: _controller!.drive(Tween(begin: Offset(0,0),end: Offset(1, 1))),//将0~1映射到Tween的0.5~1.输出。
        position: Tween(begin: Offset(0, 0), end: Offset(1, 1))
            .chain(CurveTween(curve: Curves.bounceIn))
            .chain(CurveTween(curve: Interval(0.5, 0.8)))
            .animate(_controller!), //将0~1映射到Tween的0.5~1.输出。
        child: Icon(Icons.refresh, size: 100),
      ),
    );
  }
  Widget MyWidget04Breath(){

    Animation<double> anim = Tween(begin: 0.0,end: 1.0)
        .chain(CurveTween(curve: Interval(0.0,0.2)))
        .animate(_controller!);

    // Animation anim1 = Tween(begin: 1.0, end: 1.0)
    //     .chain(CurveTween(curve: Interval(0.2, 0.8)))
    //     .animate(_controller!);

    Animation anim2 = Tween(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: Interval(0.55, 0.95)))
        .animate(_controller!);


    //++++ 0000000 --------

    return Center(
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (BuildContext context, Widget? child) {
          print(_controller!.value);
          return Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                gradient: RadialGradient(
                    colors : [Colors.blue[600]!,Colors.blue[100]!],
                    stops: _controller!.value <=0.2? [anim.value,anim.value+0.1] :[anim2.value,anim2.value+0.1],
                )
            ),
          );
        },
        child: null,
      ),
    );
  }

  Widget MyWidget05CustomPainter(){
    return Center(
      child: CustomPaint(
        painter: MyPainter(),
      ),
    );
  }

  Widget MyWidget06Provider(){
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor : Colors.deepPurple[300],
        title: Text("hello",style: TextStyle(fontSize: 30,color: Colors.black),),
      ),
      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Foo(),
            //ControlPanel(),
          ],
        ),
      )
    );
  }
}




class AnimatedCounter extends StatelessWidget {
  final Duration duration;
  final int count;

  const AnimatedCounter({super.key, required this.duration, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 120,
      color: Colors.blue,
      child: TweenAnimationBuilder(
        duration: duration,
        tween: Tween(end: count.toDouble()),
        builder: (context, value, child) {
          print(value);
          final whole = value ~/ 1;
          final decimal = value - whole;
          print("$whole" + "$decimal");
          return Stack(
            children: [
              Positioned(
                top: -100 * decimal,
                child: Opacity(
                  opacity: 1 - decimal,
                  child: Text("$whole", style: TextStyle(fontSize: 100)),
                ),
              ),
              Positioned(
                top: 100 - decimal * 100,
                child: Opacity(
                  opacity: decimal,
                  child: Text("${whole + 1}", style: TextStyle(fontSize: 100)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MyPainter extends CustomPainter{
  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
  
}