// --- START OF PRO WORKSPACE SCREEN CODE ---
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
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

class ProWorkspaceScreen extends StatefulWidget {
  final ProjectModel? project;
  final String? initialAction;
  final String? initialData; 

  const ProWorkspaceScreen({Key? key, this.project, this.initialAction, this.initialData}) : super(key: key);
  
  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  final ValueNotifier<int> _canvasNotifier = ValueNotifier<int>(0);

  bool _isCanvasLocked = false;
  bool _showGrid = false;
  double currentCanvasW = 1000;
  double currentCanvasH = 1000;
  late String projectId;
  late String projectName;
  List<DesignPage> pages = [];
  int currentPageIndex = 0;
  List<List<DesignElement>> undoStack = [];
  List<List<DesignElement>> redoStack = [];
  String? selectedId;
  
  String activeToolbarMenu = 'main';

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
        if (widget.initialAction == 'text_editor') _showTextComposerDialog();
        else if (widget.initialAction == 'images') addImageFromGallery(fromModal: false);
        else if (widget.initialAction == 'elements') showAddNewModal();
        else if (widget.initialAction == 'add_sticker' && widget.initialData != null) {
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

  void _triggerCanvasUpdate() {
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
    _triggerCanvasUpdate();
  }

  double _getElWidth(DesignElement e) {
    if (e.isTable) return e.width > 80 ? e.width : 300;
    if (e.isBorder) return e.width > 50 ? e.width : 200; 
    return e.width > 80 ? e.width : 80;
  }

  double _getElHeight(DesignElement e) {
    if (e.isTable) return e.height > 30 ? e.height : 150;
    if (e.isBorder) return e.height > 50 ? e.height : 200; 
    if (!e.isText && e.height > 20) return e.height;
    if (e.isShape) return 90;
    if (e.isText) {
      if (e.textCurveRadius != 0) {
        return e.textCurveRadius.abs() * 2.5 + 20;
      }
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: e.content.isEmpty ? 'Text' : e.content, 
          style: TextStyle(
            fontFamily: e.fontFamily, 
            fontSize: e.fontSize, 
            letterSpacing: e.letterSpacing, 
            wordSpacing: e.wordSpacing, 
            height: e.lineHeight,
            fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: e.isItalic ? FontStyle.italic : FontStyle.normal,
          )
        ),
        textAlign: e.textAlign,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: e.width > 80 ? e.width : 80);
      
      return textPainter.size.height + (e.hasShadow ? e.shadowBlur * 2 : 0) + (e.hasStroke ? e.strokeWidth * 2 : 0) + 10;
    }
    return 150;
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
      
      ProjectModel p = ProjectModel(id: projectId, name: projectName, pages: pages, lastModified: DateTime.now().millisecondsSinceEpoch);
      
      jsonList.removeWhere((item) => item['id'] == projectId);
      jsonList.add(p.toJson());
      
      await file.writeAsString(jsonEncode(jsonList));
      
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project Saved Successfully!')));
    } catch (e) {
      debugPrint("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving project!')));
    }
  }

  List<DesignElement> get elements => pages[currentPageIndex].elements;
  set elements(List<DesignElement> val) => pages[currentPageIndex].elements = val;
  Color get pageColor => pages[currentPageIndex].pageColor;
  set pageColor(Color val) => pages[currentPageIndex].pageColor = val;
  List<Color>? get bgGradient => pages[currentPageIndex].bgGradient;
  set bgGradient(List<Color>? val) => pages[currentPageIndex].bgGradient = val;
  double get canvasRatio => pages[currentPageIndex].canvasRatio;
  set canvasRatio(double val) => pages[currentPageIndex].canvasRatio = val;
  Uint8List? get bgImageBytes => pages[currentPageIndex].bgImageBytes;
  set bgImageBytes(Uint8List? val) => pages[currentPageIndex].bgImageBytes = val;

  void saveState() {
    undoStack.add(elements.map((e) => e.clone()).toList());
    redoStack.clear();
    if (undoStack.length > 10) undoStack.removeAt(0); 
  }

  void undoAction() {
    if (undoStack.isNotEmpty) {
      redoStack.add(elements.map((e) => e.clone()).toList());
      setState(() { elements = undoStack.removeLast(); selectedId = null; activeToolbarMenu = 'main'; });
      HapticFeedback.lightImpact();
      _triggerCanvasUpdate();
    }
  }

  void redoAction() {
    if (redoStack.isNotEmpty) {
      undoStack.add(elements.map((e) => e.clone()).toList());
      setState(() { elements = redoStack.removeLast(); selectedId = null; activeToolbarMenu = 'main'; });
      HapticFeedback.lightImpact();
      _triggerCanvasUpdate();
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
    _triggerCanvasUpdate();
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
    if (corner == 'BR') delta = ldx;
    else if (corner == 'BL') delta = -ldx;
    else if (corner == 'TR') delta = ldx;
    else if (corner == 'TL') delta = -ldx;

    if (delta == 0 && ldy != 0) {
      if (corner == 'BR' || corner == 'BL') delta = ldy;
      else delta = -ldy;
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
    _triggerCanvasUpdate();
  }

  void _rotateElement(DragUpdateDetails d, DesignElement e) {
    e.angle += (d.delta.dx + d.delta.dy) * 0.015;
    _triggerCanvasUpdate();
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Export Design', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ]
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildExportOption(Icons.image, 'Save as JPG', 'Solid Background', Colors.blue, () { Navigator.pop(context); _captureAndSave('JPG'); }),
              const SizedBox(height: 10),
              _buildExportOption(Icons.layers_clear, 'Save as PNG', 'Transparent Image', Colors.purple, () { Navigator.pop(context); _captureAndSave('PNG'); }),
              const SizedBox(height: 10),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
            Icon(Icons.arrow_forward_ios, color: color, size: 16)
          ]
        )
      )
    );
  }

  Future<void> _captureAndSave(String format) async {
    setState(() { selectedId = null; _isExporting = true; activeToolbarMenu = 'main'; });
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
        final result = await ImageGallerySaver.saveImage(pngBytes, quality: 100, name: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}");
        if (mounted && result != null && result['isSuccess'] == true) {
          _showSuccessDialog('Saved to Gallery!', 'Aapka $format design gallery mein save ho gaya hai.');
        }
      } else if (format == 'PDF') {
        final pdf = pw.Document();
        final imagePdf = pw.MemoryImage(pngBytes);
        pdf.addPage(pw.Page(pageFormat: PdfPageFormat(image.width.toDouble(), image.height.toDouble()), margin: pw.EdgeInsets.zero, build: (pw.Context context) { return pw.Center(child: pw.Image(imagePdf)); }));
        Uint8List pdfBytes = await pdf.save();
        await Printing.sharePdf(bytes: pdfBytes, filename: "QalamKaarPro_Print_${DateTime.now().millisecondsSinceEpoch}.pdf");
      }
    } catch (e) {
      debugPrint('Export Error: $e');
    } finally {
      setState(() { _isExporting = false; });
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
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))
          ]
        )
      )
    );
  }

  // ============================================================================
  // 🔥 UNIVERSAL ADVANCED COLOR PICKER 🔥
  // ============================================================================
  void _openProColorPicker({
    required String title,
    required Color currentColor,
    required Function(Color) onColorChanged,
    bool allowClear = false,
  }) {
    Set<Color> docColors = {};
    for (var e in elements) {
      if (e.isText || e.isTable) docColors.add(e.textColor);
      else docColors.add(e.elementColor);
      if (e.textBgColor != null) docColors.add(e.textBgColor!);
      if (e.hasStroke) docColors.add(e.strokeColor);
      if (e.hasShadow) docColors.add(e.shadowColor);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdvancedColorPickerModal(
        title: title,
        initialColor: currentColor,
        documentColors: docColors.toList(),
        allowClear: allowClear,
        onColorChanged: (c) {
          saveState();
          onColorChanged(c);
          _triggerCanvasUpdate();
        }
      )
    );
  }

  void _showTextComposerDialog({DesignElement? existingElement}) {
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? '');
    bool isRTL = existingElement?.textAlign == TextAlign.right ? true : (existingElement?.textAlign == TextAlign.center ? true : false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setModalState(() => isRTL = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(color: !isRTL ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(25), boxShadow: !isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []),
                              child: Text('English (LTR)', style: TextStyle(fontWeight: !isRTL ? FontWeight.bold : FontWeight.normal, color: !isRTL ? Colors.black : Colors.grey))
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setModalState(() => isRTL = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(color: isRTL ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(25), boxShadow: isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []),
                              child: Text('اردو (RTL)', style: TextStyle(fontWeight: isRTL ? FontWeight.bold : FontWeight.normal, color: isRTL ? Colors.black : Colors.grey))
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(15)),
                        child: TextField(
                          controller: controller,
                          maxLines: null,
                          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: TextStyle(fontFamily: isRTL ? 'JameelNoori' : null, fontSize: isRTL ? 28 : 20),
                          decoration: InputDecoration(border: InputBorder.none, hintText: isRTL ? 'یہاں لکھیں...' : 'Type here...'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildComposerTool(Icons.paste, 'Paste', () async { 
                          ClipboardData? data = await Clipboard.getData('text/plain'); 
                          if(data != null && data.text != null) { controller.text += data.text!; } 
                        }),
                        _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()),
                        _buildComposerTool(Icons.auto_stories, 'شاعری', () => _showPoetryLibrary(controller)),
                        _buildComposerTool(Icons.format_quote, 'اعراب', () => _showTashkeelModal(controller)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2, 
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () { 
                              if (controller.text.isNotEmpty) { 
                                saveState(); 
                                double calcW = (controller.text.length * (isRTL ? 28.0 : 20.0) * 0.6) + 40;
                                if(calcW > MediaQuery.of(context).size.width - 60) calcW = MediaQuery.of(context).size.width - 60;
                                if(calcW < 80) calcW = 80;
                                if (existingElement != null) { 
                                  setState(() { 
                                    existingElement.content = controller.text; 
                                    existingElement.textAlign = isRTL ? TextAlign.right : TextAlign.left; 
                                  }); 
                                } else { 
                                  var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, isText: true, width: calcW, height: 100, fontSize: 30);
                                  newEl.textAlign = isRTL ? TextAlign.right : TextAlign.left; 
                                  setState(() { elements.add(newEl); selectedId = newEl.id; activeToolbarMenu = 'main'; }); 
                                } 
                                _triggerCanvasUpdate(); 
                                Navigator.pop(context); 
                              } 
                            }, 
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white), 
                            label: const Text('Add to Design', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                          )
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) {
    return InkWell(onTap: onTap, child: Column(children: [Icon(icon, color: const Color(0xFF8B5CF6)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));
  }

  void _showPoetryLibrary(TextEditingController textController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(15),
          child: DefaultTabController(
            length: AppConstants.urduPoetryLibrary.keys.length,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Urdu Library اقوال / شاعری', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                  ]
                ),
                TabBar(
                  isScrollable: true,
                  labelColor: const Color(0xFF8B5CF6),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF8B5CF6),
                  tabs: AppConstants.urduPoetryLibrary.keys.map((k) => Tab(text: k)).toList()
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: AppConstants.urduPoetryLibrary.keys.map((category) {
                      return ListView.builder(
                        itemCount: AppConstants.urduPoetryLibrary[category]!.length,
                        itemBuilder: (context, index) {
                          String text = AppConstants.urduPoetryLibrary[category]![index];
                          return Card(
                            color: Colors.grey.shade50,
                            elevation: 0,
                            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 16)),
                              onTap: () { textController.text = text; Navigator.pop(context); }
                            )
                          );
                        }
                      );
                    }).toList()
                  )
                )
              ]
            )
          )
        );
      }
    );
  }

  void _showTashkeelModal(TextEditingController controller) {
    final List<String> tashkeelList = ['َ', 'ِ', 'ُ', 'ً', 'ٍ', 'ٌ', 'ّ', 'ْ', 'ٓ', 'ٰ', 'ٖ', 'ٗ', 'ۖ', 'ۗ', 'ۘ', 'ۙ', 'ۚ'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tashkeel & Symbols اعراب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ]
              ),
              const Divider(),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: tashkeelList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () { controller.text += tashkeelList[index]; Navigator.pop(context); },
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Text(tashkeelList[index], style: const TextStyle(fontSize: 22, fontFamily: 'JameelNoori'))
                      )
                    );
                  }
                )
              )
            ]
          )
        );
      }
    );
  }

  void showAddNewModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildGridItem(Icons.image, 'Gallery Pic', Colors.blue.shade100, Colors.blue, () => addImageFromGallery(fromModal: true)),
                  _buildGridItem(Icons.gradient, 'Backgrounds', Colors.indigo.shade100, Colors.indigo, () { Navigator.pop(context); showGenericStockModal('Backgrounds', 'bg', Icons.image); }),
                  _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade100, Colors.teal, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())); }),
                  _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade100, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }),
                  _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade100, Colors.amber.shade800, () { Navigator.pop(context); showGenericStockModal('Borders', 'border', Icons.border_outer); }),
                  _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade100, Colors.pink, () { Navigator.pop(context); showGenericStockModal('Shapes', 'shape', Icons.category); }),
                  _buildGridItem(Icons.table_chart, 'Table', Colors.cyan.shade100, Colors.cyan.shade800, () { Navigator.pop(context); _addTable(); }),
                ]
              )
            )
          ]
        )
      )
    );
  }

  void _addTable() {
    saveState();
    setState(() {
      elements.add(
        DesignElement(
          id: Random().nextInt(10000).toString(), 
          x: 40, y: 100, 
          content: 'Table', 
          isText: false, 
          isTable: true, 
          width: 350, height: 200, 
          tableData: [['سیریل', 'نام طالب علم', 'نمبر'], ['1', '', ''], ['2', '', '']],
          elementColor: const Color(0xFFD4AF37),
          textColor: Colors.black
        )
      );
      selectedId = elements.last.id;
      activeToolbarMenu = 'main';
    });
    _triggerCanvasUpdate();
  }

  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) {
    return InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: iconColor, size: 30)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));
  }

  Future<void> addImageFromGallery({bool fromModal = false}) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        saveState();
        setState(() { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 80, content: 'Image', isText: false, imageBytes: bytes, width: 200, height: 200)); activeToolbarMenu = 'main'; });
        _triggerCanvasUpdate();
      }
    } catch (e) {
      debugPrint("Gallery Error: $e");
    }
    if (fromModal && Navigator.canPop(context)) { Navigator.pop(context); }
  }

  Widget _buildTableToolbarBtn(IconData icon, String label, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _showTableEditorModal(DesignElement sel) {
    if (sel.tableData == null) return;
    List<List<String>> tempTable = [];
    for (var row in sel.tableData!) { tempTable.add(List.from(row)); }

    int activeR = 0;
    int activeC = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {

            void addRowBelow() {
              setModalState(() {
                tempTable.insert(activeR + 1, List.generate(tempTable[0].length, (index) => ''));
                activeR++;
              });
            }
            void addColRight() {
              setModalState(() {
                for (var row in tempTable) { row.insert(activeC, ''); }
              });
            }
            void addColLeft() {
              setModalState(() {
                for (var row in tempTable) { row.insert(activeC + 1, ''); }
                activeC++;
              });
            }
            void deleteRow() {
              if (tempTable.length > 1) {
                setModalState(() { 
                  tempTable.removeAt(activeR); 
                  if (activeR >= tempTable.length) activeR = tempTable.length - 1; 
                });
              }
            }
            void deleteCol() {
              if (tempTable[0].length > 1) {
                setModalState(() {
                  for (var row in tempTable) { row.removeAt(activeC); }
                  if (activeC >= tempTable[0].length) activeC = tempTable[0].length - 1;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.90,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Advance Table Editor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                      ]
                    ),
                    const Text('خانے پر کلک کریں اور قطار/کالم شامل کریں', style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'JameelNoori'), textDirection: TextDirection.rtl),
                    const Divider(),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTableToolbarBtn(Icons.table_rows, '+ Row', addRowBelow, Colors.blue),
                          _buildTableToolbarBtn(Icons.view_column, '+ Col Right', addColRight, Colors.blue),
                          _buildTableToolbarBtn(Icons.view_column, '+ Col Left', addColLeft, Colors.blue),
                          _buildTableToolbarBtn(Icons.delete_sweep, 'Del Row', deleteRow, Colors.red),
                          _buildTableToolbarBtn(Icons.delete_forever, 'Del Col', deleteCol, Colors.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey.shade50),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: tempTable.asMap().entries.map((rowEntry) {
                                  int r = rowEntry.key;
                                  return Row(
                                    textDirection: TextDirection.rtl,
                                    children: rowEntry.value.asMap().entries.map((colEntry) {
                                      int c = colEntry.key;
                                      bool isActive = (r == activeR && c == activeC);
                                      return GestureDetector(
                                        onTap: () { setModalState(() { activeR = r; activeC = c; }); },
                                        child: Container(
                                          width: 130, // Default width for editor boxes
                                          margin: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: isActive ? const Color(0xFF8B5CF6) : Colors.grey.shade400, width: isActive ? 2.5 : 1),
                                            color: isActive ? const Color(0xFF8B5CF6).withOpacity(0.05) : (r == 0 ? Colors.grey.shade200 : Colors.white),
                                          ),
                                          child: TextField(
                                            controller: TextEditingController(text: tempTable[r][c])..selection = TextSelection.collapsed(offset: tempTable[r][c].length),
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.center,
                                            maxLines: null,
                                            style: TextStyle(fontFamily: 'JameelNoori', fontSize: r == 0 ? 20 : 18, fontWeight: r == 0 ? FontWeight.bold : FontWeight.normal),
                                            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(8), isDense: true),
                                            onChanged: (val) { tempTable[r][c] = val; },
                                            onTap: () { setModalState(() { activeR = r; activeC = c; }); },
                                          )
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }).toList(),
                              ),
                            ),
                          )
                        )
                      )
                    ),
                    const SizedBox(height: 10),
                    
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('Width: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Slider(value: sel.width.clamp(100.0, 1500.0), min: 100.0, max: 1500.0, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setModalState((){ sel.width = val; }); }))
                            ]
                          ),
                          Row(
                            children: [
                              const Text('Height: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Slider(value: sel.height.clamp(50.0, 1500.0), min: 50.0, max: 1500.0, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setModalState((){ sel.height = val; }); }))
                            ]
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () { saveState(); setState(() { sel.tableData = tempTable; }); _triggerCanvasUpdate(); Navigator.pop(context); },
                        child: const Text('Save Table Data (محفوظ کریں)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                      )
                    )
                  ],
                )
              )
            );
          }
        );
      }
    );
  }

  Future<void> _setCanvasBackground() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() { bgImageBytes = bytes; bgGradient = null; pageColor = Colors.white; });
        _triggerCanvasUpdate();
      }
    } catch (e) {
      debugPrint("BG Image Error: $e");
    }
  }

  Future<void> _addTextureToText(DesignElement sel) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        saveState();
        setState(() => sel.textTextureBytes = bytes);
        _triggerCanvasUpdate();
      }
    } catch (e) {
      debugPrint("Texture Error: $e");
    }
  }

  // 🔥 ADVANCED BORDER & BACKGROUND MODAL 🔥
  void showGenericStockModal(String categoryTitle, String styleName, IconData categoryIcon, {bool fromModal = false}) {
    if (fromModal && Navigator.canPop(context)) Navigator.pop(context);
    List<Map<String, dynamic>> stockList = [];
    
    if (styleName == 'border') {
      for (int i = 0; i < 50; i++) {
        stockList.add({'title': 'Border Style ${i + 1}', 'style_id': i, 'color': Colors.black});
      }
    } else {
      List<Color> themeColors = [const Color(0xFFD4AF37), const Color(0xFF8B5CF6), const Color(0xFF047857), const Color(0xFFB91C1C)];
      for (int i = 1; i <= 50; i++) {
        stockList.add({'title': '$categoryTitle #$i', 'style': styleName, 'color': themeColors[(i - 1) % themeColors.length], 'icon': categoryIcon});
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 15),
            Text('$categoryTitle Library', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.2),
                itemCount: stockList.length,
                itemBuilder: (context, index) {
                  var item = stockList[index];
                  return InkWell(
                    onTap: () {
                      saveState();
                      setState(() {
                        if (styleName == 'border') {
                          double safeW = currentCanvasW > 50 ? currentCanvasW - 30 : 200;
                          double safeH = currentCanvasH > 50 ? currentCanvasH - 30 : 200;
                          
                          elements.add(DesignElement(
                            id: Random().nextInt(10000).toString(), 
                            x: 15, y: 15, 
                            content: 'Border', 
                            width: safeW, 
                            height: safeH, 
                            isText: false, 
                            isBorder: true, 
                            borderStyle: item['style_id'].toString(),
                            elementColor: Colors.black, 
                            strokeWidth: 4.0, 
                            cornerRadius: 0.0,
                          ));
                        } 
                        else if (styleName.contains('shape') || styleName == 'badge') {
                          elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 90, y: 180, content: 'Shape', width: 100, height: 100, isText: false, isShape: true, elementColor: item['color'] as Color));
                        } 
                        else {
                          elements.insert(0, DesignElement(id: Random().nextInt(10000).toString(), x: 0, y: 0, content: 'BG', width: 400, height: 400, isText: false, isShape: true, elementColor: item['color'] as Color));
                        }
                      });
                      _triggerCanvasUpdate();
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50, 
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: styleName == 'border' 
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: CustomPaint(
                              painter: AdvancedBorderPainter(
                                color: Colors.black,
                                strokeWidth: 2.0,
                                radius: 0.0,
                                styleIndex: item['style_id'],
                              ),
                              child: Center(child: Text(item['title'], style: const TextStyle(fontSize: 10, color: Colors.grey))),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item['icon'], color: item['color'], size: 30),
                              const SizedBox(height: 6),
                              Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item['color'])),
                            ]
                          )
                    )
                  );
                }
              )
            )
          ]
        )
      )
    );
  }

  void deleteSelected() {
    if (selectedId != null) {
      saveState();
      setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; activeToolbarMenu = 'main'; });
      _triggerCanvasUpdate();
    }
  }

  void duplicateSelected() {
    if (selectedId != null) {
      saveState();
      DesignElement sel = elements.firstWhere((e) => e.id == selectedId);
      setState(() { var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20; elements.add(newEl); selectedId = newEl.id; activeToolbarMenu = 'main'; });
      _triggerCanvasUpdate();
    }
  }

  void bringForward() {
    if (selectedId == null) return;
    saveState();
    int idx = elements.indexWhere((e) => e.id == selectedId);
    if (idx < elements.length - 1) {
      setState(() { var item = elements.removeAt(idx); elements.insert(idx + 1, item); });
      _triggerCanvasUpdate();
    }
  }

  void sendBackward() {
    if (selectedId == null) return;
    saveState();
    int idx = elements.indexWhere((e) => e.id == selectedId);
    if (idx > 0) {
      setState(() { var item = elements.removeAt(idx); elements.insert(idx - 1, item); });
      _triggerCanvasUpdate();
    }
  }

  void _fitBorderToPage(DesignElement sel) {
    saveState();
    setState(() {
      sel.x = 15;
      sel.y = 15;
      sel.width = (currentCanvasW > 50 ? currentCanvasW : 300) - 30;
      sel.height = (currentCanvasH > 50 ? currentCanvasH : 300) - 30;
      sel.angle = 0; 
    });
    _triggerCanvasUpdate();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Border perfectly fitted to page!', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF10B981)));
  }

  // 🔥 THE NEW UNIVERSAL PRO COLOR ENGINE 🔥
  void _openProColorPicker({
    required String title,
    required Color currentColor,
    required Function(Color) onColorChanged,
    bool allowClear = false,
  }) {
    Set<Color> docColors = {};
    for (var e in elements) {
      if (e.isText || e.isTable) docColors.add(e.textColor);
      else docColors.add(e.elementColor);
      if (e.textBgColor != null) docColors.add(e.textBgColor!);
      if (e.hasStroke) docColors.add(e.strokeColor);
      if (e.hasShadow) docColors.add(e.shadowColor);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdvancedColorPickerModal(
        title: title,
        initialColor: currentColor,
        documentColors: docColors.toList(),
        allowClear: allowClear,
        onColorChanged: (c) {
          saveState();
          onColorChanged(c);
          _triggerCanvasUpdate();
        }
      )
    );
  }

  void _showCanvasBgGradientModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 450,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Canvas Gradient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const Divider(),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5),
                      itemCount: AppConstants.proGradientPalette.length,
                      itemBuilder: (context, index) {
                        List<Color> g = AppConstants.proGradientPalette[index];
                        return GestureDetector(
                          onTap: () {
                            saveState();
                            setState(() { bgGradient = g; bgImageBytes = null; pageColor = Colors.white; });
                            setModalState((){});
                            _triggerCanvasUpdate();
                            Navigator.pop(context);
                          },
                          child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(10)))
                        );
                      }
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showGradientPickerModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 550,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gradient Tool', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Make Your Own اپنی مرضی کا شیڈ بنائیں", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(onTap: () => _openProColorPicker(title: 'Color 1', currentColor: sel.customGradColor1 ?? Colors.white, onColorChanged: (c){ setModalState(()=> sel.customGradColor1 = c); _triggerCanvasUpdate(); }), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: sel.customGradColor1 ?? Colors.white, border: Border.all(color: Colors.grey), shape: BoxShape.circle))),
                            const Icon(Icons.add),
                            InkWell(onTap: () => _openProColorPicker(title: 'Color 2', currentColor: sel.customGradColor2 ?? Colors.white, onColorChanged: (c){ setModalState(()=> sel.customGradColor2 = c); _triggerCanvasUpdate(); }), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: sel.customGradColor2 ?? Colors.white, border: Border.all(color: Colors.grey), shape: BoxShape.circle))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                              onPressed: () {
                                if(sel.customGradColor1 != null && sel.customGradColor2 != null) {
                                  saveState();
                                  setState(() => sel.textGradient = [sel.customGradColor1!, sel.customGradColor2!]);
                                  setModalState((){});
                                  _triggerCanvasUpdate();
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Apply', style: TextStyle(color: Colors.white))
                            )
                          ]
                        )
                      ]
                    )
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Clear Gradient'),
                    onTap: () { saveState(); setState(() { sel.textGradient = null; }); _triggerCanvasUpdate(); Navigator.pop(context); }
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0),
                      itemCount: AppConstants.proGradientPalette.length,
                      itemBuilder: (context, index) {
                        List<Color> g = AppConstants.proGradientPalette[index];
                        return GestureDetector(
                          onTap: () { saveState(); setState(() { sel.textGradient = g; }); setModalState((){}); _triggerCanvasUpdate(); },
                          child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(10)))
                        );
                      }
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showAdvancedStrokeModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 350,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advanced Stroke', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  SwitchListTile(
                    title: const Text('Enable Stroke', style: TextStyle(fontWeight: FontWeight.bold)),
                    activeColor: const Color(0xFF8B5CF6),
                    value: sel.hasStroke,
                    onChanged: (val) { saveState(); setState(() => sel.hasStroke = val); setModalState((){}); _triggerCanvasUpdate(); }
                  ),
                  const Divider(),
                  if (sel.hasStroke) ...[
                    Row(
                      children: [
                        const Text('Thickness:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        Expanded(child: Slider(value: sel.strokeWidth.clamp(1.0, 20.0), min: 1.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setState(() => sel.strokeWidth = val); setModalState((){}); _triggerCanvasUpdate(); }))
                      ]
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3E8FF), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () {
                           Navigator.pop(context);
                           _openProColorPicker(title: 'Stroke Color', currentColor: sel.strokeColor, onColorChanged: (c) { setState(()=> sel.strokeColor = c); });
                        },
                        icon: const Icon(Icons.color_lens_rounded, color: Color(0xFF8B5CF6)),
                        label: const Text('Choose Stroke Color', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold))
                      )
                    )
                  ]
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showAdvancedShadowModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 420,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advanced Shadow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  SwitchListTile(
                    title: const Text('Enable Shadow', style: TextStyle(fontWeight: FontWeight.bold)),
                    activeColor: const Color(0xFF8B5CF6),
                    value: sel.hasShadow,
                    onChanged: (val) { saveState(); setState(() => sel.hasShadow = val); setModalState((){}); _triggerCanvasUpdate(); }
                  ),
                  const Divider(),
                  if (sel.hasShadow) ...[
                    Row(
                      children: [
                        const Text('Blur:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        Expanded(child: Slider(value: sel.shadowBlur.clamp(0.0, 30.0), min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChanged: (val){ setState(()=> sel.shadowBlur = val); setModalState((){}); _triggerCanvasUpdate();}))
                      ]
                    ),
                    Row(
                      children: [
                        const Text('X-Offset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        Expanded(child: Slider(value: sel.shadowOffsetX.clamp(-20.0, 20.0), min: -20.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChanged: (val){ setState(()=> sel.shadowOffsetX = val); setModalState((){}); _triggerCanvasUpdate();}))
                      ]
                    ),
                    Row(
                      children: [
                        const Text('Y-Offset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        Expanded(child: Slider(value: sel.shadowOffsetY.clamp(-20.0, 20.0), min: -20.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChanged: (val){ setState(()=> sel.shadowOffsetY = val); setModalState((){}); _triggerCanvasUpdate();}))
                      ]
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3E8FF), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () {
                           Navigator.pop(context);
                           _openProColorPicker(title: 'Shadow Color', currentColor: sel.shadowColor, onColorChanged: (c) { setState(()=> sel.shadowColor = c); });
                        },
                        icon: const Icon(Icons.color_lens_rounded, color: Color(0xFF8B5CF6)),
                        label: const Text('Choose Shadow Color', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold))
                      )
                    )
                  ]
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showOpacityModal(DesignElement sel) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 180, 
              padding: const EdgeInsets.all(20), 
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Opacity شفافیت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  Slider(
                    value: sel.opacity.clamp(0.0, 1.0), 
                    min: 0.0, 
                    max: 1.0, 
                    activeColor: const Color(0xFF8B5CF6),
                    onChangeStart: (val) => saveState(),
                    onChanged: (v){ 
                      setState(()=>sel.opacity=v); 
                      setModalState((){}); 
                      _triggerCanvasUpdate(); 
                    }
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showTextEffectsModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Premium Text Effects ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        SwitchListTile(
                          title: const Text('Bevel & Emboss (اُبھرا ہوا)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('3D pop out effect', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          secondary: const Icon(Icons.layers, color: Colors.blue),
                          activeColor: const Color(0xFF8B5CF6),
                          value: sel.isBevel,
                          onChanged: (val) { saveState(); setState(() => sel.isBevel = val); setModalState((){}); _triggerCanvasUpdate(); }
                        ),
                        SwitchListTile(
                          title: const Text('Inner Shadow (اندرونی سایہ)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Deep cut / stamped effect', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          secondary: const Icon(Icons.flip_to_back, color: Colors.purple),
                          activeColor: const Color(0xFF8B5CF6),
                          value: sel.isInnerShadow,
                          onChanged: (val) { saveState(); setState(() => sel.isInnerShadow = val); setModalState((){}); _triggerCanvasUpdate(); }
                        ),
                        SwitchListTile(
                          title: const Text('Glass Effect (شیشے کا انداز)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Frosted transparent look', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          secondary: const Icon(Icons.blur_on, color: Colors.cyan),
                          activeColor: const Color(0xFF8B5CF6),
                          value: sel.isGlass,
                          onChanged: (val) { saveState(); setState(() => sel.isGlass = val); setModalState((){}); _triggerCanvasUpdate(); }
                        ),
                        ListTile(
                          title: const Text('Add Texture (ٹیکسچر)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Image clipping on text', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          leading: const Icon(Icons.texture, color: Colors.orange),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (sel.textTextureBytes != null)
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () { saveState(); setState(() => sel.textTextureBytes = null); setModalState((){}); _triggerCanvasUpdate(); }),
                              const Icon(Icons.arrow_forward_ios, size: 16)
                            ]
                          ),
                          onTap: () async {
                            await _addTextureToText(sel);
                            setModalState((){});
                          }
                        ),
                      ]
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void _show3DBlockModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 380,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('3D Block/Depth تھری ڈی موٹائی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Text('Depth:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Expanded(
                        child: Slider(
                          value: sel.text3dDepth.clamp(0.0, 30.0),
                          min: 0.0,
                          max: 30.0,
                          activeColor: const Color(0xFF8B5CF6),
                          onChangeStart: (val) => saveState(),
                          onChanged: (val) {
                            setState(() => sel.text3dDepth = val);
                            setModalState(() {});
                            _triggerCanvasUpdate();
                          }
                        )
                      )
                    ]
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3E8FF), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () {
                         Navigator.pop(context);
                         _openProColorPicker(title: '3D Color', currentColor: sel.text3dColor, onColorChanged: (c) { setState(()=> sel.text3dColor = c); });
                      },
                      icon: const Icon(Icons.color_lens_rounded, color: Color(0xFF8B5CF6)),
                      label: const Text('Choose 3D Block Color', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold))
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showBorderSettingsModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 280,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Border Setup (بارڈر کنٹرول)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Thickness:', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                        child: Slider(
                          value: sel.strokeWidth.clamp(1.0, 50.0),
                          min: 1.0, max: 50.0,
                          activeColor: const Color(0xFF8B5CF6),
                          onChangeStart: (val) => saveState(),
                          onChanged: (val) { setState(() => sel.strokeWidth = val); setModalState((){}); _triggerCanvasUpdate(); }
                        )
                      )
                    ]
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Radius:', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                        child: Slider(
                          value: sel.cornerRadius.clamp(0.0, 150.0),
                          min: 0.0, max: 150.0,
                          activeColor: const Color(0xFF10B981),
                          onChangeStart: (val) => saveState(),
                          onChanged: (val) { setState(() => sel.cornerRadius = val); setModalState((){}); _triggerCanvasUpdate(); }
                        )
                      )
                    ]
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showRadiusModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Corner Radius گولائی: ${sel.cornerRadius.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  Slider(
                    value: sel.cornerRadius.clamp(0.0, 150.0),
                    min: 0.0,
                    max: 150.0,
                    activeColor: const Color(0xFF8B5CF6),
                    onChangeStart: (val) => saveState(),
                    onChanged: (val) { setState(() => sel.cornerRadius = val); setModalState((){}); _triggerCanvasUpdate(); }
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showShapeClipModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 250,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Crop to Shape کٹنگ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildShapeOption(sel, setModalState, 'None', 0, Icons.crop_square),
                        _buildShapeOption(sel, setModalState, 'Circle', 1, Icons.circle_outlined),
                        _buildShapeOption(sel, setModalState, 'Triangle', 2, Icons.change_history),
                        _buildShapeOption(sel, setModalState, 'Star', 3, Icons.star_border),
                        _buildShapeOption(sel, setModalState, 'Hexagon', 4, Icons.hexagon_outlined)
                      ]
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  Widget _buildShapeOption(DesignElement sel, StateSetter setModalState, String title, int val, IconData icon) {
    bool isSel = sel.clipShape == val;
    return InkWell(
      onTap: () { saveState(); setState(() => sel.clipShape = val); setModalState((){}); _triggerCanvasUpdate(); },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade600, size: 30),
            const SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal))
          ]
        )
      )
    );
  }

  void _showImageFiltersModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 250,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Image Filters تصویر کے رنگ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterOption(sel, setModalState, 'Normal', 0, Colors.grey),
                        _buildFilterOption(sel, setModalState, 'B & W', 1, Colors.black87),
                        _buildFilterOption(sel, setModalState, 'Sepia', 2, Colors.brown),
                        _buildFilterOption(sel, setModalState, 'Invert', 3, Colors.blue)
                      ]
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  Widget _buildFilterOption(DesignElement sel, StateSetter setModalState, String title, int filterVal, Color iconColor) {
    bool isSel = sel.imageFilter == filterVal;
    return InkWell(
      onTap: () { saveState(); setState(() => sel.imageFilter = filterVal); setModalState((){}); _triggerCanvasUpdate(); },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_filter, color: isSel ? const Color(0xFF8B5CF6) : iconColor, size: 30),
            const SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal))
          ]
        )
      )
    );
  }

  void showSpacingModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Spacing فاصلے', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Line:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Expanded(child: Slider(value: sel.lineHeight.clamp(0.5, 3.5), min: 0.5, max: 3.5, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setState(()=> sel.lineHeight = val); setModalState((){}); _triggerCanvasUpdate();}))
                    ]
                  ),
                  Row(
                    children: [
                      const Text('Word:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Expanded(child: Slider(value: sel.wordSpacing.clamp(-10.0, 30.0), min: -10.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setState(()=> sel.wordSpacing = val); setModalState((){}); _triggerCanvasUpdate();}))
                    ]
                  ),
                  Row(
                    children: [
                      const Text('Letter:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Expanded(child: Slider(value: sel.letterSpacing.clamp(-5.0, 20.0), min: -5.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setState(()=> sel.letterSpacing = val); setModalState((){}); _triggerCanvasUpdate();}))
                    ]
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void showSizeSliderModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Size: ${sel.fontSize.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  Slider(
                    value: sel.fontSize.clamp(10.0, 150.0),
                    min: 10.0,
                    max: 150.0,
                    activeColor: const Color(0xFF8B5CF6),
                    onChangeStart: (val) => saveState(),
                    onChanged: (val) { setState(() => sel.fontSize = val); setModalState((){}); _triggerCanvasUpdate(); }
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void showRotationModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rotate گھمائیں', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: sel.angle.clamp(-pi, pi),
                    min: -pi,
                    max: pi,
                    activeColor: const Color(0xFF8B5CF6),
                    onChangeStart: (val) => saveState(),
                    onChanged: (val) { setState(() => sel.angle = val); setModalState((){}); _triggerCanvasUpdate(); }
                  ),
                  Text('${(sel.angle * 180 / pi).toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold))
                ]
              )
            );
          }
        );
      }
    );
  }

  void show3DModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 280,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('3D Perspective زاویہ ڈی تھری', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('X-Axis:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Slider(value: sel.pitch.clamp(-pi / 2, pi / 2), min: -pi / 2, max: pi / 2, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setState(()=> sel.pitch=val); setModalState((){}); _triggerCanvasUpdate(); }))
                    ]
                  ),
                  Row(
                    children: [
                      const Text('Y-Axis:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Slider(value: sel.yaw.clamp(-pi / 2, pi / 2), min: -pi / 2, max: pi / 2, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setState(()=> sel.yaw=val); setModalState((){}); _triggerCanvasUpdate(); }))
                    ]
                  ),
                  ElevatedButton(
                    onPressed: () { saveState(); setState((){ sel.pitch = 0; sel.yaw = 0; }); setModalState((){}); _triggerCanvasUpdate(); },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200),
                    child: const Text('Reset Perspective', style: TextStyle(color: Colors.black))
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  void showMoveModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double stepSize = 5.0; 

            void move(double dx, double dy) {
              saveState();
              setState(() {
                sel.x += dx;
                sel.y += dy;
                if (sel.groupId != null) {
                  for (var other in elements) {
                    if (other.id != sel.id && other.groupId == sel.groupId && !other.isLocked) {
                      other.x += dx;
                      other.y += dy;
                    }
                  }
                }
              });
              setModalState((){});
              _triggerCanvasUpdate();
            }

            Widget buildDpadBtn(IconData icon, VoidCallback onTap) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  child: Icon(icon, size: 30, color: const Color(0xFF8B5CF6)),
                ),
              );
            }

            return Container(
              height: 330,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Move Tool (حرکت دیں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => stepSize = 1.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: stepSize == 1.0 ? Colors.white : Colors.transparent, 
                              borderRadius: BorderRadius.circular(10), 
                              boxShadow: stepSize == 1.0 ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []
                            ),
                            child: Text('1 px (Slow)', style: TextStyle(fontWeight: stepSize == 1.0 ? FontWeight.bold : FontWeight.normal, color: stepSize == 1.0 ? const Color(0xFF8B5CF6) : Colors.grey)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setModalState(() => stepSize = 5.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: stepSize == 5.0 ? Colors.white : Colors.transparent, 
                              borderRadius: BorderRadius.circular(10), 
                              boxShadow: stepSize == 5.0 ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []
                            ),
                            child: Text('5 px (Fast)', style: TextStyle(fontWeight: stepSize == 5.0 ? FontWeight.bold : FontWeight.normal, color: stepSize == 5.0 ? const Color(0xFF8B5CF6) : Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [buildDpadBtn(Icons.arrow_upward_rounded, () => move(0, -stepSize))]
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildDpadBtn(Icons.arrow_back_rounded, () => move(-stepSize, 0)),
                      const SizedBox(width: 68),
                      buildDpadBtn(Icons.arrow_forward_rounded, () => move(stepSize, 0))
                    ]
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [buildDpadBtn(Icons.arrow_downward_rounded, () => move(0, stepSize))]
                  ),
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showMoreOptionsModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        List<Widget> moreTools = [];

        if (sel.isText) {
           moreTools.add(_buildGridToolBtn(Icons.rotate_right_rounded, 'Rotate', () { Navigator.pop(context); showRotationModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.view_in_ar_outlined, '3D Block', () { Navigator.pop(context); _show3DBlockModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.data_usage_rounded, 'Curve', () { Navigator.pop(context); _showCurveModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.view_in_ar_rounded, 'Perspective', () { Navigator.pop(context); show3DModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.arrow_upward_rounded, 'Bring Fwd', () { bringForward(); Navigator.pop(context); }));
           moreTools.add(_buildGridToolBtn(Icons.arrow_downward_rounded, 'Send Bwd', () { sendBackward(); Navigator.pop(context); }));
        } else {
           if (sel.imageBytes != null || sel.isShape) moreTools.add(_buildGridToolBtn(Icons.format_paint_rounded, 'Tint', () { Navigator.pop(context); _openProColorPicker(title: 'Color', currentColor: sel.elementColor, onColorChanged: (c) { setState(()=> sel.elementColor = c); }); }));
           if (sel.imageBytes != null) moreTools.add(_buildGridToolBtn(Icons.auto_awesome_motion_rounded, 'Blend', () { Navigator.pop(context); _showBlendModeModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.center_focus_strong_rounded, 'Position', () { Navigator.pop(context); _showAlignmentModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.open_with_rounded, 'Move', () { Navigator.pop(context); showMoveModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.rotate_right_rounded, 'Rotate', () { Navigator.pop(context); showRotationModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.view_in_ar_rounded, 'Perspective', () { Navigator.pop(context); show3DModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.flip_rounded, 'Flip H', () { saveState(); setState(() => sel.flipX = !sel.flipX); _triggerCanvasUpdate(); Navigator.pop(context); }));
           moreTools.add(_buildGridToolBtn(Icons.flip_camera_android_rounded, 'Flip V', () { saveState(); setState(() => sel.flipY = !sel.flipY); _triggerCanvasUpdate(); Navigator.pop(context); }));
           moreTools.add(_buildGridToolBtn(Icons.opacity_rounded, 'Opacity', () { Navigator.pop(context); _showOpacityModal(sel); }));
           if (!sel.isBorder && !sel.isTable) moreTools.add(_buildGridToolBtn(Icons.rounded_corner_rounded, 'Radius', () { Navigator.pop(context); _showRadiusModal(sel); }));
           moreTools.add(_buildGridToolBtn(Icons.arrow_upward_rounded, 'Bring Fwd', () { bringForward(); Navigator.pop(context); }));
           moreTools.add(_buildGridToolBtn(Icons.arrow_downward_rounded, 'Send Bwd', () { sendBackward(); Navigator.pop(context); }));
        }

        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('More Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]
              ),
              const Divider(),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 10,
                  physics: const BouncingScrollPhysics(),
                  children: moreTools,
                )
              )
            ]
          )
        );
      }
    );
  }

  Widget _buildGridToolBtn(IconData icon, String label, VoidCallback onTap, [Color? color]) {
    Color c = color ?? Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: c.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.1))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c))
          ]
        )
      )
    );
  }

  Widget _buildPill(bool isHorizontal) {
    return Container(
      width: isHorizontal ? 24 : 6,
      height: isHorizontal ? 6 : 24,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)])
    );
  }

  Widget _buildCircle() {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)])
    );
  }

  Widget _buildIconCircle(IconData icon) {
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)]),
      child: Icon(icon, size: 14, color: const Color(0xFF8B5CF6)),
    );
  }

  Widget _buildToolBtn(IconData icon, String label, [VoidCallback? onTap, Color? color]) { 
    Color c = color ?? Colors.black87;
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 54, 
        margin: const EdgeInsets.symmetric(horizontal: 3), 
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2), 
        decoration: BoxDecoration(
          color: c.withOpacity(0.06), 
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withOpacity(0.12), width: 0.8)
        ), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Icon(icon, size: 20, color: c), 
            const SizedBox(height: 4), 
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w800))
          ]
        )
      )
    ); 
  }

  Widget _buildTopToolBtn(IconData icon, String label, VoidCallback? onTap, {Color color = const Color(0xFF1E293B)}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
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
            _buildTopToolBtn(Icons.undo_rounded, 'Undo', undoAction, color: const Color(0xFF64748B)),
            _buildTopToolBtn(Icons.redo_rounded, 'Redo', redoAction, color: const Color(0xFF64748B)),
            _buildTopToolBtn(Icons.layers_rounded, 'Layers', showLayersPanel, color: const Color(0xFF1E293B)),
            _buildTopToolBtn(Icons.auto_stories_rounded, 'Pages', showPagesPanel, color: const Color(0xFF1E293B)),
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
          if (!_isExporting)
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
              onTap: () { setState(() { selectedId = null; activeToolbarMenu = 'main'; }); _triggerCanvasUpdate(); }, 
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
                        currentCanvasW = constraints.maxWidth - 32;
                        currentCanvasH = constraints.maxHeight - 32;
                        return ValueListenableBuilder<int>(
                          valueListenable: _canvasNotifier,
                          builder: (context, _, __) {
                            return Container(
                              margin: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                              child: RepaintBoundary(
                                key: _canvasKey,
                                child: Container(
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
                                        Positioned.fill(child: Container(margin: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1)))),
                                      
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

                                        double currentWidth = _getElWidth(e); 
                                        double currentHeight = _getElHeight(e);
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
                                          Widget buildTextWidget(Color c, [List<Shadow>? shadow]) {
                                            List<Shadow> currentShadows = shadow != null ? List.from(shadow) : [];
                                            if (shadow == null && e.hasShadow) currentShadows.add(Shadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY)));

                                            Color finalTextColor = c;
                                            
                                            if (e.isGlass && e.textGradient == null && e.textTextureBytes == null) {
                                               finalTextColor = c.withOpacity(0.35);
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
                                              color: finalTextColor, 
                                              letterSpacing: e.letterSpacing, 
                                              wordSpacing: e.wordSpacing, 
                                              height: e.lineHeight, 
                                              shadows: currentShadows.isNotEmpty ? currentShadows : null, 
                                              fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, 
                                              fontStyle: e.isItalic ? FontStyle.italic : FontStyle.normal
                                            );
                                            
                                            if (e.textCurveRadius != 0) return CurvedTextWidget(text: e.content, style: st, radius: e.textCurveRadius);
                                            return SizedBox(width: currentWidth, child: Text(e.content, textAlign: e.textAlign, style: st));
                                          }
                                          
                                          List<Widget> blockLayers = [];
                                          if (e.text3dDepth > 0) {
                                            for (double i = e.text3dDepth; i > 0; i -= 1.0) blockLayers.add(Transform.translate(offset: Offset(i, i), child: buildTextWidget(e.text3dColor, [])));
                                          }
                                          
                                          Widget mainTxt = buildTextWidget(e.textGradient != null ? Colors.white : e.textColor);
                                          if (e.textGradient != null) mainTxt = ShaderMask(shaderCallback: (bounds) => LinearGradient(colors: e.textGradient!).createShader(bounds), child: mainTxt);
                                          if (e.textTextureBytes != null) mainTxt = TextureTextWrapper(child: mainTxt, textureBytes: e.textTextureBytes!);
                                          blockLayers.add(mainTxt);
                                          
                                          Widget txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: blockLayers);
                                          
                                          if (e.hasStroke) {
                                            TextStyle stStroke = TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, letterSpacing: e.letterSpacing, wordSpacing: e.wordSpacing, height: e.lineHeight, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = e.strokeWidth..color = e.strokeColor, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: e.isItalic ? FontStyle.italic : FontStyle.normal);
                                            Widget strokeTxt = e.textCurveRadius != 0 ? CurvedTextWidget(text: e.content, style: stStroke, radius: e.textCurveRadius) : SizedBox(width: currentWidth, child: Text(e.content, textAlign: e.textAlign, style: stStroke));
                                            txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [strokeTxt, txt]);
                                          }
                                          
                                          if (e.textBgColor != null) txt = Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: e.textBgColor, borderRadius: BorderRadius.circular(e.cornerRadius)), child: txt);
                                          contentWidget = txt; 
                                        }
                                        
                                        if (_isExporting) { 
                                          return Positioned(left: e.x, top: e.y, child: Transform(transform: matrix, alignment: Alignment.center, child: contentWidget));
                                        }
                                        
                                        return Positioned(
                                          left: e.x - bp, 
                                          top: e.y - bp,
                                          child: Transform(
                                            transform: matrix, alignment: Alignment.center,
                                            child: SizedBox(
                                              width: currentWidth + (bp * 2), height: currentHeight + (bp * 2),
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Positioned(
                                                    left: bp, top: bp, right: bp, bottom: bp,
                                                    child: GestureDetector(
                                                      behavior: HitTestBehavior.opaque,
                                                      onTap: () { 
                                                        if (e.isLocked) {
                                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layer is Locked')));
                                                        } else {
                                                          setState(() => selectedId = e.id);
                                                          _triggerCanvasUpdate();
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
                                                          _triggerCanvasUpdate();
                                                        }
                                                      },
                                                      child: Container(
                                                        decoration: isSel ? BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.0)) : null,
                                                        child: Opacity(opacity: e.opacity.clamp(0.0, 1.0), child: contentWidget)
                                                      )
                                                    )
                                                  ),
                                                  
                                                  if (isSel) ...[
                                                    Positioned(top: 0, left: bp + currentWidth/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'T', e), child: Container(padding: const EdgeInsets.all(10), color: Colors.transparent, child: _buildPill(true)))),
                                                    Positioned(bottom: 0, left: bp + currentWidth/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'B', e), child: Container(padding: const EdgeInsets.all(10), color: Colors.transparent, child: _buildPill(true)))),
                                                    Positioned(left: 0, top: bp + currentHeight/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'L', e), child: Container(padding: const EdgeInsets.all(10), color: Colors.transparent, child: _buildPill(false)))),
                                                    Positioned(right: 0, top: bp + currentHeight/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'R', e), child: Container(padding: const EdgeInsets.all(10), color: Colors.transparent, child: _buildPill(false)))),
                                                    
                                                    Positioned(top: 0, left: 0, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e, 'TL'), child: Container(padding: const EdgeInsets.all(10), color: Colors.transparent, child: _buildCircle()))),
                                                    Positioned(top: 0, right: 0, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e, 'TR'), child: Container(padding: const EdgeInsets.all(10), color: Colors.transparent, child: _buildCircle()))),
                                                    Positioned(bottom: 0, left: 0, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e, 'BL'), child: Container(padding: const EdgeInsets.all(10), color: Colors.transparent, child: _buildCircle()))),
                                                    Positioned(bottom: 0, right: 0, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e, 'BR'), child: Container(padding: const EdgeInsets.all(10), color: Colors.transparent, child: _buildCircle()))),
                                                    
                                                    Positioned(
                                                      top: 0, right: 0, 
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onPanStart: (_) => saveState(),
                                                        onPanUpdate: (d) => _rotateElement(d, e), 
                                                        child: Container(padding: const EdgeInsets.only(top: 0, right: 0, bottom: 20, left: 20), color: Colors.transparent, child: _buildIconCircle(Icons.rotate_right))
                                                      )
                                                    ),
                                                    Positioned(
                                                      bottom: 0, left: 0, 
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onPanStart: (_) => saveState(),
                                                        onPanUpdate: (d) => _scaleCorner(d, e, 'BL'),
                                                        child: Container(padding: const EdgeInsets.only(bottom: 0, left: 0, top: 20, right: 20), color: Colors.transparent, child: _buildIconCircle(Icons.open_in_full))
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
      bottomNavigationBar: SafeArea(child: Container(color: Colors.white, child: (hasSelection && sel != null) ? _buildSelectedToolBar(sel) : _buildDefaultBottomBar())),
    );
  }

  Widget _buildDefaultBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          InkWell(onTap: showAddNewModal, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: Colors.white))),
          const SizedBox(width: 8),
          Container(width: 1, height: 40, color: Colors.grey.shade300), 
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToolBtn(Icons.grid_on, 'Grid', () { setState(() => _showGrid = !_showGrid); _triggerCanvasUpdate(); }), 
                  _buildToolBtn(Icons.aspect_ratio, 'Resize', _showResizeModal), 
                  _buildToolBtn(Icons.image, 'BG Image', _setCanvasBackground),
                  _buildToolBtn(Icons.format_color_fill, 'BG Color', () => _openProColorPicker(title: 'Canvas Color', currentColor: pageColor, onColorChanged: (c){ setState((){ pageColor=c; bgImageBytes=null; bgGradient=null; }); })),
                  _buildToolBtn(Icons.gradient, 'BG Gradient', _showCanvasBgGradientModal),
                  _buildToolBtn(Icons.layers_clear, 'Clear BG', () { saveState(); setState((){ pageColor = Colors.white; bgImageBytes = null; bgGradient = null; }); _triggerCanvasUpdate(); }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedToolBar(DesignElement sel) {
    List<Widget> topRow = [];
    List<Widget> bottomRow = [];

    if (sel.isText) {
      topRow.add(_buildToolBtn(Icons.delete_outline_rounded, 'Delete', deleteSelected, Colors.red));
      topRow.add(_buildToolBtn(Icons.text_fields_rounded, 'Size', () => showSizeSliderModal(sel)));
      topRow.add(_buildToolBtn(Icons.border_color_rounded, 'Stroke', () => _showAdvancedStrokeModal(sel)));
      topRow.add(_buildToolBtn(Icons.brightness_6_rounded, 'Shadow', () => _showAdvancedShadowModal(sel)));
      topRow.add(_buildToolBtn(Icons.copy_rounded, 'Duplicate', duplicateSelected, Colors.blue));
      topRow.add(_buildToolBtn(Icons.opacity_rounded, 'Opacity', () => _showOpacityModal(sel)));
      topRow.add(_buildToolBtn(Icons.content_copy_rounded, 'Copy', () { Clipboard.setData(ClipboardData(text: sel.content)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text Copied!'))); }));
      topRow.add(_buildToolBtn(Icons.flip_rounded, 'Flip H', () { saveState(); setState(() => sel.flipX = !sel.flipX); _triggerCanvasUpdate(); }));
      topRow.add(_buildToolBtn(Icons.flip_camera_android_rounded, 'Flip V', () { saveState(); setState(() => sel.flipY = !sel.flipY); _triggerCanvasUpdate(); }));
      topRow.add(_buildToolBtn(Icons.open_with_rounded, 'Move', () => showMoveModal(sel)));
      topRow.add(_buildToolBtn(Icons.lock_outline_rounded, 'Lock', () { saveState(); setState(() { sel.isLocked = true; selectedId = null; }); _triggerCanvasUpdate(); }, Colors.orange));

      bottomRow.add(_buildToolBtn(Icons.close_rounded, 'Deselect', () { setState(() => selectedId = null); _triggerCanvasUpdate(); }, Colors.redAccent));
      bottomRow.add(_buildToolBtn(Icons.edit_rounded, 'Edit', () => _showTextComposerDialog(existingElement: sel)));
      bottomRow.add(_buildToolBtn(Icons.font_download_rounded, 'Font', () => showFontPickerModal(sel)));
      bottomRow.add(_buildToolBtn(Icons.palette_rounded, 'Colour', () => _openProColorPicker(title: 'Text Color', currentColor: sel.textColor, onColorChanged: (c){ setState((){ sel.textColor = c; sel.textGradient = null; }); }), const Color(0xFF8B5CF6)));
      bottomRow.add(_buildToolBtn(Icons.gradient_rounded, 'Gradient', () => _showGradientPickerModal(sel)));
      bottomRow.add(_buildToolBtn(Icons.format_bold_rounded, 'Bold', () { saveState(); setState(() => sel.isBold = !sel.isBold); _triggerCanvasUpdate(); }));
      bottomRow.add(_buildToolBtn(Icons.height_rounded, 'Spacing', () => showSpacingModal(sel)));
      bottomRow.add(_buildToolBtn(Icons.format_color_fill_rounded, 'Text BG', () => _openProColorPicker(title: 'Text Background', currentColor: sel.textBgColor ?? Colors.transparent, allowClear: true, onColorChanged: (c){ setState(()=> sel.textBgColor = c == Colors.transparent ? null : c); })));
      bottomRow.add(_buildToolBtn(Icons.auto_awesome_rounded, 'Effect', () => _showTextEffectsModal(sel), const Color(0xFF10B981)));
      bottomRow.add(_buildToolBtn(Icons.format_align_center_rounded, 'Align', () => _toggleAlignment(sel)));
      bottomRow.add(_buildToolBtn(Icons.more_horiz_rounded, 'More', () => _showMoreOptionsModal(sel), Colors.grey.shade800));
    } 
    else if (sel.isBorder) {
      topRow.add(_buildToolBtn(Icons.close_rounded, 'Deselect', () { setState(() => selectedId = null); _triggerCanvasUpdate(); }, Colors.redAccent));
      topRow.add(_buildToolBtn(Icons.fullscreen_rounded, 'Fit Page', () => _fitBorderToPage(sel), const Color(0xFF10B981)));
      topRow.add(_buildToolBtn(Icons.palette_rounded, 'Colour', () => _openProColorPicker(title: 'Border Color', currentColor: sel.elementColor, onColorChanged: (c){ setState(()=> sel.elementColor = c); }), const Color(0xFF8B5CF6)));
      topRow.add(_buildToolBtn(Icons.line_weight_rounded, 'Setup', () => _showBorderSettingsModal(sel)));
      topRow.add(_buildToolBtn(Icons.opacity_rounded, 'Opacity', () => _showOpacityModal(sel)));
      topRow.add(_buildToolBtn(Icons.copy_rounded, 'Duplicate', duplicateSelected, Colors.blue));
      topRow.add(_buildToolBtn(Icons.delete_outline_rounded, 'Delete', deleteSelected, Colors.red));

      bottomRow.add(_buildToolBtn(Icons.center_focus_strong_rounded, 'Position', () => _showAlignmentModal(sel)));
      bottomRow.add(_buildToolBtn(Icons.open_with_rounded, 'Move', () => showMoveModal(sel)));
      bottomRow.add(_buildToolBtn(Icons.arrow_upward_rounded, 'Bring Fwd', () => bringForward()));
      bottomRow.add(_buildToolBtn(Icons.arrow_downward_rounded, 'Send Bwd', () => sendBackward()));
    } 
    else {
      topRow.add(_buildToolBtn(Icons.close_rounded, 'Deselect', () { setState(() => selectedId = null); _triggerCanvasUpdate(); }, Colors.redAccent));
      if (sel.isTable) topRow.add(_buildToolBtn(Icons.table_rows_rounded, 'Edit Table', () => _showTableEditorModal(sel), const Color(0xFF10B981)));
      if (sel.isTable) topRow.add(_buildToolBtn(Icons.font_download_rounded, 'Font', () => showFontPickerModal(sel)));
      if (sel.isTable) topRow.add(_buildToolBtn(Icons.text_fields_rounded, 'Size', () => showSizeSliderModal(sel)));
      topRow.add(_buildToolBtn(Icons.palette_rounded, 'Colour', () => _openProColorPicker(title: 'Shape Color', currentColor: sel.elementColor, onColorChanged: (c){ setState(()=> sel.elementColor = c); }), const Color(0xFF8B5CF6)));
      topRow.add(_buildToolBtn(Icons.copy_rounded, 'Duplicate', duplicateSelected, Colors.blue));
      topRow.add(_buildToolBtn(Icons.delete_outline_rounded, 'Delete', deleteSelected, Colors.red));

      if (!sel.isTable) bottomRow.add(_buildToolBtn(Icons.border_color_rounded, 'Stroke', () => _showAdvancedStrokeModal(sel)));
      if (!sel.isTable) bottomRow.add(_buildToolBtn(Icons.brightness_6_rounded, 'Shadow', () => _showAdvancedShadowModal(sel)));
      if (sel.imageBytes != null && !sel.isTinted) bottomRow.add(_buildToolBtn(Icons.photo_filter_rounded, 'Filters', () => _showImageFiltersModal(sel)));
      if (sel.imageBytes != null) bottomRow.add(_buildToolBtn(Icons.crop_rounded, 'Crop', () => _showShapeClipModal(sel)));
      bottomRow.add(_buildToolBtn(Icons.more_horiz_rounded, 'More', () => _showMoreOptionsModal(sel), Colors.grey.shade800));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: topRow)),
          const SizedBox(height: 6),
          SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: bottomRow)),
        ],
      ),
    );
  }
}

// ============================================================================
// 🔥 BUG-FREE ADVANCED VECTOR BORDER ENGINE 🔥
// ============================================================================
class AdvancedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final int styleIndex;

  AdvancedBorderPainter({required this.color, required this.strokeWidth, required this.radius, required this.styleIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final Rect baseRect = (Offset.zero & size).deflate(strokeWidth / 2);
    int type = styleIndex % 5; 
    double varVal = (styleIndex ~/ 5).toDouble() * 3.0;

    switch (type) {
      case 0:
        canvas.drawRRect(RRect.fromRectAndRadius(baseRect.deflate(varVal), Radius.circular(radius)), paint);
        break;
      case 1:
        canvas.drawRRect(RRect.fromRectAndRadius(baseRect, Radius.circular(radius)), paint);
        if (varVal >= 0) { paint.strokeWidth = strokeWidth * 0.5; canvas.drawRRect(RRect.fromRectAndRadius(baseRect.deflate(6 + varVal), Radius.circular(max(0, radius - 2))), paint); }
        if (varVal > 10) { canvas.drawRRect(RRect.fromRectAndRadius(baseRect.deflate(12 + varVal), Radius.circular(max(0, radius - 4))), paint); }
        break;
      case 2:
        double lineLen = 20.0 + varVal; if (lineLen > size.width / 2) lineLen = size.width / 2;
        canvas.drawLine(baseRect.topLeft, baseRect.topLeft + Offset(lineLen, 0), paint); canvas.drawLine(baseRect.topLeft, baseRect.topLeft + Offset(0, lineLen), paint);
        canvas.drawLine(baseRect.topRight, baseRect.topRight + Offset(-lineLen, 0), paint); canvas.drawLine(baseRect.topRight, baseRect.topRight + Offset(0, lineLen), paint);
        canvas.drawLine(baseRect.bottomLeft, baseRect.bottomLeft + Offset(lineLen, 0), paint); canvas.drawLine(baseRect.bottomLeft, baseRect.bottomLeft + Offset(0, -lineLen), paint);
        canvas.drawLine(baseRect.bottomRight, baseRect.bottomRight + Offset(-lineLen, 0), paint); canvas.drawLine(baseRect.bottomRight, baseRect.bottomRight + Offset(0, -lineLen), paint);
        break;
      case 3:
        double gap = 15.0 + varVal; if (gap > size.width / 3) gap = size.width / 3;
        Path path = Path();
        path.moveTo(baseRect.left + gap, baseRect.top); path.lineTo(baseRect.right - gap, baseRect.top);
        path.moveTo(baseRect.left + gap, baseRect.bottom); path.lineTo(baseRect.right - gap, baseRect.bottom);
        path.moveTo(baseRect.left, baseRect.top + gap); path.lineTo(baseRect.left, baseRect.bottom - gap);
        path.moveTo(baseRect.right, baseRect.top + gap); path.lineTo(baseRect.right, baseRect.bottom - gap);
        canvas.drawPath(path, paint);
        if (varVal > 5) {
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(baseRect.topLeft + const Offset(5, 5), strokeWidth, paint); canvas.drawCircle(baseRect.topRight + const Offset(-5, 5), strokeWidth, paint);
          canvas.drawCircle(baseRect.bottomLeft + const Offset(5, -5), strokeWidth, paint); canvas.drawCircle(baseRect.bottomRight + const Offset(-5, -5), strokeWidth, paint);
        }
        break;
      case 4:
        double dashW = varVal < 10 ? 6.0 : 2.0; double spaceW = dashW + strokeWidth + 2.0;
        for (double i = 0; i < baseRect.width; i += dashW + spaceW) {
          double endX = (i + dashW > baseRect.width) ? baseRect.width : i + dashW;
          canvas.drawLine(Offset(baseRect.left + i, baseRect.top), Offset(baseRect.left + endX, baseRect.top), paint);
          canvas.drawLine(Offset(baseRect.left + i, baseRect.bottom), Offset(baseRect.left + endX, baseRect.bottom), paint);
        }
        for (double i = 0; i < baseRect.height; i += dashW + spaceW) {
          double endY = (i + dashW > baseRect.height) ? baseRect.height : i + dashW;
          canvas.drawLine(Offset(baseRect.left, baseRect.top + i), Offset(baseRect.left, baseRect.top + endY), paint);
          canvas.drawLine(Offset(baseRect.right, baseRect.top + i), Offset(baseRect.right, baseRect.top + endY), paint);
        }
        break;
    }
  }
  @override bool shouldRepaint(covariant AdvancedBorderPainter oldDelegate) { return color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth || radius != oldDelegate.radius || styleIndex != oldDelegate.styleIndex; }
}

// ============================================================================
// 🔥 THE NEW FIGMA-STYLE UNIVERSAL PRO COLOR ENGINE 🔥
// ============================================================================
class AdvancedColorPickerModal extends StatefulWidget {
  final String title;
  final Color initialColor;
  final Function(Color) onColorChanged;
  final List<Color> documentColors;
  final bool allowClear;

  const AdvancedColorPickerModal({
    Key? key, required this.title, required this.initialColor, required this.onColorChanged, required this.documentColors, this.allowClear = false,
  }) : super(key: key);

  @override
  State<AdvancedColorPickerModal> createState() => _AdvancedColorPickerModalState();
}

class _AdvancedColorPickerModalState extends State<AdvancedColorPickerModal> {
  late HSVColor hsvColor;
  final TextEditingController _hexCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    hsvColor = HSVColor.fromColor(widget.initialColor == Colors.transparent ? Colors.black : widget.initialColor);
    _updateHexFromHsv();
  }

  void _updateHexFromHsv() {
    Color c = hsvColor.toColor();
    _hexCtrl.text = c.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2);
  }

  void _onColorUpdate() {
    _updateHexFromHsv();
    widget.onColorChanged(hsvColor.toColor());
    setState(() {});
  }

  void _handleHexInput(String val) {
    if (val.length == 6 || val.length == 8) {
      try {
        String hex = val.length == 6 ? 'FF$val' : val;
        Color c = Color(int.parse('0x$hex'));
        setState(() { hsvColor = HSVColor.fromColor(c); });
        widget.onColorChanged(c);
      } catch (e) {
        // invalid hex
      }
    }
  }

  void _setFromPreset(Color c) {
    setState(() { hsvColor = HSVColor.fromColor(c); });
    _onColorUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 15), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                Row(
                  children: [
                    if (widget.allowClear)
                      TextButton.icon(onPressed: () { widget.onColorChanged(Colors.transparent); Navigator.pop(context); }, icon: const Icon(Icons.layers_clear_rounded, color: Colors.red, size: 16), label: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 0),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                GestureDetector(
                  onPanStart: (d) => _handleShadeDrag(d.localPosition),
                  onPanUpdate: (d) => _handleShadeDrag(d.localPosition),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Stack(
                      children: [
                        Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight))),
                        Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                        Positioned(
                          left: hsvColor.saturation * (MediaQuery.of(context).size.width - 40) - 12,
                          top: (1.0 - hsvColor.value) * 200 - 12,
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: hsvColor.toColor(), border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onPanStart: (d) => _handleHueDrag(d.localPosition),
                  onPanUpdate: (d) => _handleHueDrag(d.localPosition),
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00), Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000)])
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: (hsvColor.hue / 360) * (MediaQuery.of(context).size.width - 40) - 10,
                          top: -4,
                          child: Container(width: 20, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)])),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                Row(
                  children: [
                    Container(width: 45, height: 45, decoration: BoxDecoration(shape: BoxShape.circle, color: hsvColor.toColor(), border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: hsvColor.toColor().withOpacity(0.3), blurRadius: 8)])),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 45, padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            const Text('#', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 5),
                            Expanded(child: TextField(controller: _hexCtrl, onChanged: _handleHexInput, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Opacity', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          SliderTheme(
                            data: SliderThemeData(trackHeight: 4, activeTrackColor: const Color(0xFF8B5CF6), thumbColor: const Color(0xFF8B5CF6), overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2)),
                            child: Slider(value: hsvColor.alpha, min: 0.0, max: 1.0, onChanged: (v) { setState(() => hsvColor = hsvColor.withAlpha(v)); _onColorUpdate(); }),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30),

                if (widget.documentColors.isNotEmpty) ...[
                  const Text('Document Colors', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                      itemCount: widget.documentColors.length,
                      itemBuilder: (ctx, i) => _buildColorBubble(widget.documentColors[i]),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],

                const Text('Solid Palette', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const SizedBox(height: 10),
                Wrap(spacing: 12, runSpacing: 12, children: AppConstants.proColorPalette.map((c) => _buildColorBubble(c)).toList()),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _handleShadeDrag(Offset pos) {
    double w = MediaQuery.of(context).size.width - 40;
    double s = (pos.dx / w).clamp(0.0, 1.0);
    double v = 1.0 - (pos.dy / 200).clamp(0.0, 1.0);
    setState(() { hsvColor = hsvColor.withSaturation(s).withValue(v); });
    _onColorUpdate();
  }

  void _handleHueDrag(Offset pos) {
    double w = MediaQuery.of(context).size.width - 40;
    double h = ((pos.dx / w) * 360).clamp(0.0, 360.0);
    setState(() { hsvColor = hsvColor.withHue(h); });
    _onColorUpdate();
  }

  Widget _buildColorBubble(Color c) {
    bool isSel = hsvColor.toColor().value == c.value;
    return GestureDetector(
      onTap: () => _setFromPreset(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 45, height: 45, margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300, width: isSel ? 3 : 1),
          boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)] : null
        ),
      ),
    );
  }
}
// --- END OF PRO WORKSPACE SCREEN CODE ---
