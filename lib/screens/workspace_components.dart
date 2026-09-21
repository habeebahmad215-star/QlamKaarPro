import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class AdvancedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final int styleIndex;

  AdvancedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.styleIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Rect baseRect = (Offset.zero & size).deflate(strokeWidth / 2);

    int type = styleIndex % 5; 
    double varVal = (styleIndex ~/ 5).toDouble() * 3.0;

    switch (type) {
      case 0:
        final double offset = varVal;
        final Rect innerRect = baseRect.deflate(offset);
        canvas.drawRRect(RRect.fromRectAndRadius(innerRect, Radius.circular(radius)), paint);
        break;
      case 1:
        canvas.drawRRect(RRect.fromRectAndRadius(baseRect, Radius.circular(radius)), paint);
        if (varVal >= 0) {
          paint.strokeWidth = strokeWidth * 0.5;
          canvas.drawRRect(RRect.fromRectAndRadius(baseRect.deflate(6 + varVal), Radius.circular(max(0.0, radius - 2))), paint);
        }
        if (varVal > 10) {
          canvas.drawRRect(RRect.fromRectAndRadius(baseRect.deflate(12 + varVal), Radius.circular(max(0.0, radius - 4))), paint);
        }
        break;
      case 2:
        double lineLen = 20.0 + varVal;
        if (lineLen > size.width / 2) lineLen = size.width / 2;
        canvas.drawLine(baseRect.topLeft, baseRect.topLeft + Offset(lineLen, 0), paint);
        canvas.drawLine(baseRect.topLeft, baseRect.topLeft + Offset(0, lineLen), paint);
        canvas.drawLine(baseRect.topRight, baseRect.topRight + Offset(-lineLen, 0), paint);
        canvas.drawLine(baseRect.topRight, baseRect.topRight + Offset(0, lineLen), paint);
        canvas.drawLine(baseRect.bottomLeft, baseRect.bottomLeft + Offset(lineLen, 0), paint);
        canvas.drawLine(baseRect.bottomLeft, baseRect.bottomLeft + Offset(0, -lineLen), paint);
        canvas.drawLine(baseRect.bottomRight, baseRect.bottomRight + Offset(-lineLen, 0), paint);
        canvas.drawLine(baseRect.bottomRight, baseRect.bottomRight + Offset(0, -lineLen), paint);
        break;
      case 3:
        double gap = 15.0 + varVal;
        if (gap > size.width / 3) gap = size.width / 3;
        Path path = Path();
        path.moveTo(baseRect.left + gap, baseRect.top);
        path.lineTo(baseRect.right - gap, baseRect.top);
        path.moveTo(baseRect.left + gap, baseRect.bottom);
        path.lineTo(baseRect.right - gap, baseRect.bottom);
        path.moveTo(baseRect.left, baseRect.top + gap);
        path.lineTo(baseRect.left, baseRect.bottom - gap);
        path.moveTo(baseRect.right, baseRect.top + gap);
        path.lineTo(baseRect.right, baseRect.bottom - gap);
        canvas.drawPath(path, paint);
        if (varVal > 5) {
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(baseRect.topLeft + const Offset(5, 5), strokeWidth, paint);
          canvas.drawCircle(baseRect.topRight + const Offset(-5, 5), strokeWidth, paint);
          canvas.drawCircle(baseRect.bottomLeft + const Offset(5, -5), strokeWidth, paint);
          canvas.drawCircle(baseRect.bottomRight + const Offset(-5, -5), strokeWidth, paint);
        }
        break;
      case 4:
        double dashW = varVal < 10 ? 6.0 : 2.0;
        double spaceW = dashW + strokeWidth + 2.0;
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

  @override
  bool shouldRepaint(covariant AdvancedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
           strokeWidth != oldDelegate.strokeWidth ||
           radius != oldDelegate.radius ||
           styleIndex != oldDelegate.styleIndex;
  }
}

class AdvancedColorPickerModal extends StatefulWidget {
  final String title;
  final Color initialColor;
  final Function(Color) onColorChanged;
  final List<Color> documentColors;
  final bool allowClear;

  const AdvancedColorPickerModal({
    Key? key, 
    required this.title, 
    required this.initialColor, 
    required this.onColorChanged, 
    required this.documentColors, 
    this.allowClear = false,
  }) : super(key: key);

  @override
  State<AdvancedColorPickerModal> createState() => _AdvancedColorPickerModalState();
}

class _AdvancedColorPickerModalState extends State<AdvancedColorPickerModal> {
  late HSVColor hsvColor;
  final TextEditingController _hexCtrl = TextEditingController();

  final Map<String, List<Color>> _colorCategories = {
    'Basic (بنیادی)': [
      Colors.black, Colors.white, Colors.red, Colors.pink, Colors.purple,
      Colors.deepPurple, Colors.indigo, Colors.blue, Colors.lightBlue,
      Colors.cyan, Colors.teal, Colors.green, Colors.lightGreen,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey
    ],
    'Premium (خاص)': [
      const Color(0xFFD4AF37), const Color(0xFFC0C0C0), const Color(0xFFCD7F32), 
      const Color(0xFFB76E79), const Color(0xFF003366), const Color(0xFF800000), 
      const Color(0xFF006400), const Color(0xFF36454F),
    ],
    'Pastel (ہلکے)': [
      const Color(0xFFFFB3BA), const Color(0xFFFFDFBA), const Color(0xFFFFFFBA),
      const Color(0xFFBAFFC9), const Color(0xFFBAE1FF), const Color(0xFFE2CBF7),
      const Color(0xFFFDE2E4), const Color(0xFFE2ECE9), const Color(0xFFBCCCE0),
    ],
    'Dark (گہرے)': [
      const Color(0xFF121212), const Color(0xFF1A1A2E), const Color(0xFF16213E),
      const Color(0xFF0F3460), const Color(0xFF4A0E4E), const Color(0xFF3E1F47),
      const Color(0xFF002200), const Color(0xFF3E0000), const Color(0xFF2F4F4F),
    ]
  };

  String _selectedCategory = 'Basic (بنیادی)';

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
      } catch (e) {}
    }
  }

  void _setFromPreset(Color c) {
    setState(() { hsvColor = HSVColor.fromColor(c); });
    _onColorUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        height: MediaQuery.of(context).size.height * 0.75, 
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: -5)]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      Row(
                        children: [
                          if (widget.allowClear)
                            TextButton.icon(
                              onPressed: () { 
                                widget.onColorChanged(Colors.transparent); 
                                Navigator.pop(context); 
                              }, 
                              icon: const Icon(Icons.layers_clear_rounded, color: Colors.red, size: 16), 
                              label: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                            ),
                          IconButton(icon: const Icon(Icons.close_rounded, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context)),
                        ],
                      )
                    ],
                  ),
                ),
                const Divider(height: 0, color: Colors.black12),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(15),
                    children: [
                      GestureDetector(
                        onPanStart: (d) => _handleShadeDrag(d.localPosition),
                        onPanUpdate: (d) => _handleShadeDrag(d.localPosition),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: Stack(
                            children: [
                              Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight))),
                              Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                              Positioned(
                                left: hsvColor.saturation * (MediaQuery.of(context).size.width - 64) - 12,
                                top: (1.0 - hsvColor.value) * 140 - 12,
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, 
                                    color: hsvColor.toColor(), 
                                    border: Border.all(color: Colors.white, width: 3), 
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      GestureDetector(
                        onPanStart: (d) => _handleHueDrag(d.localPosition),
                        onPanUpdate: (d) => _handleHueDrag(d.localPosition),
                        child: Container(
                          height: 20,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                            gradient: const LinearGradient(colors: [Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00), Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000)])
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: (hsvColor.hue / 360) * (MediaQuery.of(context).size.width - 64) - 10,
                                top: -4,
                                child: Container(
                                  width: 20, height: 28, 
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)])
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            width: 45, height: 45, 
                            decoration: BoxDecoration(shape: BoxShape.circle, color: hsvColor.toColor(), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: hsvColor.toColor().withOpacity(0.3), blurRadius: 8)])
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 45, padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white)),
                              child: Row(
                                children: [
                                  const Text('#', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 5),
                                  Expanded(child: TextField(controller: _hexCtrl, onChanged: _handleHexInput, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 14), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
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
                                const Text('Opacity', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                                SliderTheme(
                                  data: SliderThemeData(trackHeight: 4, activeTrackColor: const Color(0xFF8B5CF6), thumbColor: const Color(0xFF8B5CF6), overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2)),
                                  child: Slider(value: hsvColor.alpha, min: 0.0, max: 1.0, onChanged: (v) { setState(() => hsvColor = hsvColor.withAlpha(v)); _onColorUpdate(); }),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (widget.documentColors.isNotEmpty) ...[
                        const Text('Document Colors (استعمال شدہ)', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 12)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 45,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                            itemCount: widget.documentColors.length,
                            itemBuilder: (ctx, i) => _buildColorBubble(widget.documentColors[i]),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _colorCategories.keys.map((catName) {
                            bool isSel = _selectedCategory == catName;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(catName, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 12, color: isSel ? Colors.white : Colors.black87)),
                                selected: isSel,
                                selectedColor: const Color(0xFF8B5CF6),
                                backgroundColor: Colors.white.withOpacity(0.5),
                                showCheckmark: false,
                                onSelected: (val) {
                                  if(val) setState(() => _selectedCategory = catName);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Wrap(
                        spacing: 12, 
                        runSpacing: 12, 
                        children: _colorCategories[_selectedCategory]!.map((c) => _buildColorBubble(c)).toList()
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleShadeDrag(Offset pos) {
    double w = MediaQuery.of(context).size.width - 64;
    double s = (pos.dx / w).clamp(0.0, 1.0);
    double v = 1.0 - (pos.dy / 140).clamp(0.0, 1.0);
    setState(() { hsvColor = hsvColor.withSaturation(s).withValue(v); });
    _onColorUpdate();
  }

  void _handleHueDrag(Offset pos) {
    double w = MediaQuery.of(context).size.width - 64;
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
        width: 45, height: 45, 
        decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.white, width: isSel ? 3.5 : 2.0),
          boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)] : [const BoxShadow(color: Colors.black12, blurRadius: 4)]
        ),
      ),
    );
  }
}
