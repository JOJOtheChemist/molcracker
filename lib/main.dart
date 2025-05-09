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
      title: '3D分子可视化',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D分子可视化'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MoleculeViewerPage()),
                );
              },
              child: const Text('查看分子结构'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HeartEffectPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
              ),
              child: const Text('查看心形特效'),
            ),
          ],
        ),
      ),
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
  String? pdbData;
  final List<String> predefinedMolecules = [
    'caffeine.pdb',
    'ethanol.pdb',
    'aspirin.pdb',
    'glucose.pdb',
    'dna.pdb',
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _loadMoleculeData();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView错误: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('JS消息: ${message.message}');
        },
      );
    
    _loadHtmlFromAssets();
    _loadPredefinedMolecule('caffeine.pdb'); // 默认加载咖啡因分子
  }

  Future<void> _loadPredefinedMolecule(String fileName) async {
    try {
      final String data = await rootBundle.loadString('assets/molecules/$fileName');
      setState(() {
        pdbData = data;
      });
      _loadMoleculeData();
    } catch (e) {
      debugPrint('加载预定义分子失败: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdb'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String data = await file.readAsString();
        setState(() {
          pdbData = data;
        });
        _loadMoleculeData();
      }
    } catch (e) {
      debugPrint('选择文件失败: $e');
    }
  }

  void _loadMoleculeData() {
    if (pdbData != null) {
      _controller.runJavaScript('loadMolecule(`$pdbData`);');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分子查看器'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _loadPredefinedMolecule,
            itemBuilder: (BuildContext context) {
              return predefinedMolecules.map((String molecule) {
                return PopupMenuItem<String>(
                  value: molecule,
                  child: Text(molecule.replaceAll('.pdb', '')),
                );
              }).toList();
            },
            icon: const Icon(Icons.science),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _pickFile,
              child: const Text('选择PDB文件'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHtmlFromAssets() async {
    String fileHtml = await rootBundle.loadString('assets/js/molecule_viewer.html');
    _controller.loadHtmlString(
      fileHtml,
      baseUrl: Uri.dataFromString(
        '',
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ).toString(),
    );
  }
}

class HeartEffectPage extends StatefulWidget {
  const HeartEffectPage({super.key});

  @override
  State<HeartEffectPage> createState() => _HeartEffectPageState();
}

class _HeartEffectPageState extends State<HeartEffectPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('心形特效页面加载完成');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView错误: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('JS消息: ${message.message}');
        },
      );
    
    _loadHeartEffectHtml();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心形特效'),
        backgroundColor: Colors.pink,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  Future<void> _loadHeartEffectHtml() async {
    String fileHtml = await rootBundle.loadString('assets/js/codepen_heart.html');
    _controller.loadHtmlString(
      fileHtml,
      baseUrl: Uri.dataFromString(
        '',
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ).toString(),
    );
  }
}
