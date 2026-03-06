import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // 1. 引入字节流处理
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 用于判断 Web 环境

// 新增枚举
enum LoadResult {
  success,    // 加载成功
  cancelled,  // 用户手动取消
  failure     // 文件读取或解析错误（例如文件不存在或格式错误）
}

class PersistenceLogic {
  static const String _defaultFileName = 'concept_navigator_data.json';

  static Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_defaultFileName');
  }
  // 新增：记录当前打开的文件路径
  static String? currentFilePath;
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// 保存所有数据到指定文件
  static Future<void> save({
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
    String? path,
  }) async {
    try {
      final Map<String, dynamic> fullData = {
        'version': '1.0',
        'tree': treeModel.toJson(),
        'nodeDrawingDic': nodeDrawingDic.data.map((key, value) => MapEntry(key, value.toJson())),
        'domainDrawingDic': domainDrawingDic.data.map((key, value) => MapEntry(key, value.toJson())),
        'nodeViewDic': nodeViewDic.data.map((key, value) => MapEntry(key, value.toJson())),
      };

      String? targetPath = path ?? currentFilePath;
      File file;
      if (targetPath != null) {
        file = File(targetPath);
      } else {
        file = await _localFile;
      }

      await file.writeAsString(jsonEncode(fullData));
      currentFilePath = file.path; // 更新当前路径
      print("Persistence: Data saved successfully to ${file.path}");
    } catch (e) {
      print("Persistence Error (Save): $e");
    }
  }

  /// 从本地文件加载所有数据
  /// 修改后的 load 方法，返回 LoadResult
  static Future<LoadResult> load({
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
    String? path,
  }) async {
    try {
      File file;
      if (path != null) {
        file = File(path);
      } else {
        file = await _localFile;
      }

      if (!await file.exists()) {
        print("Persistence: No save file found at ${file.path}");
        return LoadResult.failure;
      }

      final String content = await file.readAsString();
      final Map<String, dynamic> fullData = jsonDecode(content);

      // 应用数据
      _applyData(
          fullData: fullData,
          treeModel: treeModel,
          nodeDrawingDic: nodeDrawingDic,
          domainDrawingDic: domainDrawingDic,
          nodeViewDic: nodeViewDic
      );

      // 加载成功后更新当前路径
      currentFilePath = file.path;
      print("Persistence: Data loaded successfully from ${file.path}");
      return LoadResult.success;
    } catch (e) {
      print("Persistence Error (Load): $e");
      return LoadResult.failure;
    }
  }

  /// 将解析好的 Map 数据应用到内存 Model 中 (提取的公共方法)
  static void _applyData({
    required Map<String, dynamic> fullData,
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
  }) {
    // 1. 加载逻辑树并重建搜索字典
    if (fullData['tree'] != null) {
      final loadedTreeModel = ConceptTreeModel.fromJson(fullData['tree']);
      treeModel.rootTree = loadedTreeModel.rootTree;
      treeModel.GenerateDic();
    }

    // 2. 加载 Node 绘图字典
    if (fullData['nodeDrawingDic'] != null) {
      Map<String, NodeDrawingData> newNodeDrawing = {};
      (fullData['nodeDrawingDic'] as Map).forEach((key, value) {
        newNodeDrawing[key.toString()] = NodeDrawingData.fromJson(value);
      });
      nodeDrawingDic.data = newNodeDrawing;
    }

    // 3. 加载 Domain 绘图字典
    if (fullData['domainDrawingDic'] != null) {
      Map<String, DomainDrawingData> newDomainDrawing = {};
      (fullData['domainDrawingDic'] as Map).forEach((key, value) {
        newDomainDrawing[key.toString()] = NodeDrawingData.fromJson(value) as DomainDrawingData;
      });
      domainDrawingDic.data = newDomainDrawing;
    }

    // 4. 加载视角字典
    if (fullData['nodeViewDic'] != null) {
      Map<String, NodeViewData> newNodeView = {};
      (fullData['nodeViewDic'] as Map).forEach((key, value) {
        newNodeView[key.toString()] = NodeViewData.fromJson(value);
      });
      nodeViewDic.data = newNodeView;
    }
  }

  /// 获取私有目录下所有的保存文件列表
  static Future<List<File>> getSavedFiles() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);
      return dir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
    } catch (e) {
      print("Persistence Error (getSavedFiles): $e");
      return [];
    }
  }
  /// 指定名称保存到私有目录 (用于新建/另存为)
  static Future<void> saveToLocalWithName({
    required String fileName,
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
  }) async {
    final path = await _localPath;
    // 确保有 .json 后缀
    String finalName = fileName.endsWith('.json') ? fileName : '$fileName.json';
    await save(
      treeModel: treeModel,
      nodeDrawingDic: nodeDrawingDic,
      domainDrawingDic: domainDrawingDic,
      nodeViewDic: nodeViewDic,
      path: '$path/$finalName',
    );
  }
  /// 使用文件选择器选择文件并加载
  static Future<LoadResult> loadWithPicker({
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        return await load(
          treeModel: treeModel,
          nodeDrawingDic: nodeDrawingDic,
          domainDrawingDic: domainDrawingDic,
          nodeViewDic: nodeViewDic,
          path: result.files.single.path,
        );
      } else if (result != null && result.files.single.bytes != null) {
        // 针对 Web 端处理：Web 端没有 path，直接解析 bytes
        final content = utf8.decode(result.files.single.bytes!);
        final Map<String, dynamic> fullData = jsonDecode(content);

        _applyData(
            fullData: fullData,
            treeModel: treeModel,
            nodeDrawingDic: nodeDrawingDic,
            domainDrawingDic: domainDrawingDic,
            nodeViewDic: nodeViewDic
        );

        currentFilePath = result.files.single.name; // Web 端记录文件名作为路径参考
        print("Persistence: Web load successful: ${result.files.single.name}");
        return LoadResult.success;
      } else {
        print("Persistence: User cancelled the picker.");
        return LoadResult.cancelled;
      }
    } catch (e) {
      print("Persistence Error (loadWithPicker): $e");
      return LoadResult.failure;
    }
  }

  /// 使用文件选择器选择路径并保存（另存为）
  static Future<void> saveWithPicker({
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
  }) async {
    try {
      // 1. 序列化数据
      final Map<String, dynamic> fullData = {
        'version': '1.0',
        'tree': treeModel.toJson(),
        'nodeDrawingDic': nodeDrawingDic.data.map((key, value) => MapEntry(key, value.toJson())),
        'domainDrawingDic': domainDrawingDic.data.map((key, value) => MapEntry(key, value.toJson())),
        'nodeViewDic': nodeViewDic.data.map((key, value) => MapEntry(key, value.toJson())),
      };

      // 2. 转换成字节数组 (满足 Android/iOS/Web 的 saveFile 要求)
      final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonEncode(fullData)));

      // 3. 直接调用插件保存
      String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'concept_navigator_data.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (result != null) {
        // PC 端补齐后缀逻辑
        if (!result.toLowerCase().endsWith('.json')) {
          result = '$result.json';
        }

        // 桌面端手动补齐逻辑 (kIsWeb 用于防止 Web 端调用 Platform 报错)
        if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
          await File(result).writeAsBytes(bytes);
        }

        print("Persistence: Save complete. Result: $result");
        currentFilePath = result;
      } else {
        print("Persistence: User cancelled the picker.");
      }
    } catch (e) {
      print("Persistence Error (saveWithPicker): $e");
    }
  }
}