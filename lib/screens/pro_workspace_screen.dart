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
  bool _isCanvasLocked = false, _showGrid = false, _isExporting = false;
  double currentCanvasW = 1000, currentCanvasH = 1000;
  late String projectId, projectName;
  List<DesignPage> pages = [];
  int currentPageIndex = 0;
  List<List<DesignElement>> undoStack = [], redoStack = [];
  String? selectedId;
  final ImagePicker _picker = ImagePicker();
  List<String> customFonts = [];
  final List<Map<String, String>> availableFontsData = [
    {'name': 'JameelNoori', 'title': 'جمیل نوری نستعلیق', 'desc': 'Classic Standard Urdu Font'},
    {'name': 'AlviNastaleeq', 'title': 'علوی نستعلیق', 'desc': 'Beautiful Nasta\'liq Style'},
    {'name': 'Mehr', 'title': 'مہر نستعلیق', 'desc': 'Modern & Elegant Font'},
    {'name': 'BombayBlack', 'title': 'بمبئی بلیک', 'desc': 'Thick Header & Title Font'},
    {'name': 'AlMajeed', 'title': 'المجید قرآنی فونٹ', 'desc': 'Classic Arabic/Quranic Font'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      projectId = widget.project!.id; projectName = widget.project!.name; pages = widget.project!.pages;
    } else {
      projectId = DateTime.now().millisecondsSinceEpoch.toString(); projectName = 'Design_$projectId';
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
  void dispose() { _transformController.dispose(); _canvasNotifier.dispose(); super.dispose(); }
  void _triggerCanvasUpdate() { _canvasNotifier.value++; }

  double _getElWidth(DesignElement e) => max(e.width, 50.0);
  double _getElHeight(DesignElement e) {
    if (!e.isText && e.height > 20) return e.height;
    if (e.isShape) return 90;
    if (e.isText) return (e.content.isEmpty ? 1 : e.content.split('\n').length) * e.fontSize * e.lineHeight + 15;
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project Saved Successfully!')));
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

  void saveState() { undoStack.add(elements.map((e) => e.clone()).toList()); redoStack.clear(); if (undoStack.length > 20) undoStack.removeAt(0); }
  void undoAction() { if (undoStack.isNotEmpty) { redoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = undoStack.removeLast(); selectedId = null; }); HapticFeedback.lightImpact(); _triggerCanvasUpdate(); } }
  void redoAction() { if (redoStack.isNotEmpty) { undoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = redoStack.removeLast(); selectedId = null; }); HapticFeedback.lightImpact(); _triggerCanvasUpdate(); } }

  // ---------------------------------------------------------
  // HANDLE LOGIC RE-WRITTEN FOR FLAWLESS OPERATION
  // ---------------------------------------------------------
  void _resizeEdge(DragUpdateDetails d, String edge, DesignElement e) {
    setState(() {
      double ldx = d.delta.dx, ldy = d.delta.dy;
      if (e.angle != 0) { 
        double cosA = cos(-e.angle), sinA = sin(-e.angle); 
        ldx = d.delta.dx * cosA - d.delta.dy * sinA; 
        ldy = d.delta.dx * sinA + d.delta.dy * cosA; 
      }
      
      if (edge == 'R') { 
        e.width = max(50.0, e.width + ldx); 
      } 
      else if (edge == 'L') { 
        double oldW = e.width; 
        e.width = max(50.0, e.width - ldx); 
        // Only adjust position if width actually changed to prevent jumping
        if (e.width > 50.0) {
            e.x += (oldW - e.width) * cos(e.angle); 
            e.y += (oldW - e.width) * sin(e.angle); 
        }
      } 
      else if (edge == 'B') { 
        if(!e.isText) e.height = max(30.0, e.height + ldy); 
      } 
      else if (edge == 'T') { 
        if(!e.isText) { 
          double oldH = e.height; 
          e.height = max(30.0, e.height - ldy); 
          if (e.height > 30.0) {
             e.x -= (oldH - e.height) * sin(e.angle); 
             e.y += (oldH - e.height) * cos(e.angle); 
          }
        } 
      }
    });
    _triggerCanvasUpdate();
  }

  void _scaleCorner(DragUpdateDetails d, DesignElement e) {
    setState(() {
      double delta = (d.delta.dx + d.delta.dy) * 0.5;
      if (e.width + delta > 50) {
        double ratio = e.width / (e.height > 0 ? e.height : 1);
        e.width += delta; 
        if (!e.isText) e.height += delta / ratio;
        if (e.isText) e.fontSize = max(10.0, e.fontSize + delta * 0.2);
        
        // Adjust position so scaling feels like it's from the center
        e.x -= delta / 2; 
        e.y -= (e.isText ? 0 : delta / ratio) / 2;
      }
    });
    _triggerCanvasUpdate();
  }

  void _rotateHandle(DragUpdateDetails d, DesignElement e) { 
    setState(() { e.angle += (d.delta.dx + d.delta.dy) * 0.01; });
    _triggerCanvasUpdate(); 
  }
  
  // ---------------------------------------------------------
  
  void deleteSelected() { if (selectedId != null) { saveState(); setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; }); _triggerCanvasUpdate(); } }
  void duplicateSelected() { if (selectedId != null) { saveState(); DesignElement sel = elements.firstWhere((e) => e.id == selectedId); setState(() { var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20; elements.add(newEl); selectedId = newEl.id; }); _triggerCanvasUpdate(); } }
  void bringForward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx < elements.length - 1) { setState(() { var item = elements.removeAt(idx); elements.insert(idx + 1, item); }); _triggerCanvasUpdate(); } }
  void sendBackward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx > 0) { setState(() { var item = elements.removeAt(idx); elements.insert(idx - 1, item); }); _triggerCanvasUpdate(); } }
  
  void _toggleAlignment(DesignElement sel) { 
    saveState(); 
    setState(() { 
      if (sel.textAlign == TextAlign.right) sel.textAlign = TextAlign.center; 
      else if (sel.textAlign == TextAlign.center) sel.textAlign = TextAlign.left; 
      else sel.textAlign = TextAlign.right; 
    }); 
    _triggerCanvasUpdate(); 
  }

  Future<void> _captureAndSave(String format) async {
    setState(() { selectedId = null; _isExporting = true; }); await Future.delayed(const Duration(milliseconds: 400));
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      if (format == 'JPG' || format == 'PNG') {
        final result = await ImageGallerySaver.saveImage(pngBytes, quality: 100, name: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}");
        if (mounted && result != null && result['isSuccess'] == true) _showSuccessDialog('Saved to Gallery!', 'Aapka $format design gallery mein save ho gaya hai.');
      } else if (format == 'PDF') {
        final pdf = pw.Document(); final imagePdf = pw.MemoryImage(pngBytes);
        pdf.addPage(pw.Page(pageFormat: PdfPageFormat(image.width.toDouble(), image.height.toDouble()), margin: pw.EdgeInsets.zero, build: (pw.Context context) { return pw.Image(imagePdf, fit: pw.BoxFit.cover); }));
        Uint8List pdfBytes = await pdf.save(); await Printing.sharePdf(bytes: pdfBytes, filename: "QalamKaarPro_Print_${DateTime.now().millisecondsSinceEpoch}.pdf");
      }
    } catch (e) { debugPrint('Export Error: $e'); } finally { setState(() { _isExporting = false; }); }
  }

  void _showSuccessDialog(String title, String message) {
    HapticFeedback.mediumImpact(); showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 15), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))])));
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) { return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))])), Icon(Icons.arrow_forward_ios, color: color, size: 16)]))); }
  void _showExportMenu() { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Export Design', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), const SizedBox(height: 10), _buildExportOption(Icons.image, 'Save as JPG', 'Solid Background', Colors.blue, () { Navigator.pop(context); _captureAndSave('JPG'); }), const SizedBox(height: 10), _buildExportOption(Icons.layers_clear, 'Save as PNG', 'Transparent Image', Colors.purple, () { Navigator.pop(context); _captureAndSave('PNG'); }), const SizedBox(height: 10), _buildExportOption(Icons.picture_as_pdf, 'Save as Print PDF', 'High Quality PDF', Colors.red, () { Navigator.pop(context); _captureAndSave('PDF'); })])); }); }

  void _showTextComposerDialog({DesignElement? existingElement}) {
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? '');
    bool isRTL = existingElement?.textAlign == TextAlign.right ? true : (existingElement?.textAlign == TextAlign.left ? false : true);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) {
      return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
        return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.75, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20),
          Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)), padding: const EdgeInsets.all(4), child: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(onTap: () => setModalState(() => isRTL = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: !isRTL ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: !isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null), child: Text('English', style: TextStyle(fontWeight: !isRTL ? FontWeight.w900 : FontWeight.w600, color: !isRTL ? const Color(0xFF6366F1) : Colors.grey.shade500)))),
            GestureDetector(onTap: () => setModalState(() => isRTL = true), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: isRTL ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null), child: Text('اردو', style: TextStyle(fontWeight: isRTL ? FontWeight.w900 : FontWeight.w600, color: isRTL ? const Color(0xFF10B981) : Colors.grey.shade500, fontFamily: 'JameelNoori', fontSize: 16)))),
          ])), const SizedBox(height: 20),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: isRTL ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF6366F1).withOpacity(0.3), width: 1.5), borderRadius: BorderRadius.circular(16)), child: TextField(controller: controller, maxLines: null, textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr, textAlign: isRTL ? TextAlign.right : TextAlign.left, style: TextStyle(fontFamily: isRTL ? 'JameelNoori' : null, fontSize: isRTL ? 28 : 20, height: 1.5), decoration: InputDecoration(border: InputBorder.none, hintText: isRTL ? 'یہاں لکھیں...' : 'Type here...', hintTextDirection: isRTL ? TextDirection.rtl : TextDirection.ltr)))), const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            InkWell(onTap: () async { ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain); if (data != null && data.text != null) controller.text += data.text!; }, child: Column(children: const [Icon(Icons.paste, color: Color(0xFF8B5CF6)), Text('Paste', style: TextStyle(fontSize: 12))])),
            InkWell(onTap: () => controller.clear(), child: Column(children: const [Icon(Icons.delete_outline, color: Color(0xFF8B5CF6)), Text('Clear', style: TextStyle(fontSize: 12))])),
          ]), const SizedBox(height: 20),
          Row(children: [
            Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)))), const SizedBox(width: 15),
            Expanded(flex: 2, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: isRTL ? const Color(0xFF10B981) : const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () {
              if (controller.text.isNotEmpty) {
                saveState();
                double calcW = (controller.text.length * (isRTL ? 28.0 : 20.0) * 0.6) + 40;
                if(calcW > MediaQuery.of(context).size.width - 60) calcW = MediaQuery.of(context).size.width - 60;
                if(calcW < 80) calcW = 80;
                if (existingElement != null) { setState(() { existingElement.content = controller.text; existingElement.textAlign = isRTL ? TextAlign.right : TextAlign.left; }); } 
                else { var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, width: calcW); newEl.textAlign = isRTL ? TextAlign.right : TextAlign.left; setState(() { elements.add(newEl); selectedId = newEl.id; }); }
                _triggerCanvasUpdate(); Navigator.pop(context);
              }
            }, icon: const Icon(Icons.check_circle_outline, color: Colors.white), label: const Text('Add to Design', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
          ])
        ])));
      });
    });
  }

  void _addTable() { saveState(); setState(() { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: 'Table', width: 300, height: 150, isText: false, isTable: true, tableData: [['Column 1', 'Column 2'], ['Data 1', 'Data 2']])); selectedId = elements.last.id; }); _triggerCanvasUpdate(); }
  Future<void> addImageFromGallery({bool fromModal = false}) async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 80, content: '', imageBytes: bytes, isText: false, width: 250, height: 250))); _triggerCanvasUpdate(); } } catch (e) { debugPrint("Gallery Error: $e"); } if (fromModal && Navigator.canPop(context)) { Navigator.pop(context); } }
  Future<void> _setCanvasBackground() async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); setState(() { bgImageBytes = bytes; bgGradient = null; pageColor = Colors.white; }); _triggerCanvasUpdate(); } } catch (e) { debugPrint("BG Image Error: $e"); } }
  Future<void> _addTextureToText(DesignElement sel) async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => sel.textTextureBytes = bytes); _triggerCanvasUpdate(); } } catch (e) {} }

  void showAddNewModal() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.65, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, children: [
      _buildGridItem(Icons.image, 'Gallery Pic', Colors.blue.shade100, Colors.blue, () => addImageFromGallery(fromModal: true)),
      _buildGridItem(Icons.gradient, 'Backgrounds', Colors.indigo.shade100, Colors.indigo, () { Navigator.pop(context); _showCanvasBgGradientModal(); }),
      _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade100, Colors.teal, () { Navigator.pop(context); Navigator.pop(context); }),
      _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade100, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }),
      _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade100, Colors.amber.shade800, () { Navigator.pop(context); }),
      _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade100, Colors.pink, () { Navigator.pop(context); }),
      _buildGridItem(Icons.table_chart, 'Table', Colors.cyan.shade100, Colors.cyan.shade800, () { Navigator.pop(context); _addTable(); })
    ]))])));
  }

  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: iconColor, size: 28)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)])); }

  void _showTableEditorModal(DesignElement sel) {
    if (sel.tableData == null) return; List<List<String>> tempTable = []; for (var row in sel.tableData!) { tempTable.add(List.from(row)); }
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.85, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Edit Table ٹیبل ایڈٹ کریں', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Text('MS Word / InPage Style', style: TextStyle(fontSize: 12, color: Colors.grey)), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(onPressed: () { setModalState(() { List<String> newRow = List.generate(tempTable[0].length, (i) => 'New Data'); tempTable.add(newRow); }); }, icon: const Icon(Icons.table_rows), label: const Text('+ Add Row')), ElevatedButton.icon(onPressed: () { setModalState(() { for(int i=0; i<tempTable.length; i++) { tempTable[i].add('New Col'); } }); }, icon: const Icon(Icons.view_column), label: const Text('+ Add Col'))]), const SizedBox(height: 10), Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: tempTable.asMap().entries.map((rowEntry) { int rowIndex = rowEntry.key; List<String> row = rowEntry.value; return Row(children: [...row.asMap().entries.map((colEntry) { int colIndex = colEntry.key; return Container(width: 100, margin: const EdgeInsets.all(4), child: TextField(controller: TextEditingController(text: tempTable[rowIndex][colIndex]), textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'JameelNoori'), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)), onChanged: (val) { tempTable[rowIndex][colIndex] = val; })); }).toList(), if (tempTable.length > 1) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () { setModalState(() { tempTable.removeAt(rowIndex); }); })]); }).toList())))), const SizedBox(height: 15), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: () { saveState(); setState(() { sel.tableData = tempTable; }); _triggerCanvasUpdate(); Navigator.pop(context); }, child: const Text('Update Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))]))); }); });
  }

  void _pickCustomGradColor(DesignElement sel, int colorNum, StateSetter parentSetState) { showModalBottomSheet(context: context, builder: (ctx) => Container(height: 300, padding: const EdgeInsets.all(20), child: Column(children: [const Text('Pick a Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: AppConstants.proColorPalette.length, itemBuilder: (ctx, index) { return InkWell(onTap: () { if(colorNum == 1) sel.customGradColor1 = AppConstants.proColorPalette[index]; else sel.customGradColor2 = AppConstants.proColorPalette[index]; parentSetState((){}); _triggerCanvasUpdate(); Navigator.pop(ctx); }, child: Container(decoration: BoxDecoration(color: AppConstants.proColorPalette[index], shape: BoxShape.circle, border: Border.all(color: Colors.black26)))); }))]))); }
  void _showCanvasBgColorModal() { TextEditingController hexCtrl = TextEditingController(); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 480, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: TextField(controller: hexCtrl, decoration: const InputDecoration(hintText: 'Hex Code: #FF0000', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)))), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () { String hex = hexCtrl.text.replaceAll('#', ''); if(hex.length == 6) hex = 'FF$hex'; if(hex.length == 8) { saveState(); setState((){ pageColor = Color(int.parse('0x$hex')); bgImageBytes = null; bgGradient = null; }); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white)))])), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSelected = pageColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { pageColor = c; bgImageBytes = null; bgGradient = null; }); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))]))); }); }); }
  void _showCanvasBgGradientModal() { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 450, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Gradient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 2.0), itemCount: AppConstants.proGradientPalette.length, itemBuilder: (context, index) { List<Color> g = AppConstants.proGradientPalette[index]; return GestureDetector(onTap: () { saveState(); setState(() { bgGradient = g; bgImageBytes = null; pageColor = Colors.white; }); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300, width: 1.5)))); }))])); }); }); }
  void _showTextBgPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 550, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Text Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), ListTile(leading: const Icon(Icons.block), title: const Text('Remove Background'), onTap: () { saveState(); setState(() { sel.textBgColor = null; }); _triggerCanvasUpdate(); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSelected = sel.textBgColor?.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { sel.textBgColor = c; }); setModalState((){}); _triggerCanvasUpdate(); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5)), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))])); }); }); }
  void _showGradientPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 550, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Gradient Tool', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Make Your Own اپنی مرضی کا شیڈ بنائیں", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [InkWell(onTap: () => _pickCustomGradColor(sel, 1, setModalState), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: sel.customGradColor1 ?? Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.black26)))), const Icon(Icons.add), InkWell(onTap: () => _pickCustomGradColor(sel, 2, setModalState), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: sel.customGradColor2 ?? Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.black26)))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () { if(sel.customGradColor1 != null && sel.customGradColor2 != null) { saveState(); setState(() => sel.textGradient = [sel.customGradColor1!, sel.customGradColor2!]); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white)))])])), const SizedBox(height: 10), ListTile(leading: const Icon(Icons.block), title: const Text('Clear Gradient'), onTap: () { saveState(); setState(() { sel.textGradient = null; }); _triggerCanvasUpdate(); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 2.0), itemCount: AppConstants.proGradientPalette.length, itemBuilder: (context, index) { List<Color> g = AppConstants.proGradientPalette[index]; return GestureDetector(onTap: () { saveState(); setState(() { sel.textGradient = g; }); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300, width: 1.5)))); }))])); }); }); }
  void _showColorPickerModal(DesignElement sel) { TextEditingController hexCtrl = TextEditingController(); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { Color currentColor = sel.isText ? sel.textColor : sel.elementColor; return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 480, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Color رنگ منتخب کریں', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: TextField(controller: hexCtrl, decoration: const InputDecoration(hintText: 'Custom Hex: #FF0000', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)))), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () { String hex = hexCtrl.text.replaceAll('#', ''); if(hex.length == 6) hex = 'FF$hex'; if(hex.length == 8) { saveState(); setState((){ if(sel.isText){ sel.textColor = Color(int.parse('0x$hex')); sel.textGradient = null; } else { sel.elementColor = Color(int.parse('0x$hex')); } }); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white)))])), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSelected = currentColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { if (sel.isText) { sel.textColor = c; sel.textGradient = null; } else { sel.elementColor = c; } }); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))]))); }); }); }
  
  void _showAdvancedStrokeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 450, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Advanced Stroke', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Stroke', style: TextStyle(fontWeight: FontWeight.bold)), activeColor: const Color(0xFF8B5CF6), value: sel.hasStroke, onChanged: (val) { saveState(); setState(() => sel.hasStroke = val); setModalState((){}); _triggerCanvasUpdate(); }), const Divider(), if (sel.hasStroke) ...[Row(children: [const Text('Thickness:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.strokeWidth, min: 1.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.strokeWidth = val); setModalState((){}); _triggerCanvasUpdate(); }))]), const Text('Stroke Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSel = sel.strokeColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.strokeColor = c); setModalState((){}); _triggerCanvasUpdate(); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))] ])); }); }); }
  void _showAdvancedShadowModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 550, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Advanced Shadow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Shadow', style: TextStyle(fontWeight: FontWeight.bold)), activeColor: const Color(0xFF8B5CF6), value: sel.hasShadow, onChanged: (val) { saveState(); setState(() => sel.hasShadow = val); setModalState((){}); _triggerCanvasUpdate(); }), const Divider(), if (sel.hasShadow) ...[Row(children: [const Text('Blur:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowBlur, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowBlur = val); setModalState((){}); _triggerCanvasUpdate(); }))]), Row(children: [const Text('X-Offset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetX, min: -20.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetX = val); setModalState((){}); _triggerCanvasUpdate(); }))]), Row(children: [const Text('Y-Offset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetY, min: -20.0, max: 20.0, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetY = val); setModalState((){}); _triggerCanvasUpdate(); }))]), const Text('Shadow Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSel = sel.shadowColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.shadowColor = c); setModalState((){}); _triggerCanvasUpdate(); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))] ])); }); }); }
  
  void _show3DBlockModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 480, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('3D Block/Depth تھری ڈی موٹائی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Row(children: [const Text('Depth:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.text3dDepth, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.text3dDepth = val); setModalState(() {}); _triggerCanvasUpdate(); }))]), const Text('3D Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSel = sel.text3dColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.text3dColor = c); setModalState(() {}); _triggerCanvasUpdate(); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))])); }); }); }
  void _showRadiusModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Corner Radius گولائی: ${sel.cornerRadius.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Slider(value: sel.cornerRadius, min: 0.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.cornerRadius = val); setModalState((){}); _triggerCanvasUpdate(); })])); }); }); }
  void _showShapeClipModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Crop to Shape کٹنگ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView(scrollDirection: Axis.horizontal, children: [_buildShapeOption(sel, setModalState, 'None', 0, Icons.crop_square), _buildShapeOption(sel, setModalState, 'Circle', 1, Icons.circle_outlined), _buildShapeOption(sel, setModalState, 'Triangle', 2, Icons.change_history), _buildShapeOption(sel, setModalState, 'Star', 3, Icons.star_border), _buildShapeOption(sel, setModalState, 'Hexagon', 4, Icons.hexagon_outlined)]))])); }); }); }
  Widget _buildShapeOption(DesignElement sel, StateSetter setModalState, String title, int val, IconData icon) { bool isSel = sel.clipShape == val; return InkWell(onTap: () { saveState(); setState(() => sel.clipShape = val); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); }, child: Container(width: 80, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade600, size: 30), const SizedBox(height: 5), Text(title, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFF8B5CF6) : Colors.black87))]))); }
  void _showImageFiltersModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Image Filters تصویر کے رنگ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView(scrollDirection: Axis.horizontal, children: [_buildFilterOption(sel, setModalState, 'Normal', 0, Colors.grey), _buildFilterOption(sel, setModalState, 'B & W', 1, Colors.black87), _buildFilterOption(sel, setModalState, 'Sepia', 2, Colors.brown), _buildFilterOption(sel, setModalState, 'Invert', 3, Colors.blue)]))])); }); }); }
  Widget _buildFilterOption(DesignElement sel, StateSetter setModalState, String title, int filterVal, Color iconColor) { bool isSel = sel.imageFilter == filterVal; return InkWell(onTap: () { saveState(); setState(() => sel.imageFilter = filterVal); setModalState((){}); _triggerCanvasUpdate(); Navigator.pop(context); }, child: Container(width: 80, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_filter, color: isSel ? const Color(0xFF8B5CF6) : iconColor, size: 30), const SizedBox(height: 5), Text(title, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFF8B5CF6) : Colors.black87))]))); }
  void showSpacingModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 300, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Spacing فاصلے', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(children: [const Text('Line:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.lineHeight, min: 0.5, max: 3.5, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.lineHeight = val); setModalState((){}); _triggerCanvasUpdate(); }))]), Row(children: [const Text('Word:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.wordSpacing, min: -10.0, max: 30.0, activeColor: const Color(0xFF10B981), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.wordSpacing = val); setModalState((){}); _triggerCanvasUpdate(); }))]), Row(children: [const Text('Letter:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.letterSpacing, min: -5.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.letterSpacing = val); setModalState((){}); _triggerCanvasUpdate(); }))])])); }); }); }
  void showSizeSliderModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Size: ${sel.fontSize.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Slider(value: sel.fontSize, min: 10.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.fontSize = val); setModalState((){}); _triggerCanvasUpdate(); })])); }); }); }
  void showRotationModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 200, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rotate گھمائیں', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Slider(value: sel.angle, min: -pi, max: pi, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.angle = val); setModalState((){}); _triggerCanvasUpdate(); }), Text('${(sel.angle * 180 / pi).toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])); }); }); }
  void show3DModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 280, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('3D Perspective تھری ڈی زاویہ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(children: [const Text('X-Axis:', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Slider(value: sel.pitch, min: -pi / 2, max: pi / 2, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.pitch = val); setModalState((){}); _triggerCanvasUpdate(); }))]), Row(children: [const Text('Y-Axis:', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Slider(value: sel.yaw, min: -pi / 2, max: pi / 2, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.yaw = val); setModalState((){}); _triggerCanvasUpdate(); }))]), ElevatedButton(onPressed: () { saveState(); setState((){ sel.pitch = 0; sel.yaw = 0; }); setModalState((){}); _triggerCanvasUpdate(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200), child: const Text('Reset Perspective', style: TextStyle(color: Colors.black)))])); }); }); }
  void showNudgeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { void move(double dx, double dy) { saveState(); setState(() { sel.x += dx; sel.y += dy; if (sel.groupId != null) { for (var other in elements) { if (other.id != sel.id && other.groupId == sel.groupId && !other.isLocked) { other.x += dx; other.y += dy; } } } }); setModalState((){}); _triggerCanvasUpdate(); } return Container(height: 260, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Nudge Tool خردبینی حرکت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_upward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(0, -2))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_back, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(-2, 0)), const SizedBox(width: 40), IconButton(icon: const Icon(Icons.arrow_forward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(2, 0))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_downward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(0, 2))])])); }); }); }

  void _showAlignmentModal(DesignElement sel) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) {
      return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Position on Page سیدھ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildAlignButton(Icons.align_horizontal_left, 'Left', () { saveState(); setState(() => sel.x = 10); _triggerCanvasUpdate(); Navigator.pop(context); }),
          _buildAlignButton(Icons.align_horizontal_center, 'Center', () { saveState(); setState(() => sel.x = (currentCanvasW - _getElWidth(sel)) / 2); _triggerCanvasUpdate(); Navigator.pop(context); }),
          _buildAlignButton(Icons.align_horizontal_right, 'Right', () { saveState(); setState(() => sel.x = currentCanvasW - _getElWidth(sel) - 10); _triggerCanvasUpdate(); Navigator.pop(context); }),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildAlignButton(Icons.align_vertical_top, 'Top', () { saveState(); setState(() => sel.y = 10); _triggerCanvasUpdate(); Navigator.pop(context); }),
          _buildAlignButton(Icons.align_vertical_center, 'Middle', () { saveState(); setState(() => sel.y = (currentCanvasH - _getElHeight(sel)) / 2); _triggerCanvasUpdate(); Navigator.pop(context); }),
          _buildAlignButton(Icons.align_vertical_bottom, 'Bottom', () { saveState(); setState(() => sel.y = currentCanvasH - _getElHeight(sel) - 10); _triggerCanvasUpdate(); Navigator.pop(context); }),
        ])
      ]));
    });
  }

  Widget _buildAlignButton(IconData icon, String label, VoidCallback onTap) { return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: Column(children: [Icon(icon, color: const Color(0xFF8B5CF6)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]))); }

  void _showResizeModal() { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return Container(height: 300, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Resize Canvas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView(children: [ListTile(leading: const Icon(Icons.crop_square), title: const Text('1:1 (Square/Logo/DP)'), onTap: (){ saveState(); setState(()=> canvasRatio = 1.0); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.crop_16_9), title: const Text('16:9 (YouTube/Post)'), onTap: (){ saveState(); setState(()=> canvasRatio = 16/9); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.crop_portrait), title: const Text('9:16 (Story/ Reel/Status)'), onTap: (){ saveState(); setState(()=> canvasRatio = 9/16); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.description), title: const Text('1:1.414 (A4 Print/Letter)'), onTap: (){ saveState(); setState(()=> canvasRatio = 1/1.414); Navigator.pop(context); })]))])); }); }

  void showLayersPanel() { Set<String> selectedForGroup = {}; showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 450, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Layers & Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), if (selectedForGroup.length > 1) ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 10)), icon: const Icon(Icons.link, size: 16, color: Colors.white), label: const Text('Group', style: TextStyle(color: Colors.white, fontSize: 12)), onPressed: () { String newGroup = DateTime.now().millisecondsSinceEpoch.toString(); saveState(); for (var e in elements) { if (selectedForGroup.contains(e.id)) e.groupId = newGroup; } selectedForGroup.clear(); setModalState((){}); setState((){}); _triggerCanvasUpdate(); }), if (selectedForGroup.isNotEmpty) ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 10)), icon: const Icon(Icons.link_off, size: 16, color: Colors.white), label: const Text('Ungroup', style: TextStyle(color: Colors.white, fontSize: 12)), onPressed: () { saveState(); for (var e in elements) { if (selectedForGroup.contains(e.id)) e.groupId = null; } selectedForGroup.clear(); setModalState((){}); setState((){}); _triggerCanvasUpdate(); }), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Text('Tick boxes to group layers together', style: TextStyle(fontSize: 11, color: Colors.grey)), const Divider(), Expanded(child: elements.isEmpty ? const Center(child: Text('No elements yet.', style: TextStyle(color: Colors.grey))) : ListView.builder(itemCount: elements.length, itemBuilder: (context, index) { int actualIndex = elements.length - 1 - index; DesignElement e = elements[actualIndex]; bool isSel = selectedId == e.id; bool isGroupChecked = selectedForGroup.contains(e.id); return Card(color: isSel ? const Color(0xFFF3E8FF) : (e.groupId != null ? Colors.blue.shade50 : Colors.white), elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(side: BorderSide(color: isSel ? const Color(0xFF8B5CF6) : (e.groupId != null ? Colors.blue.shade300 : Colors.grey.shade300)), borderRadius: BorderRadius.circular(8)), child: ListTile(leading: Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: isGroupChecked, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setModalState(() { if (val == true) selectedForGroup.add(e.id); else selectedForGroup.remove(e.id); }); }), CircleAvatar(radius: 14, backgroundColor: e.isText ? e.textColor : Colors.blueGrey, child: Icon(e.isText ? Icons.title : (e.isBorder ? Icons.filter_frames : Icons.category), size: 14, color: Colors.white))]), title: Row(children: [Expanded(child: Text(e.isText ? e.content.replaceAll('\n', '') : (e.isBorder ? e.content : 'Shape'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))), if (e.groupId != null) const Icon(Icons.link, size: 14, color: Colors.blue)]), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(e.isHidden ? Icons.visibility_off : Icons.visibility, size: 18, color: e.isHidden ? Colors.red : Colors.black54), onPressed: () { saveState(); setState(() => e.isHidden = !e.isHidden); setModalState((){}); _triggerCanvasUpdate(); }), const SizedBox(width: 8), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(e.isLocked ? Icons.lock : Icons.lock_open, size: 18, color: e.isLocked ? Colors.red : Colors.black54), onPressed: () { saveState(); setState(() { e.isLocked = !e.isLocked; if(e.isLocked && isSel) selectedId = null; }); setModalState((){}); }), const SizedBox(width: 8), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.arrow_upward, size: 18, color: Colors.black54), onPressed: () { if (actualIndex < elements.length - 1) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex + 1, item); }); setModalState((){}); _triggerCanvasUpdate(); } }), const SizedBox(width: 8), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.arrow_downward, size: 18, color: Colors.black54), onPressed: () { if (actualIndex > 0) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex - 1, item); }); setModalState((){}); _triggerCanvasUpdate(); } })]), onTap: () { if(!e.isLocked && !e.isHidden) { setState(() => selectedId = e.id); setModalState((){}); _triggerCanvasUpdate(); } })); }))])); }); }); }
  void showPagesPanel() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 400, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pages صفحات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView.builder(itemCount: pages.length, itemBuilder: (context, index) { bool isCurrent = currentPageIndex == index; return Card(color: isCurrent ? const Color(0xFFF3E8FF) : Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(side: BorderSide(color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: ListTile(leading: Icon(Icons.description, color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey), title: Text(pages[index].title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.copy, color: Colors.blue, size: 20), onPressed: () { setState(() { pages.insert(index + 1, DesignPage(title: '${pages[index].title} Copy', elements: pages[index].elements.map((e) => e.clone()).toList(), pageColor: pages[index].pageColor, bgImageBytes: pages[index].bgImageBytes, canvasRatio: pages[index].canvasRatio, bgGradient: pages[index].bgGradient)); currentPageIndex = index + 1; }); setModalState((){}); _triggerCanvasUpdate(); }), if(pages.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () { setState(() { pages.removeAt(index); if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1; }); setModalState((){}); _triggerCanvasUpdate(); })]), onTap: () { setState(() { currentPageIndex = index; selectedId = null; }); _triggerCanvasUpdate(); Navigator.pop(context); })); })), const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () { setState(() { pages.add(DesignPage(title: 'Page ${pages.length + 1}', elements: [DesignElement(id: Random().nextInt(10000).toString(), x: 60, y: 100, content: 'نیا صفحہ', width: 250)], pageColor: Colors.white)); currentPageIndex = pages.length - 1; selectedId = null; }); _triggerCanvasUpdate(); Navigator.pop(context); }, child: const Text('Add New Page', style: TextStyle(color: Colors.white))))])); }); }); }
  void _showCurveModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Curve Text گولائی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(children: [const Text('Bend:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.textCurveRadius, min: -150.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.textCurveRadius = val); setModalState((){}); _triggerCanvasUpdate(); }))]), Row(children: [const Text('Spacing:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.letterSpacing, min: -5.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.letterSpacing = val); setModalState((){}); _triggerCanvasUpdate(); }))]), ElevatedButton(onPressed: () { saveState(); setState(() => sel.textCurveRadius = 0.0); setModalState((){}); _triggerCanvasUpdate(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200), child: const Text('Reset Curve', style: TextStyle(color: Colors.black)))])); }); }); }
  void _showBlendModeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Blend Modes مکس کرنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView.builder(itemCount: AppConstants.blendModes.length, itemBuilder: (context, index) { String bName = AppConstants.blendModes[index].toString().replaceAll('BlendMode.', '').toUpperCase(); return ListTile(title: Text(bName, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: sel.blendModeIndex == index ? const Icon(Icons.check_circle, color: const Color(0xFF8B5CF6)) : null, onTap: () { saveState(); setState(() => sel.blendModeIndex = index); _triggerCanvasUpdate(); Navigator.pop(context); }); }))])); }); }); }

  // HANDLES UI BUILDERS
  Widget _buildPillHandle(bool isHorizontal, Function(DragUpdateDetails) onDrag) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: onDrag,
      child: Container(
        padding: const EdgeInsets.all(12), color: Colors.transparent,
        child: Container(width: isHorizontal ? 24 : 8, height: isHorizontal ? 8 : 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5))),
      ),
    );
  }

  Widget _buildCircleHandle(Function(DragUpdateDetails) onDrag) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: onDrag,
      child: Container(
        padding: const EdgeInsets.all(12), color: Colors.transparent,
        child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5))),
      ),
    );
  }

  Widget _buildIconHandle(IconData icon, Function(DragUpdateDetails) onDrag) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: onDrag,
      child: Container(
        padding: const EdgeInsets.all(10), color: Colors.transparent,
        child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Icon(icon, size: 16, color: const Color(0xFF8B5CF6))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = selectedId != null;
    DesignElement? sel;
    if (hasSelection) sel = elements.firstWhere((e) => e.id == selectedId);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, titleSpacing: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40)),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTopBtn(Icons.layers, 'Layers', showLayersPanel), const SizedBox(width: 8),
              _buildTopBtn(Icons.auto_stories, 'Pages', showPagesPanel), const SizedBox(width: 8),
              _buildTopBtn(Icons.undo, 'Undo', undoAction), const SizedBox(width: 8),
              _buildTopBtn(Icons.redo, 'Redo', redoAction), const SizedBox(width: 5),
            ]
          ),
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
          if (!_isExporting)
            Container(
              padding: const EdgeInsets.only(left: 15, top: 10, bottom: 5),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _isCanvasLocked = !_isCanvasLocked); },
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Icon(_isCanvasLocked ? Icons.lock : Icons.lock_open, color: _isCanvasLocked ? Colors.redAccent : Colors.black87, size: 18)),
                  ), const SizedBox(width: 12),
                  InkWell(
                    onTap: () { HapticFeedback.selectionClick(); _transformController.value = Matrix4.identity(); },
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Icon(Icons.zoom_out_map, color: Colors.black87, size: 18)),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: GestureDetector(
              onTap: () { setState(() => selectedId = null); _triggerCanvasUpdate(); }, 
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
                                  color: bgImageBytes != null || bgGradient != null ? null : (pageColor == Colors.transparent ? null : pageColor),
                                  decoration: bgImageBytes != null 
                                      ? BoxDecoration(image: DecorationImage(image: MemoryImage(bgImageBytes!), fit: BoxFit.cover))
                                      : (bgGradient != null ? BoxDecoration(gradient: LinearGradient(colors: bgGradient!)) : (pageColor == Colors.transparent ? const BoxDecoration(image: DecorationImage(image: AssetImage('assets/transparent_pattern.png'), repeat: ImageRepeat.repeat)) : null)),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
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
                                        bool isSel = (e.id == selectedId) && !_isExporting;
                                        
                                        Matrix4 matrix = Matrix4.identity()
                                          ..setEntry(3, 2, 0.002) 
                                          ..rotateX(e.pitch)
                                          ..rotateY(e.yaw)
                                          ..rotateZ(e.angle);
                                          
                                        if (e.flipX) matrix.rotateY(pi);
                                        if (e.flipY) matrix.rotateX(pi);

                                        List<BoxShadow> boxShadows = [];
                                        if (e.hasShadow && !e.isText && !e.isBorder && !e.isTable) {
                                          boxShadows.add(BoxShadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY)));
                                        }

                                        Border? universalBorder;
                                        if (e.hasStroke && !e.isText && !e.isBorder && !e.isTable) {
                                          universalBorder = Border.all(color: e.strokeColor, width: e.strokeWidth);
                                        }

                                        double currentWidth = _getElWidth(e); 
                                        double currentHeight = _getElHeight(e);
                                        
                                        Widget contentWidget;

                                        if (e.isBorder) {
                                          return Positioned.fill(
                                            child: GestureDetector(
                                              onTap: () { if(!e.isLocked) { setState(() => selectedId = e.id); _triggerCanvasUpdate(); } },
                                              child: Transform(
                                                transform: matrix, alignment: Alignment.center,
                                                child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: e.elementColor, width: e.borderWidth), borderRadius: BorderRadius.circular(10), color: isSel && !_isExporting ? Colors.purple.withOpacity(0.05) : Colors.transparent))
                                              )
                                            )
                                          );
                                        } else if (e.isTable && e.tableData != null) {
                                          contentWidget = CustomTableWidget(tableData: e.tableData!, width: currentWidth, height: currentHeight, fontFamily: e.fontFamily, textColor: e.textColor, borderColor: e.strokeColor, hasBorder: e.hasStroke);
                                        } else if (e.isShape) {
                                          contentWidget = Container(width: currentWidth, height: currentHeight, decoration: BoxDecoration(color: e.elementColor, boxShadow: boxShadows.isNotEmpty ? boxShadows : null, border: universalBorder, borderRadius: BorderRadius.circular(e.cornerRadius)));
                                        } else if (e.imageBytes != null) {
                                          Widget img = Image.memory(e.imageBytes!, width: currentWidth, height: currentHeight, fit: BoxFit.fill);
                                          if (e.isTinted) img = Image.memory(e.imageBytes!, width: currentWidth, height: currentHeight, fit: BoxFit.fill, color: e.elementColor, colorBlendMode: BlendMode.srcIn);
                                          else {
                                            if (e.imageFilter == 1) img = ColorFiltered(colorFilter: const ColorFilter.matrix(AppConstants.grayscaleMatrix), child: img);
                                            else if (e.imageFilter == 2) img = ColorFiltered(colorFilter: const ColorFilter.matrix(AppConstants.sepiaMatrix), child: img);
                                            else if (e.imageFilter == 3) img = ColorFiltered(colorFilter: const ColorFilter.matrix(AppConstants.invertMatrix), child: img);
                                          }
                                          if (e.blendModeIndex != 0) img = ColorFiltered(colorFilter: ColorFilter.mode(Colors.transparent, AppConstants.blendModes[e.blendModeIndex]), child: img);
                                          Widget clippedImg = img;
                                          if (e.clipShape == 1) clippedImg = Container(clipBehavior: Clip.antiAlias, decoration: const BoxDecoration(shape: BoxShape.circle), child: img);
                                          else if (e.clipShape == 2) clippedImg = ClipPath(clipper: TriangleClipper(), child: img);
                                          else if (e.clipShape == 3) clippedImg = ClipPath(clipper: StarClipper(), child: img);
                                          else if (e.clipShape == 4) clippedImg = ClipPath(clipper: HexagonClipper(), child: img);
                                          contentWidget = Container(width: currentWidth, height: e.clipShape == 1 ? currentWidth : currentHeight, decoration: BoxDecoration(borderRadius: e.clipShape == 0 ? BorderRadius.circular(e.cornerRadius) : null, boxShadow: boxShadows.isNotEmpty ? boxShadows : null, border: universalBorder), child: clippedImg);
                                        } else {
                                          List<Shadow> textShadows = [];
                                          if (e.hasShadow) textShadows.add(Shadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY)));
                                          Widget buildTextWidget(Color c, [List<Shadow>? shadow]) {
                                            TextStyle st = TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, letterSpacing: e.letterSpacing, color: c, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, height: e.lineHeight, wordSpacing: e.wordSpacing, shadows: shadow);
                                            if (e.textCurveRadius != 0) return CurvedTextWidget(text: e.content, radius: e.textCurveRadius, style: st, letterSpacing: e.letterSpacing);
                                            return SizedBox(width: currentWidth, child: Text(e.content, textAlign: e.textAlign, softWrap: true, textDirection: TextDirection.rtl, style: st.copyWith(letterSpacing: e.letterSpacing)));
                                          }
                                          List<Widget> blockLayers = [];
                                          if (e.text3dDepth > 0) {
                                            for (double i = e.text3dDepth; i > 0; i -= 1.0) blockLayers.add(Transform.translate(offset: Offset(i, i), child: buildTextWidget(e.text3dColor)));
                                          }
                                          
                                          Widget mainTxt = buildTextWidget(e.textGradient != null ? Colors.white : e.textColor, textShadows.isNotEmpty ? textShadows : null);
                                          if (e.textGradient != null) mainTxt = ShaderMask(shaderCallback: (bounds) => LinearGradient(colors: e.textGradient!).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)), child: mainTxt);
                                          if (e.textTextureBytes != null) mainTxt = TextureTextWrapper(textureBytes: e.textTextureBytes, child: mainTxt);
                                          
                                          blockLayers.add(mainTxt);
                                          Widget txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: blockLayers);
                                          if (e.hasStroke) {
                                            TextStyle stStroke = TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, letterSpacing: e.letterSpacing, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = e.strokeWidth..color = e.strokeColor, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, height: e.lineHeight, wordSpacing: e.wordSpacing);
                                            Widget strokeTxt = e.textCurveRadius != 0 ? CurvedTextWidget(text: e.content, radius: e.textCurveRadius, style: stStroke, letterSpacing: e.letterSpacing) : Text(e.content, textAlign: e.textAlign, softWrap: true, textDirection: TextDirection.rtl, style: stStroke.copyWith(letterSpacing: e.letterSpacing));
                                            txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [strokeTxt, txt]);
                                          }
                                          if (e.textBgColor != null) txt = Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: e.textBgColor, borderRadius: BorderRadius.circular(e.textBgRadius)), child: txt);
                                          contentWidget = txt; 
                                        }

                                        if (_isExporting) { 
                                          return Positioned(
                                            left: e.x, top: e.y, 
                                            child: Transform(transform: matrix, alignment: Alignment.center, child: Opacity(opacity: e.opacity, child: contentWidget))
                                          );
                                        }
                                        
                                        // 100% PRO SELECTION BOX WITH FLAWLESS HANDLES
                                        return Positioned(
                                          left: e.x - 12, 
                                          top: e.y - 12,
                                          child: Transform(
                                            transform: matrix, alignment: Alignment.center,
                                            child: SizedBox(
                                              width: currentWidth + 24, height: currentHeight + 24,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  
                                                  // DRAG LAYER
                                                  Positioned(
                                                    left: 12, top: 12,
                                                    width: currentWidth, height: currentHeight,
                                                    child: GestureDetector(
                                                      behavior: HitTestBehavior.opaque,
                                                      onTap: () {
                                                        if (e.isLocked) {
                                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh Layer Lock hai.', style: TextStyle(fontFamily: 'JameelNoori')), duration: Duration(seconds: 1)));
                                                        } else {
                                                          setState(() => selectedId = e.id);
                                                          _triggerCanvasUpdate();
                                                        }
                                                      },
                                                      onPanStart: (d) { if(!e.isLocked) saveState(); },
                                                      onPanUpdate: (d) {
                                                        if(!e.isLocked && selectedId == e.id) {
                                                          setState(() { 
                                                            e.x += d.delta.dx; 
                                                            e.y += d.delta.dy; 
                                                            if (e.groupId != null) {
                                                              for (var other in elements) {
                                                                if (other.id != e.id && other.groupId == e.groupId && !other.isLocked) {
                                                                  other.x += d.delta.dx; other.y += d.delta.dy;
                                                                }
                                                              }
                                                            }
                                                          });
                                                          _triggerCanvasUpdate();
                                                        }
                                                      },
                                                      child: Container(
                                                        decoration: isSel ? BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5)) : null,
                                                        child: Opacity(opacity: e.opacity, child: contentWidget)
                                                      )
                                                    )
                                                  ),

                                                  // WORKABLE HANDLES
                                                  if (isSel) ...[
                                                    // Edge Pills
                                                    Positioned(top: 12 - 14, left: 12 + currentWidth/2 - 22, child: _buildPillHandle(true, (d) => _resizeEdge(d, 'T', e))),
                                                    Positioned(bottom: 12 - 14, left: 12 + currentWidth/2 - 22, child: _buildPillHandle(true, (d) => _resizeEdge(d, 'B', e))),
                                                    Positioned(left: 12 - 14, top: 12 + currentHeight/2 - 22, child: _buildPillHandle(false, (d) => _resizeEdge(d, 'L', e))),
                                                    Positioned(right: 12 - 14, top: 12 + currentHeight/2 - 22, child: _buildPillHandle(false, (d) => _resizeEdge(d, 'R', e))),

                                                    // Corner Circles (Scale)
                                                    Positioned(top: 12 - 16, left: 12 - 16, child: _buildCircleHandle((d) => _scaleCorner(d, e))),
                                                    Positioned(top: 12 - 16, right: 12 - 16, child: _buildCircleHandle((d) => _scaleCorner(d, e))),
                                                    Positioned(bottom: 12 - 16, left: 12 - 16, child: _buildCircleHandle((d) => _scaleCorner(d, e))),
                                                    Positioned(bottom: 12 - 16, right: 12 - 16, child: _buildCircleHandle((d) => _scaleCorner(d, e))),

                                                    // Rotate Handle (Top Right)
                                                    Positioned(
                                                      top: 12 - 45, right: 12 - 45, 
                                                      child: _buildIconHandle(Icons.rotate_right, (d) => _rotateHandle(d, e))
                                                    ),
                                                    
                                                    // Extra Scale Handle (Bottom Left)
                                                    Positioned(
                                                      bottom: 12 - 45, left: 12 - 45, 
                                                      child: _buildIconHandle(Icons.open_in_full, (d) => _scaleCorner(d, e))
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
      bottomNavigationBar: SafeArea(child: Container(color: Colors.white, child: hasSelection ? _buildSelectedToolBar(sel!) : _buildDefaultBottomBar())),
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
                  _buildToolBtn(Icons.grid_on, 'Grid', () => setState(() => _showGrid = !_showGrid)), 
                  _buildToolBtn(Icons.aspect_ratio, 'Resize', _showResizeModal), 
                  _buildToolBtn(Icons.image, 'BG Image', _setCanvasBackground),
                  _buildToolBtn(Icons.format_color_fill, 'BG Color', _showCanvasBgColorModal),
                  _buildToolBtn(Icons.gradient, 'BG Gradient', _showCanvasBgGradientModal),
                  _buildToolBtn(Icons.layers_clear, 'Clear BG', () { saveState(); setState((){ pageColor = Colors.transparent; bgImageBytes = null; bgGradient = null; }); _triggerCanvasUpdate(); }), 
                ],
              ),
            ),
          ),
        ],
      ),
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
                if (sel.isText || sel.isTable) _buildToolBtn(Icons.text_fields, 'Size', () => showSizeSliderModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.height, 'Spacing', () => showSpacingModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.format_bold, 'Bold', () { saveState(); setState(() => sel.isBold = !sel.isBold); _triggerCanvasUpdate(); }),
                if (sel.isText) _buildToolBtn(Icons.format_color_fill, 'Text BG', () => _showTextBgPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.gradient, 'Gradient', () => _showGradientPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.data_usage, 'Curve', () => _showCurveModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.texture, 'Texture', () => _addTextureToText(sel)),
                if (sel.isText && sel.textTextureBytes != null) _buildToolBtn(Icons.layers_clear, 'Clear Texture', () { saveState(); setState(() => sel.textTextureBytes = null); _triggerCanvasUpdate(); }),
                if (sel.isText) _buildToolBtn(Icons.format_align_left, 'Align Text', () => _toggleAlignment(sel)),
                _buildToolBtn(Icons.center_focus_strong, 'Position', () => _showAlignmentModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.view_in_ar_outlined, '3D Block', () => _show3DBlockModal(sel)),
                if (sel.imageBytes != null) _buildToolBtn(Icons.format_paint, 'Tint Color', () { saveState(); setState(() => sel.isTinted = !sel.isTinted); _triggerCanvasUpdate(); if(sel.isTinted)_showColorPickerModal(sel); }),
                if (sel.imageBytes != null) _buildToolBtn(Icons.auto_awesome_motion, 'Blend', () => _showBlendModeModal(sel)),
                if (!sel.isBorder) _buildToolBtn(Icons.border_color, 'Stroke', () => _showAdvancedStrokeModal(sel)),
                if (!sel.isBorder && !sel.isTable) _buildToolBtn(Icons.brightness_6, 'Shadow', () => _showAdvancedShadowModal(sel)),
                if (!sel.isText && !sel.isBorder && !sel.isTable) _buildToolBtn(Icons.rounded_corner, 'Radius', () => _showRadiusModal(sel)),
                if (sel.imageBytes != null && !sel.isTinted) _buildToolBtn(Icons.photo_filter, 'Filters', () => _showImageFiltersModal(sel)),
                if (sel.imageBytes != null) _buildToolBtn(Icons.crop, 'Crop Shape', () => _showShapeClipModal(sel)),
                if (sel.isTable) _buildToolBtn(Icons.table_rows, 'Edit Table', () => _showTableEditorModal(sel)),
                _buildToolBtn(Icons.flip, 'Flip H', () { saveState(); setState(() => sel.flipX = !sel.flipX); _triggerCanvasUpdate(); }),
                _buildToolBtn(Icons.flip_camera_android, 'Flip V', () { saveState(); setState(() => sel.flipY = !sel.flipY); _triggerCanvasUpdate(); }),
                _buildToolBtn(Icons.opacity, 'Opacity', () { saveState(); setState(() => sel.opacity = sel.opacity == 1.0 ? 0.5 : 1.0); _triggerCanvasUpdate(); }),
                _buildToolBtn(Icons.rotate_right, 'Rotate', () => showRotationModal(sel)), 
                _buildToolBtn(Icons.view_in_ar, 'Perspective', () => show3DModal(sel)), 
                _buildToolBtn(Icons.open_with, 'Nudge', () => showNudgeModal(sel)),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // PROFESSIONAL BOTTOM MENU ROW (DUPLICATE/DELETE HERE)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                InkWell(onTap: () { setState(() => selectedId = null); _triggerCanvasUpdate(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6)), borderRadius: BorderRadius.circular(20)), child: Row(children: const [Icon(Icons.remove_circle_outline, color: Color(0xFF8B5CF6), size: 18), SizedBox(width: 5), Text('DESELECT', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12))]))),
                const SizedBox(width: 15),
                _buildToolBtn(Icons.copy, 'Duplicate', duplicateSelected),
                _buildToolBtn(Icons.delete_outline, 'Delete', deleteSelected),
                const SizedBox(width: 15),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 15),
                if (sel.isText) _buildToolBtn(Icons.edit, 'Edit', () => _showTextComposerDialog(existingElement: sel)),
                if (sel.isText || sel.isTable) _buildToolBtn(Icons.font_download, 'Font', () => showFontPickerModal(sel)),
                if (sel.isText || sel.isBorder || sel.isShape || sel.isTinted || sel.isTable) _buildToolBtn(Icons.palette, 'Color', () => _showColorPickerModal(sel)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTopBtn(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade800, size: 22), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))])); }
  Widget _buildToolBtn(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade700, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700))]))); }
  
  void _showTextComposerDialog({DesignElement? existingElement}) {
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? '');
    bool isRTL = existingElement?.textAlign == TextAlign.right ? true : (existingElement?.textAlign == TextAlign.left ? false : true);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) {
      return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
        return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.75, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20),
          Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)), padding: const EdgeInsets.all(4), child: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(onTap: () => setModalState(() => isRTL = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: !isRTL ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: !isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null), child: Text('English', style: TextStyle(fontWeight: !isRTL ? FontWeight.w900 : FontWeight.w600, color: !isRTL ? const Color(0xFF6366F1) : Colors.grey.shade500)))),
            GestureDetector(onTap: () => setModalState(() => isRTL = true), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: isRTL ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null), child: Text('اردو', style: TextStyle(fontWeight: isRTL ? FontWeight.w900 : FontWeight.w600, color: isRTL ? const Color(0xFF10B981) : Colors.grey.shade500, fontFamily: 'JameelNoori', fontSize: 16)))),
          ])), const SizedBox(height: 20),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: isRTL ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF6366F1).withOpacity(0.3), width: 1.5), borderRadius: BorderRadius.circular(16)), child: TextField(controller: controller, maxLines: null, textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr, textAlign: isRTL ? TextAlign.right : TextAlign.left, style: TextStyle(fontFamily: isRTL ? 'JameelNoori' : null, fontSize: isRTL ? 28 : 20, height: 1.5), decoration: InputDecoration(border: InputBorder.none, hintText: isRTL ? 'یہاں لکھیں...' : 'Type here...', hintTextDirection: isRTL ? TextDirection.rtl : TextDirection.ltr)))), const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            InkWell(onTap: () async { ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain); if (data != null && data.text != null) controller.text += data.text!; }, child: Column(children: const [Icon(Icons.paste, color: Color(0xFF8B5CF6)), Text('Paste', style: TextStyle(fontSize: 12))])),
            InkWell(onTap: () => controller.clear(), child: Column(children: const [Icon(Icons.delete_outline, color: Color(0xFF8B5CF6)), Text('Clear', style: TextStyle(fontSize: 12))])),
          ]), const SizedBox(height: 20),
          Row(children: [
            Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)))), const SizedBox(width: 15),
            Expanded(flex: 2, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: isRTL ? const Color(0xFF10B981) : const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () {
              if (controller.text.isNotEmpty) {
                saveState();
                double calcW = (controller.text.length * (isRTL ? 28.0 : 20.0) * 0.6) + 40;
                if(calcW > MediaQuery.of(context).size.width - 60) calcW = MediaQuery.of(context).size.width - 60;
                if(calcW < 80) calcW = 80;
                if (existingElement != null) { setState(() { existingElement.content = controller.text; existingElement.textAlign = isRTL ? TextAlign.right : TextAlign.left; }); } 
                else { var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, width: calcW); newEl.textAlign = isRTL ? TextAlign.right : TextAlign.left; setState(() { elements.add(newEl); selectedId = newEl.id; }); }
                _triggerCanvasUpdate(); Navigator.pop(context);
              }
            }, icon: const Icon(Icons.check_circle_outline, color: Colors.white), label: const Text('Add to Design', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
          ])
        ])));
      });
    });
  }

  void _addTable() { saveState(); setState(() { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: 'Table', width: 300, height: 150, isText: false, isTable: true, tableData: [['Column 1', 'Column 2'], ['Data 1', 'Data 2']])); selectedId = elements.last.id; }); _triggerCanvasUpdate(); }
  Future<void> addImageFromGallery({bool fromModal = false}) async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 80, content: '', imageBytes: bytes, isText: false, width: 250, height: 250))); _triggerCanvasUpdate(); } } catch (e) { debugPrint("Gallery Error: $e"); } if (fromModal && Navigator.canPop(context)) { Navigator.pop(context); } }
  Future<void> _setCanvasBackground() async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); setState(() { bgImageBytes = bytes; bgGradient = null; pageColor = Colors.white; }); _triggerCanvasUpdate(); } } catch (e) { debugPrint("BG Image Error: $e"); } }
  Future<void> _addTextureToText(DesignElement sel) async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => sel.textTextureBytes = bytes); _triggerCanvasUpdate(); } } catch (e) {} }

  void showAddNewModal() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.65, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, children: [
      _buildGridItem(Icons.image, 'Gallery Pic', Colors.blue.shade100, Colors.blue, () => addImageFromGallery(fromModal: true)),
      _buildGridItem(Icons.gradient, 'Backgrounds', Colors.indigo.shade100, Colors.indigo, () { Navigator.pop(context); _showCanvasBgGradientModal(); }),
      _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade100, Colors.teal, () { Navigator.pop(context); Navigator.pop(context); }),
      _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade100, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }),
      _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade100, Colors.amber.shade800, () { Navigator.pop(context); }),
      _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade100, Colors.pink, () { Navigator.pop(context); }),
      _buildGridItem(Icons.table_chart, 'Table', Colors.cyan.shade100, Colors.cyan.shade800, () { Navigator.pop(context); _addTable(); })
    ]))])));
  }

  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: iconColor, size: 28)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)])); }

  void _showTableEditorModal(DesignElement sel) {
    if (sel.tableData == null) return; List<List<String>> tempTable = []; for (var row in sel.tableData!) { tempTable.add(List.from(row)); }
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.85, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Edit Table ٹیبل ایڈٹ کریں', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Text('MS Word / InPage Style', style: TextStyle(fontSize: 12, color: Colors.grey)), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(onPressed: () { setModalState(() { List<String> newRow = List.generate(tempTable[0].length, (i) => 'New Data'); tempTable.add(newRow); }); }, icon: const Icon(Icons.table_rows), label: const Text('+ Add Row')), ElevatedButton.icon(onPressed: () { setModalState(() { for(int i=0; i<tempTable.length; i++) { tempTable[i].add('New Col'); } }); }, icon: const Icon(Icons.view_column), label: const Text('+ Add Col'))]), const SizedBox(height: 10), Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: tempTable.asMap().entries.map((rowEntry) { int rowIndex = rowEntry.key; List<String> row = rowEntry.value; return Row(children: [...row.asMap().entries.map((colEntry) { int colIndex = colEntry.key; return Container(width: 100, margin: const EdgeInsets.all(4), child: TextField(controller: TextEditingController(text: tempTable[rowIndex][colIndex]), textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'JameelNoori'), decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)), onChanged: (val) { tempTable[rowIndex][colIndex] = val; })); }).toList(), if (tempTable.length > 1) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () { setModalState(() { tempTable.removeAt(rowIndex); }); })]); }).toList())))), const SizedBox(height: 15), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: () { saveState(); setState(() { sel.tableData = tempTable; }); _triggerCanvasUpdate(); Navigator.pop(context); }, child: const Text('Update Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))]))); }); });
  }

}
