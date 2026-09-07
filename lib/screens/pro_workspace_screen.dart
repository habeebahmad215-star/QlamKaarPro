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
  const ProWorkspaceScreen({Key? key, this.project}) : super(key: key);
  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  
  bool _isCanvasLocked = false;
  bool _showGrid = false; 
  bool _snapV = false;
  bool _snapH = false;

  late String projectId;
  late String projectName;
  List<DesignPage> pages = [];
  int currentPageIndex = 0;
  List<List<DesignElement>> undoStack = [];
  List<List<DesignElement>> redoStack = [];
  String? selectedId;
  
  List<String> availableFonts = ['JameelNoori', 'Amiri', 'Bombay', 'Mehr'];
  List<String> customFonts = [];

  final ImagePicker _picker = ImagePicker();
  bool _isExporting = false;

  double _initialRotation = 0.0;
  double _initialWidth = 0.0;
  double _initialHeight = 0.0;
  double _initialFontSize = 0.0;
  double _initialX = 0.0;
  double _initialY = 0.0;
  Offset _initialFocalPoint = Offset.zero;
  Map<String, Map<String, dynamic>> _initialGroupStates = {};

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

  void saveState() { undoStack.add(elements.map((e) => e.clone()).toList()); redoStack.clear(); }
  void undoAction() { if (undoStack.isNotEmpty) { redoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = undoStack.removeLast(); selectedId = null; }); } }
  void redoAction() { if (redoStack.isNotEmpty) { undoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = redoStack.removeLast(); selectedId = null; }); } }

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
      pages = [DesignPage(title: 'Page 1', elements: [DesignElement(id: 'demo1', x: 40, y: 150, content: 'مدرسہ اسلامیہ نصیرالعلوم', width: 280)], pageColor: Colors.white)];
    }
  }

  @override
  void dispose() { _transformController.dispose(); super.dispose(); }

  Future<void> _saveProjectLocally() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStrings = prefs.getStringList('qalamkaar_projects') ?? [];
    ProjectModel p = ProjectModel(id: projectId, name: projectName, pages: pages, lastModified: DateTime.now().millisecondsSinceEpoch);
    savedStrings.removeWhere((str) => jsonDecode(str)['id'] == projectId); 
    savedStrings.add(jsonEncode(p.toJson())); 
    await prefs.setStringList('qalamkaar_projects', savedStrings);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project saved successfully! 🎉', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Color(0xFF10B981)));
  }

  void _showExportMenu() { 
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), 
      builder: (context) => Container(height: 320, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Export Design', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), 
        Divider(color: Colors.grey.shade200), const SizedBox(height: 10), 
        _buildExportOption(Icons.image, 'Save as JPG', 'Solid Background', Colors.blue, () { Navigator.pop(context); _captureAndSave('JPG'); }), const SizedBox(height: 10), 
        _buildExportOption(Icons.layers_clear, 'Save as PNG', 'Transparent Image', Colors.purple, () { Navigator.pop(context); _captureAndSave('PNG'); }), const SizedBox(height: 10), 
        _buildExportOption(Icons.picture_as_pdf, 'Save as HD PDF', 'High Quality Document', Colors.red, () { Navigator.pop(context); _captureAndSave('PDF'); })
      ]))
    ); 
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) { 
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)), Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey))])), Icon(Icons.arrow_forward_ios, color: color, size: 14)]))); 
  }

  Future<void> _captureAndSave(String format) async { 
    setState(() { selectedId = null; _isExporting = true; }); 
    await Future.delayed(const Duration(milliseconds: 400)); 
    try { 
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary; 
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png); 
      Uint8List pngBytes = byteData!.buffer.asUint8List(); 
      if (format == 'JPG' || format == 'PNG') { 
        final result = await ImageGallerySaver.saveImage(pngBytes, quality: 100, name: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}"); 
        if (mounted && result != null && result['isSuccess'] == true) { showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 50), const SizedBox(height: 15), const Text('Saved to Gallery!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))]))); } 
      } else if (format == 'PDF') { 
        final pdf = pw.Document(); 
        final imagePdf = pw.MemoryImage(pngBytes); 
        pdf.addPage(pw.Page(pageFormat: PdfPageFormat(image.width.toDouble(), image.height.toDouble()), margin: pw.EdgeInsets.zero, build: (pw.Context context) { return pw.Image(imagePdf, fit: pw.BoxFit.cover); })); 
        Uint8List pdfBytes = await pdf.save(); 
        await Printing.sharePdf(bytes: pdfBytes, filename: "QalamKaarPro_Print_${DateTime.now().millisecondsSinceEpoch}.pdf"); 
      } 
    } catch (e) { debugPrint('Export Error: $e'); } finally { setState(() { _isExporting = false; }); } 
  }

  void _showPoetryLibrary(TextEditingController textController) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) {
      return Container(height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(15), child: DefaultTabController(length: AppConstants.urduPoetryLibrary.keys.length, child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Urdu Library', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]),
        TabBar(isScrollable: true, labelColor: const Color(0xFF8B5CF6), unselectedLabelColor: Colors.grey, indicatorColor: const Color(0xFF8B5CF6), tabs: AppConstants.urduPoetryLibrary.keys.map((k) => Tab(text: k)).toList()),
        const SizedBox(height: 10),
        Expanded(child: TabBarView(children: AppConstants.urduPoetryLibrary.keys.map((category) {
          return ListView.builder(itemCount: AppConstants.urduPoetryLibrary[category]!.length, itemBuilder: (context, index) {
            String text = AppConstants.urduPoetryLibrary[category]![index];
            return Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)), margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(title: Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 18, height: 1.5)), onTap: () { textController.text = text; Navigator.pop(context); }));
          });
        }).toList()))
      ])));
    });
  }

  void _showTashkeelModal(TextEditingController controller) {
    final List<String> tashkeelList = ['َ', 'ِ', 'ُ', 'ً', 'ٍ', 'ٌ', 'ّ', 'ْ', 'ٰ', 'ٓ', 'ے', 'ۓ', 'ﷺ', 'ؓ', 'ؒ', 'ﷻ', 'ﷲ', 'اکبر', 'جل جلالہ', 'بسم اللہ'];
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) {
      return Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tashkeel & Symbols', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: tashkeelList.length, itemBuilder: (context, index) { return InkWell(onTap: () { controller.text += tashkeelList[index]; Navigator.pop(context); }, borderRadius: BorderRadius.circular(8), child: Container(decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), alignment: Alignment.center, child: Text(tashkeelList[index], style: const TextStyle(fontSize: 22, fontFamily: 'JameelNoori', color: Colors.black87)))); }))]));
    });
  }

  void _showTextComposerDialog({DesignElement? existingElement}) { 
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? ''); 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(20), child: Column(children: [Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: const Text('English', style: TextStyle(color: Colors.grey, fontSize: 12))), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]), child: const Text('اردو', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)))])), const SizedBox(height: 12), Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50), child: TextField(controller: controller, maxLines: null, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 24), decoration: const InputDecoration(border: InputBorder.none, hintText: 'یہاں لکھیں...', hintTextDirection: TextDirection.rtl)))), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildComposerTool(Icons.paste, 'Paste', () async { ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain); if (data != null && data.text != null) controller.text += data.text!; }), _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()), _buildComposerTool(Icons.auto_stories, 'شاعری', () => _showPoetryLibrary(controller)), _buildComposerTool(Icons.format_quote, 'اعراب', () => _showTashkeelModal(controller))]), const SizedBox(height: 16), Row(children: [Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: Colors.grey.shade300)), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)))), const SizedBox(width: 10), Expanded(flex: 2, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { if (controller.text.isNotEmpty) { saveState(); if (existingElement != null) { setState(() => existingElement.content = controller.text); } else { var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, width: 280); setState(() { elements.add(newEl); selectedId = newEl.id; }); } } Navigator.pop(context); }, icon: const Icon(Icons.check, color: Colors.white, size: 16), label: const Text('Add to design', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))))])])))); 
  }

  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [Icon(icon, color: const Color(0xFF8B5CF6), size: 20), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87))]))); }

  void showAddNewModal() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.60, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))), padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [_buildGridItem(Icons.image, 'Gallery', Colors.blue.shade50, Colors.blue, addImageFromGallery), _buildGridItem(Icons.gradient, 'Backgrounds', Colors.indigo.shade50, Colors.indigo, () { Navigator.pop(context); _showCanvasBgGradientModal(); }), _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade50, Colors.teal, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())); }), _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade50, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }), _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade50, Colors.amber.shade800, () => showGenericStockModal('Borders', 'royal_islamic', Icons.border_outer)), _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade50, Colors.pink, () => showGenericStockModal('Shapes', 'shape_rect', Icons.category))]))]))); }
  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) { return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center)]))); }

  Future<void> addImageFromGallery() async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 80, content: '', imageBytes: bytes, isText: false, width: 250, height: 250))); } } catch (e) {} Navigator.pop(context); }
  Future<void> _setCanvasBackground() async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); setState(() { bgImageBytes = bytes; bgGradient = null; pageColor = Colors.white; }); } } catch (e) { debugPrint("BG Image Error: $e"); } }
  Future<void> _addTextureToText(DesignElement sel) async { try { final XFile? image = await _picker.pickImage(source: ImageSource.gallery); if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => sel.textTextureBytes = bytes); } } catch (e) {} }

  void showGenericStockModal(String categoryTitle, String styleName, IconData categoryIcon) { Navigator.pop(context); List<Map<String, dynamic>> stockList = []; List<Color> themeColors = [const Color(0xFFD4AF37), const Color(0xFF8B5CF6), const Color(0xFF047857), const Color(0xFF1E3A8A)]; for (int i = 1; i <= 50; i++) stockList.add({'title': '$categoryTitle #$i', 'style': styleName, 'color': themeColors[(i - 1) % themeColors.length], 'icon': categoryIcon}); showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.70, padding: const EdgeInsets.all(16), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 12), Text(categoryTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))), Divider(color: Colors.grey.shade200), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4), itemCount: stockList.length, itemBuilder: (context, index) { var item = stockList[index]; return InkWell(onTap: () { saveState(); setState(() { if (styleName.contains('shape') || styleName == 'badge') { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 90, y: 180, content: styleName == 'badge' ? 'circle' : 'rectangle', isText: false, isShape: true, elementColor: item['color'], width: 220, height: 90)); } else { elements.insert(0, DesignElement(id: Random().nextInt(10000).toString(), x: 0, y: 0, content: item['title'], isText: false, isBorder: true, borderStyle: styleName, elementColor: item['color'], borderWidth: 5.0)); } }); Navigator.pop(context); }, borderRadius: BorderRadius.circular(10), child: Container(decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: (item['color'] as Color).withOpacity(0.3), width: 1.0)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item['icon'], color: item['color'], size: 24), const SizedBox(height: 6), Text(item['title'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: item['color']))]))); }))] ))); }

  void deleteSelected() { if (selectedId != null) { saveState(); setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; }); } }
  void duplicateSelected() { if (selectedId != null) { saveState(); DesignElement sel = elements.firstWhere((e) => e.id == selectedId); setState(() { var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20; elements.add(newEl); selectedId = newEl.id; }); } }
  void bringForward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx < elements.length - 1) setState(() { var item = elements.removeAt(idx); elements.insert(idx + 1, item); }); }
  void sendBackward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx > 0) setState(() { var item = elements.removeAt(idx); elements.insert(idx - 1, item); }); }
  void _toggleAlignment(DesignElement sel) { saveState(); setState(() { sel.textAlign = (sel.textAlign == TextAlign.right) ? TextAlign.center : (sel.textAlign == TextAlign.center ? TextAlign.left : TextAlign.right); }); }

  void _pickCustomGradColor(DesignElement sel, int colorNum, StateSetter parentSetState) { showModalBottomSheet(context: context, builder: (ctx) => Container(height: 300, padding: const EdgeInsets.all(20), child: Column(children: [const Text('Pick a Color', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: AppConstants.proColorPalette.length, itemBuilder: (ctx, index) { return InkWell(onTap: () { if(colorNum == 1) sel.customGradColor1 = AppConstants.proColorPalette[index]; else sel.customGradColor2 = AppConstants.proColorPalette[index]; parentSetState((){}); Navigator.pop(ctx); }, child: Container(decoration: BoxDecoration(color: AppConstants.proColorPalette[index], shape: BoxShape.circle, border: Border.all(color: Colors.black12)))); }))]))); }
  
  void _showCanvasBgColorModal() { TextEditingController hexCtrl = TextEditingController(); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: TextField(controller: hexCtrl, style: const TextStyle(fontSize: 12), decoration: InputDecoration(hintText: 'Hex: #FF0000', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)))), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { String hex = hexCtrl.text.replaceAll('#', ''); if(hex.length == 6) hex = 'FF$hex'; if(hex.length == 8) { saveState(); setState((){ pageColor = Color(int.parse('0x$hex')); bgImageBytes = null; bgGradient = null; }); setModalState((){}); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 12)))]))), Divider(color: Colors.grey.shade200), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSelected = pageColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { pageColor = c; bgImageBytes = null; bgGradient = null; }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 4)] : null), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); }))]))); }); }); }
  void _showCanvasBgGradientModal() { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Gradient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0), itemCount: AppConstants.proGradientPalette.length, itemBuilder: (context, index) { List<Color> g = AppConstants.proGradientPalette[index]; return GestureDetector(onTap: () { saveState(); setState(() { bgGradient = g; bgImageBytes = null; pageColor = Colors.white; }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)))); }))])); }); }); }
  void _showTextBgPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Text Background', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), ListTile(leading: const Icon(Icons.block, size: 20), title: const Text('Remove Background', style: TextStyle(fontSize: 13)), dense: true, onTap: () { saveState(); setState(() { sel.textBgColor = null; }); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSelected = sel.textBgColor?.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { sel.textBgColor = c; }); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); }))])); }); }); }
  void _showGradientPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 500, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Text Gradient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Custom Gradient:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [InkWell(onTap: () => _pickCustomGradColor(sel, 1, setModalState), child: Container(width: 35, height: 35, decoration: BoxDecoration(color: sel.customGradColor1 ?? Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.black12)))), const Icon(Icons.add, size: 16), InkWell(onTap: () => _pickCustomGradColor(sel, 2, setModalState), child: Container(width: 35, height: 35, decoration: BoxDecoration(color: sel.customGradColor2 ?? Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.black12)))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { if(sel.customGradColor1 != null && sel.customGradColor2 != null) { saveState(); setState(() => sel.textGradient = [sel.customGradColor1!, sel.customGradColor2!]); setModalState((){}); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 11)))])])), const SizedBox(height: 8), ListTile(leading: const Icon(Icons.block, size: 20), title: const Text('Clear Gradient', style: TextStyle(fontSize: 13)), dense: true, onTap: () { saveState(); setState(() { sel.textGradient = null; }); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0), itemCount: AppConstants.proGradientPalette.length, itemBuilder: (context, index) { List<Color> g = AppConstants.proGradientPalette[index]; return GestureDetector(onTap: () { saveState(); setState(() { sel.textGradient = g; }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)))); }))])); }); }); }
  void _showColorPickerModal(DesignElement sel) { TextEditingController hexCtrl = TextEditingController(); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { Color currentColor = sel.isText ? sel.textColor : sel.elementColor; return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Color Picker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: TextField(controller: hexCtrl, style: const TextStyle(fontSize: 12), decoration: InputDecoration(hintText: 'Hex: #FF0000', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10)))), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { String hex = hexCtrl.text.replaceAll('#', ''); if(hex.length == 6) hex = 'FF$hex'; if(hex.length == 8) { saveState(); setState((){ if(sel.isText){ sel.textColor = Color(int.parse('0x$hex')); sel.textGradient = null; } else { sel.elementColor = Color(int.parse('0x$hex')); } }); setModalState((){}); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 12)))]))), Divider(color: Colors.grey.shade200), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSelected = currentColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { if (sel.isText) { sel.textColor = c; sel.textGradient = null; } else { sel.elementColor = c; } }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.3), blurRadius: 4)] : null), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); }))]))); }); }); }
  void _showAdvancedStrokeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Stroke', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Stroke', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), activeColor: const Color(0xFF8B5CF6), dense: true, contentPadding: EdgeInsets.zero, value: sel.hasStroke, onChanged: (val) { saveState(); setState(() => sel.hasStroke = val); setModalState((){}); }), Divider(color: Colors.grey.shade200), if (sel.hasStroke) ...[Row(children: [const Text('Width:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.strokeWidth, min: 1.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.strokeWidth = val); setModalState((){}); }))]), const Text('Color:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), const SizedBox(height: 8), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSel = sel.strokeColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.strokeColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); }))] ])); }); }); }
  void _showAdvancedShadowModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 500, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Shadow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Shadow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), activeColor: const Color(0xFF8B5CF6), dense: true, contentPadding: EdgeInsets.zero, value: sel.hasShadow, onChanged: (val) { saveState(); setState(() => sel.hasShadow = val); setModalState((){}); }), Divider(color: Colors.grey.shade200), if (sel.hasShadow) ...[Row(children: [const Text('Blur:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowBlur, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowBlur = val); setModalState((){}); }))]), Row(children: [const Text('X:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetX, min: -20.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetX = val); setModalState((){}); }))]), Row(children: [const Text('Y:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetY, min: -20.0, max: 20.0, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetY = val); setModalState((){}); }))]), const Text('Color:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), const SizedBox(height: 8), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSel = sel.shadowColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.shadowColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); }))] ])); }); }); }
  void _show3DBlockModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('3D Depth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Row(children: [const Text('Depth:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.text3dDepth, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.text3dDepth = val); setModalState((){}); }))]), const Text('Color:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), const SizedBox(height: 8), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: AppConstants.proColorPalette.length, itemBuilder: (context, index) { Color c = AppConstants.proColorPalette[index]; bool isSel = sel.text3dColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.text3dColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); })) ])); }); }); }
  void _showRadiusModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 160, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Corner Radius: ${sel.cornerRadius.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Slider(value: sel.cornerRadius, min: 0.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.cornerRadius = val); setModalState((){}); })])); }); }); }
  void _showShapeClipModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 220, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Crop to Shape', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: ListView(scrollDirection: Axis.horizontal, children: [_buildShapeOption(sel, setModalState, 'None', 0, Icons.crop_square), _buildShapeOption(sel, setModalState, 'Circle', 1, Icons.circle_outlined), _buildShapeOption(sel, setModalState, 'Triangle', 2, Icons.change_history), _buildShapeOption(sel, setModalState, 'Star', 3, Icons.star_border), _buildShapeOption(sel, setModalState, 'Hexagon', 4, Icons.hexagon_outlined)]))])); }); }); }
  Widget _buildShapeOption(DesignElement sel, StateSetter setModalState, String title, int val, IconData icon) { bool isSel = sel.clipShape == val; return InkWell(onTap: () { saveState(); setState(() => sel.clipShape = val); setModalState((){}); Navigator.pop(context); }, borderRadius: BorderRadius.circular(8), child: Container(width: 70, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade200)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade600, size: 24), const SizedBox(height: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? const Color(0xFF8B5CF6) : Colors.black54))]))); }
  void _showImageFiltersModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 220, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: ListView(scrollDirection: Axis.horizontal, children: [_buildFilterOption(sel, setModalState, 'Normal', 0, Colors.grey), _buildFilterOption(sel, setModalState, 'B & W', 1, Colors.black87), _buildFilterOption(sel, setModalState, 'Sepia', 2, Colors.brown), _buildFilterOption(sel, setModalState, 'Invert', 3, Colors.blue)]))])); }); }); }
  Widget _buildFilterOption(DesignElement sel, StateSetter setModalState, String title, int filterVal, Color iconColor) { bool isSel = sel.imageFilter == filterVal; return InkWell(onTap: () { saveState(); setState(() => sel.imageFilter = filterVal); setModalState((){}); Navigator.pop(context); }, borderRadius: BorderRadius.circular(8), child: Container(width: 70, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade200)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_filter, color: isSel ? const Color(0xFF8B5CF6) : iconColor, size: 24), const SizedBox(height: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? const Color(0xFF8B5CF6) : Colors.black54))]))); }
  void showSpacingModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 280, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Spacing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 4), Row(children: [const Text('Line:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.lineHeight, min: 0.5, max: 3.5, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.lineHeight = val); setModalState((){}); }))]), Row(children: [const Text('Word:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.wordSpacing, min: -10.0, max: 30.0, activeColor: const Color(0xFF10B981), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.wordSpacing = val); setModalState((){}); }))]), Row(children: [const Text('Letter:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.letterSpacing, min: -5.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.letterSpacing = val); setModalState((){}); }))]) ])); }); }); }
  void showSizeSliderModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 160, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Size: ${sel.fontSize.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Slider(value: sel.fontSize, min: 10.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.fontSize = val); setModalState((){}); })])); }); }); }
  void showRotationModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rotate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 4), Slider(value: sel.angle, min: -pi, max: pi, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.angle = val); setModalState((){}); }), Text('${(sel.angle * 180 / pi).toInt()}°', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))])); }); }); }
  void show3DModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Perspective', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 4), Row(children: [const Text('X:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), Expanded(child: Slider(value: sel.pitch, min: -pi/2, max: pi/2, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.pitch = val); setModalState((){}); }))]), Row(children: [const Text('Y:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), Expanded(child: Slider(value: sel.yaw, min: -pi/2, max: pi/2, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.yaw = val); setModalState((){}); }))]), ElevatedButton(onPressed: () { saveState(); setState((){ sel.pitch=0; sel.yaw=0; }); setModalState((){}); }, style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.grey.shade100, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Reset', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700))) ])); }); }); }
  
  void showNudgeModal(DesignElement sel) { 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { 
      return StatefulBuilder(builder: (context, setModalState) { 
        void move(double dx, double dy) { 
          saveState(); 
          setState(() { 
            sel.x += dx; sel.y += dy; 
            if (sel.groupId != null) {
              for (var other in elements) {
                if (other.id != sel.id && other.groupId == sel.groupId && !other.isLocked) {
                  other.x += dx; other.y += dy;
                }
              }
            }
          }); 
          setModalState((){}); 
        } 
        return Container(height: 240, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Nudge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_upward, size: 28, color: Color(0xFF8B5CF6)), onPressed: () => move(0, -2))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: Color(0xFF8B5CF6)), onPressed: () => move(-2, 0)), const SizedBox(width: 40), IconButton(icon: const Icon(Icons.arrow_forward, size: 28, color: Color(0xFF8B5CF6)), onPressed: () => move(2, 0))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_downward, size: 28, color: Color(0xFF8B5CF6)), onPressed: () => move(0, 2))]),])); 
      }); 
    }); 
  }

  void _showCurveModal(DesignElement sel) { 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { 
      return StatefulBuilder(builder: (context, setModalState) { 
        return Container(height: 240, padding: const EdgeInsets.all(20), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Curve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), 
          const SizedBox(height: 4), 
          Row(children: [const Text('Bend:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.textCurveRadius, min: -150.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.textCurveRadius = val); setModalState((){}); }))]), 
          Row(children: [const Text('Space:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.letterSpacing, min: -5.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.letterSpacing = val); setModalState((){}); }))]), 
          ElevatedButton(onPressed: () { saveState(); setState(() => sel.textCurveRadius = 0.0); setModalState((){}); }, style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.grey.shade100, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Reset', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700))) 
        ])); 
      }); 
    }); 
  }

  void _showBlendModeModal(DesignElement sel) { 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { 
      return StatefulBuilder(builder: (context, setModalState) { 
        return Container(height: 320, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Blend Modes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), 
          Divider(color: Colors.grey.shade200), 
          Expanded(child: ListView.builder(itemCount: AppConstants.blendModes.length, itemBuilder: (context, index) { 
            String bName = AppConstants.blendModes[index].toString().replaceAll('BlendMode.', '').toUpperCase(); 
            return ListTile(title: Text(bName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), dense: true, trailing: sel.blendModeIndex == index ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 18) : null, onTap: () { saveState(); setState(() => sel.blendModeIndex = index); Navigator.pop(context); }); 
          }))
        ])); 
      }); 
    }); 
  }

  void _showResizeModal() { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return Container(height: 280, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: ListView(children: [ListTile(leading: const Icon(Icons.crop_square, size: 20), title: const Text('1:1 (Logo / DP)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), dense: true, onTap: (){ saveState(); setState(()=> canvasRatio = 1.0); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.crop_16_9, size: 20), title: const Text('16:9 (YouTube)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), dense: true, onTap: (){ saveState(); setState(()=> canvasRatio = 16/9); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.crop_portrait, size: 20), title: const Text('9:16 (Story / Reel)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), dense: true, onTap: (){ saveState(); setState(()=> canvasRatio = 9/16); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.description, size: 20), title: const Text('1:1.414 (A4 Print)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), dense: true, onTap: (){ saveState(); setState(()=> canvasRatio = 1/1.414); Navigator.pop(context); }),]))])); }); }

  void showLayersPanel() { Set<String> selectedForGroup = {}; showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 450, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Layers & Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), if (selectedForGroup.length > 1) ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 10), elevation: 0), icon: const Icon(Icons.link, size: 16, color: Colors.white), label: const Text('Group', style: TextStyle(color: Colors.white, fontSize: 12)), onPressed: () { String newGroup = DateTime.now().millisecondsSinceEpoch.toString(); saveState(); for (var e in elements) { if (selectedForGroup.contains(e.id)) e.groupId = newGroup; } selectedForGroup.clear(); setModalState((){}); setState((){}); },), if (selectedForGroup.isNotEmpty) ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 10), elevation: 0), icon: const Icon(Icons.link_off, size: 16, color: Colors.white), label: const Text('Ungroup', style: TextStyle(color: Colors.white, fontSize: 12)), onPressed: () { saveState(); for (var e in elements) { if (selectedForGroup.contains(e.id)) e.groupId = null; } selectedForGroup.clear(); setModalState((){}); setState((){}); },), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), const Text('Tick boxes to group layers together', style: TextStyle(fontSize: 11, color: Colors.grey)), Divider(color: Colors.grey.shade200), Expanded(child: elements.isEmpty ? const Center(child: Text('No elements yet.', style: TextStyle(color: Colors.grey))) : ListView.builder(itemCount: elements.length, itemBuilder: (context, index) { int actualIndex = elements.length - 1 - index; DesignElement e = elements[actualIndex]; bool isSel = selectedId == e.id; bool isGroupChecked = selectedForGroup.contains(e.id); return Card(color: isSel ? const Color(0xFFF3E8FF) : (e.groupId != null ? Colors.blue.shade50 : Colors.white), elevation: 0, margin: const EdgeInsets.only(bottom: 6), shape: RoundedRectangleBorder(side: BorderSide(color: isSel ? const Color(0xFF8B5CF6) : (e.groupId != null ? Colors.blue.shade300 : Colors.grey.shade200)), borderRadius: BorderRadius.circular(8)), child: ListTile(dense: true, leading: Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: isGroupChecked, activeColor: const Color(0xFF8B5CF6), onChanged: (val) { setModalState(() { if (val == true) selectedForGroup.add(e.id); else selectedForGroup.remove(e.id); }); }), CircleAvatar(radius: 12, backgroundColor: e.isText ? e.textColor : Colors.blueGrey, child: Icon(e.isText ? Icons.title : (e.isBorder ? Icons.filter_frames : Icons.category), size: 12, color: Colors.white)),]), title: Row(children: [Expanded(child: Text(e.isText ? e.content.replaceAll('\n', ' ') : (e.isBorder ? e.content : 'Shape'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), if (e.groupId != null) const Icon(Icons.link, size: 12, color: Colors.blue),]), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(e.isHidden ? Icons.visibility_off : Icons.visibility, size: 16, color: e.isHidden ? Colors.red : Colors.black54), onPressed: () { saveState(); setState(() => e.isHidden = !e.isHidden); setModalState((){}); }), const SizedBox(width: 8), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(e.isLocked ? Icons.lock : Icons.lock_open, size: 16, color: e.isLocked ? Colors.red : Colors.black54), onPressed: () { saveState(); setState(() { e.isLocked = !e.isLocked; if(e.isLocked && isSel) selectedId = null; }); setModalState((){}); }), const SizedBox(width: 8), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.arrow_upward, size: 16, color: Colors.black54), onPressed: () { if (actualIndex < elements.length - 1) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex + 1, item); }); setModalState((){}); } }), const SizedBox(width: 8), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.arrow_downward, size: 16, color: Colors.black54), onPressed: () { if (actualIndex > 0) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex - 1, item); }); setModalState((){}); } }),]), onTap: () { if(!e.isLocked && !e.isHidden) { setState(() => selectedId = e.id); setModalState((){}); } },)); },)),]));});}); }

  void showPagesPanel() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 400, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pages (صفحات)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: ListView.builder(itemCount: pages.length, itemBuilder: (context, index) { bool isCurrent = currentPageIndex == index; return Card(color: isCurrent ? const Color(0xFFF3E8FF) : Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 6), shape: RoundedRectangleBorder(side: BorderSide(color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey.shade200), borderRadius: BorderRadius.circular(8)), child: ListTile(dense: true, leading: Icon(Icons.description, color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey, size: 20), title: Text(pages[index].title, style: TextStyle(fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, fontSize: 13)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [ IconButton(icon: const Icon(Icons.copy, color: Colors.blue, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () { setState(() { pages.insert(index + 1, DesignPage(title: '${pages[index].title} Copy', elements: pages[index].elements.map((e) => e.clone()).toList(), pageColor: pages[index].pageColor, bgImageBytes: pages[index].bgImageBytes, canvasRatio: pages[index].canvasRatio, bgGradient: pages[index].bgGradient)); currentPageIndex = index + 1; }); setModalState(() {}); }), const SizedBox(width: 12), if(pages.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () { setState(() { pages.removeAt(index); if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1; }); setModalState(() {}); }) ]), onTap: () { setState(() { currentPageIndex = index; selectedId = null; }); Navigator.pop(context); },)); },)), const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { setState(() { pages.add(DesignPage(title: 'Page ${pages.length + 1}', elements: [DesignElement(id: Random().nextInt(10000).toString(), x: 60, y: 100, content: 'نیا صفحہ', width: 250)], pageColor: Colors.white)); currentPageIndex = pages.length - 1; selectedId = null; }); Navigator.pop(context); }, child: const Text('Add New Page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),]));});}); }

  Future<void> _importCustomFont() async { try { FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['ttf', 'otf']); if (result != null && result.files.single.path != null) { String filePath = result.files.single.path!; String fontName = result.files.single.name.replaceAll('.ttf', '').replaceAll('.otf', ''); var fontLoader = FontLoader(fontName); fontLoader.addFont(Future.value(ByteData.view(File(filePath).readAsBytesSync().buffer))); await fontLoader.load(); setState(() { if (!customFonts.contains(fontName)) customFonts.add(fontName); }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Font "$fontName" imported! 🎉', style: const TextStyle(fontWeight: FontWeight.w700)))); } } catch (e) { debugPrint("Font Import Error: $e"); } }
  void showFontPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 420, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Fonts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () async { await _importCustomFont(); setModalState(() {}); }, icon: const Icon(Icons.add, color: Colors.white, size: 14), label: const Text('Add Font', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))) ]), Divider(color: Colors.grey.shade200), Expanded(child: ListView(children: [if (customFonts.isNotEmpty) ...[const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('My Fonts', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800))), ...customFonts.map((fontName) => ListTile(title: Text(fontName, style: TextStyle(fontFamily: fontName, fontSize: 20)), trailing: sel.fontFamily == fontName ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 18) : null, dense: true, onTap: () { saveState(); setState(() => sel.fontFamily = fontName); Navigator.pop(context); })).toList(), Divider(color: Colors.grey.shade200)], const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('Default Fonts', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800))), ...availableFonts.map((fontName) => ListTile(title: Text('اردو فونٹ - $fontName', style: TextStyle(fontFamily: fontName, fontSize: 20)), trailing: sel.fontFamily == fontName ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 18) : null, dense: true, onTap: () { saveState(); setState(() => sel.fontFamily = fontName); Navigator.pop(context); })).toList(),])),])); }); }); }

  void _showAlignmentModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return Container(height: 240, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Align', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildAlignButton(Icons.align_horizontal_left, 'Left', () { saveState(); setState(() => sel.x = 10); Navigator.pop(context); }), _buildAlignButton(Icons.align_horizontal_center, 'Center', () { saveState(); setState(() => sel.x = (MediaQuery.of(context).size.width - 40 - (sel.width > 0 ? sel.width : 280)) / 2); Navigator.pop(context); }), _buildAlignButton(Icons.align_horizontal_right, 'Right', () { saveState(); setState(() => sel.x = MediaQuery.of(context).size.width - 40 - (sel.width > 0 ? sel.width : 280) - 10); Navigator.pop(context); }),]), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildAlignButton(Icons.align_vertical_top, 'Top', () { saveState(); setState(() => sel.y = 10); Navigator.pop(context); }), _buildAlignButton(Icons.align_vertical_center, 'Middle', () { saveState(); setState(() => sel.y = (MediaQuery.of(context).size.height * 0.5) / 2); Navigator.pop(context); }), _buildAlignButton(Icons.align_vertical_bottom, 'Bottom', () { saveState(); setState(() => sel.y = (MediaQuery.of(context).size.height * 0.6) - 100); Navigator.pop(context); }),]),])); }); }
  Widget _buildAlignButton(IconData icon, String label, VoidCallback onTap) { return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [Icon(icon, color: const Color(0xFF8B5CF6), size: 20), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black54))]),),); }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = selectedId != null;
    DesignElement? sel;
    if (hasSelection) sel = elements.firstWhere((e) => e.id == selectedId);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), 
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, titleSpacing: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40)),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _buildTopBtn(Icons.layers, 'Layers', showLayersPanel), const SizedBox(width: 4),
            _buildTopBtn(Icons.auto_stories, 'Pages', showPagesPanel), const SizedBox(width: 4),
            _buildTopBtn(Icons.undo, 'Undo', undoAction), const SizedBox(width: 4),
            _buildTopBtn(Icons.redo, 'Redo', redoAction), const SizedBox(width: 4),
          ]),
        ),
        actions: [
          InkWell(
            onTap: _saveProjectLocally,
            borderRadius: BorderRadius.circular(6),
            child: Container(margin: const EdgeInsets.symmetric(vertical: 14), padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: Row(children: const [Icon(Icons.save, color: Color(0xFF8B5CF6), size: 14), SizedBox(width: 4), Text('Save', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w700, fontSize: 10))])),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showExportMenu,
            borderRadius: BorderRadius.circular(6),
            child: Container(margin: const EdgeInsets.symmetric(vertical: 14), padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: Row(children: const [Icon(Icons.download, color: Colors.white, size: 14), SizedBox(width: 4), Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10))])),
          ),
          const SizedBox(width: 12),
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
                    onTap: () => setState(() => _isCanvasLocked = !_isCanvasLocked),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: Icon(_isCanvasLocked ? Icons.lock : Icons.lock_open, color: _isCanvasLocked ? Colors.redAccent : Colors.black54, size: 16)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _transformController.value = Matrix4.identity(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: const Icon(Icons.zoom_out_map, color: Colors.black54, size: 16)),
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
                  panEnabled: !_isCanvasLocked && !hasSelection,
                  scaleEnabled: !_isCanvasLocked && !hasSelection, 
                  minScale: 0.2, maxScale: 5.0, 
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: AspectRatio(
                    aspectRatio: canvasRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double canvasW = constraints.maxWidth;
                        double canvasH = constraints.maxHeight;

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

                                    bool isSel = e.id == selectedId;
                                    
                                    Matrix4 matrix = Matrix4.identity()
                                      ..setEntry(3, 2, 0.002) 
                                      ..rotateX(e.pitch)
                                      ..rotateY(e.yaw)
                                      ..rotateZ(e.angle);
                                    
                                    if (e.flipX) matrix.rotateY(pi);
                                    if (e.flipY) matrix.rotateX(pi);

                                    List<BoxShadow> boxShadows = [];
                                    if (e.hasShadow && !e.isText && !e.isBorder) {
                                      boxShadows.add(BoxShadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY)));
                                    }
                                    Border? universalBorder;
                                    if (e.hasStroke && !e.isText && !e.isBorder) {
                                      universalBorder = Border.all(color: e.strokeColor, width: e.strokeWidth);
                                    }

                                    if (e.isBorder) {
                                      return Positioned.fill(
                                        child: GestureDetector(
                                          onTap: () { if(!e.isLocked) setState(() => selectedId = e.id); }, 
                                          child: Transform(
                                            transform: matrix, alignment: Alignment.center,
                                            child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: e.elementColor, width: e.borderWidth), borderRadius: BorderRadius.circular(10), color: isSel && !_isExporting ? Colors.purple.withOpacity(0.05) : Colors.transparent))
                                          )
                                        )
                                      );
                                    }

                                    Widget contentWidget;
                                    double currentWidth = e.width > 50 ? e.width : 280.0; 
                                    double currentHeight = e.height > 20 ? e.height : (e.isShape ? 90 : 150);

                                    if (e.isShape) {
                                      contentWidget = Container(width: currentWidth, height: currentHeight, decoration: BoxDecoration(color: e.elementColor, boxShadow: boxShadows.isNotEmpty ? boxShadows : null, border: universalBorder, borderRadius: BorderRadius.circular(e.cornerRadius)));
                                    } else if (e.imageBytes != null) {
                                      Widget img = Image.memory(e.imageBytes!, width: currentWidth, height: currentHeight, fit: BoxFit.fill);
                                      if (e.isTinted) {
                                        img = Image.memory(e.imageBytes!, width: currentWidth, height: currentHeight, fit: BoxFit.fill, color: e.elementColor, colorBlendMode: BlendMode.srcIn);
                                      } else {
                                        if (e.imageFilter == 1) img = ColorFiltered(colorFilter: const ColorFilter.matrix(AppConstants.grayscaleMatrix), child: img);
                                        else if (e.imageFilter == 2) img = ColorFiltered(colorFilter: const ColorFilter.matrix(AppConstants.sepiaMatrix), child: img);
                                        else if (e.imageFilter == 3) img = ColorFiltered(colorFilter: const ColorFilter.matrix(AppConstants.invertMatrix), child: img);
                                      }

                                      if (e.blendModeIndex != 0) {
                                        img = ColorFiltered(colorFilter: ColorFilter.mode(Colors.transparent, AppConstants.blendModes[e.blendModeIndex]), child: img);
                                      }

                                      Widget clippedImg = img;
                                      if (e.clipShape == 1) {
                                        clippedImg = Container(clipBehavior: Clip.antiAlias, decoration: const BoxDecoration(shape: BoxShape.circle), child: img);
                                      } else if (e.clipShape == 2) {
                                        clippedImg = ClipPath(clipper: TriangleClipper(), child: img);
                                      } else if (e.clipShape == 3) {
                                        clippedImg = ClipPath(clipper: StarClipper(), child: img);
                                      } else if (e.clipShape == 4) {
                                        clippedImg = ClipPath(clipper: HexagonClipper(), child: img);
                                      }

                                      contentWidget = Container(
                                        width: currentWidth, 
                                        height: e.clipShape == 1 ? currentWidth : currentHeight, 
                                        decoration: BoxDecoration(borderRadius: e.clipShape == 0 ? BorderRadius.circular(e.cornerRadius) : null, boxShadow: boxShadows.isNotEmpty ? boxShadows : null, border: universalBorder), 
                                        child: clippedImg
                                      );
                                    } else {
                                      List<Shadow> textShadows = [];
                                      if (e.hasShadow) { textShadows.add(Shadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY))); }

                                      Widget buildTextWidget(Color c, [List<Shadow>? shadow]) {
                                        TextStyle st = TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, letterSpacing: e.letterSpacing, color: c, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, height: e.lineHeight, wordSpacing: e.wordSpacing, shadows: shadow);
                                        if (e.textCurveRadius != 0) {
                                          return CurvedTextWidget(text: e.content, radius: e.textCurveRadius, style: st, letterSpacing: e.letterSpacing);
                                        }
                                        return Text(e.content, textAlign: e.textAlign, softWrap: true, textDirection: TextDirection.rtl, style: st.copyWith(letterSpacing: e.letterSpacing));
                                      }

                                      List<Widget> blockLayers = [];
                                      if (e.text3dDepth > 0) {
                                        for (double i = e.text3dDepth; i > 0; i -= 1.0) {
                                          blockLayers.add(Transform.translate(offset: Offset(i, i), child: buildTextWidget(e.text3dColor)));
                                        }
                                      }
                                      
                                      Widget mainTxt = buildTextWidget(e.textGradient != null ? Colors.white : e.textColor, textShadows.isNotEmpty ? textShadows : null);
                                      if (e.textGradient != null) { mainTxt = ShaderMask(shaderCallback: (bounds) => LinearGradient(colors: e.textGradient!).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)), child: mainTxt); }
                                      if (e.textTextureBytes != null) { mainTxt = TextureTextWrapper(textureBytes: e.textTextureBytes, child: mainTxt); }
                                      
                                      blockLayers.add(mainTxt);
                                      Widget txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: blockLayers);

                                      if (e.hasStroke) {
                                        TextStyle stStroke = TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, letterSpacing: e.letterSpacing, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = e.strokeWidth..color = e.strokeColor, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, height: e.lineHeight, wordSpacing: e.wordSpacing);
                                        Widget strokeTxt = e.textCurveRadius != 0 ? CurvedTextWidget(text: e.content, radius: e.textCurveRadius, style: stStroke, letterSpacing: e.letterSpacing) : Text(e.content, textAlign: e.textAlign, softWrap: true, textDirection: TextDirection.rtl, style: stStroke.copyWith(letterSpacing: e.letterSpacing));
                                        txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [strokeTxt, txt]);
                                      }
                                      if (e.textBgColor != null) { txt = Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: e.textBgColor, borderRadius: BorderRadius.circular(e.textBgRadius)), child: txt); }
                                      contentWidget = e.textCurveRadius != 0 ? txt : SizedBox(width: currentWidth, child: txt);
                                    }

                                    if (_isExporting) { 
                                      return Positioned(left: e.x, top: e.y, child: Transform(transform: matrix, alignment: Alignment.center, child: Opacity(opacity: e.opacity, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), child: contentWidget)))); 
                                    }

                                    return Positioned(
                                      left: e.x, top: e.y,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (e.isLocked) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layer is Locked.', style: TextStyle(fontWeight: FontWeight.w600)), duration: Duration(seconds: 1)));
                                          } else {
                                            setState(() => selectedId = e.id);
                                          }
                                        },
                                        onScaleStart: (details) {
                                          if (!e.isLocked) {
                                            saveState();
                                            setState(() {
                                              selectedId = e.id;
                                              _initialRotation = e.angle;
                                              _initialWidth = e.width > 50 ? e.width : 280.0;
                                              _initialHeight = e.height > 20 ? e.height : (e.isShape ? 90 : 150);
                                              _initialFontSize = e.fontSize;
                                              _initialX = e.x;
                                              _initialY = e.y;
                                              _initialFocalPoint = details.focalPoint;
                                              
                                              _initialGroupStates.clear();
                                              if (e.groupId != null) {
                                                for (var other in elements) {
                                                  if (other.groupId == e.groupId) {
                                                    _initialGroupStates[other.id] = {'x': other.x, 'y': other.y};
                                                  }
                                                }
                                              }
                                            });
                                          }
                                        },
                                        onScaleUpdate: (details) {
                                          if (!e.isLocked) {
                                            setState(() {
                                              selectedId = e.id;
                                              
                                              Offset delta = details.focalPoint - _initialFocalPoint;
                                              e.x = _initialX + delta.dx;
                                              e.y = _initialY + delta.dy;

                                              double snapCenterX = e.x + currentWidth / 2 + 20; 
                                              double snapCenterY = e.y + (e.isText && e.textCurveRadius == 0 ? 100 : currentHeight) / 2 + 15;
                                              
                                              _snapV = (snapCenterX - canvasW/2).abs() < 12;
                                              _snapH = (snapCenterY - canvasH/2).abs() < 12;

                                              double snapShiftX = 0, snapShiftY = 0;
                                              if (_snapV) {
                                                 snapShiftX = (canvasW/2 - currentWidth/2 - 20) - e.x;
                                                 e.x += snapShiftX;
                                              }
                                              if (_snapH) {
                                                 snapShiftY = (canvasH/2 - (e.isText && e.textCurveRadius == 0 ? 100 : currentHeight)/2 - 15) - e.y;
                                                 e.y += snapShiftY;
                                              }

                                              if (e.groupId != null) {
                                                for (var other in elements) {
                                                  if (other.id != e.id && other.groupId == e.groupId && !other.isLocked) {
                                                    var initStates = _initialGroupStates[other.id];
                                                    if (initStates != null) {
                                                      other.x = initStates['x'] + delta.dx + snapShiftX;
                                                      other.y = initStates['y'] + delta.dy + snapShiftY;
                                                    }
                                                  }
                                                }
                                              }

                                              if (details.scale != 1.0) {
                                                if (e.isText) {
                                                  double newSize = _initialFontSize * details.scale;
                                                  if (newSize > 10.0 && newSize < 300.0) e.fontSize = newSize;
                                                } else {
                                                  double newW = _initialWidth * details.scale;
                                                  double newH = _initialHeight * details.scale;
                                                  if (newW > 20 && newH > 20) {
                                                    e.width = newW;
                                                    e.height = newH;
                                                  }
                                                }
                                              }

                                              if (details.rotation != 0.0) {
                                                e.angle = _initialRotation + details.rotation;
                                              }
                                            });
                                          }
                                        },
                                        onScaleEnd: (details) {
                                          setState(() { _snapV = false; _snapH = false; });
                                        },
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
                                                        
                                                        Positioned(
                                                          top: -15, left: 0, right: 0, 
                                                          child: Center(
                                                            child: GestureDetector(
                                                              onPanUpdate: (d) {
                                                                setState(() { e.angle += d.delta.dx * 0.02; });
                                                              },
                                                              child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]), child: const Icon(Icons.rotate_right, size: 14, color: Colors.black87))
                                                            )
                                                          )
                                                        ),
                                                        
                                                        if (!e.isText && !e.isShape) Positioned(right: -15, top: 0, bottom: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double w = currentWidth + d.delta.dx; if (w > 50) e.width = w; }); }, child: Container(width: 30, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 6, height: 20, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                                        if (!e.isText && !e.isShape) Positioned(left: -15, top: 0, bottom: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double newW = currentWidth - d.delta.dx; if (newW > 50) { e.width = newW; e.x += d.delta.dx; } }); }, child: Container(width: 30, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 6, height: 20, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                                        if (!e.isText) Positioned(bottom: -15, left: 0, right: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double h = currentHeight + d.delta.dy; if (h > 20) e.height = h; }); }, child: Container(height: 30, color: Colors.transparent, alignment: Alignment.center, child: Container(height: 6, width: 20, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                                        
                                                        Positioned(
                                                          bottom: -15, right: -15, 
                                                          child: GestureDetector(
                                                            onPanUpdate: (d) { 
                                                              setState(() { 
                                                                if (e.isText) {
                                                                  double newSize = e.fontSize + (d.delta.dx + d.delta.dy) * 0.4;
                                                                  if (newSize > 10 && newSize < 300) e.fontSize = newSize;
                                                                } else {
                                                                  double ratio = currentWidth / currentHeight; 
                                                                  double newW = currentWidth + d.delta.dx; 
                                                                  if (newW > 50) { e.width = newW; e.height = newW / ratio; } 
                                                                }
                                                              }); 
                                                            }, 
                                                            child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFF8B5CF6), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]), child: const Icon(Icons.open_in_full, size: 12, color: Colors.white))
                                                          )
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Material(
                                                      color: Colors.transparent, elevation: 6, borderRadius: BorderRadius.circular(12),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            InkWell(onTap: bringForward, borderRadius: BorderRadius.circular(6), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.arrow_upward, size: 18, color: Colors.black87))), const SizedBox(width: 10),
                                                            InkWell(onTap: sendBackward, borderRadius: BorderRadius.circular(6), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.arrow_downward, size: 18, color: Colors.black87))), const SizedBox(width: 10),
                                                            InkWell(onTap: duplicateSelected, borderRadius: BorderRadius.circular(6), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy, size: 18, color: Colors.black87))), const SizedBox(width: 10),
                                                            InkWell(onTap: deleteSelected, borderRadius: BorderRadius.circular(6), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent))),
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

                                  if (_snapV && !_isExporting) Positioned(left: canvasW/2, top: 0, bottom: 0, child: Container(width: 1.5, color: Colors.redAccent.withOpacity(0.8))),
                                  if (_snapH && !_isExporting) Positioned(top: canvasH/2, left: 0, right: 0, child: Container(height: 1.5, color: Colors.redAccent.withOpacity(0.8))),
                                ],
                              ),
                            ),
                          ),
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
      bottomNavigationBar: SafeArea(child: Container(decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))]), child: hasSelection ? _buildSelectedToolBar(sel!) : _buildDefaultBottomBar())),
    );
  }

  Widget _buildDefaultBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: showAddNewModal, 
            borderRadius: BorderRadius.circular(10),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2))), child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.add_box, color: Color(0xFF8B5CF6), size: 20), SizedBox(height: 2), Text('ADD NEW', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 9, fontWeight: FontWeight.w800))]))
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 35, color: Colors.grey.shade200), 
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
                  _buildToolBtn(Icons.layers_clear, 'Clear BG', () { saveState(); setState((){ pageColor = Colors.transparent; bgImageBytes = null; bgGradient = null; }); }), 
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
          color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 8),
                if (sel.isText) _buildToolBtn(Icons.text_fields, 'Size', () => showSizeSliderModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.height, 'Spacing', () => showSpacingModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.format_color_fill, 'Text BG', () => _showTextBgPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.gradient, 'Gradient', () => _showGradientPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.data_usage, 'Curve', () => _showCurveModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.texture, 'Texture', () => _addTextureToText(sel)),
                if (sel.isText && sel.textTextureBytes != null) _buildToolBtn(Icons.layers_clear, 'No Texture', () { saveState(); setState(() => sel.textTextureBytes = null); }),
                if (sel.isText) _buildToolBtn(Icons.format_align_left, 'Align', () => _toggleAlignment(sel)),
                _buildToolBtn(Icons.center_focus_strong, 'Position', () => _showAlignmentModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.view_in_ar_outlined, '3D', () => _show3DBlockModal(sel)),
                if (sel.imageBytes != null) _buildToolBtn(Icons.format_paint, 'Tint', () { saveState(); setState(() => sel.isTinted = !sel.isTinted); if(sel.isTinted) _showColorPickerModal(sel); }),
                if (sel.imageBytes != null) _buildToolBtn(Icons.auto_awesome_motion, 'Blend', () => _showBlendModeModal(sel)),
                if (!sel.isBorder) _buildToolBtn(Icons.border_color, 'Stroke', () => _showAdvancedStrokeModal(sel)),
                if (!sel.isBorder) _buildToolBtn(Icons.brightness_6, 'Shadow', () => _showAdvancedShadowModal(sel)),
                if (!sel.isText && !sel.isBorder) _buildToolBtn(Icons.rounded_corner, 'Radius', () => _showRadiusModal(sel)),
                if (sel.imageBytes != null && !sel.isTinted) _buildToolBtn(Icons.photo_filter, 'Filters', () => _showImageFiltersModal(sel)),
                if (sel.imageBytes != null) _buildToolBtn(Icons.crop, 'Crop', () => _showShapeClipModal(sel)),
                
                _buildToolBtn(Icons.flip, 'Flip H', () { saveState(); setState(() => sel.flipX = !sel.flipX); }),
                _buildToolBtn(Icons.flip_camera_android, 'Flip V', () { saveState(); setState(() => sel.flipY = !sel.flipY); }),
                _buildToolBtn(Icons.opacity, 'Opacity', () { saveState(); setState(() => sel.opacity = sel.opacity == 1.0 ? 0.5 : 1.0); }),
                _buildToolBtn(Icons.rotate_right, 'Rotate', () => showRotationModal(sel)), 
                _buildToolBtn(Icons.view_in_ar, 'Angles', () => show3DModal(sel)), 
                _buildToolBtn(Icons.open_with, 'Nudge', () => showNudgeModal(sel)),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => selectedId = null), 
                borderRadius: BorderRadius.circular(8),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(8)), child: Row(children: const [Icon(Icons.deselect, color: Colors.red, size: 14), SizedBox(width: 4), Text('DESELECT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 9))]))
              ),
              const Expanded(child: SizedBox()),
              if (sel.isText) _buildToolBtn(Icons.edit, 'Edit', () => _showTextComposerDialog(existingElement: sel)),
              if (sel.isText) _buildToolBtn(Icons.font_download, 'Font', () => showFontPickerModal(sel)),
              if (sel.isText || sel.isBorder || sel.isShape || sel.isTinted) _buildToolBtn(Icons.palette, 'Color', () => _showColorPickerModal(sel)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTopBtn(IconData icon, String label, [VoidCallback? onTap]) { 
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
        child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFF4B5563), size: 20), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563), fontWeight: FontWeight.w600))])
      )
    ); 
  }
  
  Widget _buildToolBtn(IconData icon, String label, [VoidCallback? onTap]) { 
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), 
        child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFF4B5563), size: 20), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563), fontWeight: FontWeight.w700))])
      )
    ); 
  }
}
