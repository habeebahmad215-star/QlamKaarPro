import 'package:flutter/material.dart';
import 'dart:math';
import '../models/design_models.dart';
import 'pro_workspace_screen.dart';

class ProEffectsScreen extends StatefulWidget {
  const ProEffectsScreen({Key? key}) : super(key: key);

  @override
  State<ProEffectsScreen> createState() => _ProEffectsScreenState();
}

class _ProEffectsScreenState extends State<ProEffectsScreen> {
  final TextEditingController _textController = TextEditingController(text: 'قلمکار پُرو');
  int _selectedEffectIndex = 0;
  late DesignElement _previewElement;

  final List<Map<String, dynamic>> _effectsLibrary = [
    {
      'title': 'Gold & Royal',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFFD4AF37),
      'builder': (String text) => DesignElement(
        id: 'gold_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFD4AF37), Color(0xFFFFF200)],
        isBevel: true,
        hasStroke: true, strokeColor: Colors.black87, strokeWidth: 2.5,
        hasShadow: true, shadowColor: Colors.black45, shadowBlur: 10, shadowOffsetX: 5, shadowOffsetY: 5,
      ),
    },
    {
      'title': '3D Pop-Out',
      'icon': Icons.view_in_ar_rounded,
      'color': const Color(0xFF8B5CF6),
      'builder': (String text) => DesignElement(
        id: '3d_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: const Color(0xFF8B5CF6),
        text3dDepth: 12.0, text3dColor: const Color(0xFF4C1D95),
        hasShadow: true, shadowColor: Colors.black26, shadowBlur: 15, shadowOffsetX: 15, shadowOffsetY: 15,
      ),
    },
    {
      'title': 'Neon Glow',
      'icon': Icons.lightbulb_circle_rounded,
      'color': Colors.cyanAccent,
      'builder': (String text) => DesignElement(
        id: 'neon_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.white,
        hasStroke: true, strokeWidth: 1.5, strokeColor: Colors.white,
        hasShadow: true, shadowColor: Colors.cyanAccent, shadowBlur: 25.0, shadowOffsetX: 0, shadowOffsetY: 0,
      ),
    },
    {
      'title': 'Glassmorphism',
      'icon': Icons.blur_on_rounded,
      'color': Colors.blueGrey,
      'builder': (String text) => DesignElement(
        id: 'glass_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.white, isGlass: true, opacity: 0.9,
      ),
    },
    {
      'title': 'Vintage Stamp',
      'icon': Icons.local_post_office_rounded,
      'color': const Color(0xFFB91C1C),
      'builder': (String text) => DesignElement(
        id: 'vintage_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.transparent, 
        hasStroke: true, strokeColor: const Color(0xFFB91C1C), strokeWidth: 2.0,
        angle: -0.1, // Halka sa tehra
        isInnerShadow: true, hasShadow: true, shadowColor: Colors.black12, shadowBlur: 5,
      ),
    }
  ];

  @override
  void initState() {
    super.initState();
    _applyEffect(0);
  }

  void _applyEffect(int index) {
    setState(() {
      _selectedEffectIndex = index;
      _previewElement = _effectsLibrary[index]['builder'](_textController.text.isEmpty ? 'ٹیکسٹ' : _textController.text);
    });
  }

  void _openInWorkspace() {
    // Canvas ke liye element ki position safe set kar rahe hain
    DesignElement finalElement = _previewElement.clone();
    finalElement.x = 60;
    finalElement.y = 200;
    finalElement.width = 300;
    finalElement.height = 150;

    ProjectModel proj = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Pro Effect Design',
      lastModified: DateTime.now().millisecondsSinceEpoch,
      pages: [
        DesignPage(
          title: 'Page 1',
          pageColor: _selectedEffectIndex == 2 ? const Color(0xFF1E293B) : Colors.white, // Neon ke liye dark bg automatically
          elements: [finalElement],
        )
      ],
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProWorkspaceScreen(project: proj)),
    );
  }

  // Same text rendering logic as Workspace to ensure exactly matching preview
  Widget _buildPreviewText(DesignElement e) {
    Widget buildTextWidget(Color c, [List<Shadow>? shadow]) {
      List<Shadow> currentShadows = shadow != null ? List.from(shadow) : [];
      if (shadow == null && e.hasShadow) currentShadows.add(Shadow(color: e.shadowColor, blurRadius: e.shadowBlur, offset: Offset(e.shadowOffsetX, e.shadowOffsetY)));

      Color finalTextColor = c;
      if (e.isGlass && e.textGradient == null && e.textTextureBytes == null) {
        finalTextColor = c.withOpacity(0.35);
        currentShadows.add(const Shadow(color: Colors.white, offset: Offset(0, 0), blurRadius: 15));
        currentShadows.add(const Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 5));
      }

      if (e.isBevel) {
        currentShadows.add(const Shadow(color: Colors.white70, offset: Offset(-2, -2), blurRadius: 2));
        currentShadows.add(const Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 2));
      }

      if (e.isInnerShadow) {
        currentShadows.add(const Shadow(color: Colors.black87, offset: Offset(1.5, 1.5), blurRadius: 2));
      }

      TextStyle st = TextStyle(
        fontFamily: e.fontFamily, fontSize: e.fontSize, color: finalTextColor, 
        shadows: currentShadows.isNotEmpty ? currentShadows : null,
      );
      
      return Text(e.content, textAlign: e.textAlign, style: st);
    }
    
    List<Widget> blockLayers = [];
    if (e.text3dDepth > 0) {
      for (double i = e.text3dDepth; i > 0; i -= 1.0) {
        blockLayers.add(Transform.translate(offset: Offset(i, i), child: buildTextWidget(e.text3dColor, [])));
      }
    }
    
    Widget mainTxt = buildTextWidget(e.textGradient != null ? Colors.white : e.textColor);
    if (e.textGradient != null) {
      mainTxt = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(colors: e.textGradient!).createShader(bounds), 
        child: mainTxt
      );
    }
    blockLayers.add(mainTxt);
    
    Widget txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: blockLayers);
    
    if (e.hasStroke) {
      TextStyle stStroke = TextStyle(
        fontFamily: e.fontFamily, fontSize: e.fontSize, 
        foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = e.strokeWidth..color = e.strokeColor,
      );
      Widget strokeTxt = Text(e.content, textAlign: e.textAlign, style: stStroke);
      txt = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [strokeTxt, txt]);
    }
    
    return Transform.rotate(angle: e.angle, child: txt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Premium Text Effects', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Live Preview Area
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                // Neon glow ke liye preview bg dark ho jata hai
                color: _selectedEffectIndex == 2 ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                image: _selectedEffectIndex != 2 ? const DecorationImage(
                  image: AssetImage('assets/images/transparent_bg_grid.png'), // Agar grid image ho toh acha hai
                  repeat: ImageRepeat.repeat, opacity: 0.3
                ) : null,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildPreviewText(_previewElement),
                ),
              ),
            ),
          ),

          // 2. Control Area (Text Input & Effects)
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  
                  // Text Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _textController,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 24),
                        decoration: const InputDecoration(
                          hintText: 'یہاں کچھ لکھیں...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (val) => _applyEffect(_selectedEffectIndex),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Choose Style (انداز منتخب کریں)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  const SizedBox(height: 15),

                  // Effects Gallery Grid
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _effectsLibrary.length,
                      itemBuilder: (context, index) {
                        var eff = _effectsLibrary[index];
                        bool isSelected = _selectedEffectIndex == index;
                        return GestureDetector(
                          onTap: () => _applyEffect(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 110,
                            margin: const EdgeInsets.only(right: 12, bottom: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? eff['color'].withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? eff['color'] : Colors.grey.shade200, width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(eff['icon'], size: 36, color: eff['color']),
                                const SizedBox(height: 12),
                                Text(
                                  eff['title'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: const Color(0xFF1E293B)),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                        ),
                        onPressed: _openInWorkspace,
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: const Text('Use in Design (ڈیزائن میں شامل کریں)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
