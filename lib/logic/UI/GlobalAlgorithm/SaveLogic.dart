import 'dart:io';
import 'package:concept_navigator/logic/Data/ConceptDecoration.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/GlobalAlgorithm/PersistenceLogic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SaveLogic {
  /// 统一显示提示信息，后发的提示会立即覆盖前方的
  static void _showStatusSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // 核心：先清除当前所有的 SnackBar，防止排队
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2), // 设置较短的停留时间
      ),
    );
  }

  /// 封装的另存为逻辑
  static Future<void> performSaveAs(BuildContext context) async {
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
          decorationDic: context.read<ConceptTree2ConceptDecorationDic>(),
        );
        _showStatusSnackBar(context, "数据已保存为: $fileName");
      }
    } else {
      // PC端：使用 Picker 另存为
      await PersistenceLogic.saveWithPicker(
        treeModel: context.read<ConceptTreeModel>(),
        nodeDrawingDic: context.read<ConceptTree2NodeDrawingDataDic>(),
        domainDrawingDic: context.read<ConceptTree2DomainDrawingDataDic>(),
        nodeViewDic: context.read<ConceptTree2NodeViewDataDic>(),
        decorationDic: context.read<ConceptTree2ConceptDecorationDic>(),
      );
      if (PersistenceLogic.currentFilePath != null) {
        String fileName = PersistenceLogic.currentFilePath!.split(Platform.pathSeparator).last;
        _showStatusSnackBar(context, "数据已保存至: $fileName");
      }
    }
  }

  /// 封装的保存逻辑
  static Future<void> performSave(BuildContext context) async {
    if (PersistenceLogic.currentFilePath == null) {
      await performSaveAs(context);
    } else {
      await PersistenceLogic.save(
        treeModel: context.read<ConceptTreeModel>(),
        nodeDrawingDic: context.read<ConceptTree2NodeDrawingDataDic>(),
        domainDrawingDic: context.read<ConceptTree2DomainDrawingDataDic>(),
        nodeViewDic: context.read<ConceptTree2NodeViewDataDic>(),
        decorationDic: context.read<ConceptTree2ConceptDecorationDic>(),
      );
      String fileName = PersistenceLogic.currentFilePath!.split(Platform.pathSeparator).last;
      _showStatusSnackBar(context, "数据已保存至: $fileName");
    }
  }

  /// 封装的导出初始文件逻辑
  static Future<void> performExportOrigin(BuildContext context) async {
    await PersistenceLogic.saveOriginWithPicker(
      treeModel: context.read<ConceptTreeModel>(),
      decorationDic: context.read<ConceptTree2ConceptDecorationDic>(),
    );
    _showStatusSnackBar(context, "初始文件已导出");
  }

  /// 封装的加载初始文件逻辑
  static Future<void> performLoadOrigin(BuildContext context) async {
    LoadResult result = await PersistenceLogic.loadOriginWithPicker(
      treeModel: context.read<ConceptTreeModel>(),
      nodeDrawingDic: context.read<ConceptTree2NodeDrawingDataDic>(),
      domainDrawingDic: context.read<ConceptTree2DomainDrawingDataDic>(),
      nodeViewDic: context.read<ConceptTree2NodeViewDataDic>(),
      decorationDic: context.read<ConceptTree2ConceptDecorationDic>(),
    );

    if (context.mounted) {
      if (result == LoadResult.success) {
        _showStatusSnackBar(context, "初始文件已加载");
      } else if (result == LoadResult.failure) {
        _showStatusSnackBar(context, "加载初始文件失败");
      }
    }
  }

  static Future<String?> _showFileNameDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("请输入存档名称"),
        content: TextField(
          controller: controller, 
          autofocus: true,
          decoration: const InputDecoration(hintText: "例如: 我的笔记")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("确认")),
        ],
      ),
    );
  }
}
