import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const QalamKaarProApp());
}

class QalamKaarProApp extends StatelessWidget {
  const QalamKaarProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QalamKaar Pro',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B5CF6), 
        scaffoldBackgroundColor: const Color(0xFFF8F9FA)
      ),
      home: const HomeScreen(),
    );
  }
}

// ================= HOME SCREEN =================
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showNewDesignModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Design', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildInputBox('WIDTH', '1080')),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.lock_outline, color: Colors.grey)),
                Expanded(child: _buildInputBox('HEIGHT', '1080')),
                const SizedBox(width: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: const Text('px', style: TextStyle(fontWeight: FontWeight.bold)))
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProWorkspaceScreen()));
                },
                child: const Text('Create Design', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(textAlign: TextAlign.center, decoration: InputDecoration(hintText: val, filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35))),
              child: Column(
                children: [
                  Container(padding: const EdgeInsets.all(18), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))]), child: const Icon(Icons.draw, size: 55, color: Color(0xFF6D28D9))),
                  const SizedBox(height: 15),
                  const Text('قلمکار پرو', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 55, color: Colors.white, height: 1.2)),
                  const Text('Professional Urdu Designer', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2.0, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
                children: [
                  _buildMenuCard(context, 'نیا ڈیزائن', 'New Design', Icons.add_to_photos, const Color(0xFF8B5CF6), isNewDesign: true),
                  _buildMenuCard(context, 'آن لائن ڈیزائن', 'Templates', Icons.cloud_download, const Color(0xFF10B981), isNewDesign: false),
                  _buildMenuCard(context, 'میرے ڈیزائن', 'My Folder', Icons.folder_special, const Color(0xFFF59E0B), isMyFolder: true),
                  _buildMenuCard(context, 'رہنمائی', 'Tutorials', Icons.play_circle_fill, const Color(0xFFEF4444), isNewDesign: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String urduText, String engText, IconData icon, Color color, {bool isNewDesign = false, bool isMyFolder = false}) {
    return InkWell(
      onTap: () {
        if (isNewDesign) {
          _showNewDesignModal(context);
        } else if (isMyFolder) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$engText jald aa raha hai!')));
        }
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 35)),
            const SizedBox(height: 12),
            Text(urduText, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 28, color: Colors.black87, height: 1.0)),
            Text(engText, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}

// ================= MY FOLDER SCREEN =================
class MyFolderScreen extends StatefulWidget {
  const MyFolderScreen({Key? key}) : super(key: key);
  @override
  State<MyFolderScreen> createState() => _MyFolderScreenState();
}

class _MyFolderScreenState extends State<MyFolderScreen> {
  List<ProjectModel> savedProjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    List<String> projStrings = prefs.getStringList('qalamkaar_projects') ?? [];
    setState(() {
      savedProjects = projStrings.map((s) {
        final Map<String, dynamic> jsonMap = jsonDecode(s) as Map<String, dynamic>;
        return ProjectModel.fromJson(jsonMap);
      }).toList();
      savedProjects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      isLoading = false;
    });
  }

  Future<void> _deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    savedProjects.removeWhere((p) => p.id == id);
    List<String> projStrings = savedProjects.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('qalamkaar_projects', projStrings);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text('My Folder (میرے ڈیزائن)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), elevation: 0),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : savedProjects.isEmpty 
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, size: 80, color: Colors.grey.shade400), const SizedBox(height: 15), const Text('Koi design save nahi hai.', style: TextStyle(fontSize: 18, color: Colors.grey))]))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.85),
              itemCount: savedProjects.length,
              itemBuilder: (context, index) {
                var proj = savedProjects[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProWorkspaceScreen(project: proj))).then((_) => _loadProjects());
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))), child: const Icon(Icons.design_services, size: 50, color: Color(0xFF8B5CF6)))),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(proj.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), Text('Edited: ${DateTime.fromMillisecondsSinceEpoch(proj.lastModified).toString().substring(0,10)}', style: const TextStyle(fontSize: 10, color: Colors.grey))])),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteProject(proj.id), padding: EdgeInsets.zero, constraints: const BoxConstraints())
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ================= WORKSPACE ELEMENTS (MODELS STRICT) =================
class ProjectModel {
  String id; String name; List<DesignPage> pages; int lastModified;
  ProjectModel({required this.id, required this.name, required this.pages, required this.lastModified});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'lastModified': lastModified,
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id']?.toString() ?? '', 
    name: json['name']?.toString() ?? 'Project', 
    lastModified: (json['lastModified'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    pages: (json['pages'] as List<dynamic>?)?.map((p) => DesignPage.fromJson(p as Map<String, dynamic>)).toList() ?? [],
  );
}

class DesignPage {
  String title; List<DesignElement> elements; Color pageColor;
  Uint8List? bgImageBytes; 
  double canvasRatio; 
  
  DesignPage({required this.title, required this.elements, required this.pageColor, this.bgImageBytes, this.canvasRatio = 0.707});

  Map<String, dynamic> toJson() => {
    'title': title, 'pageColor': pageColor.value,
    'bgImageBytes': bgImageBytes != null ? base64Encode(bgImageBytes!) : null,
    'canvasRatio': canvasRatio,
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  factory DesignPage.fromJson(Map<String, dynamic> json) => DesignPage(
    title: json['title']?.toString() ?? 'Page', 
    pageColor: Color((json['pageColor'] as num?)?.toInt() ?? 0xFFFFFFFF),
    bgImageBytes: json['bgImageBytes'] != null ? base64Decode(json['bgImageBytes'] as String) : null,
    canvasRatio: (json['canvasRatio'] as num?)?.toDouble() ?? 0.707,
    elements: (json['elements'] as List<dynamic>?)?.map((e) => DesignElement.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
}

class DesignElement {
  String id; double x, y; String content; Uint8List? imageBytes;
  bool isText; double fontSize; Color textColor; double opacity; double angle;
  double pitch; double yaw; bool isCircleCrop; bool flipX; bool flipY;
  bool isLocked; bool isHidden; int imageFilter; 
  
  // 🔥 NEW: Path / Freehand Drawing Support
  bool isPath;
  List<Offset>? drawPath;

  bool isBold; bool isItalic; TextAlign textAlign; double lineHeight; String fontFamily;
  bool isBorder; bool isShape; Color elementColor; double width; double height;
  double borderWidth; String borderStyle;
  Color? textBgColor; double textBgRadius; double wordSpacing; List<Color>? textGradient;
  bool hasStroke; Color strokeColor; double strokeWidth;
  bool hasShadow; Color shadowColor; double shadowBlur; double shadowOffsetX; double shadowOffsetY;

  DesignElement({
    required this.id, required this.x, required this.y, required this.content, this.imageBytes,
    this.isText = true, this.fontSize = 40.0, this.textColor = Colors.black, this.opacity = 1.0, this.angle = 0.0,
    this.pitch = 0.0, this.yaw = 0.0, this.isCircleCrop = false, this.flipX = false, this.flipY = false,
    this.isLocked = false, this.isHidden = false, this.imageFilter = 0,
    this.isPath = false, this.drawPath,
    this.isBold = false, this.isItalic = false, this.textAlign = TextAlign.center, this.lineHeight = 1.5, 
    this.fontFamily = 'JameelNoori', this.isBorder = false, this.isShape = false, 
    this.elementColor = const Color(0xFFD4AF37), this.width = 0, this.height = 0, 
    this.borderWidth = 5.0, this.borderStyle = 'royal_islamic', this.textBgColor, 
    this.textBgRadius = 10.0, this.wordSpacing = 0.0, this.textGradient,
    this.hasStroke = false, this.strokeColor = Colors.white, this.strokeWidth = 3.0,
    this.hasShadow = false, this.shadowColor = Colors.black54, this.shadowBlur = 5.0, 
    this.shadowOffsetX = 3.0, this.shadowOffsetY = 3.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'x': x, 'y': y, 'content': content,
    'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
    'isText': isText, 'fontSize': fontSize, 'textColor': textColor.value, 'opacity': opacity, 'angle': angle,
    'pitch': pitch, 'yaw': yaw, 'isCircleCrop': isCircleCrop, 'flipX': flipX, 'flipY': flipY,
    'isLocked': isLocked, 'isHidden': isHidden, 'imageFilter': imageFilter,
    'isPath': isPath, 'drawPath': drawPath?.map((o) => {'dx': o.dx, 'dy': o.dy}).toList(),
    'isBold': isBold, 'isItalic': isItalic, 'textAlign': textAlign.index, 'lineHeight': lineHeight, 'fontFamily': fontFamily,
    'isBorder': isBorder, 'isShape': isShape, 'elementColor': elementColor.value, 'width': width, 'height': height,
    'borderWidth': borderWidth, 'borderStyle': borderStyle,
    'textBgColor': textBgColor?.value, 'textBgRadius': textBgRadius, 'wordSpacing': wordSpacing,
    'textGradient': textGradient?.map((c) => c.value).toList(),
    'hasStroke': hasStroke, 'strokeColor': strokeColor.value, 'strokeWidth': strokeWidth,
    'hasShadow': hasShadow, 'shadowColor': shadowColor.value, 'shadowBlur': shadowBlur, 'shadowOffsetX': shadowOffsetX, 'shadowOffsetY': shadowOffsetY,
  };

  factory DesignElement.fromJson(Map<String, dynamic> json) => DesignElement(
    id: json['id']?.toString() ?? '', 
    x: (json['x'] as num?)?.toDouble() ?? 0.0, 
    y: (json['y'] as num?)?.toDouble() ?? 0.0, 
    content: json['content']?.toString() ?? '',
    imageBytes: json['imageBytes'] != null ? base64Decode(json['imageBytes'] as String) : null,
    isText: json['isText'] as bool? ?? true, 
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 40.0, 
    textColor: Color((json['textColor'] as num?)?.toInt() ?? 0xFF000000), 
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0, 
    angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
    pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0, 
    yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0, 
    isCircleCrop: json['isCircleCrop'] as bool? ?? false, 
    flipX: json['flipX'] as bool? ?? false, 
    flipY: json['flipY'] as bool? ?? false,
    isLocked: json['isLocked'] as bool? ?? false, 
    isHidden: json['isHidden'] as bool? ?? false, 
    imageFilter: (json['imageFilter'] as num?)?.toInt() ?? 0,
    isPath: json['isPath'] as bool? ?? false,
    drawPath: json['drawPath'] != null ? (json['drawPath'] as List<dynamic>).map((o) { final map = o as Map<String, dynamic>; return Offset((map['dx'] as num).toDouble(), (map['dy'] as num).toDouble()); }).toList() : null,
    isBold: json['isBold'] as bool? ?? false, 
    isItalic: json['isItalic'] as bool? ?? false, 
    textAlign: TextAlign.values[(json['textAlign'] as num?)?.toInt() ?? 1], 
    lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.5, 
    fontFamily: json['fontFamily']?.toString() ?? 'JameelNoori',
    isBorder: json['isBorder'] as bool? ?? false, 
    isShape: json['isShape'] as bool? ?? false, 
    elementColor: Color((json['elementColor'] as num?)?.toInt() ?? 0xFFD4AF37), 
    width: (json['width'] as num?)?.toDouble() ?? 0.0, 
    height: (json['height'] as num?)?.toDouble() ?? 0.0,
    borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 5.0, 
    borderStyle: json['borderStyle']?.toString() ?? 'royal_islamic',
    textBgColor: json['textBgColor'] != null ? Color((json['textBgColor'] as num).toInt()) : null, 
    textBgRadius: (json['textBgRadius'] as num?)?.toDouble() ?? 10.0, 
    wordSpacing: (json['wordSpacing'] as num?)?.toDouble() ?? 0.0,
    textGradient: json['textGradient'] != null ? (json['textGradient'] as List<dynamic>).map((c) => Color((c as num).toInt())).toList() : null,
    hasStroke: json['hasStroke'] as bool? ?? false, 
    strokeColor: Color((json['strokeColor'] as num?)?.toInt() ?? 0xFFFFFFFF), 
    strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
    hasShadow: json['hasShadow'] as bool? ?? false, 
    shadowColor: Color((json['shadowColor'] as num?)?.toInt() ?? 0x8A000000), 
    shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 5.0, 
    shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble() ?? 3.0, 
    shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble() ?? 3.0,
  );

  DesignElement clone() { return DesignElement.fromJson(toJson()); }
}

// ================= MAIN EDITOR SCREEN =================
class ProWorkspaceScreen extends StatefulWidget {
  final ProjectModel? project;
  const ProWorkspaceScreen({Key? key, this.project}) : super(key: key);
  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  bool _isCanvasLocked = false;
  bool _showGrid = false; 

  // 🔥 NEW: DRAWING STATES
  bool _isDrawingMode = false;
  List<Offset> _currentPath = [];
  Color _brushColor = Colors.black;
  double _brushSize = 5.0;

  // 🔥 NEW: STYLE COPIER
  DesignElement? _copiedStyle;

  late String projectId;
  late String projectName;
  List<DesignPage> pages = [];
  int currentPageIndex = 0;
  List<List<DesignElement>> undoStack = [];
  List<List<DesignElement>> redoStack = [];
  String? selectedId;
  List<String> availableFonts = ['JameelNoori', 'Amiri', 'Bombay', 'Mehr'];
  final ImagePicker _picker = ImagePicker();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      projectId = widget.project!.id;
      projectName = widget.project!.name;
      pages = widget.project!.pages;
    } else {
      projectId = DateTime.now().millisecondsSinceEpoch.toString();
      projectName = 'Design_$projectId';
      pages = [DesignPage(title: 'Page 1', elements: [DesignElement(id: 'demo1', x: 40, y: 150, content: 'مدرسہ اسلامیہ نصیرالعلوم', width: 280)], pageColor: Colors.white, canvasRatio: 1 / 1.414)];
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  double get currentCanvasRatio => pages[currentPageIndex].canvasRatio;
  set currentCanvasRatio(double val) => pages[currentPageIndex].canvasRatio = val;

  Future<void> _saveProjectLocally() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    List<String> savedStrings = prefs.getStringList('qalamkaar_projects') ?? [];
    ProjectModel p = ProjectModel(id: projectId, name: projectName, pages: pages, lastModified: DateTime.now().millisecondsSinceEpoch);
    savedStrings.removeWhere((str) => (jsonDecode(str) as Map<String, dynamic>)['id'] == projectId); 
    savedStrings.add(jsonEncode(p.toJson())); 
    await prefs.setStringList('qalamkaar_projects', savedStrings);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project "My Folder" mein save ho gaya! 🎉', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 20)), backgroundColor: Color(0xFF10B981)));
  }

  final List<Color> _proColorPalette = [
    Colors.black, Colors.white, Colors.grey.shade900, Colors.grey.shade700, Colors.grey.shade400, Colors.grey.shade200,
    const Color(0xFF800000), const Color(0xFFA52A2A), const Color(0xFFDC143C), const Color(0xFFEF4444), const Color(0xFFF87171),
    const Color(0xFF4B0082), const Color(0xFF8B5CF6), const Color(0xFF9C27B0), const Color(0xFFD946EF), const Color(0xFFEC4899), const Color(0xFFF43F5E), const Color(0xFFFFC0CB),
    const Color(0xFF000080), const Color(0xFF1E3A8A), const Color(0xFF2563EB), const Color(0xFF3B82F6), const Color(0xFF06B6D4), const Color(0xFF38BDF8), const Color(0xFFE0F2FE),
    const Color(0xFF004d00), const Color(0xFF14532D), const Color(0xFF047857), const Color(0xFF10B981), const Color(0xFF22C55E), const Color(0xFF84CC16), const Color(0xFF14B8A6), const Color(0xFFCCFFCC),
    const Color(0xFFD4AF37), const Color(0xFFB8860B), const Color(0xFFF59E0B), const Color(0xFFF97316), const Color(0xFFFF8C00), const Color(0xFFEAB308), const Color(0xFFFEF08A), const Color(0xFFFFD700),
    const Color(0xFF8B4513), const Color(0xFFD2B48C), const Color(0xFFFFE4C4), const Color(0xFFFAEBD7),
  ];

  final List<List<Color>> _proGradientPalette = [
    [const Color(0xFFBF953F), const Color(0xFFFCF6BA), const Color(0xFFB38728), const Color(0xFFFBF5B7)],
    [const Color(0xFF8E9EAB), const Color(0xFFEEF2F3)], [const Color(0xFFB87333), const Color(0xFFFFCC99), const Color(0xFFB87333)], [const Color(0xFFB76E79), const Color(0xFFE0BFB8)],
    [const Color(0xFFFF4E50), const Color(0xFFF9D423)], [const Color(0xFF1A2980), const Color(0xFF26D0CE)], [const Color(0xFF134E5E), const Color(0xFF71B280)], [const Color(0xFFFF7E5F), const Color(0xFFFEB47B)], [const Color(0xFF2C3E50), const Color(0xFF3498DB)],
    [const Color(0xFF833AB4), const Color(0xFFFD1D1D), const Color(0xFFFCB045)], [const Color(0xFF12C2E9), const Color(0xFFC471ED), const Color(0xFFF64F59)], [const Color(0xFF00C9FF), const Color(0xFF92FE9D)], [const Color(0xFFF09819), const Color(0xFFEDDE5D)], [const Color(0xFFDA22FF), const Color(0xFF9733EE)], [const Color(0xFFEC008C), const Color(0xFFFC6767)], [const Color(0xFF02AAB0), const Color(0xFF00CDAC)],
    [const Color(0xFF434343), const Color(0xFF000000)], [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], [const Color(0xFF141E30), const Color(0xFF243B55)], [const Color(0xFF870000), const Color(0xFF190A05)],
  ];

  final List<ColorFilter> _filters = [
    const ColorFilter.mode(Colors.transparent, BlendMode.dst), 
    ColorFilter.matrix(const <double>[0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]), 
    ColorFilter.matrix(const <double>[0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0]), 
    ColorFilter.matrix(const <double>[-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]), 
  ];

  List<DesignElement> get elements => pages[currentPageIndex].elements;
  set elements(List<DesignElement> val) => pages[currentPageIndex].elements = val;
  Color get pageColor => pages[currentPageIndex].pageColor;
  set pageColor(Color val) => pages[currentPageIndex].pageColor = val;
  Uint8List? get bgImage => pages[currentPageIndex].bgImageBytes;
  set bgImage(Uint8List? val) => pages[currentPageIndex].bgImageBytes = val;

  void saveState() { undoStack.add(elements.map((e) => e.clone()).toList()); redoStack.clear(); }
  void undoAction() { if (undoStack.isNotEmpty) { redoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = undoStack.removeLast(); selectedId = null; }); } }
  void redoAction() { if (redoStack.isNotEmpty) { undoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = redoStack.removeLast(); selectedId = null; }); } }

  void _showExportMenu() {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Export Design (سیو کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), const SizedBox(height: 10), _buildExportOption(Icons.image, 'Save as JPG', 'High Quality Image (Gallery)', Colors.blue, () { Navigator.pop(context); _captureAndSave('JPG'); }), const SizedBox(height: 10), _buildExportOption(Icons.layers_clear, 'Save as PNG', 'Transparent Image (Logos)', Colors.purple, () { Navigator.pop(context); _captureAndSave('PNG'); }), const SizedBox(height: 10), _buildExportOption(Icons.picture_as_pdf, 'Save as Print HD PDF', 'Zero Margins & Normal Size', Colors.red, () { Navigator.pop(context); _captureAndSave('PDF'); })])));
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))])), Icon(Icons.arrow_forward_ios, color: color, size: 16)])));
  }

  Future<void> _captureAndSave(String format) async {
    setState(() { selectedId = null; _isExporting = true; });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      double pixelRatio = 3.0; 
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (format == 'JPG' || format == 'PNG') {
        final dynamic result = await ImageGallerySaver.saveImage(pngBytes, quality: 100, name: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}");
        if (mounted && result != null && result is Map && result['isSuccess'] == true) {
          _showSuccessDialog('Saved to Gallery!', 'Aapka $format design gallery mein save ho gaya hai.');
        }
      } else if (format == 'PDF') {
        final pdf = pw.Document();
        final imagePdf = pw.MemoryImage(pngBytes);
        pdf.addPage(pw.Page(pageFormat: PdfPageFormat(image.width.toDouble(), image.height.toDouble()), margin: pw.EdgeInsets.zero, build: (pw.Context pwContext) { return pw.Image(imagePdf, fit: pw.BoxFit.cover); }));
        Uint8List pdfBytes = await pdf.save();
        await Printing.sharePdf(bytes: pdfBytes, filename: "QalamKaarPro_Print_${DateTime.now().millisecondsSinceEpoch}.pdf");
      }
    } catch (e) { debugPrint('Export Error: $e'); } finally { if (mounted) setState(() { _isExporting = false; }); }
  }

  void _showSuccessDialog(String title, String message) { showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 15), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))]))); }

  void _showTextComposerDialog({DesignElement? existingElement}) {
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? '');
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.75, padding: const EdgeInsets.all(20), child: Column(children: [Container(decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: const Text('English', style: TextStyle(color: Colors.grey))), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Text('اردو', style: TextStyle(fontWeight: FontWeight.bold)))])), const SizedBox(height: 15), Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15), color: Colors.grey.shade50), child: TextField(controller: controller, maxLines: null, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 28), decoration: const InputDecoration(border: InputBorder.none, hintText: 'یہاں لکھیں...', hintTextDirection: TextDirection.rtl)))), const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildComposerTool(Icons.paste, 'Paste'), _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()), _buildComposerTool(Icons.auto_awesome, 'AI'), _buildComposerTool(Icons.translate, 'Translate')]), const SizedBox(height: 20), Row(children: [Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)))), const SizedBox(width: 15), Expanded(flex: 2, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { if (controller.text.isNotEmpty) { saveState(); if (existingElement != null) { setState(() => existingElement.content = controller.text); } else { var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, width: 280); setState(() { elements.add(newEl); selectedId = newEl.id; }); } } Navigator.pop(context); }, icon: const Icon(Icons.check, color: Colors.white), label: const Text('Add to design', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))))])]))));
  }
  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(children: [Icon(icon, color: Colors.grey.shade600), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))])); }

  void showAddNewModal() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.65, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, children: [_buildGridItem(Icons.image, 'Gallery Pic', Colors.blue.shade100, Colors.blue, addImageFromGallery), _buildGridItem(Icons.collections, 'Stock Images', Colors.indigo.shade100, Colors.indigo, () => Navigator.pop(context)), _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade100, Colors.teal, () => Navigator.pop(context)), _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade100, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }), _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade100, Colors.amber.shade800, () => showGenericStockModal('Borders', 'royal_islamic', Icons.border_outer)), _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade100, Colors.pink, () => showGenericStockModal('Shapes', 'shape_rect', Icons.category))]))])));
  }
  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: iconColor, size: 28)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)])); }

  Future<void> addImageFromGallery() async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); saveState(); if (mounted) setState(() => elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 80, content: '', imageBytes: bytes, isText: false, width: 250))); } } catch (e) {} if(mounted) Navigator.pop(context); }
  Future<void> _pickBgImage() async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); saveState(); if(mounted) setState(() => bgImage = bytes); } } catch (e) {} }

  void showGenericStockModal(String categoryTitle, String styleName, IconData categoryIcon) {
    Navigator.pop(context); List<Map<String, dynamic>> stockList = []; List<Color> themeColors = [const Color(0xFFD4AF37), const Color(0xFF8B5CF6), const Color(0xFF047857), const Color(0xFF1E3A8A)]; for (int i = 1; i <= 50; i++) stockList.add({'title': '$categoryTitle #$i', 'style': styleName, 'color': themeColors[(i - 1) % themeColors.length], 'icon': categoryIcon});
    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.75, padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 15), Text('$categoryTitle Library', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.4), itemCount: stockList.length, itemBuilder: (context, index) { var item = stockList[index]; return InkWell(onTap: () { saveState(); setState(() { if (styleName.contains('shape') || styleName == 'badge') { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 90, y: 180, content: styleName == 'badge' ? 'circle' : 'rectangle', isText: false, isShape: true, elementColor: item['color'] as Color, width: 220, height: 90)); } else { elements.insert(0, DesignElement(id: Random().nextInt(10000).toString(), x: 0, y: 0, content: item['title'] as String, isText: false, isBorder: true, borderStyle: styleName, elementColor: item['color'] as Color, borderWidth: 5.0)); } }); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: item['color'] as Color, width: 1.5)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item['icon'] as IconData, color: item['color'] as Color, size: 30), const SizedBox(height: 6), Text(item['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item['color'] as Color))]))); }))] )));
  }

  void deleteSelected() { if (selectedId != null) { saveState(); setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; }); } }
  void duplicateSelected() { if (selectedId != null) { saveState(); DesignElement sel = elements.firstWhere((e) => e.id == selectedId, orElse: () => elements.first); setState(() { var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20; elements.add(newEl); selectedId = newEl.id; }); } }
  
  // 🔥 UPGRADED Z-INDEX TOOLS 🔥
  void bringForward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx < elements.length - 1) setState(() { var item = elements.removeAt(idx); elements.insert(idx + 1, item); }); }
  void sendBackward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx > 0) setState(() { var item = elements.removeAt(idx); elements.insert(idx - 1, item); }); }
  void bringToFront() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); setState(() { var item = elements.removeAt(idx); elements.add(item); }); }
  void sendToBack() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); setState(() { var item = elements.removeAt(idx); elements.insert(0, item); }); }

  void _toggleAlignment(DesignElement sel) { saveState(); setState(() { sel.textAlign = (sel.textAlign == TextAlign.right) ? TextAlign.center : (sel.textAlign == TextAlign.center ? TextAlign.left : TextAlign.right); }); }

  void _showTextBgPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 450, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Text Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), ListTile(leading: const Icon(Icons.block), title: const Text('Remove Background'), onTap: () { saveState(); setState(() { sel.textBgColor = null; }); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSelected = sel.textBgColor?.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { sel.textBgColor = c; }); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5)), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))])); }); }); }
  void _showGradientPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 450, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Gradient Text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), ListTile(leading: const Icon(Icons.block), title: const Text('Clear Gradient'), onTap: () { saveState(); setState(() { sel.textGradient = null; }); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 2.0), itemCount: _proGradientPalette.length, itemBuilder: (context, index) { List<Color> g = _proGradientPalette[index]; return GestureDetector(onTap: () { saveState(); setState(() { sel.textGradient = g; }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300, width: 1.5)))); }))])); }); }); }
  
  void _showColorPickerModal(DesignElement sel) { 
    TextEditingController hexCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { Color currentColor = sel.isText ? sel.textColor : sel.elementColor; return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 480, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Color (رنگ منتخب کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), 
    Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: TextField(controller: hexCtrl, decoration: const InputDecoration(hintText: 'Custom Hex: FF0000', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)))), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () { String hex = hexCtrl.text.replaceAll('#', ''); if(hex.length == 6) hex = 'FF$hex'; if(hex.length == 8) { saveState(); setState((){ int colorInt = int.tryParse(hex, radix: 16) ?? 0xFFFFFFFF; if(sel.isText){ sel.textColor = Color(colorInt); sel.textGradient = null; } else { sel.elementColor = Color(colorInt); } }); setModalState((){}); } }, child: const Text('Apply', style: TextStyle(color: Colors.white)))])),
    const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSelected = currentColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { if (sel.isText) { sel.textColor = c; sel.textGradient = null; } else { sel.elementColor = c; } }); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))]))); }); }); 
  }

  void _showAdvancedStrokeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 450, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Advanced Stroke', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Stroke', style: TextStyle(fontWeight: FontWeight.bold)), activeColor: const Color(0xFF8B5CF6), value: sel.hasStroke, onChanged: (val) { saveState(); setState(() => sel.hasStroke = val); setModalState((){}); }), const Divider(), if (sel.hasStroke) ...[Row(children: [const Text('Thickness:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.strokeWidth, min: 1.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.strokeWidth = val); setModalState((){}); }))]), const Text('Stroke Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSel = sel.strokeColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.strokeColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))] ])); }); }); }
  void _showAdvancedShadowModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 550, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Advanced Shadow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Shadow', style: TextStyle(fontWeight: FontWeight.bold)), activeColor: const Color(0xFF8B5CF6), value: sel.hasShadow, onChanged: (val) { saveState(); setState(() => sel.hasShadow = val); setModalState((){}); }), const Divider(), if (sel.hasShadow) ...[Row(children: [const Text('Blur:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowBlur, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowBlur = val); setModalState((){}); }))]), Row(children: [const Text('X-Offset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetX, min: -20.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetX = val); setModalState((){}); }))]), Row(children: [const Text('Y-Offset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetY, min: -20.0, max: 20.0, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetY = val); setModalState((){}); }))]), const Text('Shadow Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSel = sel.shadowColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.shadowColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))] ])); }); }); }
  void showSpacingModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Spacing (فاصلہ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(children: [const Text('Line:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.lineHeight, min: 0.5, max: 3.5, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.lineHeight = val); setModalState((){}); }))]), Row(children: [const Text('Word:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.wordSpacing, min: -10.0, max: 30.0, activeColor: const Color(0xFF10B981), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.wordSpacing = val); setModalState((){}); }))]),])); }); }); }
  void showSizeSliderModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Size: ${sel.fontSize.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Slider(value: sel.fontSize, min: 10.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.fontSize = val); setModalState((){}); })])); }); }); }
  void showRotationModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 200, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rotate (گھمائیں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Slider(value: sel.angle, min: -pi, max: pi, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.angle = val); setModalState((){}); }), Text('${(sel.angle * 180 / pi).toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])); }); }); }
  void show3DModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 280, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('3D Rotate (تھری ڈی زاویہ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(children: [const Text('X-Axis:', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Slider(value: sel.pitch, min: -pi/2, max: pi/2, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.pitch = val); setModalState((){}); }))]), Row(children: [const Text('Y-Axis:', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Slider(value: sel.yaw, min: -pi/2, max: pi/2, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.yaw = val); setModalState((){}); }))]), ElevatedButton(onPressed: () { saveState(); setState((){ sel.pitch=0.0; sel.yaw=0.0; }); setModalState((){}); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200), child: const Text('Reset 3D', style: TextStyle(color: Colors.black))) ])); }); }); }
  void showNudgeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { void move(double dx, double dy) { saveState(); setState(() { sel.x += dx; sel.y += dy; }); setModalState((){}); } return Container(height: 260, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Nudge Tool (خردبینی حرکت)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_upward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(0, -2))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_back, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(-2, 0)), const SizedBox(width: 40), IconButton(icon: const Icon(Icons.arrow_forward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(2, 0))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_downward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(0, 2))]),])); }); }); }
  void showFontPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Select Font (فونٹ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(), Expanded(child: ListView.builder(itemCount: availableFonts.length, itemBuilder: (context, index) { String fontName = availableFonts[index]; return ListTile(title: Text('اردو فونٹ - $fontName', style: TextStyle(fontFamily: fontName, fontSize: 24)), trailing: sel.fontFamily == fontName ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)) : null, onTap: () { saveState(); setState(() => sel.fontFamily = fontName); Navigator.pop(context); }); })),]),),); }
  
  void showFilterModal(DesignElement sel) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Image Filter (تصویری فلٹرز)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: GridView.count(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [ _buildFilterBtn(0, 'None', Icons.block, sel, setModalState), _buildFilterBtn(1, 'Grayscale', Icons.tonality, sel, setModalState), _buildFilterBtn(2, 'Sepia', Icons.filter_vintage, sel, setModalState), _buildFilterBtn(3, 'Invert', Icons.invert_colors, sel, setModalState), ])) ])); }); });
  }
  Widget _buildFilterBtn(int id, String label, IconData icon, DesignElement sel, StateSetter setModalState) {
    bool isSel = sel.imageFilter == id;
    return InkWell(onTap: () { saveState(); setState(() => sel.imageFilter = id); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.2) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.transparent)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade600), const SizedBox(height: 5), Text(label, style: TextStyle(fontSize: 10, color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade600))])));
  }

  void _autoAlign(DesignElement sel, String alignType) {
    final RenderBox? rb = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    double cw = rb.size.width; double ch = rb.size.height;
    double ew = sel.width > 50 ? sel.width : 280;
    double eh = sel.isShape || sel.isPath ? (sel.height > 20 ? sel.height : 90) : (sel.isText ? sel.fontSize * 1.5 : 150);
    saveState();
    setState(() {
      if (alignType == 'center_h') sel.x = (cw - ew) / 2;
      else if (alignType == 'center_v') sel.y = (ch - eh) / 2;
      else if (alignType == 'left') sel.x = 0;
      else if (alignType == 'right') sel.x = cw - ew;
      else if (alignType == 'top') sel.y = 0;
      else if (alignType == 'bottom') sel.y = ch - eh;
    });
  }

  void showAlignSnapModal(DesignElement sel) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Smart Align (جادوئی سیدھ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0, children: [ ElevatedButton.icon(onPressed: () => _autoAlign(sel, 'center_h'), icon: const Icon(Icons.align_horizontal_center, size: 16), label: const Text('Center H', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue)), ElevatedButton.icon(onPressed: () => _autoAlign(sel, 'center_v'), icon: const Icon(Icons.align_vertical_center, size: 16), label: const Text('Center V', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue)), ElevatedButton.icon(onPressed: () { _autoAlign(sel, 'center_h'); _autoAlign(sel, 'center_v'); }, icon: const Icon(Icons.center_focus_strong, size: 16), label: const Text('Middle', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1), foregroundColor: const Color(0xFF8B5CF6))), ElevatedButton.icon(onPressed: () => _autoAlign(sel, 'left'), icon: const Icon(Icons.align_horizontal_left, size: 16), label: const Text('Left', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87)), ElevatedButton.icon(onPressed: () => _autoAlign(sel, 'right'), icon: const Icon(Icons.align_horizontal_right, size: 16), label: const Text('Right', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87)), ElevatedButton.icon(onPressed: () => _autoAlign(sel, 'top'), icon: const Icon(Icons.align_vertical_top, size: 16), label: const Text('Top', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87)), ])) ])); });
  }

  void showCanvasResizeModal() {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Size (سائز)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView(children: [ ListTile(leading: const Icon(Icons.crop_square), title: const Text('Square / Logo (1:1)'), onTap: () { setState(() => currentCanvasRatio = 1.0); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.crop_portrait), title: const Text('Story / Reel (9:16)'), onTap: () { setState(() => currentCanvasRatio = 9/16); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.crop_landscape), title: const Text('YouTube Thumbnail (16:9)'), onTap: () { setState(() => currentCanvasRatio = 16/9); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.description), title: const Text('Document A4 (Standard)'), onTap: () { setState(() => currentCanvasRatio = 1/1.414); Navigator.pop(context); }), ])) ])); });
  }

  void showLayersPanel() { 
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) { 
      return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { 
        return Container(height: 450, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Layers (پرتیں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), 
          const Divider(), 
          Expanded(child: elements.isEmpty ? const Center(child: Text('No elements yet.', style: TextStyle(color: Colors.grey))) : ListView.builder(itemCount: elements.length, itemBuilder: (context, index) { 
            int actualIndex = elements.length - 1 - index; 
            DesignElement e = elements[actualIndex]; 
            bool isSel = selectedId == e.id; 
            
            return Card(
              color: isSel ? const Color(0xFFF3E8FF) : Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8), 
              shape: RoundedRectangleBorder(side: BorderSide(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), 
              child: ListTile(
                leading: CircleAvatar(radius: 16, backgroundColor: e.isText ? e.textColor : Colors.blueGrey, child: Icon(e.isPath ? Icons.brush : (e.isText ? Icons.title : (e.isBorder ? Icons.filter_frames : Icons.category)), size: 16, color: Colors.white)), 
                title: Text(e.isPath ? 'Drawing' : (e.isText ? e.content.replaceAll('\n', ' ') : (e.isBorder ? e.content : 'Shape/Image')), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(decoration: e.isHidden ? TextDecoration.lineThrough : null, color: e.isHidden ? Colors.grey : Colors.black)), 
                trailing: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      IconButton(icon: Icon(e.isHidden ? Icons.visibility_off : Icons.visibility, size: 20, color: e.isHidden ? Colors.grey : const Color(0xFF8B5CF6)), onPressed: () { saveState(); setState(() => e.isHidden = !e.isHidden); setModalState((){}); }),
                      IconButton(icon: Icon(e.isLocked ? Icons.lock : Icons.lock_open, size: 20, color: e.isLocked ? Colors.redAccent : const Color(0xFF8B5CF6)), onPressed: () { saveState(); setState(() { e.isLocked = !e.isLocked; if(e.isLocked && selectedId == e.id) selectedId = null; }); setModalState((){}); }),
                      Container(height: 20, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 5)),
                      IconButton(icon: const Icon(Icons.arrow_upward, size: 20, color: Colors.black54), onPressed: () { if (actualIndex < elements.length - 1) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex + 1, item); }); setModalState((){}); } }), 
                      IconButton(icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black54), onPressed: () { if (actualIndex > 0) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex - 1, item); }); setModalState((){}); } }),
                    ]
                  ),
                ), 
                onTap: () { if(!e.isLocked) { setState(() => selectedId = e.id); setModalState((){}); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh layer locked hai. Pehle unlock karein.', style: TextStyle(fontFamily: 'JameelNoori')), duration: Duration(seconds: 1))); } },
              )
            ); 
          },)),
        ]));
      });
    }); 
  }
  
  void showPagesPanel() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 400, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pages (صفحات)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView.builder(itemCount: pages.length, itemBuilder: (context, index) { bool isCurrent = currentPageIndex == index; return Card(color: isCurrent ? const Color(0xFFF3E8FF) : Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(side: BorderSide(color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: ListTile(leading: Icon(Icons.description, color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey), title: Text(pages[index].title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)), trailing: pages.length > 1 ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () { setState(() { pages.removeAt(index); if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1; }); setModalState(() {}); }) : null, onTap: () { setState(() { currentPageIndex = index; selectedId = null; }); Navigator.pop(context); },)); },)), const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () { setState(() { pages.add(DesignPage(title: 'Page ${pages.length + 1}', elements: [DesignElement(id: Random().nextInt(10000).toString(), x: 60, y: 100, content: 'نیا صفحہ', width: 250)], pageColor: Colors.white, canvasRatio: currentCanvasRatio)); currentPageIndex = pages.length - 1; selectedId = null; }); Navigator.pop(context); }, child: const Text('Add New Page', style: TextStyle(color: Colors.white)))),]));});}); }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = selectedId != null;
    DesignElement? sel;
    if (hasSelection) {
      try { sel = elements.firstWhere((e) => e.id == selectedId); } catch(e) { sel = null; }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, titleSpacing: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40)),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _buildTopBtn(Icons.layers, 'Layers', showLayersPanel), const SizedBox(width: 8),
            _buildTopBtn(Icons.auto_stories, 'Pages', showPagesPanel), const SizedBox(width: 8),
            _buildTopBtn(Icons.undo, 'Undo', undoAction), const SizedBox(width: 8),
            _buildTopBtn(Icons.redo, 'Redo', redoAction), const SizedBox(width: 5),
          ]),
        ),
        actions: [
          InkWell(
            onTap: _saveProjectLocally,
            child: Container(margin: const EdgeInsets.symmetric(vertical: 12), padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6)), borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: Row(children: const [Icon(Icons.save, color: Color(0xFF8B5CF6), size: 14), SizedBox(width: 4), Text('Save', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 11))])),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showExportMenu,
            child: Container(margin: const EdgeInsets.symmetric(vertical: 12), padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: Row(children: const [Icon(Icons.download, color: Colors.white, size: 14), SizedBox(width: 4), Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))])),
          ),
          const SizedBox(width: 10),
        ],
      ),
      
      body: Column(
        children: [
          if (!_isExporting && !_isDrawingMode)
            Container(
              padding: const EdgeInsets.only(left: 15, top: 10, bottom: 5),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _isCanvasLocked = !_isCanvasLocked),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Icon(_isCanvasLocked ? Icons.lock : Icons.lock_open, color: _isCanvasLocked ? Colors.redAccent : Colors.black87, size: 18)),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _transformController.value = Matrix4.identity(),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Icon(Icons.zoom_out_map, color: Colors.black87, size: 18)),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedId = null), 
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  panEnabled: !_isCanvasLocked && !hasSelection && !_isDrawingMode,
                  scaleEnabled: !_isCanvasLocked && !_isDrawingMode,
                  minScale: 0.2, maxScale: 5.0, 
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: AspectRatio(
                    aspectRatio: currentCanvasRatio,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: Container(
                          color: pageColor, 
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (bgImage != null)
                                Positioned.fill(
                                  child: Image.memory(bgImage!, fit: BoxFit.cover),
                                ),

                              if (_showGrid && !_isExporting)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Stack(
                                      children: [
                                        Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Container(height: 1, color: Colors.blue.withOpacity(0.3)), Container(height: 1, color: Colors.blue.withOpacity(0.3))]),
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Container(width: 1, color: Colors.blue.withOpacity(0.3)), Container(width: 1, color: Colors.blue.withOpacity(0.3))]),
                                        Center(child: Container(width: double.infinity, height: 1, color: Colors.red.withOpacity(0.5))),
                                        Center(child: Container(width: 1, height: double.infinity, color: Colors.red.withOpacity(0.5))),
                                      ],
                                    ),
                                  ),
                                ),

                              if (!_isExporting)
                                Positioned.fill(child: Container(margin: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5)), child: Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(4.0), child: Text('Safe Area', style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontSize: 10)))))),
                              
                              ...elements.map((e) {
                                if (e.isHidden) return const SizedBox.shrink();

                                bool isSel = e.id == selectedId;
                                
                                Matrix4 matrix = Matrix4.identity()
                                  ..setEntry(3, 2, 0.002) 
                                  ..rotateX(e.pitch)
                                  ..rotateY(e.yaw)
                                  ..rotateZ(e.angle);
                                
                                if (e.flipX) matrix.rotateY(pi);
                                if (e.flipY) matrix.rotateX(pi);

                                if (e.isBorder) {
                                  return Positioned.fill(
                                    child: GestureDetector(
                                      onTap: e.isLocked || _isDrawingMode ? null : () => setState(() => selectedId = e.id), 
                                      child: Transform(
                                        transform: matrix, alignment: Alignment.center,
                                        child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: e.elementColor, width: e.borderWidth), borderRadius: BorderRadius.circular(10), color: isSel && !_isExporting ? Colors.purple.withOpacity(0.05) : Colors.transparent))
                                      )
                                    )
                                  );
                                }

                                Widget contentWidget;
                                double currentWidth = e.width > 50 ? e.width : 280.0; 

                                // 🔥 NEW: PATH DRAWING RENDERER 🔥
                                if (e.isPath && e.drawPath != null) {
                                  contentWidget = CustomPaint(
                                    size: Size(currentWidth, e.height > 10 ? e.height : 50),
                                    painter: DrawingPainter(path: e.drawPath!, color: e.elementColor, width: e.strokeWidth),
                                  );
                                }
                                else if (e.isShape) {
                                  contentWidget = Container(width: currentWidth, height: e.height > 20 ? e.height : 90, decoration: BoxDecoration(color: e.elementColor, borderRadius: BorderRadius.circular(8)));
                                } else if (e.imageBytes != null) {
                                  Widget img = Image.memory(e.imageBytes!, width: currentWidth, fit: BoxFit.contain);
                                  if (e.imageFilter > 0 && e.imageFilter < _filters.length) {
                                    img = ColorFiltered(colorFilter: _filters[e.imageFilter], child: img);
                                  }
                                  if (e.isCircleCrop) {
                                    contentWidget = Container(width: currentWidth, height: currentWidth, clipBehavior: Clip.antiAlias, decoration: const BoxDecoration(shape: BoxShape.circle), child: img);
                                  } else {
                                    contentWidget = SizedBox(width: currentWidth, child: img);
                                  }
                                } else {
                                  List<Shadow> textShadows = [];
                                  if (e.hasShadow) { textShadows.add(Shadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY))); }

                                  Widget txt = Text(
                                    e.content, textAlign: e.textAlign, softWrap: true, textDirection: TextDirection.rtl,
                                    style: TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, color: e.textGradient != null ? Colors.white : e.textColor, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, height: e.lineHeight, wordSpacing: e.wordSpacing, shadows: textShadows.isNotEmpty ? textShadows : null),
                                  );
                                  
                                  if (e.textGradient != null) { txt = ShaderMask(shaderCallback: (bounds) => LinearGradient(colors: e.textGradient!).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)), child: txt); }
                                  if (e.hasStroke) {
                                    Widget strokeTxt = Text(e.content, textAlign: e.textAlign, softWrap: true, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = e.strokeWidth..color = e.strokeColor, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, height: e.lineHeight, wordSpacing: e.wordSpacing));
                                    txt = Stack(clipBehavior: Clip.none, children: [strokeTxt, txt]);
                                  }
                                  if (e.textBgColor != null) { txt = Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: e.textBgColor, borderRadius: BorderRadius.circular(e.textBgRadius)), child: txt); }
                                  contentWidget = SizedBox(width: currentWidth, child: txt);
                                }

                                if (_isExporting) { 
                                  return Positioned(left: e.x, top: e.y, child: Transform(transform: matrix, alignment: Alignment.center, child: Opacity(opacity: e.opacity, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), child: contentWidget)))); 
                                }

                                return Positioned(
                                  left: e.x, top: e.y,
                                  child: GestureDetector(
                                    onTap: e.isLocked || _isDrawingMode ? null : () => setState(() => selectedId = e.id),
                                    onPanStart: e.isLocked || _isDrawingMode ? null : (d) => saveState(),
                                    onPanUpdate: e.isLocked || _isDrawingMode ? null : (d) => setState(() { selectedId = e.id; e.x += d.delta.dx; e.y += d.delta.dy; }),
                                    child: Transform(
                                      transform: matrix, alignment: Alignment.center,
                                      child: isSel 
                                        ? Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5), color: Colors.purple.withOpacity(0.05)), child: Opacity(opacity: e.opacity, child: contentWidget)),
                                                    const Positioned(top: -15, left: 0, right: 0, child: Center(child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.refresh, size: 14, color: Colors.black)))),
                                                    Positioned(right: -15, top: 0, bottom: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double w = currentWidth + d.delta.dx; if (w > 50) e.width = w; }); }, child: Container(width: 30, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 8, height: 25, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                                    Positioned(left: -15, top: 0, bottom: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double newW = currentWidth - d.delta.dx; if (newW > 50) { e.width = newW; e.x += d.delta.dx; } }); }, child: Container(width: 30, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 8, height: 25, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                                  ],
                                                ),
                                                const SizedBox(height: 15),
                                                Material(
                                                  color: Colors.transparent, elevation: 4, borderRadius: BorderRadius.circular(20),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        InkWell(onTap: sendToBack, child: const Icon(Icons.vertical_align_bottom, size: 22, color: Colors.black87)), const SizedBox(width: 10),
                                                        InkWell(onTap: sendBackward, child: const Icon(Icons.arrow_downward, size: 22, color: Colors.black87)), const SizedBox(width: 10),
                                                        InkWell(onTap: duplicateSelected, child: const Icon(Icons.copy, size: 22, color: Colors.black87)), const SizedBox(width: 10),
                                                        InkWell(onTap: deleteSelected, child: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent)), const SizedBox(width: 10),
                                                        InkWell(onTap: bringForward, child: const Icon(Icons.arrow_upward, size: 22, color: Colors.black87)), const SizedBox(width: 10),
                                                        InkWell(onTap: bringToFront, child: const Icon(Icons.vertical_align_top, size: 22, color: Colors.black87)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), child: Opacity(opacity: e.opacity, child: contentWidget)),
                                    ),
                                  ),
                                );
                              }).toList(),

                              // 🔥 NEW PRO FEATURE: FREEHAND DRAWING OVERLAY 🔥
                              if (_isDrawingMode)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onPanStart: (d) => setState(() => _currentPath = [d.localPosition]),
                                    onPanUpdate: (d) => setState(() => _currentPath.add(d.localPosition)),
                                    onPanEnd: (d) {
                                      if (_currentPath.length > 1) {
                                        double minX = _currentPath.map((o) => o.dx).reduce(min);
                                        double maxX = _currentPath.map((o) => o.dx).reduce(max);
                                        double minY = _currentPath.map((o) => o.dy).reduce(min);
                                        double maxY = _currentPath.map((o) => o.dy).reduce(max);
                                        List<Offset> normalized = _currentPath.map((o) => Offset(o.dx - minX, o.dy - minY)).toList();
                                        saveState();
                                        setState(() {
                                          elements.add(DesignElement(
                                            id: Random().nextInt(100000).toString(),
                                            x: minX, y: minY, content: 'Path',
                                            isText: false, isPath: true, drawPath: normalized,
                                            elementColor: _brushColor, strokeWidth: _brushSize,
                                            width: max(maxX - minX, 10.0), height: max(maxY - minY, 10.0)
                                          ));
                                        });
                                        _currentPath = [];
                                      }
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      child: CustomPaint(
                                        painter: DrawingPainter(path: _currentPath, color: _brushColor, width: _brushSize),
                                      ),
                                    )
                                  )
                                ),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(child: Container(color: Colors.white, child: _isDrawingMode ? _buildDrawingToolBar() : (hasSelection && sel != null ? _buildSelectedToolBar(sel) : _buildDefaultBottomBar()))),
    );
  }

  Widget _buildDefaultBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          InkWell(onTap: showAddNewModal, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(15)), child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.add, color: Color(0xFF8B5CF6), size: 24), SizedBox(height: 2), Text('ADD NEW', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold))]))),
          const SizedBox(width: 8),
          Container(width: 1, height: 40, color: Colors.grey.shade300), 
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToolBtn(Icons.brush, 'Draw', () => setState(() { _isDrawingMode = true; selectedId = null; })), // 🔥 BRUSH TOOL
                  _buildToolBtn(Icons.grid_on, 'Grid', () => setState(() => _showGrid = !_showGrid)), 
                  _buildToolBtn(Icons.image, 'BG Image', _pickBgImage), 
                  _buildToolBtn(Icons.aspect_ratio, 'Resize', showCanvasResizeModal), 
                  _buildToolBtn(Icons.layers_clear, 'Clear BG', () { saveState(); setState(() { pageColor = Colors.transparent; bgImage = null; }); }), 
                  _buildToolBtn(Icons.format_color_fill, 'BG Color', () { saveState(); setState((){ pageColor = pageColor == Colors.white ? Colors.amber.shade100 : Colors.white; bgImage = null; }); }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingToolBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 30), onPressed: () => setState(() => _isDrawingMode = false)),
          Expanded(child: Slider(value: _brushSize, min: 1.0, max: 30.0, activeColor: _brushColor, onChanged: (v) => setState(() => _brushSize = v))),
          InkWell(
            onTap: () {
              showModalBottomSheet(context: context, builder: (ctx) => Container(height: 300, padding: const EdgeInsets.all(20), child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _proColorPalette.length, itemBuilder: (ctx, i) { Color c = _proColorPalette[i]; return InkWell(onTap: () { setState(() => _brushColor = c); Navigator.pop(ctx); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey)))); })));
            },
            child: Container(width: 35, height: 35, decoration: BoxDecoration(color: _brushColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey))),
          ),
          const SizedBox(width: 10),
          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 30), onPressed: () => setState(() => _isDrawingMode = false)),
        ]
      )
    );
  }

  Widget _buildSelectedToolBar(DesignElement sel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.grey.shade50, padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 10),
                _buildToolBtn(Icons.align_horizontal_center, 'Align', () => showAlignSnapModal(sel)),

                // 🔥 NEW: STYLE COPIER TOOLS 🔥
                _buildToolBtn(Icons.copy_all, 'Copy Style', () { setState(() => _copiedStyle = sel.clone()); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Style Copied!'))); }),
                if (_copiedStyle != null)
                  _buildToolBtn(Icons.paste, 'Paste Style', () { saveState(); setState(() { sel.textColor = _copiedStyle!.textColor; sel.fontFamily = _copiedStyle!.fontFamily; sel.hasShadow = _copiedStyle!.hasShadow; sel.shadowColor = _copiedStyle!.shadowColor; sel.shadowBlur = _copiedStyle!.shadowBlur; sel.shadowOffsetX = _copiedStyle!.shadowOffsetX; sel.shadowOffsetY = _copiedStyle!.shadowOffsetY; sel.hasStroke = _copiedStyle!.hasStroke; sel.strokeColor = _copiedStyle!.strokeColor; sel.strokeWidth = _copiedStyle!.strokeWidth; sel.textGradient = _copiedStyle!.textGradient; sel.textBgColor = _copiedStyle!.textBgColor; sel.opacity = _copiedStyle!.opacity; }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Style Pasted!'))); }),

                if (sel.isText) _buildToolBtn(Icons.text_fields, 'Size', () => showSizeSliderModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.height, 'Spacing', () => showSpacingModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.format_color_fill, 'Text BG', () => _showTextBgPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.gradient, 'Gradient', () => _showGradientPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.format_align_left, 'Justify', () => _toggleAlignment(sel)),
                if (sel.isText || sel.isPath) _buildToolBtn(Icons.border_color, 'Stroke', () => _showAdvancedStrokeModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.brightness_6, 'Shadow', () => _showAdvancedShadowModal(sel)),
                
                if (sel.imageBytes != null) _buildToolBtn(Icons.filter_b_and_w, 'Filters', () => showFilterModal(sel)),
                if (sel.imageBytes != null) _buildToolBtn(Icons.crop_din, 'Circle Crop', () { saveState(); setState(() => sel.isCircleCrop = !sel.isCircleCrop); }),
                
                _buildToolBtn(Icons.flip, 'Flip H', () { saveState(); setState(() => sel.flipX = !sel.flipX); }),
                _buildToolBtn(Icons.flip_camera_android, 'Flip V', () { saveState(); setState(() => sel.flipY = !sel.flipY); }),
                _buildToolBtn(Icons.opacity, 'Opacity', () { saveState(); setState(() => sel.opacity = sel.opacity == 1.0 ? 0.5 : 1.0); }),
                _buildToolBtn(Icons.rotate_right, 'Rotate', () => showRotationModal(sel)), 
                _buildToolBtn(Icons.view_in_ar, '3D Rotate', () => show3DModal(sel)), 
                _buildToolBtn(Icons.open_with, 'Nudge', () => showNudgeModal(sel)),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              InkWell(onTap: () => setState(() => selectedId = null), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6)), borderRadius: BorderRadius.circular(20)), child: Row(children: const [Icon(Icons.remove_circle_outline, color: Color(0xFF8B5CF6), size: 18), SizedBox(width: 5), Text('DESELECT', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12))]))),
              const Expanded(child: SizedBox()),
              if (sel.isText) _buildToolBtn(Icons.edit, 'Edit', () => _showTextComposerDialog(existingElement: sel)),
              if (sel.isText) _buildToolBtn(Icons.font_download, 'Font', () => showFontPickerModal(sel)),
              if (sel.isText || sel.isBorder || sel.isShape || sel.isPath) _buildToolBtn(Icons.palette, 'Color', () => _showColorPickerModal(sel)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTopBtn(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade800, size: 22), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))])); }
  Widget _buildToolBtn(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade700, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700))]))); }
}

// 🔥 NEW: DRAWING RENDERER (FREEHAND BRUSH) 🔥
class DrawingPainter extends CustomPainter {
  final List<Offset> path;
  final Color color;
  final double width;

  DrawingPainter({required this.path, required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p = Path();
    p.moveTo(path[0].dx, path[0].dy);
    for (int i = 1; i < path.length; i++) {
      p.lineTo(path[i].dx, path[i].dy);
    }
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
