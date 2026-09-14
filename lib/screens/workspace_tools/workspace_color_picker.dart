import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../utils/constants.dart';

class AdvancedColorPickerModal extends StatefulWidget {
  final String title;
  final Color initialColor;
  final Function(Color) onColorChanged;
  final Function(List<Color>)? onGradientChanged; // 🔥 Naya Safe Function Gradients ke liye
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
        // Ignored for invalid hex
      }
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
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
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
                          height: 160,
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: Stack(
                            children: [
                              Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight))),
                              Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                              Positioned(
                                left: hsvColor.saturation * (MediaQuery.of(context).size.width - 60) - 12,
                                top: (1.0 - hsvColor.value) * 160 - 12,
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
                            border: Border.all(color: Colors.white, width: 1),
                            gradient: const LinearGradient(colors: [Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00), Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000)])
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: (hsvColor.hue / 360) * (MediaQuery.of(context).size.width - 60) - 10,
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

                      // Document Colors (Agar User Ne Code Mein Pass Kiye Hain)
                      if (widget.documentColors.isNotEmpty) ...[
                        const Text('Document Colors', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 12)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                            itemCount: widget.documentColors.length,
                            itemBuilder: (ctx, i) => _buildColorBubble(widget.documentColors[i]),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 🔥 1. PRO GRADIENT PALETTE (Single Horizontal Scroll)
                      const Text('Pro Gradients', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 12)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: AppConstants.proGradientPalette.length,
                          itemBuilder: (ctx, i) => _buildGradientBubble(AppConstants.proGradientPalette[i]),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🔥 2. SOLID PALETTE (Double Horizontal Scrollable Grid)
                      const Text('Solid Palette (Scroll 👉)', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 12)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 95, // Do lines ke liye perfect height
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Double line
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.0, 
                          ),
                          itemCount: AppConstants.proColorPalette.length,
                          itemBuilder: (ctx, i) => _buildGridColorBubble(AppConstants.proColorPalette[i]),
                        ),
                      ),
                      const SizedBox(height: 10),
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
    double w = MediaQuery.of(context).size.width - 60;
    double s = (pos.dx / w).clamp(0.0, 1.0);
    double v = 1.0 - (pos.dy / 160).clamp(0.0, 1.0);
    setState(() { hsvColor = hsvColor.withSaturation(s).withValue(v); });
    _onColorUpdate();
  }

  void _handleHueDrag(Offset pos) {
    double w = MediaQuery.of(context).size.width - 60;
    double h = ((pos.dx / w) * 360).clamp(0.0, 360.0);
    setState(() { hsvColor = hsvColor.withHue(h); });
    _onColorUpdate();
  }

  // Bubble for normal horizontal lists (Document Colors)
  Widget _buildColorBubble(Color c) {
    bool isSel = hsvColor.toColor().value == c.value;
    return GestureDetector(
      onTap: () => _setFromPreset(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40, height: 40, margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.white, width: isSel ? 3 : 1.5),
          boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)] : [const BoxShadow(color: Colors.black12, blurRadius: 2)]
        ),
      ),
    );
  }

  // Bubble for Grid View (Solid Palette)
  Widget _buildGridColorBubble(Color c) {
    bool isSel = hsvColor.toColor().value == c.value;
    return GestureDetector(
      onTap: () => _setFromPreset(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.white, width: isSel ? 3 : 1.5),
          boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)] : [const BoxShadow(color: Colors.black12, blurRadius: 2)]
        ),
      ),
    );
  }

  // Naya Bubble Gradients Ke Liye
  Widget _buildGradientBubble(List<Color> colors) {
    return GestureDetector(
      onTap: () {
        if (widget.onGradientChanged != null) {
          widget.onGradientChanged!(colors);
        }
        // Fallback: Gradient ka pehla color HSV mein set kar do taake UI crash na ho
        _setFromPreset(colors.first);
      },
      child: Container(
        width: 40, height: 40, margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)]
        ),
      ),
    );
  }
}
