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
import 'package:shared_preferences/shared_preferences.dart';

import '../models/design_models.dart';
import '../widgets/custom_widgets.dart';
import '../utils/constants.dart';
import 'my_folder_screen.dart';

class ProWorkspaceScreen extends StatefulWidget {
  final ProjectModel? project;
  final String? initialAction;
  
  const ProWorkspaceScreen({Key? key, this.project, this.initialAction}) : super(key: key);
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
      });
    }
  }

  @override
  void dispose() { 
    _transformController.dispose(); 
    _canvasNotifier.dispose(); 
    super.dispose(); 
  }

  void _triggerCanvasUpdate() { _canvasNotifier.value++; }

  double _getElWidth(DesignElement e) => e.width > 50 ? e.width : 280;
  double _getElHeight(DesignElement e) {
    if (!e.isText && e.height > 20) return e.height;
    if (e.isShape) return 90;
    if (e.isText) {
      int lines = e.content.isEmpty ? 1 : e.content.split('\n').length;
      return lines * e.fontSize * e.lineHeight; 
    }
    return 150;
  }

  Future<void> _saveProjectLocally() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStrings = prefs.getStringList('qalamkaar_projects') ?? [];
    ProjectModel p = ProjectModel(id: projectId, name: projectName, pages: pages, lastModified: DateTime.now().millisecondsSinceEpoch);
    savedStrings.removeWhere((str) => jsonDecode(str)['id'] == projectId); 
    savedStrings.add(jsonEncode(p.toJson())); 
    await prefs.setStringList('qalamkaar_projects', savedStrings);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project Saved Successfully!', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 18)), backgroundColor: Color(0xFF10B981)));
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
    if (undoStack.length > 20) undoStack.removeAt(0); 
  }
  
  void undoAction() { if (undoStack.isNotEmpty) { redoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = undoStack.removeLast(); selectedId = null; }); HapticFeedback.lightImpact(); } }
  void redoAction() { if (redoStack.isNotEmpty) { undoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = redoStack.removeLast(); selectedId = null; }); HapticFeedback.lightImpact(); } }

  // 🔥 MATHEMATICAL RESIZE (Left / Right / Top / Bottom)
  void _handleRightPill(double dx, double dy, DesignElement e, double w, double h) {
    setState(() {
      double lDx = dx * cos(e.angle) + dy * sin(e.angle);
      double newW = w + lDx;
      if (newW >= 50) {
        e.width = newW;
        e.x += (lDx / 2) * cos(e.angle);
        e.y += (lDx / 2) * sin(e.angle);
        if (e.isTable) _triggerCanvasUpdate();
      }
    });
  }

  void _handleLeftPill(double dx, double dy, DesignElement e, double w, double h) {
    setState(() {
      double lDx = dx * cos(e.angle) + dy * sin(e.angle);
      double newW = w - lDx;
      if (newW >= 50) {
        e.width = newW;
        e.x += (lDx / 2) * cos(e.angle);
        e.y += (lDx / 2) * sin(e.angle);
        if (e.isTable) _triggerCanvasUpdate();
      }
    });
  }

  void _handleBottomPill(double dx, double dy, DesignElement e, double w, double h) {
    setState(() {
      double lDy = -dx * sin(e.angle) + dy * cos(e.angle);
      double newH = h + lDy;
      if (newH >= 20) {
        e.height = newH;
        e.x += (lDy / 2) * (-sin(e.angle));
        e.y += (lDy / 2) * cos(e.angle);
        if (e.isTable) _triggerCanvasUpdate();
      }
    });
  }

  void _handleTopPill(double dx, double dy, DesignElement e, double w, double h) {
    setState(() {
      double lDy = -dx * sin(e.angle) + dy * cos(e.angle);
      double newH = h - lDy;
      if (newH >= 20) {
        e.height = newH;
        e.x += (lDy / 2) * (-sin(e.angle));
        e.y += (lDy / 2) * cos(e.angle);
        if (e.isTable) _triggerCanvasUpdate();
      }
    });
  }

  // 🔥 MATHEMATICAL PROPORTIONAL SCALE (Bottom-Left)
  Widget _buildScaleHandle(DesignElement e, double w, double h) {
    return GestureDetector(
      onPanStart: (_) => saveState(),
      onPanUpdate: (d) {
        setState(() {
          double rx = (-w / 2) * cos(e.angle) - (h / 2) * sin(e.angle);
          double ry = (-w / 2) * sin(e.angle) + (h / 2) * cos(e.angle);
          double r = sqrt(rx * rx + ry * ry);
          if (r > 0) {
            double ux = rx / r;
            double uy = ry / r;
            double radialDelta = d.delta.dx * ux + d.delta.dy * uy;
            double scale = (r + radialDelta) / r;
            if (scale > 0.05) {
              double newW = w * scale;
              double newH = h * scale;
              if (newW >= 50 && (!e.isText || e.fontSize * scale >= 8)) {
                double oldCx = e.x + w / 2;
                double oldCy = e.y + h / 2;
                e.width = newW;
                if (!e.isText) e.height = newH;
                if (e.isText) e.fontSize *= scale;
                e.x = oldCx - newW / 2;
                e.y = oldCy - (e.isText ? _getElHeight(e) : newH) / 2;
                if (e.isTable) _triggerCanvasUpdate();
              }
            }
          }
        });
      },
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]),
        child: const Icon(Icons.open_in_full, size: 13, color: Color(0xFF8B5CF6)),
      ),
    );
  }

  // 🔥 TANGENT-BASED ROTATION (Top-Right)
  Widget _buildRotateHandle(DesignElement e, double w, double h) {
    return GestureDetector(
      onPanStart: (_) => saveState(),
      onPanUpdate: (d) {
        setState(() {
          double rx = (w / 2) * cos(e.angle) - (-h / 2) * sin(e.angle);
          double ry = (w / 2) * sin(e.angle) + (-h / 2) * cos(e.angle);
          double r = sqrt(rx * rx + ry * ry);
          if (r > 0) {
            double tx = -ry / r;
            double ty = rx / r;
            double dTheta = (d.delta.dx * tx + d.delta.dy * ty) / r;
            e.angle += dTheta;
          }
        });
      },
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]),
        child: const Icon(Icons.refresh, size: 15, color: Color(0xFF8B5CF6)),
      ),
    );
  }

  // 🔥 FLOATING ACTION BAR (Below Selected Box)
  Widget _buildFloatingBar(DesignElement e) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(30),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onPanStart: (_) => saveState(),
              onPanUpdate: (d) {
                setState(() {
                  e.x += d.delta.dx;
                  e.y += d.delta.dy;
                });
              },
              child: Transform.rotate(
                angle: -e.angle,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.open_with, size: 18, color: Color(0xFF4B5563)),
                ),
              ),
            ),
            InkWell(
              onTap: deleteSelected,
              child: Transform.rotate(
                angle: -e.angle,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                ),
              ),
            ),
            InkWell(
              onTap: duplicateSelected,
              child: Transform.rotate(
                angle: -e.angle,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.copy, size: 18, color: Color(0xFF4B5563)),
                ),
              ),
            ),
            InkWell(
              onTap: () => _showAlignmentModal(e),
              child: Transform.rotate(
                angle: -e.angle,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.menu, size: 18, color: Color(0xFF4B5563)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportMenu() { 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Export Design (سیو کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), const SizedBox(height: 10), _buildExportOption(Icons.image, 'Save as JPG', 'Solid Background', Colors.blue, () { Navigator.pop(context); _captureAndSave('JPG'); }), const SizedBox(height: 10), _buildExportOption(Icons.layers_clear, 'Save as PNG', 'Transparent Image (Logos)', Colors.purple, () { Navigator.pop(context); _captureAndSave('PNG'); }), const SizedBox(height: 10), _buildExportOption(Icons.picture_as_pdf, 'Save as Print HD PDF', 'High Quality PDF Document', Colors.red, () { Navigator.pop(context); _captureAndSave('PDF'); })]))); 
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) { 
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))])), Icon(Icons.arrow_forward_ios, color: color, size: 16)]))); 
  }

  Future<void> _captureAndSave(String format) async { 
    setState(() { selectedId = null; _isExporting = true; }); 
    await Future.delayed(const Duration(milliseconds: 400)); 
    try { 
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary; 
      double pixelRatio = 3.0; 
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png); 
      Uint8List pngBytes = byteData!.buffer.asUint8List(); 
      if (format == 'JPG' || format == 'PNG') { 
        final result = await ImageGallerySaver.saveImage(pngBytes, quality: 100, name: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}"); 
        if (mounted && result != null && result['isSuccess'] == true) { _showSuccessDialog('Saved to Gallery!', 'Aapka $format design gallery mein save ho gaya hai.'); } 
      } else if (format == 'PDF') { 
        final pdf = pw.Document(); 
        final imagePdf = pw.MemoryImage(pngBytes); 
        pdf.addPage(pw.Page(pageFormat: PdfPageFormat(image.width.toDouble(), image.height.toDouble()), margin: pw.EdgeInsets.zero, build: (pw.Context context) { return pw.Image(imagePdf, fit: pw.BoxFit.cover); })); 
        Uint8List pdfBytes = await pdf.save(); 
        await Printing.sharePdf(bytes: pdfBytes, filename: "QalamKaarPro_Print_${DateTime.now().millisecondsSinceEpoch}.pdf"); 
      } 
    } catch (e) { debugPrint('Export Error: $e'); } finally { setState(() { _isExporting = false; }); } 
  }

  void _showSuccessDialog(String title, String message) { 
    HapticFeedback.mediumImpact(); 
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 15), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))]))); 
  }

  void _showPoetryLibrary(TextEditingController textController) { 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return Container(height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(15), child: DefaultTabController(length: AppConstants.urduPoetryLibrary.keys.length, child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Urdu Library (شاعری / اقوال)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), TabBar(isScrollable: true, labelColor: const Color(0xFF8B5CF6), unselectedLabelColor: Colors.grey, indicatorColor: const Color(0xFF8B5CF6), tabs: AppConstants.urduPoetryLibrary.keys.map((k) => Tab(text: k)).toList()), const SizedBox(height: 10), Expanded(child: TabBarView(children: AppConstants.urduPoetryLibrary.keys.map((category) { return ListView.builder(itemCount: AppConstants.urduPoetryLibrary[category]!.length, itemBuilder: (context, index) { String text = AppConstants.urduPoetryLibrary[category]![index]; return Card(color: Colors.grey.shade50, elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.symmetric(vertical: 6), child: ListTile(title: Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 20, height: 1.5)), onTap: () { textController.text = text; Navigator.pop(context); })); }); }).toList()))]))); }); 
  }

  void _showTashkeelModal(TextEditingController controller) { 
    final List<String> tashkeelList = ['َ', 'ِ', 'ُ', 'ً', 'ٍ', 'ٌ', 'ّ', 'ْ', 'ٰ', 'ٓ', 'ے', 'ۓ', 'ﷺ', 'ؓ', 'ؒ', 'ﷻ', 'ﷲ', 'اکبر', 'جل جلالہ', 'بسم اللہ']; 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tashkeel & Symbols (اعراب)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: tashkeelList.length, itemBuilder: (context, index) { return InkWell(onTap: () { controller.text += tashkeelList[index]; Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), alignment: Alignment.center, child: Text(tashkeelList[index], style: const TextStyle(fontSize: 22, fontFamily: 'JameelNoori', color: Colors.black87)))); }))])); }); 
  }

  void _showTextComposerDialog({DesignElement? existingElement}) { 
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? ''); 
    bool isRTL = existingElement?.textAlign == TextAlign.right ? true : (existingElement?.textAlign == TextAlign.left ? false : true); 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.75, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20), Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)), padding: const EdgeInsets.all(4), child: Row(mainAxisSize: MainAxisSize.min, children: [GestureDetector(onTap: () => setModalState(() => isRTL = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: !isRTL ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: !isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null), child: Text('English (LTR)', style: TextStyle(fontWeight: !isRTL ? FontWeight.w900 : FontWeight.w600, color: !isRTL ? const Color(0xFF6366F1) : Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)))), GestureDetector(onTap: () => setModalState(() => isRTL = true), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: isRTL ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null), child: Text('اردو (RTL)', style: TextStyle(fontWeight: isRTL ? FontWeight.w900 : FontWeight.w600, color: isRTL ? const Color(0xFF10B981) : Colors.grey.shade500, fontSize: 16, fontFamily: 'JameelNoori'))))])), const SizedBox(height: 20), Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: isRTL ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF6366F1).withOpacity(0.3), width: 1.5), borderRadius: BorderRadius.circular(16)), child: TextField(controller: controller, maxLines: null, textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr, textAlign: isRTL ? TextAlign.right : TextAlign.left, style: TextStyle(fontFamily: isRTL ? 'JameelNoori' : null, fontSize: isRTL ? 28 : 20, height: 1.5, color: Colors.black87), decoration: InputDecoration(border: InputBorder.none, hintText: isRTL ? 'یہاں لکھیں...' : 'Type here...', hintTextDirection: isRTL ? TextDirection.rtl : TextDirection.ltr, hintStyle: TextStyle(color: Colors.grey.shade400))))), const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildComposerTool(Icons.paste, 'Paste', () async { ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain); if (data != null && data.text != null) controller.text += data.text!; }), _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()), _buildComposerTool(Icons.auto_stories, 'شاعری', () => _showPoetryLibrary(controller)), _buildComposerTool(Icons.format_quote, 'اعراب', () => _showTashkeelModal(controller))]), const SizedBox(height: 20), Row(children: [Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)))), const SizedBox(width: 15), Expanded(flex: 2, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: isRTL ? const Color(0xFF10B981) : const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4), onPressed: () { if (controller.text.isNotEmpty) { saveState(); if (existingElement != null) { setState(() { existingElement.content = controller.text; existingElement.textAlign = isRTL ? TextAlign.right : TextAlign.left; }); } else { var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, width: 280); newEl.textAlign = isRTL ? TextAlign.right : TextAlign.left; setState(() { elements.add(newEl); selectedId = newEl.id; }); } } Navigator.pop(context); }, icon: const Icon(Icons.check_circle_outline, color: Colors.white), label: const Text('Add to Design', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))])]))); }); }); 
  }

  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) { 
    return InkWell(onTap: onTap, child: Column(children: [Icon(icon, color: const Color(0xFF8B5CF6)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))])); 
  }

  void showAddNewModal() { 
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.65, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, children: [_buildGridItem(Icons.image, 'Gallery Pic', Colors.blue.shade100, Colors.blue, () => addImageFromGallery(fromModal: true)), _buildGridItem(Icons.gradient, 'Backgrounds', Colors.indigo.shade100, Colors.indigo, () { Navigator.pop(context); _showCanvasBgGradientModal(); }), _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade100, Colors.teal, () { Navigator.pop(context); Navigator.pop(context); }), _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade100, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }), _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade100, Colors.amber.shade800, () => showGenericStockModal('Borders', 'royal_islamic', Icons.border_outer, fromModal: true)), _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade100, Colors.pink, () => showGenericStockModal('Shapes', 'shape_rect', Icons.category, fromModal: true)), _buildGridItem(Icons.table_chart, 'Table', Colors.cyan.shade100, Colors.cyan.shade800, () { Navigator.pop(context); _addTable(); })]))]))); 
  }

  void _addTable() { 
    saveState(); 
    setState(() { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: 'Table', width: 300, height: 150, isText: false, isTable: true, tableData: [['Column 1', 'Column 2', 'Column 3'], ['Data 1', 'Data 2', 'Data 3'], ['Data 4', 'Data 5', 'Data 6'],])); selectedId = elements.last.id; }); 
  }

  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) { 
    return InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: iconColor, size: 28)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)])); 
  }

  Future<void> addImageFromGallery({bool fromModal = false}) async { 
    try { 
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery); 
      if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 80, content: '', imageBytes: bytes, isText: false, width: 250, height: 250))); } 
    } catch (e) { debugPrint("Gallery Error: $e"); } 
    if(fromModal && Navigator.canPop(context)) { Navigator.pop(context); } 
  }

  void _showTableEditorModal(DesignElement sel) { 
    if (sel.tableData == null) return; 
    List<List<String>> tempTable = []; 
    for (var row in sel.tableData!) { tempTable.add(List.from(row)); } 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.85, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Edit Table (ٹیبل ایڈٹ کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Text('MS Word / InPage Style Advance Table Editing', style: TextStyle(fontSize: 10, color: Colors.grey)), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(onPressed: () { setModalState(() { List<String> newRow = List.generate(tempTable[0].length, (i) => 'New Data'); tempTable.add(newRow); }); }, icon: const Icon(Icons.table_rows), label: const Text('+ Add Row')), ElevatedButton.icon(onPressed: () { setModalState(() { for(int i=0; i<tempTable.length; i++) { tempTable[i].add('New Col'); } }); }, icon: const Icon(Icons.view_column), label: const Text('+ Add Col'))]), const SizedBox(height: 10), Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: tempTable.asMap().entries.map((rowEntry) { int rowIndex = rowEntry.key; List<String> row = rowEntry.value; return Row(children: [...row.asMap().entries.map((colEntry) { int colIndex = colEntry.key; return Container(width: 100, margin: const EdgeInsets.all(4), child: TextField(controller: TextEditingController(text: tempTable[rowIndex][colIndex]), textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 14), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)), onChanged: (val) { tempTable[rowIndex][colIndex] = val; })); }).toList(), if (tempTable.length > 1) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () { setModalState(() { tempTable.removeAt(rowIndex); }); })]); }).toList())))), const SizedBox(height: 10), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: Column(children: [Row(children: [const Text('Total Width:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Expanded(child: Slider(value: sel.width > 50 ? sel.width : 280, min: 100, max: currentCanvasW, activeColor: Colors.blue, onChanged: (val) { setModalState(() => sel.width = val); setState((){}); } ))]), Row(children: [const Text('Total Height:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Expanded(child: Slider(value: sel.height > 20 ? sel.height : 150, min: 50, max: currentCanvasH, activeColor: Colors.green, onChanged: (val) { setModalState(() => sel.height = val); setState((){}); } ))])])), const SizedBox(height: 15), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: () { saveState(); setState(() { sel.tableData = tempTable; _triggerCanvasUpdate(); }); Navigator.pop(context); }, child: const Text('Update Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))]))); }); }); 
  }

  Future<void> _setCanvasBackground() async { 
    try { 
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery); 
      if (image != null) { final bytes = await image.readAsBytes(); setState(() { bgImageBytes = bytes; bgGradient = null; pageColor = Colors.white; }); } 
    } catch (e) {} 
  }

  Future<void> _addTextureToText(DesignElement sel) async { 
    try { 
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery); 
      if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => sel.textTextureBytes = bytes); } 
    } catch (e) {} 
  }

  void showGenericStockModal(String categoryTitle, String styleName, IconData categoryIcon, {bool fromModal = false}) { 
    if(fromModal && Navigator.canPop(context)) Navigator.pop(context); 
    List<Map<String, dynamic>> stockList = []; 
    List<Color> themeColors = [const Color(0xFFD4AF37), const Color(0xFF8B5CF6), const Color(0xFF047857), const Color(0xFF1E3A8A)]; 
    for (int i = 1; i <= 50; i++) stockList.add({'title': '$categoryTitle #$i', 'style': styleName, 'color': themeColors[(i - 1) % themeColors.length], 'icon': categoryIcon}); 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.75, padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 15), Text('$categoryTitle Library', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.4), itemCount: stockList.length, itemBuilder: (context, index) { var item = stockList[index]; return InkWell(onTap: () { saveState(); setState(() { if (styleName.contains('shape') || styleName == 'badge') { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 90, y: 180, content: styleName == 'badge' ? 'circle' : 'rectangle', isText: false, isShape: true, elementColor: item['color'], width: 220, height: 90)); } else { elements.insert(0, DesignElement(id: Random().nextInt(10000).toString(), x: 0, y: 0, content: item['title'], isText: false, isBorder: true, borderStyle: styleName, elementColor: item['color'], width: currentCanvasW, height: currentCanvasH, borderWidth: 5.0)); } }); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: item['color'], width: 1.5)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item['icon'], color: item['color'], size: 30), const SizedBox(height: 6), Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item['color']))]))); }))] ))); 
  }

  void deleteSelected() { 
    if (selectedId != null) { 
      saveState(); 
      setState(() { 
        elements.removeWhere((e) => e.id == selectedId); 
        selectedId = null; 
      }); 
    } 
  }

  void duplicateSelected() { 
    if (selectedId != null) { 
      saveState(); 
      DesignElement sel = elements.firstWhere((e) => e.id == selectedId); 
      setState(() { 
        var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20; 
        elements.add(newEl); 
        selectedId = newEl.id; 
      }); 
    } 
  }

  void bringForward() { 
    if (selectedId == null) return; 
    saveState(); 
    int idx = elements.indexWhere((e) => e.id == selectedId); 
    if (idx < elements.length - 1) setState(() { var item = elements.removeAt(idx); elements.insert(idx + 1, item); }); 
  }

  void sendBackward() { 
    if (selectedId == null) return; 
    saveState(); 
    int idx = elements.indexWhere((e) => e.id == selectedId); 
    if (idx > 0) setState(() { var item = elements.removeAt(idx); elements.insert(idx - 1, item); }); 
  }

  void _toggleAlignment(DesignElement sel) { 
    saveState(); 
    setState(() { 
      sel.textAlign = (sel.textAlign == TextAlign.right) ? TextAlign.center : (sel.textAlign == TextAlign.center ? TextAlign.left : TextAlign.right); 
    }); 
  }

  void _pickCustomGradColor(DesignElement sel, int colorNum, StateSetter parentSetState) { 
    showModalBottomSheet(context: context, builder: (ctx) => Container(height: 300, padding: const EdgeInsets.all(20), child: Column(children: [const Text('Pick a Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: AppConstants.proColorPalette.length, itemBuilder: (ctx, index) { return InkWell(onTap: () { if(colorNum == 1) sel.customGradColor1 = AppConstants.proColorPalette[index]; else sel.customGradColor2 = AppConstants.proColorPalette[index]; parentSetState((){}); Navigator.pop(ctx); }, child: Container(decoration: BoxDecoration(color: AppConstants.proColorPalette[index], shape: BoxShape.circle, border: Border.all(color: Colors.black26)))); }))]))); 
  }

  void _showCanvasBgColorModal() { 
    TextEditingController hexCtrl = TextEditingController(); 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 480, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: TextField(controller: hexCtrl, decoration: const InputDecoration(hintText: 'Hex Code: #FF0000', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)))), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: ()
