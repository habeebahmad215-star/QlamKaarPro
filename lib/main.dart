import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      theme: ThemeData(primaryColor: const Color(0xFF8B5CF6), scaffoldBackgroundColor: const Color(0xFFF8F9FA)),
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
                  _buildMenuCard(context, 'نیا ڈیزائن', 'New Design', Icons.add_to_photos, const Color(0xFF8B5CF6), true),
                  _buildMenuCard(context, 'آن لائن ڈیزائن', 'Templates', Icons.cloud_download, const Color(0xFF10B981), false),
                  _buildMenuCard(context, 'میرے ڈیزائن', 'My Folder', Icons.folder_special, const Color(0xFFF59E0B), false),
                  _buildMenuCard(context, 'رہنمائی', 'Tutorials', Icons.play_circle_fill, const Color(0xFFEF4444), false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String urduText, String engText, IconData icon, Color color, bool isNewDesign) {
    return InkWell(
      onTap: () {
        if (isNewDesign) _showNewDesignModal(context);
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$engText jald aa raha hai!')));
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

// ================= WORKSPACE ELEMENTS =================
class DesignElement {
  String id; double x, y; String content; Uint8List? imageBytes;
  bool isText; double fontSize; Color textColor; bool hasStroke; bool hasShadow; double opacity;
  bool isBold; bool isItalic; TextAlign textAlign; double lineHeight; String fontFamily;
  bool isBorder; bool isShape; Color elementColor; double width; double height;
  double borderWidth; String borderStyle;

  DesignElement({
    required this.id, required this.x, required this.y, required this.content, this.imageBytes,
    this.isText = true, this.fontSize = 40.0, this.textColor = Colors.black, this.hasStroke = false,
    this.hasShadow = false, this.opacity = 1.0, this.isBold = false, this.isItalic = false,
    this.textAlign = TextAlign.center, this.lineHeight = 1.5, this.fontFamily = 'JameelNoori',
    this.isBorder = false, this.isShape = false, this.elementColor = const Color(0xFFD4AF37),
    this.width = 0, this.height = 0, this.borderWidth = 5.0, this.borderStyle = 'royal_islamic',
  });

  DesignElement clone() {
    return DesignElement(
      id: id, x: x, y: y, content: content, imageBytes: imageBytes, isText: isText, fontSize: fontSize,
      textColor: textColor, hasStroke: hasStroke, hasShadow: hasShadow, opacity: opacity,
      isBold: isBold, isItalic: isItalic, textAlign: textAlign, lineHeight: lineHeight, fontFamily: fontFamily,
      isBorder: isBorder, isShape: isShape, elementColor: elementColor, width: width, height: height,
      borderWidth: borderWidth, borderStyle: borderStyle,
    );
  }
}

class DesignPage {
  String title; List<DesignElement> elements; Color pageColor;
  DesignPage({required this.title, required this.elements, required this.pageColor});
}

// ================= MAIN EDITOR SCREEN =================
class ProWorkspaceScreen extends StatefulWidget {
  const ProWorkspaceScreen({Key? key}) : super(key: key);
  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  List<DesignPage> pages = [
    DesignPage(title: 'Page 1', elements: [DesignElement(id: 'demo1', x: 40, y: 150, content: 'مدرسہ اسلامیہ نصیرالعلوم', width: 280)], pageColor: Colors.white)
  ];
  int currentPageIndex = 0;
  List<List<DesignElement>> undoStack = [];
  List<List<DesignElement>> redoStack = [];
  String? selectedId;
  double canvasRatio = 1 / 1.414; 
  List<String> availableFonts = ['JameelNoori', 'Amiri', 'Bombay', 'Mehr'];
  final ImagePicker _picker = ImagePicker();
  
  bool _isExporting = false;

  List<DesignElement> get elements => pages[currentPageIndex].elements;
  set elements(List<DesignElement> val) => pages[currentPageIndex].elements = val;
  Color get pageColor => pages[currentPageIndex].pageColor;
  set pageColor(Color val) => pages[currentPageIndex].pageColor = val;

  void saveState() { undoStack.add(elements.map((e) => e.clone()).toList()); redoStack.clear(); }
  void undoAction() { if (undoStack.isNotEmpty) { redoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = undoStack.removeLast(); selectedId = null; }); } }
  void redoAction() { if (redoStack.isNotEmpty) { undoStack.add(elements.map((e) => e.clone()).toList()); setState(() { elements = redoStack.removeLast(); selectedId = null; }); } }

  // ==== EXPORT & SAVE LOGIC (ULTRA HD FIX) ====
  void _showExportMenu() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 350, padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Export Design (سیو کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            _buildExportOption(Icons.image, 'Save as JPG', 'High Quality Image (Gallery)', Colors.blue, () {
              Navigator.pop(context); _captureAndSave('JPG');
            }),
            const SizedBox(height: 10),
            _buildExportOption(Icons.layers_clear, 'Save as PNG', 'Transparent Image (Logos)', Colors.purple, () {
              Navigator.pop(context); _captureAndSave('PNG');
            }),
            const SizedBox(height: 10),
            _buildExportOption(Icons.picture_as_pdf, 'Save as HD PDF', '100% Crisp Print Quality', Colors.red, () {
              Navigator.pop(context); _captureAndSave('PDF');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))])),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndSave(String format) async {
    setState(() {
      selectedId = null;
      _isExporting = true; 
    });
    
    // UI refresh hone ka wait karein
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // 🚀 HD LOGIC: PDF ke liye 5.0 (Ultra HD), Images ke liye 3.0
      double pixelRatio = format == 'PDF' ? 5.0 : 3.0;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (format == 'JPG' || format == 'PNG') {
        final result = await ImageGallerySaver.saveImage(
          pngBytes, quality: 100, name: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}"
        );
        if (mounted && result != null && result['isSuccess'] == true) {
          _showSuccessDialog('Saved to Gallery!', 'Aapka $format design phone ki gallery mein save ho gaya hai.');
        }
      } 
      else if (format == 'PDF') {
        // PDF ko bina compress kiye exact HD image ke sath map karna
        final pdf = pw.Document(compress: false);
        final imagePdf = pw.MemoryImage(pngBytes);
        
        double imgWidth = image.width.toDouble();
        double imgHeight = image.height.toDouble();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(imgWidth, imgHeight), // Exact HD dimension match
            margin: pw.EdgeInsets.zero, // Zero margin to prevent "page inside page"
            build: (pw.Context context) {
              return pw.Image(imagePdf, fit: pw.BoxFit.contain);
            },
          ),
        );

        Uint8List pdfBytes = await pdf.save();
        await Printing.sharePdf(
          bytes: pdfBytes, 
          filename: "QalamKaarPro_${DateTime.now().millisecondsSinceEpoch}.pdf"
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
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  // ==== TEXT COMPOSER ====
  void _showTextComposerDialog({DesignElement? existingElement}) {
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? '');
    
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75, padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: const Text('English', style: TextStyle(color: Colors.grey))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Text('اردو', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15), color: Colors.grey.shade50),
                  child: TextField(
                    controller: controller, maxLines: null, textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 28),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'یہاں لکھیں...', hintTextDirection: TextDirection.rtl),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildComposerTool(Icons.paste, 'Paste'),
                  _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()),
                  _buildComposerTool(Icons.auto_awesome, 'AI'),
                  _buildComposerTool(Icons.translate, 'Translate'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)))),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          saveState();
                          if (existingElement != null) {
                            setState(() => existingElement.content = controller.text);
                          } else {
                            var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, width: 280);
                            setState(() { elements.add(newEl); selectedId = newEl.id; });
                          }
                        }
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Add to design', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(children: [Icon(icon, color: Colors.grey.shade600), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))])); }

  // ==== "ADD NEW" MODAL ====
  void showAddNewModal() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15,
                children: [
                  _buildGridItem(Icons.image, 'Gallery Pic', Colors.blue.shade100, Colors.blue, addImageFromGallery),
                  _buildGridItem(Icons.collections, 'Stock Images', Colors.indigo.shade100, Colors.indigo, () => Navigator.pop(context)),
                  _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade100, Colors.teal, () => Navigator.pop(context)),
                  _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade100, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }),
                  _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade100, Colors.amber.shade800, () => showGenericStockModal('Borders', 'royal_islamic', Icons.border_outer)),
                  _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade100, Colors.pink, () => showGenericStockModal('Shapes', 'shape_rect', Icons.category)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: iconColor, size: 28)),
          const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showColorPickerModal(DesignElement sel) {
    List<Color> colorPalette = [
      Colors.black, Colors.white, Colors.grey.shade800, Colors.grey.shade400,
      const Color(0xFFEF4444), const Color(0xFFF97316), const Color(0xFFF59E0B), const Color(0xFFEAB308),
      const Color(0xFF84CC16), const Color(0xFF22C55E), const Color(0xFF10B981), const Color(0xFF14B8A6),
      const Color(0xFF06B6D4), const Color(0xFF3B82F6), const Color(0xFF6366F1), const Color(0xFF8B5CF6),
      const Color(0xFFA855F7), const Color(0xFFD946EF), const Color(0xFFEC4899), const Color(0xFFF43F5E),
      const Color(0xFFD4AF37), const Color(0xFF8B4513),
    ];

    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Color currentColor = sel.isText ? sel.textColor : sel.elementColor;
            return Container(
              height: 380, padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Color (رنگ منتخب کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
                  const Divider(),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 15, mainAxisSpacing: 15),
                      itemCount: colorPalette.length,
                      itemBuilder: (context, index) {
                        Color c = colorPalette[index];
                        bool isSelected = currentColor.value == c.value;
                        return GestureDetector(
                          onTap: () {
                            saveState();
                            setState(() { if (sel.isText) { sel.textColor = c; } else { sel.elementColor = c; } });
                            setModalState((){}); 
                          },
                          child: Container(
                            decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5), boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null),
                            child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20) : null,
                          ),
                        );
                      }
                    )
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  // ==== PANELS & ACTIONS ====
  Future<void> addImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) { final bytes = await image.readAsBytes(); saveState(); setState(() => elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 80, content: '', imageBytes: bytes, isText: false))); }
    } catch (e) {}
    Navigator.pop(context);
  }

  void showGenericStockModal(String categoryTitle, String styleName, IconData categoryIcon) {
    Navigator.pop(context);
    List<Map<String, dynamic>> stockList = [];
    List<Color> themeColors = [const Color(0xFFD4AF37), const Color(0xFF8B5CF6), const Color(0xFF047857), const Color(0xFF1E3A8A)];
    for (int i = 1; i <= 50; i++) stockList.add({'title': '$categoryTitle #$i', 'style': styleName, 'color': themeColors[(i - 1) % themeColors.length], 'icon': categoryIcon});

    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75, padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 15),
            Text('$categoryTitle Library', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))), const Divider(),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.4),
                itemCount: stockList.length,
                itemBuilder: (context, index) {
                  var item = stockList[index];
                  return InkWell(
                    onTap: () {
                      saveState();
                      setState(() {
                        if (styleName.contains('shape') || styleName == 'badge') { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 90, y: 180, content: styleName == 'badge' ? 'circle' : 'rectangle', isText: false, isShape: true, elementColor: item['color'], width: 220, height: 90)); } else { elements.insert(0, DesignElement(id: Random().nextInt(10000).toString(), x: 0, y: 0, content: item['title'], isText: false, isBorder: true, borderStyle: styleName, elementColor: item['color'], borderWidth: 5.0)); }
                      });
                      Navigator.pop(context);
                    },
                    child: Container(decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: item['color'], width: 1.5)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item['icon'], color: item['color'], size: 30), const SizedBox(height: 6), Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item['color']))])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void deleteSelected() { if (selectedId != null) { saveState(); setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; }); } }
  void duplicateSelected() {
    if (selectedId != null) { saveState(); DesignElement sel = elements.firstWhere((e) => e.id == selectedId); setState(() { var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20; elements.add(newEl); selectedId = newEl.id; }); }
  }
  void bringForward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx < elements.length - 1) setState(() { var item = elements.removeAt(idx); elements.insert(idx + 1, item); }); }
  void sendBackward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx > 0) setState(() { var item = elements.removeAt(idx); elements.insert(idx - 1, item); }); }
  void _toggleAlignment(DesignElement sel) { saveState(); setState(() { sel.textAlign = (sel.textAlign == TextAlign.right) ? TextAlign.center : (sel.textAlign == TextAlign.center ? TextAlign.left : TextAlign.right); }); }

  void showLayersPanel() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 400, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Layers (پرتیں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: elements.isEmpty ? const Center(child: Text('No elements yet.', style: TextStyle(color: Colors.grey))) : ListView.builder(itemCount: elements.length, itemBuilder: (context, index) { int actualIndex = elements.length - 1 - index; DesignElement e = elements[actualIndex]; bool isSel = selectedId == e.id; return Card(color: isSel ? const Color(0xFFF3E8FF) : Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(side: BorderSide(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: ListTile(leading: CircleAvatar(radius: 16, backgroundColor: e.isText ? e.textColor : Colors.blueGrey, child: Icon(e.isText ? Icons.title : (e.isBorder ? Icons.filter_frames : Icons.category), size: 16, color: Colors.white)), title: Text(e.isText ? e.content.replaceAll('\n', ' ') : (e.isBorder ? e.content : 'Shape'), maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.arrow_upward, size: 20, color: Colors.black54), onPressed: () { if (actualIndex < elements.length - 1) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex + 1, item); }); setModalState((){}); } }), IconButton(icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black54), onPressed: () { if (actualIndex > 0) { saveState(); setState(() { var item = elements.removeAt(actualIndex); elements.insert(actualIndex - 1, item); }); setModalState((){}); } }),]), onTap: () { setState(() => selectedId = e.id); setModalState((){}); },)); },)),]));});});
  }

  void showPagesPanel() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) { return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) { return Container(height: 400, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pages (صفحات)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView.builder(itemCount: pages.length, itemBuilder: (context, index) { bool isCurrent = currentPageIndex == index; return Card(color: isCurrent ? const Color(0xFFF3E8FF) : Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(side: BorderSide(color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: ListTile(leading: Icon(Icons.description, color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey), title: Text(pages[index].title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)), trailing: pages.length > 1 ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () { setState(() { pages.removeAt(index); if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1; }); setModalState(() {}); }) : null, onTap: () { setState(() { currentPageIndex = index; selectedId = null; }); Navigator.pop(context); },)); },)), const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), onPressed: () { setState(() { pages.add(DesignPage(title: 'Page ${pages.length + 1}', elements: [DesignElement(id: Random().nextInt(10000).toString(), x: 60, y: 100, content: 'نیا صفحہ', width: 250)], pageColor: Colors.white)); currentPageIndex = pages.length - 1; selectedId = null; }); Navigator.pop(context); }, child: const Text('Add New Page', style: TextStyle(color: Colors.white)))),]));});});
  }

  void showSizeSliderModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Text Size: ${sel.fontSize.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Slider(value: sel.fontSize, min: 10.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.fontSize = val); setModalState((){}); })])); }); }); }
  void showSpacingSliderModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Line Spacing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), Slider(value: sel.lineHeight, min: 0.5, max: 3.5, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.lineHeight = val); setModalState((){}); })])); }); }); }
  void showFontPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Select Font (فونٹ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(), Expanded(child: ListView.builder(itemCount: availableFonts.length, itemBuilder: (context, index) { String fontName = availableFonts[index]; return ListTile(title: Text('حبیب احمد خان - $fontName', style: TextStyle(fontFamily: fontName, fontSize: 24)), trailing: sel.fontFamily == fontName ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)) : null, onTap: () { saveState(); setState(() => sel.fontFamily = fontName); Navigator.pop(context); }); })),]),),); }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = selectedId != null;
    DesignElement? sel;
    if (hasSelection) sel = elements.firstWhere((e) => e.id == selectedId);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, titleSpacing: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _buildTopBtn(Icons.layers, 'Layers', showLayersPanel), const SizedBox(width: 10),
          _buildTopBtn(Icons.auto_stories, 'Pages', showPagesPanel), const SizedBox(width: 10),
          _buildTopBtn(Icons.undo, 'Undo', undoAction), const SizedBox(width: 10),
          _buildTopBtn(Icons.redo, 'Redo', redoAction), const SizedBox(width: 10),
        ]),
        actions: [
          InkWell(
            onTap: _showExportMenu,
            child: Container(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Row(children: const [Icon(Icons.download, color: Colors.white, size: 16), SizedBox(width: 5), Text('Save Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
          )
        ],
      ),
      
      body: GestureDetector(
        onTap: () => setState(() => selectedId = null), 
        child: Center(
          child: AspectRatio(
            aspectRatio: canvasRatio,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
              ),
              child: RepaintBoundary(
                key: _canvasKey,
                child: Container(
                  color: pageColor, 
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (!_isExporting)
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(15), 
                            decoration: BoxDecoration(border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5)),
                            child: Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(4.0), child: Text('Safe Area', style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontSize: 10)))),
                          ),
                        ),
                      
                      ...elements.map((e) {
                        bool isSel = e.id == selectedId;
                        
                        if (e.isBorder) {
                          return Positioned.fill(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedId = e.id),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: e.elementColor, width: e.borderWidth),
                                  borderRadius: BorderRadius.circular(10),
                                  color: isSel && !_isExporting ? Colors.purple.withOpacity(0.05) : Colors.transparent,
                                )
                              )
                            )
                          );
                        }

                        List<Shadow> textShadows = [];
                        if (e.hasShadow) textShadows.add(const Shadow(color: Colors.black54, offset: Offset(3, 3), blurRadius: 5));
                        if (e.hasStroke) textShadows.addAll([Shadow(color: Colors.white, offset: const Offset(-1.5, -1.5)), Shadow(color: Colors.white, offset: const Offset(1.5, 1.5))]);

                        Widget contentWidget;
                        if (e.isShape) {
                          contentWidget = Container(width: e.width, height: e.height, decoration: BoxDecoration(color: e.elementColor, borderRadius: BorderRadius.circular(8)));
                        } else if (e.imageBytes != null) {
                          contentWidget = Image.memory(e.imageBytes!, width: 150, height: 150, fit: BoxFit.cover);
                        } else {
                          double currentWidth = e.width > 0 ? e.width : 280.0;
                          contentWidget = SizedBox(
                            width: currentWidth,
                            child: Text(
                              e.content, textAlign: e.textAlign, softWrap: true,
                              style: TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, color: e.textColor, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, height: e.lineHeight, shadows: textShadows.isNotEmpty ? textShadows : null),
                            ),
                          );
                        }

                        if (_isExporting) {
                          return Positioned(
                            left: e.x, top: e.y,
                            child: Opacity(opacity: e.opacity, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), child: contentWidget)),
                          );
                        }

                        return Positioned(
                          left: e.x, top: e.y,
                          child: GestureDetector(
                            onTap: () => setState(() => selectedId = e.id),
                            onPanStart: (d) => saveState(),
                            onPanUpdate: (d) => setState(() { selectedId = e.id; e.x += d.delta.dx; e.y += d.delta.dy; }),
                            child: isSel 
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5), color: Colors.purple.withOpacity(0.05)),
                                        child: Opacity(opacity: e.opacity, child: contentWidget),
                                      ),
                                      const Positioned(top: -15, left: 0, right: 0, child: Center(child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.refresh, size: 14, color: Colors.black)))),
                                      if (e.isText) Positioned(right: -10, top: 0, bottom: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double w = (e.width > 0 ? e.width : 280.0) + d.delta.dx; if (w > 50) e.width = w; }); }, child: Container(width: 25, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 8, height: 25, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                      if (e.isText) Positioned(left: -10, top: 0, bottom: 0, child: GestureDetector(onPanUpdate: (d) { setState(() { double newW = (e.width > 0 ? e.width : 280.0) - d.delta.dx; if (newW > 50) { e.width = newW; e.x += d.delta.dx; } }); }, child: Container(width: 25, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 8, height: 25, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)))))),
                                      Positioned(
                                        bottom: -45, left: 0, right: 0,
                                        child: Center(
                                          child: Material(
                                            elevation: 4, borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(onTap: bringForward, child: const Icon(Icons.arrow_upward, size: 20, color: Colors.black54)), const SizedBox(width: 15),
                                                  InkWell(onTap: sendBackward, child: const Icon(Icons.arrow_downward, size: 20, color: Colors.black54)), const SizedBox(width: 15),
                                                  InkWell(onTap: duplicateSelected, child: const Icon(Icons.copy, size: 20, color: Colors.black54)), const SizedBox(width: 15),
                                                  InkWell(onTap: deleteSelected, child: const Icon(Icons.delete_outline, size: 20, color: Colors.black54)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), child: Opacity(opacity: e.opacity, child: contentWidget)),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(child: Container(color: Colors.white, child: hasSelection ? _buildSelectedToolBar(sel!) : _buildDefaultBottomBar())),
    );
  }

  // ==== BOTTOM TOOLBARS ====
  Widget _buildDefaultBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: showAddNewModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(15)),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.close, color: Color(0xFF8B5CF6), size: 28), SizedBox(height: 2), Text('ADD NEW', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold))]),
            ),
          ),
          _buildToolBtn(Icons.aspect_ratio, 'Resize Paper'),
          _buildToolBtn(Icons.layers_clear, 'Transparent BG'),
          _buildToolBtn(Icons.format_color_fill, 'BG Color', () { saveState(); setState(() => pageColor = pageColor == Colors.white ? Colors.amber.shade100 : Colors.white); }),
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
                if (sel.isText) _buildToolBtn(Icons.format_align_left, 'Align', () => _toggleAlignment(sel)),
                if (sel.isText) _buildToolBtn(Icons.height, 'Spacing', () => showSpacingSliderModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.border_color, 'Stroke', () { saveState(); setState(() => sel.hasStroke = !sel.hasStroke); }),
                if (sel.isText) _buildToolBtn(Icons.brightness_6, 'Shadow', () { saveState(); setState(() => sel.hasShadow = !sel.hasShadow); }),
                _buildToolBtn(Icons.opacity, 'Opacity', () { saveState(); setState(() => sel.opacity = sel.opacity == 1.0 ? 0.5 : 1.0); }),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => selectedId = null),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6)), borderRadius: BorderRadius.circular(20)), child: Row(children: const [Icon(Icons.remove_circle_outline, color: Color(0xFF8B5CF6), size: 18), SizedBox(width: 5), Text('DESELECT', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12))])),
              ),
              const Expanded(child: SizedBox()),
              if (sel.isText) _buildToolBtn(Icons.edit, 'Edit', () => _showTextComposerDialog(existingElement: sel)),
              if (sel.isText) _buildToolBtn(Icons.font_download, 'Font', () => showFontPickerModal(sel)),
              if (sel.isText || sel.isBorder || sel.isShape) _buildToolBtn(Icons.palette, 'Color', () => _showColorPickerModal(sel)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTopBtn(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade800, size: 22), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))])); }
  Widget _buildToolBtn(IconData icon, String label, [VoidCallback? onTap]) { return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade700, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700))]))); }
}
