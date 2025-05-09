import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '分子可视化卡片',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MoleculeViewerPage(),
    );
  }
}

class MoleculeViewerPage extends StatefulWidget {
  const MoleculeViewerPage({super.key});

  @override
  State<MoleculeViewerPage> createState() => _MoleculeViewerPageState();
}

class _MoleculeViewerPageState extends State<MoleculeViewerPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _currentMolecule = 'water.pdb';

  // 可用的分子列表
  final List<Map<String, String>> _availableMolecules = [
    {'name': '水分子 (Water)', 'file': 'water.pdb'},
    {'name': '咖啡因 (Caffeine)', 'file': 'caffeine.pdb'},
    {'name': '血红蛋白片段 (Hemoglobin)', 'file': 'hemoglobin.pdb'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            debugPrint('WebView page finished loading');
            await _loadDefaultMolecule();
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (message) {
          debugPrint('Message from JS: ${message.message}');
        },
      )
      ..loadFlutterAsset('assets/js/molecule_viewer.html');
  }

  Future<void> _loadDefaultMolecule() async {
    try {
      final String moleculeData = await rootBundle.loadString('assets/models/water.pdb');
      debugPrint('水分子数据加载成功: ${moleculeData.substring(0, 50)}...');
      
      await _controller.runJavaScript(
        '''
        try {
          console.log("加载分子数据");
          updateMoleculeFromData(`$moleculeData`);
          Flutter.postMessage("分子加载成功");
        } catch(e) {
          console.error("分子加载失败", e);
          Flutter.postMessage("错误: " + e.toString());
        }
        '''
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载分子数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _switchMolecule(String filename) async {
    setState(() {
      _isLoading = true;
      _currentMolecule = filename;
    });
    
    try {
      final String moleculeData = await rootBundle.loadString('assets/models/$filename');
      debugPrint('分子数据加载成功: ${moleculeData.substring(0, 50)}...');
      
      await _controller.runJavaScript(
        '''
        try {
          console.log("切换到新分子");
          updateMoleculeFromData(`$moleculeData`);
          Flutter.postMessage("分子切换成功: $filename");
        } catch(e) {
          console.error("分子切换失败", e);
          Flutter.postMessage("错误: " + e.toString());
        }
        '''
      );
    } catch (e) {
      debugPrint('切换分子失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMoleculeFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdb', 'mol', 'sdf', 'xyz'],
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
        });
        
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileContent = await file.readAsString();
        
        // 保存文件到应用目录
        final directory = await getApplicationDocumentsDirectory();
        final targetFile = File('${directory.path}/$fileName');
        await targetFile.writeAsString(fileContent);
        
        // 使用JavaScript更新分子视图
        await _controller.runJavaScript(
          '''
          try {
            console.log("加载用户上传的分子");
            updateMoleculeFromData(`$fileContent`);
            Flutter.postMessage("用户分子加载成功: $fileName");
          } catch(e) {
            console.error("用户分子加载失败", e);
            Flutter.postMessage("错误: " + e.toString());
          }
          '''
        );
        
        setState(() {
          _currentMolecule = fileName;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功加载分子: $fileName')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分子可视化卡片'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  '化学分子可视化',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // 分子选择按钮
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _availableMolecules.map((molecule) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () => _switchMolecule(molecule['file']!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentMolecule == molecule['file'] 
                                ? Colors.blue 
                                : Colors.grey.shade200,
                            foregroundColor: _currentMolecule == molecule['file']
                                ? Colors.white
                                : Colors.black87,
                          ),
                          child: Text(molecule['name']!),
                        ),
                      )
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // 分子查看器卡片
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_isLoading)
                        Container(
                          color: Colors.white60,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 上传按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('上传自定义分子文件'),
                  onPressed: _loadMoleculeFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '支持格式: PDB, MOL, SDF, XYZ',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
