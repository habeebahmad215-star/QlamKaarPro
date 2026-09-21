import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async'; 
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/design_models.dart';
import '../widgets/custom_widgets.dart';
import '../utils/constants.dart';
import 'my_folder_screen.dart';
import 'workspace_components.dart';
import 'workspace_modals.dart';
import 'workspace_toolbars.dart';

class ProWorkspaceScreen extends StatefulWidget {
  final ProjectModel? project;
  final String? initialAction;
  final String? initialData; 

  const ProWorkspaceScreen({
    Key? key, 
    this.project, 
    this.initialAction, 
    this.initialData
  }) : super(key: key);
  
  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> with WorkspaceModals {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  final ValueNotifier<int> _canvasNotifier = ValueNotifier<int>(0);

  bool _isCanvasLocked = false;
  bool _showGrid = false;
  @override
  double currentCanvasW = 1000;
  @override
  double currentCanvasH = 1000;
  
  bool _needsRescale = false;
  
  late String projectId;
  late String projectName;
  @override
  List<DesignPage> pages = [];
  @override
  int currentPageIndex = 0;
  
  List<List<DesignElement>> undoStack = [];
  List<List<DesignElement>> redoStack = [];
  @override
  String? selectedId;
  @override
  String activeToolbarMenu = 'main';

  @override
  Map<String, Map<int, Map<String, dynamic>>> textMultiStyles = {};
  
  List<Map<String, Map<int, Map<String, dynamic>>>> undoMultiStylesStack = [];
  List<Map<String, Map<int, Map<String, dynamic>>>> redoMultiStylesStack = [];

  final List<Map<String, String>> availableFontsData = [
    {'name': 'JameelNoori', 'title': 'جمیل نوری نستعلیق', 'desc': 'Classic Standard Urdu Font'},
    {'name': 'AlviNastaleeq', 'title': 'علوی نستعلیق', 'desc': 'Beautiful Nasta\'liq Style'},
    {'name': 'Mehr', 'title': 'مہر نستعلیق', 'desc': 'Modern & Elegant Font'},
    {'name': 'BombayBlack', 'title': 'بمبئی بلیک', 'desc': 'Thick Header & Title Font'},
    {'name': 'AlMajeed', 'title': 'المجید قرآنی فونٹ', 'desc': 'Classic Arabic/Quranic Font'},
  ];

  List<String> customFonts = [];
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
      pages = [DesignPage(title: 'Page 1', elements: [], pageColor: Colors.white)];
    }
    
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialAction == 'text_editor') {
          showTextComposerDialog();
        } else if (widget.initialAction == 'images') {
          addImageFromGallery(fromModal: false);
        } else if (widget.initialAction == 'elements') {
          showAddNewModal();
        } else if (widget.initialAction == 'add_sticker' && widget.initialData != null) {
          _addStickerToCanvas(widget.initialData!);
        }
      });
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    _canvasNotifier.dispose();
    super.dispose();
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

  @override
  void triggerCanvasUpdate() {
    _canvasNotifier.value++;
  }

  void _addStickerToCanvas(String stickerStr) {
    saveState();
    setState(() {
      var newEl = DesignElement(
        id: Random().nextInt(10000).toString(),
        x: 80, y: 150,
        content: stickerStr,
        isText: true,
        width: 150, height: 150,
        fontSize: 80, 
      );
      elements.add(newEl);
      selectedId = newEl.id;
      activeToolbarMenu = 'main';
    });
    triggerCanvasUpdate();
  }

  Future<File> _getProjectsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/qalamkaar_projects.json');
  }

  Future<void> _saveProjectLocally() async {
    try {
      final file = await _getProjectsFile();
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
      
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project Saved Successfully!'))
      );
    } catch (e) {
      debugPrint("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving project!'))
      );
    }
  }

  @override
  List<DesignElement> get elements => pages[currentPageIndex].elements;
  @override
  set elements(List<DesignElement> val) => pages[currentPageIndex].elements = val;
  Color get pageColor => pages[currentPageIndex].pageColor;
  set pageColor(Color val) => pages[currentPageIndex].pageColor = val;
  List<Color>? get bgGradient => pages[currentPageIndex].bgGradient;
  set bgGradient(List<Color>? val) => pages[currentPageIndex].bgGradient = val;
  double get canvasRatio => pages[currentPageIndex].canvasRatio;
  set canvasRatio(double val) => pages[currentPageIndex].canvasRatio = val;
  Uint8List? get bgImageBytes => pages[currentPageIndex].bgImageBytes;
  set bgImageBytes(Uint8List? val) => pages[currentPageIndex].bgImageBytes = val;

  @override
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
      setState(() { 
        elements = undoStack.removeLast(); 
        textMultiStyles = undoMultiStylesStack.removeLast();
        selectedId = null; 
        activeToolbarMenu = 'main'; 
      });
      HapticFeedback.lightImpact();
      triggerCanvasUpdate();
    }
  }

  void redoAction() {
    if (redoStack.isNotEmpty) {
      undoStack.add(elements.map((e) => e.clone()).toList());
      redoMultiStylesStack.add(deepCopyMultiStyles(textMultiStyles));
      setState(() { 
        elements = redoStack.removeLast(); 
        textMultiStyles = redoMultiStylesStack.removeLast();
        selectedId = null; 
        activeToolbarMenu = 'main'; 
      });
      HapticFeedback.lightImpact();
      triggerCanvasUpdate();
    }
  }

  void _resizeEdge(DragUpdateDetails d, String edge, DesignElement e) {
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
    triggerCanvasUpdate();
  }

  void _scaleCorner(DragUpdateDetails d, DesignElement e, String corner) {
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
    triggerCanvasUpdate();
  }

  void _rotateElement(DragUpdateDetails d, DesignElement e) {
    e.angle += (d.delta.dx + d.delta.dy) * 0.015;
    triggerCanvasUpdate();
  }

  Future<void> _captureAndSave(String format) async {
    setState(() { 
      selectedId = null; 
      _isExporting = true; 
      activeToolbarMenu = 'main'; 
    });
    
    await Future.delayed(const Duration(milliseconds: 400));
    
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      double pixelRatio = (currentCanvasW > 1200 || currentCanvasH > 1200) ? 2.0 : 3.0;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }
      
      Uint8List pngBytes = byteData.buffer.asUint8List();
      
      if (format == 'JPG' || format == 'PNG') {
        final result = await ImageGallerySaver.saveImage(
          pngBytes, 
          quality: 100, 
          name: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}"
        );
        if (mounted && result != null && result['isSuccess'] == true) {
          _showSuccessDialog('Saved to Gallery!', 'Aapka $format design gallery mein save ho gaya hai.');
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
      setState(() { 
        _isExporting = false; 
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent, 
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _buildGlassContainer(
          context,
          height: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Export Design', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context))
                ]
              ),
              const Divider(color: Colors.black12),
              const SizedBox(height: 5),
              _buildExportOption(Icons.image, 'Save as JPG', 'Solid Background', Colors.blue, () { Navigator.pop(context); _captureAndSave('JPG'); }),
              const SizedBox(height: 8),
              _buildExportOption(Icons.layers_clear, 'Save as PNG', 'Transparent Image', Colors.purple, () { Navigator.pop(context); _captureAndSave('PNG'); }),
              const SizedBox(height: 8),
              _buildExportOption(Icons.picture_as_pdf, 'Save as Print PDF', 'High Quality PDF', Colors.red, () { Navigator.pop(context); _captureAndSave('PDF'); })
            ]
          )
        );
      }
    );
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: color, shape: BoxShape.circle), 
              child: Icon(icon, color: Colors.white, size: 18)
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54))
                ]
              )
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14)
          ]
        )
      )
    );
  }

  Future<void> addImageFromGallery({bool fromModal = false}) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        saveState();
        setState(() { 
          elements.add(DesignElement(
            id: Random().nextInt(10000).toString(), 
            x: 80, y: 80, 
            content: 'Image', 
            isText: false, 
            imageBytes: bytes, 
            width: 200, 
            height: 200
          )); 
          activeToolbarMenu = 'main'; 
        });
        triggerCanvasUpdate();
      }
    } catch (e) {
      debugPrint("Gallery Error: $e");
    }
    if (fromModal && Navigator.canPop(context)) { 
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = false;
    DesignElement? sel;
    if (selectedId != null) {
      try {
        sel = elements.firstWhere((e) => e.id == selectedId);
        hasSelection = true;
      } catch (e) {
        selectedId = null; 
      }
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        titleSpacing: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            WorkspaceToolbars.buildTopToolBtn(context, Icons.undo_rounded, 'Undo', undoAction, color: const Color(0xFF64748B)),
            WorkspaceToolbars.buildTopToolBtn(context, Icons.redo_rounded, 'Redo', redoAction, color: const Color(0xFF64748B)),
            WorkspaceToolbars.buildTopToolBtn(context, Icons.layers_rounded, 'Layers', showLayersPanel, color: const Color(0xFF1E293B)),
            WorkspaceToolbars.buildTopToolBtn(context, Icons.auto_stories_rounded, 'Pages', showPagesPanel, color: const Color(0xFF1E293B)),
          ],
        ),
        actions: [
          Center(
            child: InkWell(
              onTap: _saveProjectLocally,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Text('Save', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: InkWell(
              onTap: _showExportMenu,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
                ),
                child: Row(
                  children: const [
                    Icon(Icons.ios_share_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 15, top: 10, bottom: 5),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _isCanvasLocked = !_isCanvasLocked); },
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: _isCanvasLocked ? Colors.red.shade50 : Colors.white, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(_isCanvasLocked ? Icons.lock : Icons.lock_open, size: 14, color: _isCanvasLocked ? Colors.red : Colors.black), const SizedBox(width: 5), Text(_isCanvasLocked ? 'Locked' : 'Unlocked', style: TextStyle(fontSize: 12, color: _isCanvasLocked ? Colors.red : Colors.black))]))
                ), const SizedBox(width: 12),
                InkWell(
                  onTap: () { HapticFeedback.selectionClick(); _transformController.value = Matrix4.identity(); },
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.fit_screen, size: 14), SizedBox(width: 5), Text('Reset View', style: TextStyle(fontSize: 12))]))
                ),
              ],
            ),
          ),
          
          Expanded(
            child: GestureDetector(
              onTap: () { setState(() { selectedId = null; activeToolbarMenu = 'main'; }); triggerCanvasUpdate(); }, 
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  panEnabled: !_isCanvasLocked && !hasSelection,
                  scaleEnabled: !_isCanvasLocked,
                  minScale: 0.2, maxScale: 5.0, 
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: AspectRatio(
                    aspectRatio: canvasRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double newW = constraints.maxWidth - 32;
                        double newH = constraints.maxHeight - 32;

                        if (_needsRescale && currentCanvasW > 50 && currentCanvasH > 50) {
                          double scaleX = newW / currentCanvasW;
                          double scaleY = newH / currentCanvasH;
                          double scaleMin = min(scaleX, scaleY);
                          
                          for (var e in elements) {
                            e.x *= scaleX;
                            e.y *= scaleY;
                            e.width *= scaleX;
                            e.height *= scaleY;
                            
                            if (e.isText) {
                              e.fontSize *= scaleMin;
                              e.textCurveRadius *= scaleMin;
                              e.shadowOffsetX *= scaleX;
                              e.shadowOffsetY *= scaleY;
                            }
                            e.strokeWidth *= scaleMin;
                            e.cornerRadius *= scaleMin;
                          }
                          _needsRescale = false;
                        }

                        currentCanvasW = newW;
                        currentCanvasH = newH;

                        return ValueListenableBuilder<int>(
                          valueListenable: _canvasNotifier,
                          builder: (context, _, __) {
                            return Container(
                              margin: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                              child: RepaintBoundary(
                                key: _canvasKey,
                                child: ClipRect(
                                  child: Container(
                                    width: currentCanvasW,
                                    height: currentCanvasH,
                                    color: bgImageBytes != null || bgGradient != null ? null : (pageColor == Colors.transparent ? Colors.white : pageColor),
                                    decoration: bgImageBytes != null 
                                      ? BoxDecoration(image: DecorationImage(image: MemoryImage(bgImageBytes!), fit: BoxFit.cover))
                                      : (bgGradient != null ? BoxDecoration(gradient: LinearGradient(colors: bgGradient!)) : null),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (_showGrid && !_isExporting)
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: Stack(
                                                children: [
                                                  Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) => Container(height: 1, color: Colors.black12))),
                                                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) => Container(width: 1, color: Colors.black12))),
                                                  Center(child: Container(width: double.infinity, height: 1, color: Colors.blue.withOpacity(0.5))),
                                                  Center(child: Container(width: 1, height: double.infinity, color: Colors.blue.withOpacity(0.5))),
                                                ],
                                              ),
                                            ),
                                          ),
                                        
                                        if (!_isExporting)
                                          Positioned.fill(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1)))),
                                        
                                        ...elements.map((e) {
                                          if (e.isHidden) return const SizedBox.shrink();
                                          bool isSel = (e.id == selectedId) && !_isExporting;
                                          
                                          Matrix4 matrix = Matrix4.identity()
                                            ..setEntry(3, 2, 0.002) 
                                            ..rotateX(e.pitch)
                                            ..rotateY(e.yaw)
                                            ..rotateZ(e.angle);
                                          
                                          if (e.flipX) matrix.rotateY(pi);
                                          if (e.flipY) matrix.rotateX(pi);

                                          double currentWidth = getElWidth(e); 
                                          double currentHeight = getElHeight(e);
                                          double bp = 20.0; 
                                          
                                          Widget contentWidget;
                                          if (e.isBorder) {
                                            contentWidget = SizedBox(
                                              width: currentWidth,
                                              height: currentHeight,
                                              child: CustomPaint(
                                                painter: AdvancedBorderPainter(
                                                  color: e.elementColor,
                                                  strokeWidth: e.strokeWidth,
                                                  radius: e.cornerRadius,
                                                  styleIndex: int.tryParse(e.borderStyle) ?? 0,
                                                ),
                                              ),
                                            );
                                          } else if (e.isTable && e.tableData != null) {
                                            contentWidget = CustomTableWidget(tableData: e.tableData!, width: currentWidth, height: currentHeight, fontFamily: e.fontFamily, textColor: e.textColor, borderColor: e.elementColor, hasBorder: true);
                                          } else if (e.isShape) {
                                            contentWidget = Container(width: currentWidth, height: currentHeight, decoration: BoxDecoration(color: e.elementColor, borderRadius: BorderRadius.circular(e.cornerRadius)));
                                          } else if (e.imageBytes != null) {
                                            Widget img = Image.memory(e.imageBytes!, width: currentWidth, height: currentHeight, fit: BoxFit.fill);
                                            if (e.isTinted) img = Image.memory(e.imageBytes!, width: currentWidth, height: currentHeight, color: e.elementColor, fit: BoxFit.fill);
                                            else {
                                              if (e.imageFilter == 1) img = ColorFiltered(colorFilter: const ColorFilter.matrix([0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]), child: img);
                                              else if (e.imageFilter == 2) img = ColorFiltered(colorFilter: const ColorFilter.matrix([0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0]), child: img);
                                              else if (e.imageFilter == 3) img = ColorFiltered(colorFilter: const ColorFilter.matrix([-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]), child: img);
                                            }
                                            if (e.blendModeIndex != 0) img = ColorFiltered(colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.0), AppConstants.blendModes[e.blendModeIndex]), child: img);
                                            Widget clippedImg = img;
                                            if (e.clipShape == 1) clippedImg = Container(clipBehavior: Clip.antiAlias, decoration: const BoxDecoration(shape: BoxShape.circle), child: img);
                                            else if (e.clipShape == 2) clippedImg = ClipPath(clipper: TriangleClipper(), child: img);
                                            else if (e.clipShape == 3) clippedImg = ClipPath(clipper: StarClipper(), child: img);
                                            else if (e.clipShape == 4) clippedImg = ClipPath(clipper: HexagonClipper(), child: img);
                                            contentWidget = SizedBox(width: currentWidth, height: e.clipShape == 0 ? currentHeight : currentWidth, child: clippedImg);
                                          } else {
                                            List<Widget> blockLayers = [];
                                            if (e.text3dDepth > 0) {
                                              for (double i = e.text3dDepth; i > 0; i -= 1.0) {
                                                blockLayers.add(Transform.translate(offset: Offset(i, i), child: _buildTextWidget(e, currentWidth, e.text3dColor, extraShadows: [])));
                                              }
                                            }
                                            
                                            Widget mainTxt = _buildTextWidget(e, currentWidth, e.textGradient != null ? Colors.white : e.textColor);
                                            if (e.textGradient != null) mainTxt = ShaderMask(shaderCallback: (bounds) => LinearGradient(colors: e.textGradient!).createShader(bounds), child: mainTxt);
                                            if (e.textTextureBytes != null) mainTxt = TextureTextWrapper(child: mainTxt, textureBytes: e.textTextureBytes!);
                                            blockLayers.add(mainTxt);
                                            
                                            Widget txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: blockLayers);
                                            
                                            if (e.hasStroke) {
                                              Paint strokePaint = Paint()
                                                 ..style = PaintingStyle.stroke
                                                 ..strokeWidth = e.strokeWidth
                                                 ..color = e.strokeColor;
                                              
                                              Widget strokeTxt = _buildTextWidget(e, currentWidth, null, foregroundPaint: strokePaint);
                                              txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [strokeTxt, txt]);
                                            }
                                            
                                            if (e.textBgColor != null) {
                                               txt = Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: e.textBgColor, borderRadius: BorderRadius.circular(e.cornerRadius)), child: txt);
                                            }
                                            contentWidget = txt; 
                                          }
                                          
                                          if (_isExporting) { 
                                            return Positioned(
                                              left: e.x, 
                                              top: e.y, 
                                              child: Transform(
                                                transform: matrix, 
                                                alignment: Alignment.center, 
                                                child: Opacity(
                                                  opacity: e.opacity.clamp(0.0, 1.0),
                                                  child: contentWidget
                                                )
                                              )
                                            );
                                          }
                                          
                                          return Positioned(
                                            left: e.x - 20, 
                                            top: e.y - 20,
                                            child: Transform(
                                              transform: matrix, alignment: Alignment.center,
                                              child: SizedBox(
                                                width: currentWidth + 40, height: currentHeight + 40,
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Positioned(
                                                      left: 20, top: 20, right: 20, bottom: 20,
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () { 
                                                          if (e.isLocked) {
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layer is Locked')));
                                                          } else {
                                                            setState(() => selectedId = e.id);
                                                            triggerCanvasUpdate();
                                                          }
                                                        },
                                                        onPanStart: (d) { if(!e.isLocked) saveState(); },
                                                        onPanUpdate: (d) {
                                                          if(!e.isLocked && selectedId == e.id) {
                                                            e.x += d.delta.dx; 
                                                            e.y += d.delta.dy; 
                                                            if (e.groupId != null) {
                                                              for (var other in elements) {
                                                                if (other.id != e.id && other.groupId == e.groupId && !other.isLocked) {
                                                                  other.x += d.delta.dx; other.y += d.delta.dy;
                                                                }
                                                              }
                                                            }
                                                            triggerCanvasUpdate();
                                                          }
                                                        },
                                                        child: Stack(
                                                          fit: StackFit.passthrough,
                                                          clipBehavior: Clip.none,
                                                          children: [
                                                            Opacity(opacity: e.opacity.clamp(0.0, 1.0), child: contentWidget),
                                                            if (isSel)
                                                              Positioned.fill(
                                                                child: IgnorePointer(
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                      border: Border.all(color: Colors.white, width: 2.0),
                                                                    ),
                                                                    child: Container(
                                                                      decoration: BoxDecoration(
                                                                        border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      )
                                                    ),
                                                    
                                                    if (isSel) ...[
                                                      Positioned(top: 0, left: 20 + currentWidth/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'T', e), child: _buildTouchTarget(child: _buildPill(true)))),
                                                      Positioned(bottom: 0, left: 20 + currentWidth/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'B', e), child: _buildTouchTarget(child: _buildPill(true)))),
                                                      Positioned(left: 0, top: 20 + currentHeight/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'L', e), child: _buildTouchTarget(child: _buildPill(false)))),
                                                      Positioned(right: 0, top: 20 + currentHeight/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'R', e), child: _buildTouchTarget(child: _buildPill(false)))),
                                                      
                                                      Positioned(top: 0, left: 0, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e, 'TL'), child: _buildTouchTarget(child: _buildCircle()))),
                                                      Positioned(top: 0, right: 0, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e, 'TR'), child: _buildTouchTarget(child: _buildCircle()))),
                                                      Positioned(bottom: 0, left: 0, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e, 'BL'), child: _buildTouchTarget(child: _buildCircle()))),
                                                      Positioned(bottom: 0, right: 0, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e, 'BR'), child: _buildTouchTarget(child: _buildCircle()))),
                                                      
                                                      Positioned(
                                                        top: -15, right: -15, 
                                                        child: GestureDetector(
                                                          behavior: HitTestBehavior.opaque,
                                                          onPanStart: (_) => saveState(),
                                                          onPanUpdate: (d) => _rotateElement(d, e), 
                                                          child: _buildTouchTarget(child: _buildIconCircle(Icons.rotate_right))
                                                        )
                                                      ),
                                                      Positioned(
                                                        bottom: -15, left: -15, 
                                                        child: GestureDetector(
                                                          behavior: HitTestBehavior.opaque,
                                                          onPanStart: (_) => saveState(),
                                                          onPanUpdate: (d) => _scaleCorner(d, e, 'BL'),
                                                          child: _buildTouchTarget(child: _buildIconCircle(Icons.open_in_full))
                                                        )
                                                      ),
                                                    ]
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        );
                      }
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 140, 
          color: Colors.white, 
          child: (hasSelection && sel != null) ? _buildSelectedToolBar(sel) : WorkspaceToolbars.buildDefaultBottomBar(
            context, 
            showAddNewModal, 
            () { setState(() => _showGrid = !_showGrid); triggerCanvasUpdate(); }, 
            _showResizeModal, 
            _setCanvasBackground, 
            _showCanvasBgColorModal, 
            _showCanvasBgGradientModal, 
            () { saveState(); setState((){ pageColor = Colors.white; bgImageBytes = null; bgGradient = null; }); triggerCanvasUpdate(); }
          )
        )
      ),
    );
  }

  Widget _buildPill(bool isHorizontal) {
    return Container(
      width: isHorizontal ? 24 : 6,
      height: isHorizontal ? 6 : 24,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), 
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]
      )
    );
  }

  Widget _buildCircle() {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: Colors.white, 
        shape: BoxShape.circle, 
        border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), 
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]
      )
    );
  }

  Widget _buildIconCircle(IconData icon) {
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: Colors.white, 
        shape: BoxShape.circle, 
        border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), 
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)]
      ),
      child: Icon(icon, size: 14, color: const Color(0xFF8B5CF6)),
    );
  }

  Widget _buildTextWidget(DesignElement e, double currentWidth, Color? baseColor, {List<Shadow>? extraShadows, Paint? foregroundPaint}) {
    List<Shadow> currentShadows = extraShadows != null ? List.from(extraShadows) : [];
    if (extraShadows == null && e.hasShadow) {
      currentShadows.add(Shadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY)));
    }

    Color? finalTextColor = baseColor;
    if (e.isGlass && e.textGradient == null && e.textTextureBytes == null && foregroundPaint == null) {
       finalTextColor = baseColor?.withOpacity(0.35);
       currentShadows.add(const Shadow(color: Colors.white, offset: Offset(0, 0), blurRadius: 15));
       currentShadows.add(const Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 5));
    }
    if (e.isBevel) {
       currentShadows.add(const Shadow(color: Colors.white70, offset: Offset(-2, -2), blurRadius: 2));
       currentShadows.add(const Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 2));
    }
    if (e.isInnerShadow) {
       currentShadows.add(const Shadow(color: Colors.black87, offset: Offset(1.5, 1.5), blurRadius: 2));
    }

    TextStyle st = TextStyle(
      fontFamily: e.fontFamily, 
      fontSize: e.fontSize, 
      color: foregroundPaint == null ? finalTextColor : null,
      foreground: foregroundPaint,
      letterSpacing: e.letterSpacing, 
      wordSpacing: e.wordSpacing, 
      height: e.lineHeight, 
      shadows: currentShadows.isNotEmpty ? currentShadows : null, 
      fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, 
      fontStyle: e.isItalic ? FontStyle.italic : FontStyle.normal
    );
    
    bool hasMultiStyle = textMultiStyles.containsKey(e.id) && textMultiStyles[e.id]!.isNotEmpty;
    
    if (e.textCurveRadius != 0) {
      return CurvedTextWidget(text: e.content, style: st, radius: e.textCurveRadius);
    }

    if (hasMultiStyle) {
      List<String> words = e.content.split(' ');
      List<TextSpan> spans = [];
      for (int i = 0; i < words.length; i++) {
        TextStyle wordStyle = st;
        if (textMultiStyles[e.id]!.containsKey(i)) {
           var ms = textMultiStyles[e.id]![i]!;
           wordStyle = st.copyWith(
             color: foregroundPaint == null ? (ms['color'] != null ? (ms['color'] as Color) : st.color) : null,
             fontSize: ms['fontSize'] != null ? (ms['fontSize'] as double) : st.fontSize,
             fontFamily: ms['fontFamily'] != null ? (ms['fontFamily'] as String) : st.fontFamily,
             foreground: foregroundPaint, 
           );
        }
        spans.add(TextSpan(text: words[i] + (i < words.length - 1 ? ' ' : ''), style: wordStyle));
      }
      return SizedBox(
        width: currentWidth, 
        child: RichText(
          textAlign: e.textAlign,
          textDirection: isRTLText(e.content) ? TextDirection.rtl : TextDirection.ltr,
          text: TextSpan(children: spans),
        )
      );
    } else {
      return SizedBox(width: currentWidth, child: Text(e.content, textAlign: e.textAlign, style: st));
    }
  }

  Widget _buildSelectedToolBar(DesignElement sel) {
    List<Widget> topRow = [];
    List<Widget> bottomRow = [];

    if (sel.isText) {
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.delete_outline_rounded, 'Delete', deleteSelected, Colors.red));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.text_fields_rounded, 'Size', () => showSizeSliderModal(sel)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.format_paint_rounded, 'Word Style', () => _showMultiStyleModal(sel), const Color(0xFF10B981)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.border_color_rounded, 'Stroke', () => _showAdvancedStrokeModal(sel)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.brightness_6_rounded, 'Shadow', () => _showAdvancedShadowModal(sel)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.copy_rounded, 'Duplicate', duplicateSelected, Colors.blue));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.opacity_rounded, 'Opacity', () => _showOpacityModal(sel)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.content_copy_rounded, 'Copy', () { Clipboard.setData(ClipboardData(text: sel.content)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text Copied!'))); }));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.flip_rounded, 'Flip H', () { saveState(); setState(() => sel.flipX = !sel.flipX); triggerCanvasUpdate(); }));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.flip_camera_android_rounded, 'Flip V', () { saveState(); setState(() => sel.flipY = !sel.flipY); triggerCanvasUpdate(); }));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.open_with_rounded, 'Move', () => showMoveModal(sel)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.lock_outline_rounded, 'Lock', () { saveState(); setState(() { sel.isLocked = true; selectedId = null; }); triggerCanvasUpdate(); }, Colors.orange));

      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.close_rounded, 'Deselect', () { setState(() => selectedId = null); triggerCanvasUpdate(); }, Colors.redAccent));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.edit_rounded, 'Edit', () => showTextComposerDialog(existingElement: sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.font_download_rounded, 'Font', () => showFontPickerModal(sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.palette_rounded, 'Colour', () => _showColorPickerModal(sel), const Color(0xFF8B5CF6)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.gradient_rounded, 'Gradient', () => _showGradientPickerModal(sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context,Icons.format_bold_rounded, 'Bold', () { saveState(); setState(() => sel.isBold = !sel.isBold); triggerCanvasUpdate(); }));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.height_rounded, 'Spacing', () => showSpacingModal(sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.format_color_fill_rounded, 'Text BG', () => _showTextBgPickerModal(sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.auto_awesome_rounded, 'Effect', () => _showTextEffectsModal(sel), const Color(0xFF10B981)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.format_align_center_rounded, 'Align', () => _toggleAlignment(sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.more_horiz_rounded, 'More', () => _showMoreOptionsModal(sel), Colors.grey.shade800));
    } 
    else if (sel.isBorder) {
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.close_rounded, 'Deselect', () { setState(() => selectedId = null); triggerCanvasUpdate(); }, Colors.redAccent));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.fullscreen_rounded, 'Fit Page', () => _fitBorderToPage(sel), const Color(0xFF10B981)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.straighten_rounded, 'Size', () => _showElementSizeModal(sel), const Color(0xFF10B981)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.palette_rounded, 'Colour', () => _showColorPickerModal(sel), const Color(0xFF8B5CF6)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.line_weight_rounded, 'Setup', () => _showBorderSettingsModal(sel)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.opacity_rounded, 'Opacity', () => _showOpacityModal(sel)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.copy_rounded, 'Duplicate', duplicateSelected, Colors.blue));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.delete_outline_rounded, 'Delete', deleteSelected, Colors.red));

      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.center_focus_strong_rounded, 'Position', () => _showAlignmentModal(sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.open_with_rounded, 'Move', () => showMoveModal(sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.arrow_upward_rounded, 'Bring Fwd', () => bringForward()));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.arrow_downward_rounded, 'Send Bwd', () => sendBackward()));
    } 
    else {
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.close_rounded, 'Deselect', () { setState(() => selectedId = null); triggerCanvasUpdate(); }, Colors.redAccent));
      if (sel.isTable) topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.table_rows_rounded, 'Edit Table', () => _showTableEditorModal(sel), const Color(0xFF10B981)));
      if (sel.isTable) topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.font_download_rounded, 'Font', () => showFontPickerModal(sel)));
      if (sel.isTable) topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.text_fields_rounded, 'Size', () => showSizeSliderModal(sel)));
      
      if (!sel.isTable) topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.straighten_rounded, 'Size', () => _showElementSizeModal(sel), const Color(0xFF10B981)));
      
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.palette_rounded, 'Colour', () => _showColorPickerModal(sel), const Color(0xFF8B5CF6)));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.copy_rounded, 'Duplicate', duplicateSelected, Colors.blue));
      topRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.delete_outline_rounded, 'Delete', deleteSelected, Colors.red));

      if (!sel.isTable) bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.border_color_rounded, 'Stroke', () => _showAdvancedStrokeModal(sel)));
      if (!sel.isTable) bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.brightness_6_rounded, 'Shadow', () => _showAdvancedShadowModal(sel)));
      if (sel.imageBytes != null && !sel.isTinted) bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.photo_filter_rounded, 'Filters', () => _showImageFiltersModal(sel)));
      if (sel.imageBytes != null) bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.crop_rounded, 'Crop', () => _showShapeClipModal(sel)));
      bottomRow.add(WorkspaceToolbars.buildToolBtn(context, Icons.more_horiz_rounded, 'More', () => _showMoreOptionsModal(sel), Colors.grey.shade800));
    }

    return Container(
      height: 140, 
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: topRow)),
          const SizedBox(height: 6),
          SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: bottomRow)),
        ],
      ),
    );
  }

  Widget _buildTouchTarget({required Widget child}) {
    return Container(
      width: 40, height: 40, 
      color: Colors.transparent, 
      alignment: Alignment.center, 
      child: child
    );
  }
}
