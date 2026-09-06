import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

// Naye folders ke imports
import '../models/design_models.dart';
import '../widgets/custom_widgets.dart';

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
  final ImagePicker _picker = ImagePicker();
  bool _isExporting = false;

  static const List<double> grayscaleMatrix = [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0];
  static const List<double> sepiaMatrix = [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0];
  static const List<double> invertMatrix = [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0];
  final List<BlendMode> _blendModes = [BlendMode.srcOver, BlendMode.multiply, BlendMode.screen, BlendMode.overlay, BlendMode.darken, BlendMode.colorBurn];

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
  void dispose() { 
    _transformController.dispose(); 
    super.dispose(); 
  }

  Future<void> _saveProjectLocally() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStrings = prefs.getStringList('qalamkaar_projects') ?? [];
    ProjectModel p = ProjectModel(id: projectId, name: projectName, pages: pages, lastModified: DateTime.now().millisecondsSinceEpoch);
    savedStrings.removeWhere((str) => jsonDecode(str)['id'] == projectId); 
    savedStrings.add(jsonEncode(p.toJson())); 
    await prefs.setStringList('qalamkaar_projects', savedStrings);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project "My Folder" mein save ho gaya! 🎉', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 20)), backgroundColor: Color(0xFF10B981)));
  }

  final List<Color> _proColorPalette = [Colors.black, Colors.white, Colors.grey.shade900, Colors.grey.shade700, Colors.grey.shade400, Colors.grey.shade200, const Color(0xFF800000), const Color(0xFFA52A2A), const Color(0xFFDC143C), const Color(0xFFEF4444), const Color(0xFFF87171), const Color(0xFF4B0082), const Color(0xFF8B5CF6), const Color(0xFF9C27B0), const Color(0xFFD946EF), const Color(0xFFEC4899), const Color(0xFFF43F5E), const Color(0xFFFFC0CB), const Color(0xFF000080), const Color(0xFF1E3A8A), const Color(0xFF2563EB), const Color(0xFF3B82F6), const Color(0xFF06B6D4), const Color(0xFF38BDF8), const Color(0xFFE0F2FE), const Color(0xFF004d00), const Color(0xFF14532D), const Color(0xFF047857), const Color(0xFF10B981), const Color(0xFF22C55E), const Color(0xFF84CC16), const Color(0xFF14B8A6), const Color(0xFFCCFFCC), const Color(0xFFD4AF37), const Color(0xFFB8860B), const Color(0xFFF59E0B), const Color(0xFFF97316), const Color(0xFFFF8C00), const Color(0xFFEAB308), const Color(0xFFFEF08A), const Color(0xFFFFD700), const Color(0xFF8B4513), const Color(0xFFD2B48C), const Color(0xFFFFE4C4), const Color(0xFFFAEBD7)];
  final List<List<Color>> _proGradientPalette = [[const Color(0xFFBF953F), const Color(0xFFFCF6BA), const Color(0xFFB38728), const Color(0xFFFBF5B7)], [const Color(0xFF8E9EAB), const Color(0xFFEEF2F3)], [const Color(0xFFB87333), const Color(0xFFFFCC99), const Color(0xFFB87333)], [const Color(0xFFB76E79), const Color(0xFFE0BFB8)], [const Color(0xFFFF4E50), const Color(0xFFF9D423)], [const Color(0xFF1A2980), const Color(0xFF26D0CE)], [const Color(0xFF134E5E), const Color(0xFF71B280)], [const Color(0xFFFF7E5F), const Color(0xFFFEB47B)], [const Color(0xFF2C3E50), const Color(0xFF3498DB)], [const Color(0xFF833AB4), const Color(0xFFFD1D1D), const Color(0xFFFCB045)], [const Color(0xFF12C2E9), const Color(0xFFC471ED), const Color(0xFFF64F59)], [const Color(0xFF00C9FF), const Color(0xFF92FE9D)], [const Color(0xFFF09819), const Color(0xFFEDDE5D)], [const Color(0xFFDA22FF), const Color(0xFF9733EE)], [const Color(0xFFEC008C), const Color(0xFFFC6767)], [const Color(0xFF02AAB0), const Color(0xFF00CDAC)], [const Color(0xFF434343), const Color(0xFF000000)], [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], [const Color(0xFF141E30), const Color(0xFF243B55)], [const Color(0xFF870000), const Color(0xFF190A05)]];

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

  void _showExportMenu() { 
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
      builder: (context) => Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Export Design (سیو کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), 
        const Divider(), const SizedBox(height: 10), 
        _buildExportOption(Icons.image, 'Save as JPG', 'Solid Background', Colors.blue, () { Navigator.pop(context); _captureAndSave('JPG'); }), const SizedBox(height: 10), 
        _buildExportOption(Icons.layers_clear, 'Save as PNG', 'Transparent Image (Logos)', Colors.purple, () { Navigator.pop(context); _captureAndSave('PNG'); }), const SizedBox(height: 10), 
        _buildExportOption(Icons.picture_as_pdf, 'Save as Print HD PDF', 'High Quality PDF Document', Colors.red, () { Navigator.pop(context); _captureAndSave('PDF'); })
      ]))
    ); 
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) { 
    return InkWell(
      onTap: onTap, 
      child: Container(
        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), 
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)), const SizedBox(width: 15), 
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))])), 
          Icon(Icons.arrow_forward_ios, color: color, size: 16)
        ])
      )
    ); 
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
        if (mounted && result != null && result['isSuccess'] == true) { 
          _showSuccessDialog('Saved to Gallery!', 'Aapka $format design gallery mein save ho gaya hai.'); 
        } 
      } else if (format == 'PDF') { 
        final pdf = pw.Document(); 
        final imagePdf = pw.MemoryImage(pngBytes); 
        pdf.addPage(pw.Page(pageFormat: PdfPageFormat(image.width.toDouble(), image.height.toDouble()), margin: pw.EdgeInsets.zero, build: (pw.Context context) { return pw.Image(imagePdf, fit: pw.BoxFit.cover); })); 
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
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 15), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white)))]))); 
  }

  void _showTextComposerDialog({DesignElement? existingElement}) { 
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? ''); 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.75, padding: const EdgeInsets.all(20), child: Column(children: [Container(decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: const Text('English', style: TextStyle(color: Colors.grey))), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Text('اردو', style: TextStyle(fontWeight: FontWeight.bold)))])), const SizedBox(height: 15), Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15), color: Colors.grey.shade50), child: TextField(controller: controller, maxLines: null, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 28), decoration: const InputDecoration(border: InputBorder.none, hintText: 'یہاں لکھیں...', hintTextDirection: TextDirection.rtl)))), const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildComposerTool(Icons.paste, 'Paste'), _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()), _buildComposerTool(Icons.auto_awesome, 'AI'), _buildComposerTool(Icons.translate, 'Translate')]), const SizedBox(height: 20), Row(children: [Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)))), const SizedBox(width: 15), Expanded(flex: 2, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { if (controller.text.isNotEmpty) { saveState(); if (existingElement != null) { setState(() => existingElement.content = controller.text); } else { var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, width: 280); setState(() { elements.add(newEl); selectedId = newEl.id; }); } } Navigator.pop(context); }, icon: const Icon(Icons.check, color: Colors.white), label: const Text('Add to design', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))))])])))); 
  }

  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) { 
    return InkWell(onTap: onTap, child: Column(children: [Icon(icon, color: Colors.grey.shade600), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))])); 
  }

  void showAddNewModal() { 
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.65, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, children: [_buildGridItem(Icons.image, 'Gallery Pic', Colors.blue.shade100, Colors.blue, addImageFromGallery), _buildGridItem(Icons.collections, 'Stock Images', Colors.indigo.shade100, Colors.indigo, () => Navigator.pop(context)), _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade100, Colors.teal, () => Navigator.pop(context)), _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade100, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }), _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade100, Colors.amber.shade800, () => showGenericStockModal('Borders', 'royal_islamic', Icons.border_outer)), _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade100, Colors.pink, () => showGenericStockModal('Shapes', 'shape_rect', Icons.category))]))]))); 
  }

  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) { 
    return InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: iconColor, size: 28)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)])); 
  }

  Future<void> addImageFromGallery() async { 
    try { 
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery); 
      if (image != null) { 
        final bytes = await image.readAsBytes(); 
        saveState(); 
        setState(() => elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 80, content: '', imageBytes: bytes, isText: false, width: 250, height: 250))); 
      } 
    } catch (e) {} 
    Navigator.pop(context); 
  }

  Future<void> _setCanvasBackground() async { 
    try { 
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery); 
      if (image != null) { 
        final bytes = await image.readAsBytes(); 
        setState(() { bgImageBytes = bytes; bgGradient = null; pageColor = Colors.white; }); 
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
      } 
    } catch (e) {} 
  }

  void showGenericStockModal(String categoryTitle, String styleName, IconData categoryIcon) { 
    Navigator.pop(context); 
    List<Map<String, dynamic>> stockList = []; 
    List<Color> themeColors = [const Color(0xFFD4AF37), const Color(0xFF8B5CF6), const Color(0xFF047857), const Color(0xFF1E3A8A)]; 
    for (int i = 1; i <= 50; i++) stockList.add({'title': '$categoryTitle #$i', 'style': styleName, 'color': themeColors[(i - 1) % themeColors.length], 'icon': categoryIcon}); 
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), 
      builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.75, padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 15), Text('$categoryTitle Library', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.4), itemCount: stockList.length, itemBuilder: (context, index) { var item = stockList[index]; return InkWell(onTap: () { saveState(); setState(() { if (styleName.contains('shape') || styleName == 'badge') { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 90, y: 180, content: styleName == 'badge' ? 'circle' : 'rectangle', isText: false, isShape: true, elementColor: item['color'], width: 220, height: 90)); } else { elements.insert(0, DesignElement(id: Random().nextInt(10000).toString(), x: 0, y: 0, content: item['title'], isText: false, isBorder: true, borderStyle: styleName, elementColor: item['color'], borderWidth: 5.0)); } }); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: item['color'], width: 1.5)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item['icon'], color: item['color'], size: 30), const SizedBox(height: 6), Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item['color']))]))); }))] ))
    ); 
  }

  void deleteSelected() { if (selectedId != null) { saveState(); setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; }); } }
  void duplicateSelected() { if (selectedId != null) { saveState(); DesignElement sel = elements.firstWhere((e) => e.id == selectedId); setState(() { var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20; elements.add(newEl); selectedId = newEl.id; }); } }
  void bringForward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx < elements.length - 1) setState(() { var item = elements.removeAt(idx); elements.insert(idx + 1, item); }); }
  void sendBackward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx > 0) setState(() { var item = elements.removeAt(idx); elements.insert(idx - 1, item); }); }
  void _toggleAlignment(DesignElement sel) { saveState(); setState(() { sel.textAlign = (sel.textAlign == TextAlign.right) ? TextAlign.center : (sel.textAlign == TextAlign.center ? TextAlign.left : TextAlign.right); }); }

  void _pickCustomGradColor(DesignElement sel, int colorNum, StateSetter parentSetState) { showModalBottomSheet(context: context, builder: (ctx) => Container(height: 300, padding: const EdgeInsets.all(20), child: Column(children: [const Text('Pick a Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _proColorPalette.length, itemBuilder: (ctx, index) { return InkWell(onTap: () { if(colorNum == 1) sel.customGradColor1 = _proColorPalette[index]; else sel.customGradColor2 = _proColorPalette[index]; parentSetState((){}); Navigator.pop(ctx); }, child: Container(decoration: BoxDecoration(color: _proColorPalette[index], shape: BoxShape.circle, border: Border.all(color: Colors.black26)))); }))]))); }
  void _showCanvasBgColorModal() { TextEditingController hexCtrl = TextEditingController(); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 480, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: TextField(controller: hexCtrl, decoration: const InputDecoration(hintText: 'Hex Code: #FF0000', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)))), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () { String hex = hexCtrl.text.replaceAll('#', ''); if(hex.length == 6) hex = 'FF$hex'; if(hex.length == 8) { saveState(); setState((){ pageColor = Color(int.parse('0x$hex')); bgImageBytes = null; bgGradient = null; }); setModalState((){}); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white)))])), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSelected = pageColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { pageColor = c; bgImageBytes = null; bgGradient = null; }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))]))); }); }); }
  void _showCanvasBgGradientModal() { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 450, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Gradient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 2.0), itemCount: _proGradientPalette.length, itemBuilder: (context, index) { List<Color> g = _proGradientPalette[index]; return GestureDetector(onTap: () { saveState(); setState(() { bgGradient = g; bgImageBytes = null; pageColor = Colors.white; }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300, width: 1.5)))); }))])); }); }); }

  void _showTextBgPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 450, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Text Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), ListTile(leading: const Icon(Icons.block), title: const Text('Remove Background'), onTap: () { saveState(); setState(() { sel.textBgColor = null; }); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSelected = sel.textBgColor?.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { sel.textBgColor = c; }); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5)), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))])); }); }); }
  void _showGradientPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 550, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Gradient Tool (شیڈز)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Make Your Own (اپنی مرضی کا شیڈ بنائیں):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [InkWell(onTap: () => _pickCustomGradColor(sel, 1, setModalState), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: sel.customGradColor1 ?? Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.black26)))), const Icon(Icons.add), InkWell(onTap: () => _pickCustomGradColor(sel, 2, setModalState), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: sel.customGradColor2 ?? Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.black26)))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () { if(sel.customGradColor1 != null && sel.customGradColor2 != null) { saveState(); setState(() => sel.textGradient = [sel.customGradColor1!, sel.customGradColor2!]); setModalState((){}); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white)))])])), const SizedBox(height: 10), ListTile(leading: const Icon(Icons.block), title: const Text('Clear Gradient'), onTap: () { saveState(); setState(() { sel.textGradient = null; }); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 2.0), itemCount: _proGradientPalette.length, itemBuilder: (context, index) { List<Color> g = _proGradientPalette[index]; return GestureDetector(onTap: () { saveState(); setState(() { sel.textGradient = g; }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300, width: 1.5)))); }))])); }); }); }
  void _showColorPickerModal(DesignElement sel) { TextEditingController hexCtrl = TextEditingController(); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { Color currentColor = sel.isText ? sel.textColor : sel.elementColor; return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 480, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Color (رنگ منتخب کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: TextField(controller: hexCtrl, decoration: const InputDecoration(hintText: 'Custom Hex: #FF0000', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)))), const SizedBox(width: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () { String hex = hexCtrl.text.replaceAll('#', ''); if(hex.length == 6) hex = 'FF$hex'; if(hex.length == 8) { saveState(); setState((){ if(sel.isText){ sel.textColor = Color(int.parse('0x$hex')); sel.textGradient = null; } else { sel.elementColor = Color(int.parse('0x$hex')); } }); setModalState((){}); Navigator.pop(context); } }, child: const Text('Apply', style: TextStyle(color: Colors.white)))])), const Divider(), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSelected = currentColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { if (sel.isText) { sel.textColor = c; sel.textGradient = null; } else { sel.elementColor = c; } }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))]))); }); }); }

  void _showAdvancedStrokeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 450, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Advanced Stroke', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Stroke', style: TextStyle(fontWeight: FontWeight.bold)), activeColor: const Color(0xFF8B5CF6), value: sel.hasStroke, onChanged: (val) { saveState(); setState(() => sel.hasStroke = val); setModalState((){}); }), const Divider(), if (sel.hasStroke) ...[Row(children: [const Text('Thickness:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.strokeWidth, min: 1.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.strokeWidth = val); setModalState((){}); }))]), const Text('Stroke Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSel = sel.strokeColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.strokeColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))] ])); }); }); }
  void _showAdvancedShadowModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 550, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Advanced Shadow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Shadow', style: TextStyle(fontWeight: FontWeight.bold)), activeColor: const Color(0xFF8B5CF6), value: sel.hasShadow, onChanged: (val) { saveState(); setState(() => sel.hasShadow = val); setModalState((){}); }), const Divider(), if (sel.hasShadow) ...[Row(children: [const Text('Blur:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowBlur, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowBlur = val); setModalState((){}); }))]), Row(children: [const Text('X-Offset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetX, min: -20.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetX = val); setModalState((){}); }))]), Row(children: [const Text('Y-Offset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetY, min: -20.0, max: 20.0, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetY = val); setModalState((){}); }))]), const Text('Shadow Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSel = sel.shadowColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.shadowColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); }))] ])); }); }); }
  void _show3DBlockModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 480, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('3D Block / Depth (تھری ڈی موٹائی)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Row(children: [const Text('Depth:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.text3dDepth, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.text3dDepth = val); setModalState((){}); }))]), const Text('3D Color:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSel = sel.text3dColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.text3dColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null)); })) ])); }); }); }
  void _showRadiusModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Corner Radius (گولائی): ${sel.cornerRadius.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Slider(value: sel.cornerRadius, min: 0.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.cornerRadius = val); setModalState((){}); })])); }); }); }

  void _showShapeClipModal(DesignElement sel) { 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { 
      return StatefulBuilder(builder: (context, setModalState) { 
        return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Crop to Shape (کٹنگ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), 
          const Divider(), 
          Expanded(child: ListView(scrollDirection: Axis.horizontal, children: [
            _buildShapeOption(sel, setModalState, 'None', 0, Icons.crop_square), 
            _buildShapeOption(sel, setModalState, 'Circle', 1, Icons.circle_outlined), 
            _buildShapeOption(sel, setModalState, 'Triangle', 2, Icons.change_history), 
            _buildShapeOption(sel, setModalState, 'Star', 3, Icons.star_border),
            _buildShapeOption(sel, setModalState, 'Hexagon', 4, Icons.hexagon_outlined),
          ]))
        ])); 
      }); 
    }); 
  }
  Widget _buildShapeOption(DesignElement sel, StateSetter setModalState, String title, int val, IconData icon) { bool isSel = sel.clipShape == val; return InkWell(onTap: () { saveState(); setState(() => sel.clipShape = val); setModalState((){}); Navigator.pop(context); }, child: Container(width: 80, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade600, size: 30), const SizedBox(height: 5), Text(title, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFF8B5CF6) : Colors.black87))]))); }

  void _showImageFiltersModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Image Filters (تصویر کے فلٹرز)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView(scrollDirection: Axis.horizontal, children: [_buildFilterOption(sel, setModalState, 'Normal', 0, Colors.grey), _buildFilterOption(sel, setModalState, 'B & W', 1, Colors.black87), _buildFilterOption(sel, setModalState, 'Sepia', 2, Colors.brown), _buildFilterOption(sel, setModalState, 'Invert', 3, Colors.blue)]))])); }); }); }
  Widget _buildFilterOption(DesignElement sel, StateSetter setModalState, String title, int filterVal, Color iconColor) { bool isSel = sel.imageFilter == filterVal; return InkWell(onTap: () { saveState(); setState(() => sel.imageFilter = filterVal); setModalState((){}); Navigator.pop(context); }, child: Container(width: 80, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_filter, color: isSel ? const Color(0xFF8B5CF6) : iconColor, size: 30), const SizedBox(height: 5), Text(title, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFF8B5CF6) : Colors.black87))]))); }
  void showSpacingModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 300, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Spacing (فاصلہ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(children: [const Text('Line:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.lineHeight, min: 0.5, max: 3.5, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.lineHeight = val); setModalState((){}); }))]), Row(children: [const Text('Word:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.wordSpacing, min: -10.0, max: 30.0, activeColor: const Color(0xFF10B981), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.wordSpacing = val); setModalState((){}); }))]), Row(children: [const Text('Letter:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.letterSpacing, min: -5.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.letterSpacing = val); setModalState((){}); }))]) ])); }); }); }
  void showSizeSliderModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Size: ${sel.fontSize.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Slider(value: sel.fontSize, min: 10.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.fontSize = val); setModalState((){}); })])); }); }); }
  void showRotationModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 200, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rotate (گھمائیں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Slider(value: sel.angle, min: -pi, max: pi, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.angle = val); setModalState((){}); }), Text('${(sel.angle * 180 / pi).toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])); }); }); }
  void show3DModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 280, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('3D Perspective (تھری ڈی زاویہ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(children: [const Text('X-Axis:', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Slider(value: sel.pitch, min: -pi/2, max: pi/2, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.pitch = val); setModalState((){}); }))]), Row(children: [const Text('Y-Axis:', style: TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Slider(value: sel.yaw, min: -pi/2, max: pi/2, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.yaw = val); setModalState((){}); }))]), ElevatedButton(onPressed: () { saveState(); setState((){ sel.pitch=0; sel.yaw=0; }); setModalState((){}); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200), child: const Text('Reset Perspective', style: TextStyle(color: Colors.black))) ])); }); }); }
  void showNudgeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { void move(double dx, double dy) { saveState(); setState(() { sel.x += dx; sel.y += dy; }); setModalState((){}); } return Container(height: 260, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Nudge Tool (خردبینی حرکت)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_upward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(0, -2))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_back, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(-2, 0)), const SizedBox(width: 40), IconButton(icon: const Icon(Icons.arrow_forward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(2, 0))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.arrow_downward, size: 35, color: const Color(0xFF8B5CF6)), onPressed: () => move(0, 2))]),])); }); }); }
  void showFontPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Select Font (فونٹ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(), Expanded(child: ListView.builder(itemCount: availableFonts.length, itemBuilder: (context, index) { String fontName = availableFonts[index]; return ListTile(title: Text('اردو فونٹ - $fontName', style: TextStyle(fontFamily: fontName, fontSize: 24)), trailing: sel.fontFamily == fontName ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)) : null, onTap: () { saveState(); setState(() => sel.fontFamily = fontName); Navigator.pop(context); }); })),]),),); }
  void _showAlignmentModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Auto Align (سیدھ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildAlignButton(Icons.align_horizontal_left, 'Left', () { saveState(); setState(() => sel.x = 10); Navigator.pop(context); }), _buildAlignButton(Icons.align_horizontal_center, 'Center', () { saveState(); setState(() => sel.x = (MediaQuery.of(context).size.width - 40 - (sel.width > 0 ? sel.width : 280)) / 2); Navigator.pop(context); }), _buildAlignButton(Icons.align_horizontal_right, 'Right', () { saveState(); setState(() => sel.x = MediaQuery.of(context).size.width - 40 - (sel.width > 0 ? sel.width : 280) - 10); Navigator.pop(context); }),]), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildAlignButton(Icons.align_vertical_top, 'Top', () { saveState(); setState(() => sel.y = 10); Navigator.pop(context); }), _buildAlignButton(Icons.align_vertical_center, 'Middle', () { saveState(); setState(() => sel.y = (MediaQuery.of(context).size.height * 0.5) / 2); Navigator.pop(context); }), _buildAlignButton(Icons.align_vertical_bottom, 'Bottom', () { saveState(); setState(() => sel.y = (MediaQuery.of(context).size.height * 0.6) - 100); Navigator.pop(context); }),]),])); }); }
  Widget _buildAlignButton(IconData icon, String label, VoidCallback onTap) { return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: Column(children: [Icon(icon, color: const Color(0xFF8B5CF6)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),),); }
  void _showResizeModal() { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return Container(height: 300, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Resize Canvas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView(children: [ListTile(leading: const Icon(Icons.crop_square), title: const Text('1:1 (Square / Logo / DP)'), onTap: (){ saveState(); setState(()=> canvasRatio = 1.0); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.crop_16_9), title: const Text('16:9 (YouTube / Post)'), onTap: (){ saveState(); setState(()=> canvasRatio = 16/9); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.crop_portrait), title: const Text('9:16 (Story / Reel / Status)'), onTap: (){ saveState(); setState(()=> canvasRatio = 9/16); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.description), title: const Text('1:1.414 (A4 Print / Letter)'), onTap: (){ saveState(); setState(()=> canvasRatio = 1/1.414); Navigator.pop(context); }),]))])); }); }
  
  void showLayersPanel() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 400, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Layers (پرتیں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: elements.isEmpty ? const Center(child: Text('No elements yet.', style: TextStyle(color: Colors.grey))) : ListView.builder(itemCount: elements.length, itemBuilder: (context, index) { int actualIndex = elements.length - 1 - index; DesignElement e = elements[actualIndex]; bool isSel = selectedId == e.id; return Card(color: isSel ? const Color(0xFFF3E8FF) : Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(side: BorderSide(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: ListTile(leading: CircleAvatar(radius: 16, backgroundColor: e.isText ? e.textColor : Colors.blueGrey, child: Icon(e.isText ? Icons.title : (e.isBorder ? Icons.filter_frames : Icons.category), size: 16, color: Colors.white)), title: Text(e.isText ? e.content.replaceAll('\n', ' ') : (e.isBorder ? e.content : 'Shape'), maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(e.isHidden ? Icons.visibility_off : Icons.visibility, size: 20, color: e.isHidden ? Colors.red : Colors.black54), onPressed: () { saveState(); setState(() => e.isHidden = !e.isHidden); setModalState((){}); }), IconButton(icon: Icon(e.isLocked ? Icons.lock : Icons.lock_open, size: 20, color: e.isLocked ? Colors.red : Colors.black54), onPressed: () { saveState(); setState(() { e.isLocked = !e.isLocked; if(e.isLocked && isSel) selectedId = null; }); setModalState((){}); }), IconButton(icon: const Icon(Icons.arrow_upward, size: 20, color: Colors.black54), onPressed: () { if (actualIndex < elements.length - 1) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex + 1, item); }); setModalState((){}); } }), IconButton(icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black54), onPressed: () { if (actualIndex > 0) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex - 1, item); }); setModalState((){}); } }),]), onTap: () { if(!e.isLocked && !e.isHidden) { setState(() => selectedId = e.id); setModalState((){}); } },)); },)),]));});}); }
  void showPagesPanel() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 400, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pages (صفحات)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView.builder(itemCount: pages.length, itemBuilder: (context, index) { bool isCurrent = currentPageIndex == index; return Card(color: isCurrent ? const Color(0xFFF3E8FF) : Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(side: BorderSide(color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: ListTile(leading: Icon(Icons.description, color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey), title: Text(pages[index].title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [ IconButton(icon: const Icon(Icons.copy, color: Colors.blue, size: 20), onPressed: () { setState(() { pages.insert(index + 1, DesignPage(title: '${pages[index].title} Copy', elements: pages[index].elements.map((e) => e.clone()).toList(), pageColor: pages[index].pageColor, bgImageBytes: pages[index].bgImageBytes, canvasRatio: pages[index].canvasRatio, bgGradient: pages[index].bgGradient)); currentPageIndex = index + 1; }); setModalState(() {}); }), if(pages.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () { setState(() { pages.removeAt(index); if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1; }); setModalState(() {}); }) ]), onTap: () { setState(() { currentPageIndex = index; selectedId = null; }); Navigator.pop(context); },)); },)), const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () { setState(() { pages.add(DesignPage(title: 'Page ${pages.length + 1}', elements: [DesignElement(id: Random().nextInt(10000).toString(), x: 60, y: 100, content: 'نیا صفحہ', width: 250)], pageColor: Colors.white)); currentPageIndex = pages.length - 1; selectedId = null; }); Navigator.pop(context); }, child: const Text('Add New Page', style: TextStyle(color: Colors.white)))),]));});}); }

  // 🔥 CURVED TEXT & BLEND MODALS 🔥
  void _showCurveModal(DesignElement sel) { 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { 
      return StatefulBuilder(builder: (context, setModalState) { 
        return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Curve Text (گولائی)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), 
          const SizedBox(height: 10), 
          Row(children: [const Text('Bend:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.textCurveRadius, min: -150.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.textCurveRadius = val); setModalState((){}); }))]), 
          Row(children: [const Text('Spacing:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: Slider(value: sel.letterSpacing, min: -5.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.letterSpacing = val); setModalState((){}); }))]), 
          ElevatedButton(onPressed: () { saveState(); setState(() => sel.textCurveRadius = 0.0); setModalState((){}); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200), child: const Text('Reset Curve', style: TextStyle(color: Colors.black))) 
        ])); 
      }); 
    }); 
  }

  void _showBlendModeModal(DesignElement sel) { 
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { 
      return StatefulBuilder(builder: (context, setModalState) { 
        return Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Blend Modes (مکس کرنا)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), 
          const Divider(), 
          Expanded(child: ListView.builder(itemCount: _blendModes.length, itemBuilder: (context, index) { 
            String bName = _blendModes[index].toString().replaceAll('BlendMode.', '').toUpperCase(); 
            return ListTile(title: Text(bName, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: sel.blendModeIndex == index ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)) : null, onTap: () { saveState(); setState(() => sel.blendModeIndex = index); Navigator.pop(context); }); 
          }))
        ])); 
      }); 
    }); 
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
          if (!_isExporting)
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
                  panEnabled: !_isCanvasLocked && !hasSelection,
                  scaleEnabled: !_isCanvasLocked,
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
                                        if (e.imageFilter == 1) img = ColorFiltered(colorFilter: const ColorFilter.matrix(grayscaleMatrix), child: img);
                                        else if (e.imageFilter == 2) img = ColorFiltered(colorFilter: const ColorFilter.matrix(sepiaMatrix), child: img);
                                        else if (e.imageFilter == 3) img = ColorFiltered(colorFilter: const ColorFilter.matrix(invertMatrix), child: img);
                                      }

                                      if (e.blendModeIndex != 0) {
                                        img = ColorFiltered(colorFilter: ColorFilter.mode(Colors.transparent, _blendModes[e.blendModeIndex]), child: img);
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
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh Layer Lock hai. Pehle Layers me ja kar unlock karein.', style: TextStyle(fontFamily: 'JameelNoori')), duration: Duration(seconds: 1)));
                                          } else {
                                            setState(() => selectedId = e.id);
                                          }
                                        },
                                        onPanStart: (d) { if(!e.isLocked) saveState(); },
                                        onPanEnd: (d) => setState(() { _snapV = false; _snapH = false; }),
                                        onPanUpdate: (d) {
                                          if(!e.isLocked) {
                                            setState(() { 
                                              selectedId = e.id; 
                                              e.x += d.delta.dx; 
                                              e.y += d.delta.dy; 
                                              
                                              double eCenterX = e.x + currentWidth / 2 + 20; 
                                              double eCenterY = e.y + (e.isText && e.textCurveRadius == 0 ? 100 : currentHeight) / 2 + 15;
                                              
                                              _snapV = (eCenterX - canvasW/2).abs() < 12;
                                              _snapH = (eCenterY - canvasH/2).abs() < 12;

                                              if (_snapV) e.x = canvasW/2 - currentWidth/2 - 20;
                                              if (_snapH) e.y = canvasH/2 - (e.isText && e.textCurveRadius == 0 ? 100 : currentHeight)/2 - 15;
                                            });
                                          }
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
                                                        const Positioned(top: -15, left: 0, right: 0, child: Center(child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.refresh, size: 14, color: Colors.black)))),
                                                        
                                                        Positioned(right: -15, top: 0, bottom: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double w = currentWidth + d.delta.dx; if (w > 50) e.width = w; }); }, child: Container(width: 30, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 8, height: 25, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                                        Positioned(left: -15, top: 0, bottom: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double newW = currentWidth - d.delta.dx; if (newW > 50) { e.width = newW; e.x += d.delta.dx; } }); }, child: Container(width: 30, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 8, height: 25, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                                        if (!e.isText) Positioned(bottom: -15, left: 0, right: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double h = currentHeight + d.delta.dy; if (h > 20) e.height = h; }); }, child: Container(height: 30, color: Colors.transparent, alignment: Alignment.center, child: Container(height: 8, width: 25, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                                        if (!e.isText) Positioned(bottom: -15, right: -15, child: GestureDetector(onPanUpdate: (d) { setState(() { double ratio = currentWidth / currentHeight; double newW = currentWidth + d.delta.dx; if (newW > 50) { e.width = newW; e.height = newW / ratio; } }); }, child: const CircleAvatar(radius: 10, backgroundColor: Color(0xFF8B5CF6), child: Icon(Icons.open_in_full, size: 12, color: Colors.white)))),
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
                                                            InkWell(onTap: bringForward, child: const Icon(Icons.arrow_upward, size: 22, color: Colors.black87)), const SizedBox(width: 15),
                                                            InkWell(onTap: sendBackward, child: const Icon(Icons.arrow_downward, size: 22, color: Colors.black87)), const SizedBox(width: 15),
                                                            InkWell(onTap: duplicateSelected, child: const Icon(Icons.copy, size: 22, color: Colors.black87)), const SizedBox(width: 15),
                                                            InkWell(onTap: deleteSelected, child: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent)),
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

                                  if (_snapV && !_isExporting) Positioned(left: canvasW/2, top: 0, bottom: 0, child: Container(width: 2, color: Colors.redAccent)),
                                  if (_snapH && !_isExporting) Positioned(top: canvasH/2, left: 0, right: 0, child: Container(height: 2, color: Colors.redAccent)),
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
          color: Colors.grey.shade50, padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 10),
                if (sel.isText) _buildToolBtn(Icons.text_fields, 'Size', () => showSizeSliderModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.height, 'Spacing', () => showSpacingModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.format_color_fill, 'Text BG', () => _showTextBgPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.gradient, 'Gradient', () => _showGradientPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.data_usage, 'Curve', () => _showCurveModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.texture, 'Texture', () => _addTextureToText(sel)),
                if (sel.isText && sel.textTextureBytes != null) _buildToolBtn(Icons.layers_clear, 'Clear Texture', () { saveState(); setState(() => sel.textTextureBytes = null); }),
                if (sel.isText) _buildToolBtn(Icons.format_align_left, 'Align Text', () => _toggleAlignment(sel)),
                _buildToolBtn(Icons.center_focus_strong, 'Position', () => _showAlignmentModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.view_in_ar_outlined, '3D Block', () => _show3DBlockModal(sel)),

                // 🔥 FIX: Tint par click karte hi direct color picker khulega 🔥
                if (sel.imageBytes != null) _buildToolBtn(Icons.format_paint, 'Tint Color', () { 
                  saveState(); 
                  setState(() => sel.isTinted = !sel.isTinted); 
                  if(sel.isTinted) _showColorPickerModal(sel); // Auto-open color chart
                }),

                if (sel.imageBytes != null) _buildToolBtn(Icons.auto_awesome_motion, 'Blend', () => _showBlendModeModal(sel)),

                if (!sel.isBorder) _buildToolBtn(Icons.border_color, 'Stroke', () => _showAdvancedStrokeModal(sel)),
                if (!sel.isBorder) _buildToolBtn(Icons.brightness_6, 'Shadow', () => _showAdvancedShadowModal(sel)),
                if (!sel.isText && !sel.isBorder) _buildToolBtn(Icons.rounded_corner, 'Radius', () => _showRadiusModal(sel)),
                if (sel.imageBytes != null && !sel.isTinted) _buildToolBtn(Icons.photo_filter, 'Filters', () => _showImageFiltersModal(sel)),
                if (sel.imageBytes != null) _buildToolBtn(Icons.crop, 'Crop Shape', () => _showShapeClipModal(sel)),
                
                _buildToolBtn(Icons.flip, 'Flip H', () { saveState(); setState(() => sel.flipX = !sel.flipX); }),
                _buildToolBtn(Icons.flip_camera_android, 'Flip V', () { saveState(); setState(() => sel.flipY = !sel.flipY); }),
                _buildToolBtn(Icons.opacity, 'Opacity', () { saveState(); setState(() => sel.opacity = sel.opacity == 1.0 ? 0.5 : 1.0); }),
                _buildToolBtn(Icons.rotate_right, 'Rotate', () => showRotationModal(sel)), 
                _buildToolBtn(Icons.view_in_ar, 'Perspective', () => show3DModal(sel)), 
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
              
              // Only show 'Color' button if it's Text, Border, Shape, OR if it's a Tinted image
              if (sel.isText || sel.isBorder || sel.isShape || sel.isTinted) _buildToolBtn(Icons.palette, 'Color', () => _showColorPickerModal(sel)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTopBtn(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade800, size: 22), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))])); }
  Widget _buildToolBtn(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade700, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700))]))); }
}
