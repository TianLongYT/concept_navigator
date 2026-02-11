import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddressBar extends StatelessWidget {
  const AddressBar({super.key, required this.maxWidth});
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    AddressBarModel barModel = context.watch<AddressBarModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();

    List<Widget> visibleParts = [];
    List<Widget> hiddenParts = [];

    //计算域节点占用宽度。
    String domain = barModel.domainAddresses.last;
    Text domainWidget = Text(
      domain,
      style: TextStyle(color: Colors.blue,fontSize: 30),
    );
    final domainTextWidth = getTextWidth(domainWidget) + 20;//符号占位：

    double totalWidth = 0;
    double availableWidth = maxWidth - domainTextWidth;//按钮宽度，缩略号宽度。

    // 计算添加概念节点路径。
    for (int i = barModel.conceptAddresses.length-1; i >= 0 ; i--) {
      String part = barModel.conceptAddresses[i];
      Text partWidget = Text(
        part,
        style: TextStyle(color: Colors.blue,fontSize: 30),
      );

      // 测量路径部分宽度
      final textWidth = getTextWidth(partWidget) + 30;//符号占位/


      totalWidth += textWidth;


      // 如果总宽度超出可用宽度，放入隐藏部分
      if (totalWidth > availableWidth) {

        hiddenParts.add(addressWidget(part,context));
      } else {
        visibleParts.add(addressWidgetButton(part,context,(){
          print("点击路径");
          //设置selection。
          selection.currentConceptNodeName = barModel.conceptAddresses[i];
          selection.currentConceptNodeAlias = barModel.conceptAliasAddresses[i];
          selection.CancelSelection();
          //移除后面的conceptAddress.
          if(i+1>=barModel.conceptAddresses.length) {
            return;
          }
          barModel.conceptAddresses.removeRange(i+1, barModel.conceptAddresses.length);
          barModel.conceptAliasAddresses.removeRange(i+1, barModel.conceptAddresses.length);

        }));
        visibleParts.add(addressConnectWidget());
      }
    }
    if(visibleParts.isNotEmpty) {
      visibleParts.removeLast();
    }

    // 判断是否需要显示 '...'
    return Positioned(
      left: 4,
      top: 4,
      child: Row(
        children: [
          //显示回退按钮
          IconButton(onPressed: (){
            print("回退，但是不会做");
          }, icon: Icon(Icons.arrow_back_outlined)),
          //显示域名窗口和域伸缩按钮。
          PopupMenuButton<String>(
            onSelected: (path) {
              print("clickDomain"+path);
              //清空概念列表。
              barModel.conceptAddresses.clear();
              barModel.conceptAliasAddresses.clear();
              //设置域。
              barModel.domainAddresses = ConceptTreeModel.SplitDomainKey(path);
              //设置selection
              selection.currentDomain = path;
              selection.currentConceptNodeName = "";
              selection.currentConceptNodeAlias = "";
              selection.CancelSelection();
            },
            itemBuilder: (BuildContext context) {
              return barModel.domainAddresses.asMap().entries.map((entry) {
                //把domainKey当成value传入。
                String value = barModel.domainAddresses[0];
                for(int i =1;i<entry.key+1;i++){
                  value = ConceptTreeModel.AppendDomainKey(value, barModel.domainAddresses[i]);
                }
                return PopupMenuItem<String>(
                  value: value,
                  child: addressWidget(entry.value,context),
                );
              }).toList();
            },
            child: addressWidget(domain,context),
          ),

          SizedBox(
            width: 30,
              height: 30,
              child: Icon(Icons.double_arrow_rounded)
          ),

          if (hiddenParts.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (path) => onPathClick(path),
              itemBuilder: (BuildContext context) {
                return hiddenParts.reversed.map((Widget part) {
                  return PopupMenuItem<String>(
                    value: part.toString(),
                    child: part,
                  );
                }).toList();
              },
              child: addressWidget("...",context),
            ),
          SizedBox(width: 10,height: 30,),
          // 如果有可见路径，则显示
          ...visibleParts.reversed,

        ],
      ),
    );

  }
  // 计算单个文本的宽度
  double getTextWidth(Text textWidget) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: textWidget.data, style: textWidget.style),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  void onPathClick(String path) {}

  Widget addressWidget(String text,BuildContext context){
    return Container(
        decoration: BoxDecoration(
          //color: Colors.white,
          border: Border.all(),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 30,
          ),
        ),
    );
  }

  Widget addressWidgetButton(String text,BuildContext context,VoidCallback? onPressed){
    // return Material(
    //   shape: CircleBorder(),
    //   child: InkWell(
    //     onTap: onPressed,
    //     splashColor: Colors.redAccent.withValues(alpha: 0.3),
    //     highlightColor: Colors.redAccent.withValues(alpha: 0.1),
    //     hoverColor: Colors.redAccent.withValues(alpha: 0.2),
    //     radius: 20,
    //
    //     child: addressWidget(text),
    //
    //   ),
    // );
    return InkWell(
          onTap: onPressed,

          child: addressWidget(text,context),

        );

  }
  Widget addressConnectWidget(){
    return SizedBox(
      width: 30,
      height: 30,
        child: Icon(Icons.arrow_forward_ios_rounded)
    );
  }
}
