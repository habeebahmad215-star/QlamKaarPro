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

// YAHAN HUM DOOSRI FILE KO LINK KAR RAHE HAIN
part 'pro_workspace_modals.dart';

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

  void _triggerCanvasUpdate() {
    _canvasNotifier.value++;
  }

  double _getElWidth(DesignElement e) => e.width > 30 ? e.width : 80;

  double _getElHeight(DesignElement e) {
    if (!e.isText && e.height > 20) return e.height;
    if (e.isShape) return 90;
    if (e.isText) {
      int lines = e.content.isEmpty ? 1 : e.content.split('\n').length;
      return (lines * e.fontSize * e.lineHeight) + 15;
    }
    return 150;
  }

  Future<void> _saveProjectLocally() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStrings = prefs.getStringList('qalamkaar_projects') ?? [];
    ProjectModel p = ProjectModel(id: projectId, name: projectName, pages: pages, lastModified: DateTime.now());
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

  void saveState() {
    undoStack.add(elements.map((e) => e.clone()).toList());
    redoStack.clear();
    if (undoStack.length > 20) undoStack.removeAt(0);
  }

  void undoAction() {
    if (undoStack.isNotEmpty) {
      redoStack.add(elements.map((e) => e.clone()).toList());
      setState(() { elements = undoStack.removeLast(); selectedId = null; });
      HapticFeedback.lightImpact();
      _triggerCanvasUpdate();
    }
  }

  void redoAction() {
    if (redoStack.isNotEmpty) {
      undoStack.add(elements.map((e) => e.clone()).toList());
      setState(() { elements = redoStack.removeLast(); selectedId = null; });
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
      e.width = max(80.0, e.width + ldx);
    } else if (edge == 'L') {
      double oldW = e.width;
      e.width = max(80.0, e.width - ldx);
      e.x += (oldW - e.width) * cos(e.angle);
      e.y += (oldW - e.width) * sin(e.angle);
    } else if (edge == 'B') {
      if(!e.isText) e.height = max(30.0, e.height + ldy);
    } else if (edge == 'T') {
      if(!e.isText) {
        double oldH = e.height;
        e.height = max(30.0, e.height - ldy);
        e.x -= (oldH - e.height) * sin(e.angle);
        e.y += (oldH - e.height) * cos(e.angle);
      }
    }
    _triggerCanvasUpdate();
  }

  void _scaleCorner(DragUpdateDetails d, DesignElement e) {
    double delta = (d.delta.dx + d.delta.dy) * 0.5;
    if (e.width + delta > 80) {
      double ratio = e.width / (e.height > 0 ? e.height : 1);
      e.width += delta;
      if (!e.isText) e.height += delta / ratio;
      if (e.isText) e.fontSize = max(10.0, e.fontSize + delta * 0.2);
      e.x -= delta / 2;
      e.y -= (e.isText ? 0 : delta / ratio) / 2;
    }
    _triggerCanvasUpdate();
  }

  void _rotateHandle(DragUpdateDetails d, DesignElement e) {
    e.angle += (d.delta.dx + d.delta.dy) * 0.01;
    _triggerCanvasUpdate();
  }

  Widget _buildPill(bool isHorizontal) {
    return Container(
      width: isHorizontal ? 24 : 8,
      height: isHorizontal ? 8 : 24,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5))
    );
  }

  Widget _buildCircle() {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5))
    );
  }

  Widget _buildIconCircle(IconData icon) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
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
        backgroundColor: Colors.white, elevation: 0, titleSpacing: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
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
            child: Container(margin: const EdgeInsets.symmetric(vertical: 12), padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('Save', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))))
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showExportMenu,
            child: Container(margin: const EdgeInsets.symmetric(vertical: 12), padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
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
                                        
                                        Widget contentWidget;
                                        if (e.isBorder) {
                                          return Positioned.fill(
                                            child: GestureDetector(
                                              onTap: () { if(!e.isLocked) { setState(() => selectedId = e.id); _triggerCanvasUpdate(); } },
                                              child: Transform(
                                                transform: matrix, alignment: Alignment.center,
                                                child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: e.elementColor, width: e.strokeWidth), borderRadius: BorderRadius.circular(e.cornerRadius)))
                                              )
                                            )
                                          );
                                        } else if (e.isTable && e.tableData != null) {
                                          contentWidget = CustomTableWidget(tableData: e.tableData!, width: currentWidth, height: currentHeight);
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
                                          contentWidget = Container(width: currentWidth, height: e.clipShape == 0 ? currentHeight : currentWidth, child: clippedImg);
                                        } else {
                                          List<Shadow> textShadows = [];
                                          if (e.hasShadow) textShadows.add(Shadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY)));
                                          Widget buildTextWidget(Color c, [List<Shadow>? shadow]) {
                                            TextStyle st = TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, color: c, letterSpacing: e.letterSpacing, wordSpacing: e.wordSpacing, height: e.lineHeight, shadows: shadow ?? textShadows);
                                            if (e.textCurveRadius != 0) return CurvedTextWidget(text: e.content, textStyle: st, radius: e.textCurveRadius);
                                            return SizedBox(width: currentWidth, child: Text(e.content, textAlign: e.textAlign, style: st));
                                          }
                                          List<Widget> blockLayers = [];
                                          if (e.text3dDepth > 0) {
                                            for (double i = e.text3dDepth; i > 0; i -= 1.0) blockLayers.add(Transform.translate(offset: Offset(i, i), child: buildTextWidget(e.text3dColor, [])));
                                          }
                                          Widget mainTxt = buildTextWidget(e.textGradient != null ? Colors.white : e.textColor);
                                          if (e.textGradient != null) mainTxt = ShaderMask(shaderCallback: (bounds) => LinearGradient(colors: e.textGradient!).createShader(bounds), child: mainTxt);
                                          if (e.textTextureBytes != null) mainTxt = TextureTextWrapper(textWidget: mainTxt, imageBytes: e.textTextureBytes!);
                                          blockLayers.add(mainTxt);
                                          Widget txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: blockLayers);
                                          if (e.hasStroke) {
                                            TextStyle stStroke = TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, letterSpacing: e.letterSpacing, wordSpacing: e.wordSpacing, height: e.lineHeight, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = e.strokeWidth..color = e.strokeColor);
                                            Widget strokeTxt = e.textCurveRadius != 0 ? CurvedTextWidget(text: e.content, textStyle: stStroke, radius: e.textCurveRadius) : SizedBox(width: currentWidth, child: Text(e.content, textAlign: e.textAlign, style: stStroke));
                                            txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [strokeTxt, txt]);
                                          }
                                          if (e.textBgColor != null) txt = Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: e.textBgColor, borderRadius: BorderRadius.circular(e.cornerRadius)), child: txt);
                                          contentWidget = txt; 
                                        }
                                        
                                        if (_isExporting) { 
                                          return Positioned(left: e.x, top: e.y, child: Transform(transform: matrix, alignment: Alignment.center, child: contentWidget));
                                        }
                                        
                                        return Positioned(
                                          left: e.x, 
                                          top: e.y,
                                          child: Transform(
                                            transform: matrix, alignment: Alignment.center,
                                            child: SizedBox(
                                              width: currentWidth, height: currentHeight,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Positioned.fill(
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
                                                        decoration: isSel ? BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5)) : null,
                                                        child: Opacity(opacity: e.opacity, child: contentWidget)
                                                      )
                                                    )
                                                  ),
                                                  
                                                  if (isSel) ...[
                                                    Positioned(top: -4, left: currentWidth/2 - 12, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'T', e), child: _buildPill(true))),
                                                    Positioned(bottom: -4, left: currentWidth/2 - 12, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'B', e), child: _buildPill(true))),
                                                    Positioned(left: -4, top: currentHeight/2 - 12, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'L', e), child: _buildPill(false))),
                                                    Positioned(right: -4, top: currentHeight/2 - 12, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _resizeEdge(d, 'R', e), child: _buildPill(false))),
                                                    
                                                    Positioned(top: -6, left: -6, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e), child: _buildCircle())),
                                                    Positioned(top: -6, right: -6, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e), child: _buildCircle())),
                                                    Positioned(bottom: -6, left: -6, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e), child: _buildCircle())),
                                                    Positioned(bottom: -6, right: -6, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => saveState(), onPanUpdate: (d) => _scaleCorner(d, e), child: _buildCircle())),
                                                    
                                                    Positioned(
                                                      top: -35, right: -35, 
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onPanStart: (_) => saveState(),
                                                        onPanUpdate: (d) => _rotateHandle(d, e),
                                                        child: _buildIconCircle(Icons.rotate_right)
                                                      )
                                                    ),
                                                    Positioned(
                                                      bottom: -35, left: -35, 
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onPanStart: (_) => saveState(),
                                                        onPanUpdate: (d) => _scaleCorner(d, e),
                                                        child: _buildIconCircle(Icons.open_in_full)
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
}
