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

  static const List<double> grayscaleMatrix = [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0];
  static const List<double> sepiaMatrix = [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0];
  static const List<double> invertMatrix = [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0];
  final List<BlendMode> _blendModes = [BlendMode.srcOver, BlendMode.multiply, BlendMode.screen, BlendMode.overlay, BlendMode.darken, BlendMode.colorBurn];

  final Map<String, List<String>> _urduPoetryLibrary = {
    'اسلامی (Islamic)': [
      'بے شک اللہ صبر کرنے والوں کے ساتھ ہے۔',
      'جو اللہ کا ہو جاتا ہے، اللہ اس کا ہو جاتا ہے۔',
      'نماز تمام بیماریوں کی شفا ہے۔',
      'حسبنا اللہ ونعم الوکیل\n(ہمیں اللہ ہی کافی ہے اور وہی سب سے بہتر کارساز ہے)',
      'اے اللہ! ہمارے دلوں کو اپنے دین پر ثابت قدم رکھ۔',
      'قرآن وہ کتاب ہے جو اندھیروں سے نکال کر روشنی کی طرف لاتی ہے۔',
      'تمہارا بہترین دوست وہ ہے جو تمہیں اللہ کی یاد دلائے۔',
      'جب دعائیں قبول نہ ہو رہی ہوں تو سجدے لمبے کر دو۔',
      'اللہ کی رحمت سے کبھی مایوس نہ ہونا۔',
      'موت کو ہمیشہ یاد رکھو، یہ بہترین نصیحت کرنے والی ہے۔',
    ],
    'اقوال (Quotes)': [
      'وقت وہ واحد سکہ ہے جو آپ کی زندگی بناتا ہے۔',
      'خاموشی سب سے بہترین جواب ہے اس کے لیے جو آپ کے الفاظ کی قدر نہ کرے۔',
      'علم ایک ایسا خزانہ ہے جسے کوئی چوری نہیں کر سکتا۔',
      'زندگی میں کبھی ہار نہ مانو، کیونکہ گچھے کی آخری چابی بھی تالا کھول سکتی ہے۔',
      'اچھے اخلاق وہ واحد خوبصورتی ہے جو کبھی ختم نہیں ہوتی۔',
      'تجربہ ایک سخت استاد ہے کیونکہ وہ پہلے امتحان لیتا ہے اور بعد میں سبق دیتا ہے۔',
      'انسان کی اصل پہچان اس کے الفاظ نہیں، اس کا عمل ہوتا ہے۔',
      'جو دوسروں کو معاف کرنا جانتا ہے، وہ اندر سے بہت مضبوط ہوتا ہے۔',
      'غصہ ایک ایسا زہر ہے جو انسان خود پیتا ہے اور مرنے کی امید دوسروں کی کرتا ہے۔',
      'امید وہ روشنی ہے جو گھنے اندھیرے میں بھی راستہ دکھاتی ہے۔',
    ],
    'علامہ اقبال (Allama Iqbal)': [
      'ہزاروں سال نرگس اپنی بے نوری پہ روتی ہے\nبڑی مشکل سے ہوتا ہے چمن میں دیدہ ور پیدا',
      'عمل سے زندگی بنتی ہے جنت بھی جہنم بھی\nیہ خاکی اپنی فطرت میں نہ نوری ہے نہ ناری ہے',
      'ستاروں سے آگے جہاں اور بھی ہیں\nابھی عشق کے امتحاں اور بھی ہیں',
      'خودی کو کر بلند اتنا کہ ہر تقدیر سے پہلے\nخدا بندے سے خود پوچھے بتا تیری رضا کیا ہے',
      'نہیں تیرا نشیمن قصرِ سلطانی کے گنبد پر\nتو شاہیں ہے، بسیرا کر پہاڑوں کی چٹانوں میں',
      'خدا تجھے کسی طوفان سے آشنا کر دے\nکہ تیرے بحر کی موجوں میں اضطراب نہیں',
      'مٹا دے اپنی ہستی کو اگر کچھ مرتبہ چاہیے\nکہ دانہ خاک میں مل کر گل و گلزار ہوتا ہے',
      'کی محمدؐ سے وفا تو نے تو ہم تیرے ہیں\nیہ جہاں چیز ہے کیا لوح و قلم تیرے ہیں',
    ],
    'محبت (Love)': [
      'دل دھڑکنے کا سبب یاد آیا\nوہ تری یاد تھی اب یاد آیا',
      'تمہارے بعد کسی اور کو چاہا نہ گیا\nیہ وہ سچ ہے جو کبھی ہم سے چھپایا نہ گیا',
      'محبت میں نہیں ہے شرطِ ملنا اور بچھڑ جانا\nمحبت تو بس اک احساس ہے جو دل میں رہتا ہے',
      'ہم کو ان سے وفا کی ہے امید\nجو نہیں جانتے وفا کیا ہے',
      'تیرے بنا زندگی سے کوئی شکوہ تو نہیں\nتیرے بنا زندگی بھی لیکن زندگی نہیں',
      'کسی کو ٹوٹ کر چاہنا اور پھر ٹوٹ جانا\nیہی محبت کی سب سے بڑی حقیقت ہے',
    ],
    'اداس (Sad)': [
      'ہم نے سینے سے لگایا دل نہ اپنا بن سکا\nمسکراہٹ کو ترستے ہی رہے روتے رہے',
      'دل کے ٹوٹنے کی کوئی آواز نہیں ہوتی\nبس ایک خاموشی ہوتی ہے جو عمر بھر رلاتی ہے',
      'کبھی کبھی ہم غلط نہیں ہوتے\nبس ہمارے پاس وہ الفاظ نہیں ہوتے جو ہمیں صحیح ثابت کر سکیں',
      'تجھ سے بچھڑ کر ہم بھی کہاں پہلے جیسے رہے\nبس سانسیں چلتی ہیں اور زندگی کٹ رہی ہے',
      'کچھ درد ایسے ہوتے ہیں جو نہ کسی کو بتائے جا سکتے ہیں نہ سہہ جا سکتے ہیں۔',
      'وقت کے ساتھ سب کچھ بدل جاتا ہے، حتیٰ کہ وہ لوگ بھی جن پر ہمیں سب سے زیادہ یقین ہوتا ہے۔',
      'زندگی کا سب سے بڑا دکھ یہ ہے کہ جب ہم سچ بول رہے ہوں اور کوئی اعتبار نہ کرے۔',
      'آنسو وہ الفاظ ہیں جو دل بول نہیں پاتا۔',
    ],
  };

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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project saved successfully! 🎉', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Color(0xFF10B981)));
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
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))), 
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 20)), const SizedBox(width: 12), 
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)), Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey))])), 
          Icon(Icons.arrow_forward_ios, color: color, size: 14)
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
          _showSuccessDialog('Saved to Gallery!', 'Image saved successfully.'); 
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
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 50), const SizedBox(height: 15), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 15), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.white))))]))); 
  }

  void _showPoetryLibrary(TextEditingController textController) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(15),
          child: DefaultTabController(
            length: _urduPoetryLibrary.keys.length,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Urdu Library', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))
                  ],
                ),
                TabBar(
                  isScrollable: true, labelColor: const Color(0xFF8B5CF6), unselectedLabelColor: Colors.grey, indicatorColor: const Color(0xFF8B5CF6),
                  tabs: _urduPoetryLibrary.keys.map((k) => Tab(text: k)).toList(),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: _urduPoetryLibrary.keys.map((category) {
                      return ListView.builder(
                        itemCount: _urduPoetryLibrary[category]!.length,
                        itemBuilder: (context, index) {
                          String text = _urduPoetryLibrary[category]![index];
                          return Card(
                            color: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 18, height: 1.5)),
                              onTap: () {
                                textController.text = text;
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          )
        );
      }
    );
  }

  void _showTashkeelModal(TextEditingController controller) {
    final List<String> tashkeelList = ['َ', 'ِ', 'ُ', 'ً', 'ٍ', 'ٌ', 'ّ', 'ْ', 'ٰ', 'ٓ', 'ے', 'ۓ', 'ﷺ', 'ؓ', 'ؒ', 'ﷻ', 'ﷲ', 'اکبر', 'جل جلالہ', 'بسم اللہ'];
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) {
      return Container(height: 350, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tashkeel & Symbols', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]),
        Divider(color: Colors.grey.shade200),
        Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: tashkeelList.length, itemBuilder: (context, index) {
          return InkWell(onTap: () { controller.text += tashkeelList[index]; Navigator.pop(context); }, borderRadius: BorderRadius.circular(8), child: Container(decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), alignment: Alignment.center, child: Text(tashkeelList[index], style: const TextStyle(fontSize: 22, fontFamily: 'JameelNoori', color: Colors.black87))));
        }))
      ]));
    });
  }

  void _showTextComposerDialog({DesignElement? existingElement}) { 
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? ''); 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(20), child: Column(children: [Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: const Text('English', style: TextStyle(color: Colors.grey, fontSize: 12))), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]), child: const Text('اردو', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)))])), const SizedBox(height: 12), Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50), child: TextField(controller: controller, maxLines: null, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 24), decoration: const InputDecoration(border: InputBorder.none, hintText: 'یہاں لکھیں...', hintTextDirection: TextDirection.rtl)))), const SizedBox(height: 12), 
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _buildComposerTool(Icons.paste, 'Paste', () async { ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain); if (data != null && data.text != null) controller.text += data.text!; }), 
      _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()), 
      _buildComposerTool(Icons.auto_stories, 'شاعری', () => _showPoetryLibrary(controller)), 
      _buildComposerTool(Icons.format_quote, 'اعراب', () => _showTashkeelModal(controller)) 
    ]), 
    const SizedBox(height: 16), Row(children: [Expanded(flex: 1, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: Colors.grey.shade300)), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)))), const SizedBox(width: 10), Expanded(flex: 2, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { if (controller.text.isNotEmpty) { saveState(); if (existingElement != null) { setState(() => existingElement.content = controller.text); } else { var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 40, y: 100, content: controller.text, width: 280); setState(() { elements.add(newEl); selectedId = newEl.id; }); } } Navigator.pop(context); }, icon: const Icon(Icons.check, color: Colors.white, size: 16), label: const Text('Add to design', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))))])])))); 
  }

  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) { 
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [Icon(icon, color: const Color(0xFF8B5CF6), size: 20), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87))]))); 
  }

  void showAddNewModal() { 
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.60, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))), padding: const EdgeInsets.all(20), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), 
    Expanded(child: GridView.count(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
      _buildGridItem(Icons.image, 'Gallery', Colors.blue.shade50, Colors.blue, addImageFromGallery), 
      _buildGridItem(Icons.gradient, 'Backgrounds', Colors.indigo.shade50, Colors.indigo, () { Navigator.pop(context); _showCanvasBgGradientModal(); }), 
      _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade50, Colors.teal, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())); }), 
      _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade50, Colors.orange, () { Navigator.pop(context); _showTextComposerDialog(); }), 
      _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade50, Colors.amber.shade800, () => showGenericStockModal('Borders', 'royal_islamic', Icons.border_outer)), 
      _buildGridItem(Icons.category, 'Shapes', Colors.pink.shade50, Colors.pink, () => showGenericStockModal('Shapes', 'shape_rect', Icons.category))
    ]))]))); 
  }

  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) { 
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center)]))); 
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), 
      builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.70, padding: const EdgeInsets.all(16), child: Column(children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 12), Text(categoryTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))), Divider(color: Colors.grey.shade200), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4), itemCount: stockList.length, itemBuilder: (context, index) { var item = stockList[index]; return InkWell(onTap: () { saveState(); setState(() { if (styleName.contains('shape') || styleName == 'badge') { elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 90, y: 180, content: styleName == 'badge' ? 'circle' : 'rectangle', isText: false, isShape: true, elementColor: item['color'], width: 220, height: 90)); } else { elements.insert(0, DesignElement(id: Random().nextInt(10000).toString(), x: 0, y: 0, content: item['title'], isText: false, isBorder: true, borderStyle: styleName, elementColor: item['color'], borderWidth: 5.0)); } }); Navigator.pop(context); }, borderRadius: BorderRadius.circular(10), child: Container(decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: (item['color'] as Color).withOpacity(0.3), width: 1.0)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item['icon'], color: item['color'], size: 24), const SizedBox(height: 6), Text(item['title'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: item['color']))]))); }))] ))
    ); 
  }

  void deleteSelected() { if (selectedId != null) { saveState(); setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; }); } }
  void duplicateSelected() { if (selectedId != null) { saveState(); DesignElement sel = elements.firstWhere((e) => e.id == selectedId); setState(() { var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20; elements.add(newEl); selectedId = newEl.id; }); } }
  void bringForward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx < elements.length - 1) setState(() { var item = elements.removeAt(idx); elements.insert(idx + 1, item); }); }
  void sendBackward() { if (selectedId == null) return; saveState(); int idx = elements.indexWhere((e) => e.id == selectedId); if (idx > 0) setState(() { var item = elements.removeAt(idx); elements.insert(idx - 1, item); }); }
  void _toggleAlignment(DesignElement sel) { saveState(); setState(() { sel.textAlign = (sel.textAlign == TextAlign.right) ? TextAlign.center : (sel.textAlign == TextAlign.center ? TextAlign.left : TextAlign.right); }); }

  // 🔥 FORMATTED & SAFE COLOR / GRADIENT MODALS 🔥
  void _showCanvasBgColorModal() {
    TextEditingController hexCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Canvas Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hexCtrl,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Hex: #FF0000',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)
                            )
                          )
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          onPressed: () {
                            String hex = hexCtrl.text.replaceAll('#', '');
                            if(hex.length == 6) hex = 'FF$hex';
                            if(hex.length == 8) {
                              saveState();
                              setState(() {
                                pageColor = Color(int.parse('0x$hex'));
                                bgImageBytes = null;
                                bgGradient = null;
                              });
                              setModalState(() {});
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 12))
                        )
                      ]
                    )
                  ),
                  Divider(color: Colors.grey.shade200),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12
                      ),
                      itemCount: _proColorPalette.length,
                      itemBuilder: (context, index) {
                        Color c = _proColorPalette[index];
                        bool isSelected = pageColor.value == c.value;
                        return GestureDetector(
                          onTap: () {
                            saveState();
                            setState(() {
                              pageColor = c;
                              bgImageBytes = null;
                              bgGradient = null;
                            });
                            setModalState(() {});
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1.0),
                              boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 4)] : null
                            ),
                            child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null
                          )
                        );
                      }
                    )
                  )
                ]
              )
            )
          );
        });
      }
    );
  }

  void _showColorPickerModal(DesignElement sel) {
    TextEditingController hexCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          Color currentColor = sel.isText ? sel.textColor : sel.elementColor;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Color Picker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hexCtrl,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Hex: #FF0000',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10)
                            )
                          )
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          onPressed: () {
                            String hex = hexCtrl.text.replaceAll('#', '');
                            if(hex.length == 6) hex = 'FF$hex';
                            if(hex.length == 8) {
                              saveState();
                              setState(() {
                                if(sel.isText) {
                                  sel.textColor = Color(int.parse('0x$hex'));
                                  sel.textGradient = null;
                                } else {
                                  sel.elementColor = Color(int.parse('0x$hex'));
                                }
                              });
                              setModalState(() {});
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 12))
                        )
                      ]
                    )
                  ),
                  Divider(color: Colors.grey.shade200),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10
                      ),
                      itemCount: _proColorPalette.length,
                      itemBuilder: (context, index) {
                        Color c = _proColorPalette[index];
                        bool isSelected = currentColor.value == c.value;
                        return GestureDetector(
                          onTap: () {
                            saveState();
                            setState(() {
                              if (sel.isText) {
                                sel.textColor = c;
                                sel.textGradient = null;
                              } else {
                                sel.elementColor = c;
                              }
                            });
                            setModalState(() {});
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1.0),
                              boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.3), blurRadius: 4)] : null
                            ),
                            child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null
                          )
                        );
                      }
                    )
                  )
                ]
              )
            )
          );
        });
      }
    );
  }

  void _showGradientPickerModal(DesignElement sel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: 500,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Text Gradient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))
                  ]
                ),
                Divider(color: Colors.grey.shade200),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Custom Gradient:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(onTap: () => _pickCustomGradColor(sel, 1, setModalState), child: Container(width: 35, height: 35, decoration: BoxDecoration(color: sel.customGradColor1 ?? Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.black12)))),
                          const Icon(Icons.add, size: 16),
                          InkWell(onTap: () => _pickCustomGradColor(sel, 2, setModalState), child: Container(width: 35, height: 35, decoration: BoxDecoration(color: sel.customGradColor2 ?? Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.black12)))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: () {
                              if(sel.customGradColor1 != null && sel.customGradColor2 != null) {
                                saveState();
                                setState(() => sel.textGradient = [sel.customGradColor1!, sel.customGradColor2!]);
                                setModalState((){});
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 11))
                          )
                        ]
                      )
                    ]
                  )
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.block, size: 20),
                  title: const Text('Clear Gradient', style: TextStyle(fontSize: 13)),
                  dense: true,
                  onTap: () {
                    saveState();
                    setState(() { sel.textGradient = null; });
                    Navigator.pop(context);
                  }
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0),
                    itemCount: _proGradientPalette.length,
                    itemBuilder: (context, index) {
                      List<Color> g = _proGradientPalette[index];
                      return GestureDetector(
                        onTap: () {
                          saveState();
                          setState(() { sel.textGradient = g; });
                          setModalState((){});
                          Navigator.pop(context);
                        },
                        child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)))
                      );
                    }
                  )
                )
              ]
            )
          );
        });
      }
    );
  }

  void _pickCustomGradColor(DesignElement sel, int colorNum, StateSetter parentSetState) { showModalBottomSheet(context: context, builder: (ctx) => Container(height: 300, padding: const EdgeInsets.all(20), child: Column(children: [const Text('Pick a Color', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 10), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _proColorPalette.length, itemBuilder: (ctx, index) { return InkWell(onTap: () { if(colorNum == 1) sel.customGradColor1 = _proColorPalette[index]; else sel.customGradColor2 = _proColorPalette[index]; parentSetState((){}); Navigator.pop(ctx); }, child: Container(decoration: BoxDecoration(color: _proColorPalette[index], shape: BoxShape.circle, border: Border.all(color: Colors.black12)))); }))]))); }

  // 🔥 SHORTER MODALS 🔥
  void _showCanvasBgGradientModal() { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Canvas Gradient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0), itemCount: _proGradientPalette.length, itemBuilder: (context, index) { List<Color> g = _proGradientPalette[index]; return GestureDetector(onTap: () { saveState(); setState(() { bgGradient = g; bgImageBytes = null; pageColor = Colors.white; }); setModalState((){}); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: g), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)))); }))])); }); }); }
  void _showTextBgPickerModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Text Background', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), ListTile(leading: const Icon(Icons.block, size: 20), title: const Text('Remove Background', style: TextStyle(fontSize: 13)), dense: true, onTap: () { saveState(); setState(() { sel.textBgColor = null; }); Navigator.pop(context); }), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSelected = sel.textBgColor?.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() { sel.textBgColor = c; }); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)), child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); }))])); }); }); }
  void _showAdvancedStrokeModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Stroke', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Stroke', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), activeColor: const Color(0xFF8B5CF6), dense: true, contentPadding: EdgeInsets.zero, value: sel.hasStroke, onChanged: (val) { saveState(); setState(() => sel.hasStroke = val); setModalState((){}); }), Divider(color: Colors.grey.shade200), if (sel.hasStroke) ...[Row(children: [const Text('Width:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.strokeWidth, min: 1.0, max: 20.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.strokeWidth = val); setModalState((){}); }))]), const Text('Color:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), const SizedBox(height: 8), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSel = sel.strokeColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.strokeColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); }))] ])); }); }); }
  void _showAdvancedShadowModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 500, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Shadow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), SwitchListTile(title: const Text('Enable Shadow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), activeColor: const Color(0xFF8B5CF6), dense: true, contentPadding: EdgeInsets.zero, value: sel.hasShadow, onChanged: (val) { saveState(); setState(() => sel.hasShadow = val); setModalState((){}); }), Divider(color: Colors.grey.shade200), if (sel.hasShadow) ...[Row(children: [const Text('Blur:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowBlur, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowBlur = val); setModalState((){}); }))]), Row(children: [const Text('X:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetX, min: -20.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetX = val); setModalState((){}); }))]), Row(children: [const Text('Y:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.shadowOffsetY, min: -20.0, max: 20.0, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.shadowOffsetY = val); setModalState((){}); }))]), const Text('Color:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), const SizedBox(height: 8), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSel = sel.shadowColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.shadowColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); }))] ])); }); }); }
  void _show3DBlockModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 400, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('3D Depth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Row(children: [const Text('Depth:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.text3dDepth, min: 0.0, max: 30.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.text3dDepth = val); setModalState((){}); }))]), const Text('Color:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), const SizedBox(height: 8), Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _proColorPalette.length, itemBuilder: (context, index) { Color c = _proColorPalette[index]; bool isSel = sel.text3dColor.value == c.value; return GestureDetector(onTap: () { saveState(); setState(() => sel.text3dColor = c); setModalState((){}); }, child: Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)), child: isSel ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null)); })) ])); }); }); }
  void _showRadiusModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 160, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Corner Radius: ${sel.cornerRadius.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Slider(value: sel.cornerRadius, min: 0.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.cornerRadius = val); setModalState((){}); })])); }); }); }
  void _showShapeClipModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 220, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Crop to Shape', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: ListView(scrollDirection: Axis.horizontal, children: [_buildShapeOption(sel, setModalState, 'None', 0, Icons.crop_square), _buildShapeOption(sel, setModalState, 'Circle', 1, Icons.circle_outlined), _buildShapeOption(sel, setModalState, 'Triangle', 2, Icons.change_history), _buildShapeOption(sel, setModalState, 'Star', 3, Icons.star_border), _buildShapeOption(sel, setModalState, 'Hexagon', 4, Icons.hexagon_outlined)]))])); }); }); }
  Widget _buildShapeOption(DesignElement sel, StateSetter setModalState, String title, int val, IconData icon) { bool isSel = sel.clipShape == val; return InkWell(onTap: () { saveState(); setState(() => sel.clipShape = val); setModalState((){}); Navigator.pop(context); }, borderRadius: BorderRadius.circular(8), child: Container(width: 70, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade200)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade600, size: 24), const SizedBox(height: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? const Color(0xFF8B5CF6) : Colors.black54))]))); }
  void _showImageFiltersModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 220, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Divider(color: Colors.grey.shade200), Expanded(child: ListView(scrollDirection: Axis.horizontal, children: [_buildFilterOption(sel, setModalState, 'Normal', 0, Colors.grey), _buildFilterOption(sel, setModalState, 'B & W', 1, Colors.black87), _buildFilterOption(sel, setModalState, 'Sepia', 2, Colors.brown), _buildFilterOption(sel, setModalState, 'Invert', 3, Colors.blue)]))])); }); }); }
  Widget _buildFilterOption(DesignElement sel, StateSetter setModalState, String title, int filterVal, Color iconColor) { bool isSel = sel.imageFilter == filterVal; return InkWell(onTap: () { saveState(); setState(() => sel.imageFilter = filterVal); setModalState((){}); Navigator.pop(context); }, borderRadius: BorderRadius.circular(8), child: Container(width: 70, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade200)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_filter, color: isSel ? const Color(0xFF8B5CF6) : iconColor, size: 24), const SizedBox(height: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? const Color(0xFF8B5CF6) : Colors.black54))]))); }
  void showSpacingModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 280, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Spacing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 4), Row(children: [const Text('Line:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.lineHeight, min: 0.5, max: 3.5, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.lineHeight = val); setModalState((){}); }))]), Row(children: [const Text('Word:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.wordSpacing, min: -10.0, max: 30.0, activeColor: const Color(0xFF10B981), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.wordSpacing = val); setModalState((){}); }))]), Row(children: [const Text('Letter:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)), Expanded(child: Slider(value: sel.letterSpacing, min: -5.0, max: 20.0, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.letterSpacing = val); setModalState((){}); }))]) ])); }); }); }
  void showSizeSliderModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 160, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Size: ${sel.fontSize.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), Slider(value: sel.fontSize, min: 10.0, max: 150.0, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.fontSize = val); setModalState((){}); })])); }); }); }
  void showRotationModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 180, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rotate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 4), Slider(value: sel.angle, min: -pi, max: pi, activeColor: const Color(0xFF8B5CF6), onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.angle = val); setModalState((){}); }), Text('${(sel.angle * 180 / pi).toInt()}°', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))])); }); }); }
  void show3DModal(DesignElement sel) { showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Container(height: 250, padding: const EdgeInsets.all(20), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Perspective', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 4), Row(children: [const Text('X:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), Expanded(child: Slider(value: sel.pitch, min: -pi/2, max: pi/2, activeColor: Colors.blue, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.pitch = val); setModalState((){}); }))]), Row(children: [const Text('Y:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), Expanded(child: Slider(value: sel.yaw, min: -pi/2, max: pi/2, activeColor: Colors.green, onChangeStart: (val) => saveState(), onChanged: (val) { setState(() => sel.yaw = val); setModalState((){}); }))]), ElevatedButton(onPressed: () { saveState(); setState((){ sel.pitch=0; sel.yaw=0; }); setModalState((){}); }, style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.grey.shade100, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Reset', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700))) ])); }); }); }
