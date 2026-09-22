import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/design_models.dart';

class WorkspaceController extends ChangeNotifier {
  String projectId;
  String projectName;
  List<DesignPage> pages = [];
  int currentPageIndex = 0;
  
  String? selectedId;
  String activeToolbarMenu = 'main';
  
  bool isCanvasLocked = false;
  bool showGrid = false;
  bool needsRescale = false;
  bool isExporting = false;

  double currentCanvasW = 1000;
  double currentCanvasH = 1000;

  Map<String, Map<int, Map<String, dynamic>>> textMultiStyles = {};
  
  List<List<DesignElement>> undoStack = [];
  List<List<DesignElement>> redoStack = [];
  List<Map<String, Map<int, Map<String, dynamic>>>> undoMultiStylesStack = [];
  List<Map<String, Map<int, Map<String, dynamic>>>> redoMultiStylesStack = [];

  final GlobalKey canvasKey = GlobalKey();

  final List<Map<String, String>> availableFontsData = [
    {
      'name': 'JameelNoori', 
      'title': 'جمیل نوری نستعلیق', 
      'desc': 'Classic Standard Urdu Font'
    },
    {
      'name': 'AlviNastaleeq', 
      'title': 'علوی نستعلیق', 
      'desc': 'Beautiful Nasta\'liq Style'
    },
    {
      'name': 'Mehr', 
      'title': 'مہر نستعلیق', 
      'desc': 'Modern & Elegant Font'
    },
    {
      'name': 'BombayBlack', 
      'title': 'بمبئی بلیک', 
      'desc': 'Thick Header & Title Font'
    },
    {
      'name': 'AlMajeed', 
      'title': 'المجید قرآنی فونٹ', 
      'desc': 'Classic Arabic/Quranic Font'
    },
  ];

  List<String> customFonts = [];

  WorkspaceController({ProjectModel? project}) 
      : projectId = project?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        projectName = project?.name ?? 'Design_${DateTime.now().millisecondsSinceEpoch}' {
    if (project != null) {
      pages = project.pages;
    } else {
      pages = [
        DesignPage(
          title: 'Page 1', 
          elements: [], 
          pageColor: Colors.white
        )
      ];
    }
  }

  List<DesignElement> get elements => pages[currentPageIndex].elements;
  set elements(List<DesignElement> val) { 
    pages[currentPageIndex].elements = val; 
    notifyListeners(); 
  }

  Color get pageColor => pages[currentPageIndex].pageColor;
  set pageColor(Color val) { 
    pages[currentPageIndex].pageColor = val; 
    notifyListeners(); 
  }

  List<Color>? get bgGradient => pages[currentPageIndex].bgGradient;
  set bgGradient(List<Color>? val) { 
    pages[currentPageIndex].bgGradient = val; 
    notifyListeners(); 
  }

  double get canvasRatio => pages[currentPageIndex].canvasRatio;
  set canvasRatio(double val) { 
    pages[currentPageIndex].canvasRatio = val; 
    notifyListeners(); 
  }

  Uint8List? get bgImageBytes => pages[currentPageIndex].bgImageBytes;
  set bgImageBytes(Uint8List? val) { 
    pages[currentPageIndex].bgImageBytes = val; 
    notifyListeners(); 
  }

  DesignElement? get selectedElement {
    if (selectedId == null) return null;
    try { 
      return elements.firstWhere((e) => e.id == selectedId); 
    } catch (e) { 
      return null; 
    }
  }

  void triggerUpdate() { 
    notifyListeners(); 
  }

  Map<String, Map<int, Map<String, dynamic>>> deepCopyMultiStyles(Map<String, Map<int, Map<String, dynamic>>> source) {
    Map<String, Map<int, Map<String, dynamic>>> copy = {};
    source.forEach((key, val) {
      copy[key] = {};
      val.forEach((idx, styleMap) { 
        copy[key]![idx] = Map<String, dynamic>.from(styleMap); 
      });
    });
    return copy;
  }

  void saveState() {
    undoStack.add(elements.map((e) => e.clone()).toList());
    undoMultiStylesStack.add(deepCopyMultiStyles(textMultiStyles));
    redoStack.clear(); 
    redoMultiStylesStack.clear();
    if (undoStack.length > 10) { 
      undoStack.removeAt(0); 
      undoMultiStylesStack.removeAt(0); 
    }
  }

  void undoAction() {
    if (undoStack.isNotEmpty) {
      redoStack.add(elements.map((e) => e.clone()).toList());
      redoMultiStylesStack.add(deepCopyMultiStyles(textMultiStyles));
      elements = undoStack.removeLast(); 
      textMultiStyles = undoMultiStylesStack.removeLast();
      selectedId = null; 
      activeToolbarMenu = 'main'; 
      HapticFeedback.lightImpact(); 
      notifyListeners();
    }
  }

  void redoAction() {
    if (redoStack.isNotEmpty) {
      undoStack.add(elements.map((e) => e.clone()).toList());
      undoMultiStylesStack.add(deepCopyMultiStyles(textMultiStyles));
      elements = redoStack.removeLast(); 
      textMultiStyles = redoMultiStylesStack.removeLast();
      selectedId = null; 
      activeToolbarMenu = 'main'; 
      HapticFeedback.lightImpact(); 
      notifyListeners();
    }
  }

  Future<File> getProjectsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/qalamkaar_projects.json');
  }

  Future<void> saveProjectLocally(BuildContext context, {bool isAutoSave = false}) async {
    try {
      final file = await getProjectsFile();
      List<dynamic> jsonList = [];
      if (await file.exists()) {
        String contents = await file.readAsString();
        jsonList = jsonDecode(contents);
      }
      ProjectModel p = ProjectModel(
        id: projectId, 
        name: projectName, 
        pages: pages, 
        lastModified: DateTime.now().millisecondsSinceEpoch
      );
      jsonList.removeWhere((item) => item['id'] == projectId);
      jsonList.add(p.toJson());
      await file.writeAsString(jsonEncode(jsonList));
      if (!isAutoSave && context.mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project Saved Successfully!'))
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  void resizeEdge(DragUpdateDetails d, String edge, DesignElement e) {
    double ldx = d.delta.dx; 
    double ldy = d.delta.dy;
    
    if (e.angle != 0) {
      double cosA = cos(-e.angle); 
      double sinA = sin(-e.angle);
      ldx = d.delta.dx * cosA - d.delta.dy * sinA; 
      ldy = d.delta.dx * sinA + d.delta.dy * cosA;
    }
    
    if (edge == 'R') { 
      e.width = max(50.0, e.width + ldx); 
    } else if (edge == 'L') { 
      double oldW = e.width; 
      e.width = max(50.0, e.width - ldx); 
      e.x += (oldW - e.width) * cos(e.angle); 
      e.y += (oldW - e.width) * sin(e.angle); 
    } else if (edge == 'B') { 
      if (!e.isText) e.height = max(30.0, e.height + ldy); 
    } else if (edge == 'T') { 
      if (!e.isText) { 
        double oldH = e.height; 
        e.height = max(30.0, e.height - ldy); 
        e.x -= (oldH - e.height) * sin(e.angle); 
        e.y += (oldH - e.height) * cos(e.angle); 
      } 
    }
    notifyListeners();
  }

  void scaleCorner(DragUpdateDetails d, DesignElement e, String corner) {
    double ldx = d.delta.dx; 
    double ldy = d.delta.dy;
    
    if (e.angle != 0) {
      double cosA = cos(-e.angle); 
      double sinA = sin(-e.angle);
      ldx = d.delta.dx * cosA - d.delta.dy * sinA; 
      ldy = d.delta.dx * sinA + d.delta.dy * cosA;
    }
    
    double delta = 0;
    if (corner == 'BR') {
      delta = ldx;
    } else if (corner == 'BL') {
      delta = -ldx;
    } else if (corner == 'TR') {
      delta = ldx;
    } else if (corner == 'TL') {
      delta = -ldx;
    }
    
    if (delta == 0 && ldy != 0) { 
      if (corner == 'BR' || corner == 'BL') {
        delta = ldy; 
      } else {
        delta = -ldy; 
      }
    }
    
    if (e.width + delta > 40) {
      double oldWidth = e.width; 
      e.width += delta;
      
      if (e.isText) { 
        double scaleFactor = e.width / oldWidth; 
        e.fontSize = max(10.0, e.fontSize * scaleFactor); 
      } else { 
        double ratio = oldWidth / (e.height > 0 ? e.height : 1); 
        e.height += delta / ratio; 
      }
      
      double wDiff = e.width - oldWidth;
      if (corner == 'TL' || corner == 'BL') { 
        e.x -= wDiff * cos(e.angle); 
        e.y -= wDiff * sin(e.angle); 
      }
    }
    notifyListeners();
  }

  void rotateElement(DragUpdateDetails d, DesignElement e) { 
    e.angle += (d.delta.dx + d.delta.dy) * 0.015; 
    notifyListeners(); 
  }

  void deleteSelected() {
    if (selectedId != null) { 
      saveState(); 
      elements.removeWhere((e) => e.id == selectedId); 
      textMultiStyles.remove(selectedId); 
      selectedId = null; 
      activeToolbarMenu = 'main'; 
      notifyListeners(); 
    }
  }

  void duplicateSelected() {
    if (selectedId != null) {
      saveState();
      DesignElement sel = elements.firstWhere((e) => e.id == selectedId);
      var newEl = sel.clone()
        ..id = Random().nextInt(10000).toString()
        ..x += 20
        ..y += 20; 
      if (textMultiStyles.containsKey(sel.id)) {
        textMultiStyles[newEl.id] = {};
        textMultiStyles[sel.id]!.forEach((idx, styleMap) { 
          textMultiStyles[newEl.id]![idx] = Map<String, dynamic>.from(styleMap); 
        });
      }
      elements.add(newEl); 
      selectedId = newEl.id; 
      activeToolbarMenu = 'main'; 
      notifyListeners();
    }
  }

  void bringForward() {
    if (selectedId == null) return;
    saveState(); 
    int idx = elements.indexWhere((e) => e.id == selectedId);
    if (idx < elements.length - 1) { 
      var item = elements.removeAt(idx); 
      elements.insert(idx + 1, item); 
      notifyListeners(); 
    }
  }

  void sendBackward() {
    if (selectedId == null) return;
    saveState(); 
    int idx = elements.indexWhere((e) => e.id == selectedId);
    if (idx > 0) { 
      var item = elements.removeAt(idx); 
      elements.insert(idx - 1, item); 
      notifyListeners(); 
    }
  }

  Future<void> captureAndSave(BuildContext context, String format) async {
    selectedId = null; 
    isExporting = true; 
    activeToolbarMenu = 'main'; 
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 400));
    
    try {
      RenderRepaintBoundary boundary = canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      double pixelRatio = (currentCanvasW > 1200 || currentCanvasH > 1200) ? 2.0 : 3.0;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) throw Exception("Failed to convert image to bytes");
      Uint8List pngBytes = byteData.buffer.asUint8List();
      
      if (format == 'JPG' || format == 'PNG') {
        final result = await ImageGallerySaver.saveImage(
          pngBytes, 
          quality: 100, 
          name: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}"
        );
        if (context.mounted && result != null && result['isSuccess'] == true) { 
          _showSuccessDialog(context, 'Saved to Gallery!', 'Aapka $format design gallery mein save ho gaya hai.'); 
        }
      } else if (format == 'PDF') {
        final pdf = pw.Document(); 
        final imagePdf = pw.MemoryImage(pngBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(image.width.toDouble(), image.height.toDouble()), 
            margin: pw.EdgeInsets.zero, 
            build: (pw.Context context) { 
              return pw.Center(child: pw.Image(imagePdf)); 
            }
          )
        );
        Uint8List pdfBytes = await pdf.save();
        await Printing.sharePdf(
          bytes: pdfBytes, 
          filename: "QalamKaarPro_Print_${DateTime.now().millisecondsSinceEpoch}.pdf"
        );
      }
    } catch (e) { 
      debugPrint('Export Error: $e'); 
    } finally { 
      isExporting = false; 
      notifyListeners(); 
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
        content: Column(
          mainAxisSize: MainDimensions.minIfNeeded = MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), 
              onPressed: () => Navigator.pop(context), 
              child: const Text('OK', style: TextStyle(color: Colors.white))
            )
          ]
        )
      )
    );
  }
}
