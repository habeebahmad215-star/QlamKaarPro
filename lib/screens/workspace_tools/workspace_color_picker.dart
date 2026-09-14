import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../utils/constants.dart';

class AdvancedColorPickerModal extends StatefulWidget {
  final String title;
  final Color initialColor;
  final Function(Color) onColorChanged;
  final Function(List<Color>)? onGradientChanged;
  final List<Color> documentColors;
  final bool allowClear;

  const AdvancedColorPickerModal({
    Key? key, 
    required this.title, 
    required this.initialColor, 
    required this.onColorChanged, 
    this.onGradientChanged,
    required this.documentColors, 
    this.allowClear = false,
  }) : super(key: key);

  @override
  State<AdvancedColorPickerModal> createState() => _AdvancedColorPickerModalState();
}

class _AdvancedColorPickerModalState extends State<AdvancedColorPickerModal> {
  late HSVColor hsvColor;
  final TextEditingController _hexCtrl = TextEditingController();
  
  // 🔥 3 Options ke liye Tab Controller
  int selectedTabIndex = 0; // 0: Solid, 1: Gradient, 2: Wheel

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
        // Ignored
      }
    }
  }

  void _setFromPreset(Color c) {
    setState(() { hsvColor = HSVColor.fromColor(c); });
    _onColorUpdate();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Popup ki height kam kar di hai taake canvas clear rahe (45% of screen)
    double modalHeight = MediaQuery.of(context).size.height * 0.45;
    if (modalHeight < 350) modalHeight = 350; 

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        height: modalHeight,
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
                // 1. HEADER SECTION
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
                
                // 2. CUSTOM TABS (Solid | Gradient | Wheel)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Solid Color', Icons.color_lens),
                        _buildTabButton(1, 'Gradient', Icons.gradient),
                        _buildTabButton(2, 'Wheel', Icons.donut_large),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // 3. DYNAMIC CONTENT AREA
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: _buildSelectedTabContent(),
                  ),
                ),

                // 4. BOTTOM HEX & OPACITY BAR (Always visible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40, 
                        decoration: BoxDecoration(shape: BoxShape.circle, color: hsvColor.toColor(), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: hsvColor.toColor().withOpacity(0.3), blurRadius: 8)])
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 90, height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white)),
                        child: Row(
                          children: [
                            const Text('#', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 14)),
                            Expanded(child: TextField(controller: _hexCtrl, onChanged: _handleHexInput, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 13), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(trackHeight: 4, activeTrackColor: const Color(0xFF8B5CF6), thumbColor: const Color(0xFF8B5CF6), overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2)),
                          child: Slider(value: hsvColor.alpha, min: 0.0, max: 1.0, onChanged: (v) { setState(() => hsvColor = hsvColor.withAlpha(v)); _onColorUpdate(); }),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 TAB BUTTON BUILDER
  Widget _buildTabButton(int index, String text, IconData icon) {
    bool isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(text, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 CONTENT SWITCHER
  Widget _buildSelectedTabContent() {
    if (selectedTabIndex == 0) return _buildSolidColorsTab();
    if (selectedTabIndex == 1) return _buildGradientTab();
    return _buildWheelTab();
  }

  // ==========================================
  // TAB 1: SOLID COLORS (Double Horizontal Row)
  // ==========================================
  Widget _buildSolidColorsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.documentColors.isNotEmpty) ...[
          const Text('Document Colors', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 11)),
          const SizedBox(height: 6),
          SizedBox(
            height: 35,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
              itemCount: widget.documentColors.length,
              itemBuilder: (ctx, i) => _buildColorBubble(widget.documentColors[i]),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const Text('All Solid Colors', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 11)),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 🔥 2 Line Scrollable
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0, 
            ),
            itemCount: AppConstants.proColorPalette.length,
            itemBuilder: (ctx, i) => _buildGridColorBubble(AppConstants.proColorPalette[i]),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: GRADIENTS (Double Horizontal Row)
  // ==========================================
  Widget _buildGradientTab() {
    // Aapke AppConstants se data uthaya gaya hai
    List<List<Color>> gradients = AppConstants.proGradientPalette;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pro Gradients Library', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 11)),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 🔥 2 Line Scrollable
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0, 
            ),
            itemCount: gradients.length,
            itemBuilder: (ctx, i) => _buildGradientBubble(gradients[i]),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: ROUND COLOR WHEEL (Professional)
  // ==========================================
  Widget _buildWheelTab() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double size = math.min(constraints.maxWidth, constraints.maxHeight) - 20;
          if (size < 100) size = 100;
          
          return GestureDetector(
            onPanStart: (d) => _handleWheelDrag(d.localPosition, size),
            onPanUpdate: (d) => _handleWheelDrag(d.localPosition, size),
            onTapDown: (d) => _handleWheelDrag(d.localPosition, size),
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                // 🔥 Professional Wheel Design (Hue + Saturation)
                gradient: SweepGradient(
                  colors: const [
                    Color(0xFFFF0000), Color(0xFFFF00FF), Color(0xFF0000FF), 
                    Color(0xFF00FFFF), Color(0xFF00FF00), Color(0xFFFFFF00), Color(0xFFFF0000)
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white, Colors.white.withOpacity(0.0)],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: CustomPaint(
                  painter: _WheelThumbPainter(
                    hue: hsvColor.hue, 
                    saturation: hsvColor.saturation,
                    thumbColor: hsvColor.toColor(),
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // 🔥 COLOR WHEEL MATH LOGIC (Angle aur Radius se color nikalna)
  void _handleWheelDrag(Offset pos, double size) {
    double radius = size / 2;
    double dx = pos.dx - radius;
    double dy = pos.dy - radius;
    
    // Calculate distance from center (Saturation)
    double distance = math.sqrt(dx * dx + dy * dy);
    double saturation = (distance / radius).clamp(0.0, 1.0);
    
    // Calculate Angle (Hue)
    double angle = math.atan2(dy, dx); // Returns -pi to pi
    double hue = (angle * 180 / math.pi);
    if (hue < 0) hue += 360;

    setState(() { hsvColor = hsvColor.withHue(hue).withSaturation(saturation).withValue(1.0); });
    _onColorUpdate();
  }

  // BUBBLE WIDGETS
  Widget _buildColorBubble(Color c) {
    bool isSel = hsvColor.toColor().value == c.value;
    return GestureDetector(
      onTap: () => _setFromPreset(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 35, height: 35, margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.white, width: isSel ? 3 : 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)] : [const BoxShadow(color: Colors.black12, blurRadius: 2)]),
      ),
    );
  }

  Widget _buildGridColorBubble(Color c) {
    bool isSel = hsvColor.toColor().value == c.value;
    return GestureDetector(
      onTap: () => _setFromPreset(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.white, width: isSel ? 3 : 1.5), boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)] : [const BoxShadow(color: Colors.black12, blurRadius: 2)]),
      ),
    );
  }

  Widget _buildGradientBubble(List<Color> colors) {
    return GestureDetector(
      onTap: () {
        if (widget.onGradientChanged != null) widget.onGradientChanged!(colors);
        _setFromPreset(colors.first);
      },
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: Colors.white, width: 1.5), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)]),
      ),
    );
  }
}

// 🔥 ROUND WHEEL PE FINGER POINTER DIKHANE WALA CUSTOM PAINTER
class _WheelThumbPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final Color thumbColor;

  _WheelThumbPainter({required this.hue, required this.saturation, required this.thumbColor});

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    double angle = hue * math.pi / 180.0;
    double distance = saturation * radius;
    
    double dx = radius + distance * math.cos(angle);
    double dy = radius + distance * math.sin(angle);

    final Paint borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3.0;
    final Paint fillPaint = Paint()..color = thumbColor..style = PaintingStyle.fill;
    final Paint shadowPaint = Paint()..color = Colors.black38..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(Offset(dx, dy), 12, shadowPaint);
    canvas.drawCircle(Offset(dx, dy), 12, fillPaint);
    canvas.drawCircle(Offset(dx, dy), 12, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelThumbPainter oldDelegate) => true;
}
