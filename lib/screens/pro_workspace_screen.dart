import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import '../models/design_models.dart';
import '../widgets/custom_widgets.dart';
import '../utils/constants.dart';
import 'workspace_components.dart';
import 'workspace_controller.dart';
import 'workspace_modals.dart';
import 'workspace_toolbars.dart';

class ProWorkspaceScreen extends StatefulWidget {
  final ProjectModel? project;
  final String? initialAction;
  final String? initialData; 
  const ProWorkspaceScreen({Key? key, this.project, this.initialAction, this.initialData}) : super(key: key);
  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> {
  final TransformationController _transformController = TransformationController();
  late WorkspaceController ctrl;
  late WorkspaceModals modals;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    ctrl = WorkspaceController(project: widget.project);
    modals = WorkspaceModals(ctrl);

    ctrl.addListener(() {
      if (mounted) setState(() {});
    });

    // 🔥 Auto-Save Timer (Saves every 1 minute in background)
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ctrl.saveProjectLocally(context, isAutoSave: true);
    });

    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialAction == 'text_editor') modals.showTextComposerDialog(context);
        else if (widget.initialAction == 'images') modals.addImageFromGallery(context, fromModal: false);
        else if (widget.initialAction == 'elements') modals.showAddNewModal(context);
        else if (widget.initialAction == 'add_sticker' && widget.initialData != null) _addStickerLocally(widget.initialData!);
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _transformController.dispose();
    ctrl.dispose();
    super.dispose();
  }

  void _addStickerLocally(String stickerStr) {
    ctrl.saveState();
    var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 80, y: 150, content: stickerStr, isText: true, width: 150, height: 150, fontSize: 80);
    ctrl.elements.add(newEl);
    ctrl.selectedId = newEl.id;
    ctrl.activeToolbarMenu = 'main';
    ctrl.triggerUpdate();
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context, barrierColor: Colors.transparent, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => modals.buildGlassContainer(ctx, height: 280, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Export Design', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(ctx))]),
        const Divider(color: Colors.black12), const SizedBox(height: 5),
        _buildExportOpt(Icons.image, 'Save as JPG', 'Solid Background', Colors.blue, () { Navigator.pop(ctx); ctrl.captureAndSave(context, 'JPG'); }), const SizedBox(height: 8),
        _buildExportOpt(Icons.layers_clear, 'Save as PNG', 'Transparent', Colors.purple, () { Navigator.pop(ctx); ctrl.captureAndSave(context, 'PNG'); }), const SizedBox(height: 8),
        _buildExportOpt(Icons.picture_as_pdf, 'Save as Print PDF', 'High Quality', Colors.red, () { Navigator.pop(ctx); ctrl.captureAndSave(context, 'PDF'); })
      ]))
    );
  }

  Widget _buildExportOpt(IconData icon, String title, String sub, Color col, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: col, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 18)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(sub, style: const TextStyle(fontSize: 11, color: Colors.black54))])), Icon(Icons.arrow_forward_ios, color: col, size: 14)])));
  }

  Widget _buildPill(bool isH) => Container(width: isH ? 24 : 6, height: isH ? 6 : 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]));
  Widget _buildCircle() => Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]));
  Widget _buildIconCircle(IconData ic) => Container(width: 26, height: 26, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)]), child: Icon(ic, size: 14, color: const Color(0xFF8B5CF6)));
  Widget _buildTouchTarget({required Widget child}) => Container(width: 40, height: 40, color: Colors.transparent, alignment: Alignment.center, child: child);

  Widget _buildTextWidget(DesignElement e, double currentWidth, Color? baseColor, {List<Shadow>? extraShadows, Paint? foregroundPaint}) {
    List<Shadow> currentShadows = extraShadows != null ? List.from(extraShadows) : [];
    if (extraShadows == null && e.hasShadow) currentShadows.add(Shadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY)));
    Color? finalTextColor = baseColor;
    if (e.isGlass && e.textGradient == null && e.textTextureBytes == null && foregroundPaint == null) {
       finalTextColor = baseColor?.withOpacity(0.35); currentShadows.add(const Shadow(color: Colors.white, offset: Offset(0, 0), blurRadius: 15)); currentShadows.add(const Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 5));
    }
    if (e.isBevel) { currentShadows.add(const Shadow(color: Colors.white70, offset: Offset(-2, -2), blurRadius: 2)); currentShadows.add(const Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 2)); }
    if (e.isInnerShadow) currentShadows.add(const Shadow(color: Colors.black87, offset: Offset(1.5, 1.5), blurRadius: 2));

    TextStyle st = TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, color: foregroundPaint == null ? finalTextColor : null, foreground: foregroundPaint, letterSpacing: e.letterSpacing, wordSpacing: e.wordSpacing, height: e.lineHeight, shadows: currentShadows.isNotEmpty ? currentShadows : null, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: e.isItalic ? FontStyle.italic : FontStyle.normal);
    bool hasMultiStyle = ctrl.textMultiStyles.containsKey(e.id) && ctrl.textMultiStyles[e.id]!.isNotEmpty;
    
    if (e.textCurveRadius != 0) return CurvedTextWidget(text: e.content, style: st, radius: e.textCurveRadius);
    if (hasMultiStyle) {
      List<String> words = e.content.split(' '); List<TextSpan> spans = [];
      for (int i = 0; i < words.length; i++) {
        TextStyle wSt = st;
        if (ctrl.textMultiStyles[e.id]!.containsKey(i)) {
           var ms = ctrl.textMultiStyles[e.id]![i]!;
           wSt = st.copyWith(color: foregroundPaint == null ? (ms['color'] != null ? (ms['color'] as Color) : st.color) : null, fontSize: ms['fontSize'] != null ? (ms['fontSize'] as double) : st.fontSize, fontFamily: ms['fontFamily'] != null ? (ms['fontFamily'] as String) : st.fontFamily, foreground: foregroundPaint);
        }
        spans.add(TextSpan(text: words[i] + (i < words.length - 1 ? ' ' : ''), style: wSt));
      }
      return SizedBox(width: currentWidth, child: RichText(textAlign: e.textAlign, textDirection: modals.isRTLText(e.content) ? TextDirection.rtl : TextDirection.ltr, text: TextSpan(children: spans)));
    } else {
      return SizedBox(width: currentWidth, child: Text(e.content, textAlign: e.textAlign, style: st));
    }
  }
    @override
  Widget build(BuildContext context) {
    bool hasSelection = ctrl.selectedElement != null;
    DesignElement? sel = ctrl.selectedElement;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)), titleSpacing: 0, leadingWidth: 40,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20), onPressed: () => Navigator.pop(context)),
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          WorkspaceToolbars.buildTopToolBtn(context, Icons.undo_rounded, 'Undo', ctrl.undoAction, color: const Color(0xFF64748B)),
          WorkspaceToolbars.buildTopToolBtn(context, Icons.redo_rounded, 'Redo', ctrl.redoAction, color: const Color(0xFF64748B)),
          WorkspaceToolbars.buildTopToolBtn(context, Icons.layers_rounded, 'Layers', () => modals.showLayersPanel(context), color: const Color(0xFF1E293B)),
          WorkspaceToolbars.buildTopToolBtn(context, Icons.auto_stories_rounded, 'Pages', () => modals.showPagesPanel(context), color: const Color(0xFF1E293B)),
        ]),
        actions: [
          Center(child: InkWell(onTap: _showExportMenu, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]), child: Row(children: const [Icon(Icons.ios_share_rounded, color: Colors.white, size: 14), SizedBox(width: 4), Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))])))),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 15, top: 10, bottom: 5), alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              InkWell(onTap: () { HapticFeedback.selectionClick(); ctrl.isCanvasLocked = !ctrl.isCanvasLocked; ctrl.triggerUpdate(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: ctrl.isCanvasLocked ? Colors.red.shade50 : Colors.white, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(ctrl.isCanvasLocked ? Icons.lock : Icons.lock_open, size: 14, color: ctrl.isCanvasLocked ? Colors.red : Colors.black), const SizedBox(width: 5), Text(ctrl.isCanvasLocked ? 'Locked' : 'Unlocked', style: TextStyle(fontSize: 12, color: ctrl.isCanvasLocked ? Colors.red : Colors.black))]))), const SizedBox(width: 12),
              InkWell(onTap: () { HapticFeedback.selectionClick(); _transformController.value = Matrix4.identity(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.fit_screen, size: 14), SizedBox(width: 5), Text('Reset View', style: TextStyle(fontSize: 12))]))),
            ]),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () { ctrl.selectedId = null; ctrl.activeToolbarMenu = 'main'; ctrl.triggerUpdate(); }, 
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformController, panEnabled: !ctrl.isCanvasLocked && !hasSelection, scaleEnabled: !ctrl.isCanvasLocked, minScale: 0.2, maxScale: 5.0, boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: AspectRatio(
                    aspectRatio: ctrl.canvasRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double newW = constraints.maxWidth - 32; double newH = constraints.maxHeight - 32;
                        if (ctrl.needsRescale && ctrl.currentCanvasW > 50 && ctrl.currentCanvasH > 50) {
                          double scaleX = newW / ctrl.currentCanvasW; double scaleY = newH / ctrl.currentCanvasH; double scaleMin = min(scaleX, scaleY);
                          for (var e in ctrl.elements) {
                            e.x *= scaleX; e.y *= scaleY; e.width *= scaleX; e.height *= scaleY;
                            if (e.isText) { e.fontSize *= scaleMin; e.textCurveRadius *= scaleMin; e.shadowOffsetX *= scaleX; e.shadowOffsetY *= scaleY; }
                            e.strokeWidth *= scaleMin; e.cornerRadius *= scaleMin;
                          }
                          ctrl.needsRescale = false;
                        }
                        ctrl.currentCanvasW = newW; ctrl.currentCanvasH = newH;

                        return Container(
                          margin: const EdgeInsets.all(16), decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                          child: RepaintBoundary(
                            key: ctrl.canvasKey,
                            child: ClipRect(
                              child: Container(
                                width: ctrl.currentCanvasW, height: ctrl.currentCanvasH, color: ctrl.bgImageBytes != null || ctrl.bgGradient != null ? null : (ctrl.pageColor == Colors.transparent ? Colors.white : ctrl.pageColor),
                                decoration: ctrl.bgImageBytes != null ? BoxDecoration(image: DecorationImage(image: MemoryImage(ctrl.bgImageBytes!), fit: BoxFit.cover)) : (ctrl.bgGradient != null ? BoxDecoration(gradient: LinearGradient(colors: ctrl.bgGradient!)) : null),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (ctrl.showGrid && !ctrl.isExporting) Positioned.fill(child: IgnorePointer(child: Stack(children: [Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) => Container(height: 1, color: Colors.black12))), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) => Container(width: 1, color: Colors.black12))), Center(child: Container(width: double.infinity, height: 1, color: Colors.blue.withOpacity(0.5))), Center(child: Container(width: 1, height: double.infinity, color: Colors.blue.withOpacity(0.5)))]))),
                                    if (!ctrl.isExporting) Positioned.fill(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1)))),
                                    ...ctrl.elements.map((e) {
                                      if (e.isHidden) return const SizedBox.shrink();
                                      bool isSel = (e.id == ctrl.selectedId) && !ctrl.isExporting;
                                      Matrix4 matrix = Matrix4.identity()..setEntry(3, 2, 0.002)..rotateX(e.pitch)..rotateY(e.yaw)..rotateZ(e.angle);
                                      if (e.flipX) matrix.rotateY(pi); if (e.flipY) matrix.rotateX(pi);
                                      double currentWidth = modals.getElWidth(e); double currentHeight = modals.getElHeight(e); double bp = 20.0; 
                                      
                                      Widget contentWidget;
                                      if (e.isBorder) contentWidget = SizedBox(width: currentWidth, height: currentHeight, child: CustomPaint(painter: AdvancedBorderPainter(color: e.elementColor, strokeWidth: e.strokeWidth, radius: e.cornerRadius, styleIndex: int.tryParse(e.borderStyle) ?? 0)));
                                      else if (e.isTable && e.tableData != null) contentWidget = CustomTableWidget(tableData: e.tableData!, width: currentWidth, height: currentHeight, fontFamily: e.fontFamily, textColor: e.textColor, borderColor: e.elementColor, hasBorder: true);
                                      else if (e.isShape) contentWidget = Container(width: currentWidth, height: currentHeight, decoration: BoxDecoration(color: e.elementColor, borderRadius: BorderRadius.circular(e.cornerRadius)));
                                      else if (e.imageBytes != null) {
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
                                        if (e.text3dDepth > 0) for (double i = e.text3dDepth; i > 0; i -= 1.0) blockLayers.add(Transform.translate(offset: Offset(i, i), child: _buildTextWidget(e, currentWidth, e.text3dColor, extraShadows: [])));
                                        Widget mainTxt = _buildTextWidget(e, currentWidth, e.textGradient != null ? Colors.white : e.textColor);
                                        if (e.textGradient != null) mainTxt = ShaderMask(shaderCallback: (bounds) => LinearGradient(colors: e.textGradient!).createShader(bounds), child: mainTxt);
                                        if (e.textTextureBytes != null) mainTxt = TextureTextWrapper(child: mainTxt, textureBytes: e.textTextureBytes!);
                                        blockLayers.add(mainTxt);
                                        Widget txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: blockLayers);
                                        if (e.hasStroke) { Paint strokePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = e.strokeWidth..color = e.strokeColor; Widget strokeTxt = _buildTextWidget(e, currentWidth, null, foregroundPaint: strokePaint); txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [strokeTxt, txt]); }
                                        if (e.textBgColor != null) txt = Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: e.textBgColor, borderRadius: BorderRadius.circular(e.cornerRadius)), child: txt);
                                        contentWidget = txt; 
                                      }
                                      
                                      if (ctrl.isExporting) return Positioned(left: e.x, top: e.y, child: Transform(transform: matrix, alignment: Alignment.center, child: Opacity(opacity: e.opacity.clamp(0.0, 1.0), child: contentWidget)));
                                      
                                      return Positioned(
                                        left: e.x - bp, top: e.y - bp,
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
                                                    onTap: () { if (e.isLocked) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layer is Locked'))); else { ctrl.selectedId = e.id; ctrl.triggerUpdate(); } },
                                                    onPanStart: (d) { if(!e.isLocked) ctrl.saveState(); },
                                                    onPanUpdate: (d) {
                                                      if(!e.isLocked && ctrl.selectedId == e.id) {
                                                        e.x += d.delta.dx; e.y += d.delta.dy; 
                                                        if (e.groupId != null) { for (var other in ctrl.elements) { if (other.id != e.id && other.groupId == e.groupId && !other.isLocked) { other.x += d.delta.dx; other.y += d.delta.dy; } } }
                                                        ctrl.triggerUpdate();
                                                      }
                                                    },
                                                    child: Stack(
                                                      fit: StackFit.passthrough, clipBehavior: Clip.none,
                                                      children: [
                                                        Opacity(opacity: e.opacity.clamp(0.0, 1.0), child: contentWidget),
                                                        if (isSel) Positioned.fill(child: IgnorePointer(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2.0)), child: Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5)))))),
                                                      ],
                                                    ),
                                                  )
                                                ),
                                                if (isSel) ...[
                                                  Positioned(top: bp - 20, left: bp + currentWidth/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.resizeEdge(d, 'T', e), child: _buildTouchTarget(child: _buildPill(true)))),
                                                  Positioned(bottom: bp - 20, left: bp + currentWidth/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.resizeEdge(d, 'B', e), child: _buildTouchTarget(child: _buildPill(true)))),
                                                  Positioned(left: bp - 20, top: bp + currentHeight/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.resizeEdge(d, 'L', e), child: _buildTouchTarget(child: _buildPill(false)))),
                                                  Positioned(right: bp - 20, top: bp + currentHeight/2 - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.resizeEdge(d, 'R', e), child: _buildTouchTarget(child: _buildPill(false)))),
                                                  Positioned(top: bp - 20, left: bp - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.scaleCorner(d, e, 'TL'), child: _buildTouchTarget(child: _buildCircle()))),
                                                  Positioned(top: bp - 20, right: bp - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.scaleCorner(d, e, 'TR'), child: _buildTouchTarget(child: _buildCircle()))),
                                                  Positioned(bottom: bp - 20, left: bp - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.scaleCorner(d, e, 'BL'), child: _buildTouchTarget(child: _buildCircle()))),
                                                  Positioned(bottom: bp - 20, right: bp - 20, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.scaleCorner(d, e, 'BR'), child: _buildTouchTarget(child: _buildCircle()))),
                                                  Positioned(top: bp - 35, right: bp - 35, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.rotateElement(d, e), child: _buildTouchTarget(child: _buildIconCircle(Icons.rotate_right)))),
                                                  Positioned(bottom: bp - 35, left: bp - 35, child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => ctrl.saveState(), onPanUpdate: (d) => ctrl.scaleCorner(d, e, 'BL'), child: _buildTouchTarget(child: _buildIconCircle(Icons.open_in_full)))),
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
          height: 140, color: Colors.white, 
          child: (hasSelection && sel != null) ? WorkspaceToolbars.buildSelectedToolBar(context, ctrl, modals, sel) : WorkspaceToolbars.buildDefaultBottomBar(context, ctrl, modals)
        )
      ),
    );
  }
}

