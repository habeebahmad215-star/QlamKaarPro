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

  // 🔥 25 HIGH-QUALITY PREMIUM TEXT EFFECTS 🔥
  final List<Map<String, dynamic>> _effectsLibrary = [
    // 1
    {
      'title': 'Gold & Royal',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFFD4AF37),
      'builder': (String text) => DesignElement(
        id: 'gold_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFD4AF37), Color(0xFFFFF200), Color(0xFFD4AF37)],
        isBevel: true, hasStroke: true, strokeColor: Colors.black87, strokeWidth: 2.5,
        hasShadow: true, shadowColor: Colors.black45, shadowBlur: 10, shadowOffsetX: 5, shadowOffsetY: 5,
      ),
    },
    // 2
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
    // 3
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
    // 4
    {
      'title': 'Glassmorphism',
      'icon': Icons.blur_on_rounded,
      'color': Colors.blueGrey,
      'builder': (String text) => DesignElement(
        id: 'glass_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.white, isGlass: true, opacity: 0.9,
      ),
    },
    // 5
    {
      'title': 'Vintage Stamp',
      'icon': Icons.local_post_office_rounded,
      'color': const Color(0xFFB91C1C),
      'builder': (String text) => DesignElement(
        id: 'vintage_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.transparent, 
        hasStroke: true, strokeColor: const Color(0xFFB91C1C), strokeWidth: 2.0, angle: -0.1, 
        isInnerShadow: true, hasShadow: true, shadowColor: Colors.black12, shadowBlur: 5,
      ),
    },
    // 6
    {
      'title': 'Silver Platinum',
      'icon': Icons.diamond_rounded,
      'color': const Color(0xFF94A3B8),
      'builder': (String text) => DesignElement(
        id: 'silver_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFF94A3B8), Color(0xFFE2E8F0), Color(0xFF64748B)],
        isBevel: true, hasStroke: true, strokeColor: const Color(0xFF1E293B), strokeWidth: 2.0,
        hasShadow: true, shadowColor: Colors.black54, shadowBlur: 8, shadowOffsetX: 4, shadowOffsetY: 4,
      ),
    },
    // 7
    {
      'title': 'Rose Gold',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFFDA4AF),
      'builder': (String text) => DesignElement(
        id: 'rosegold_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFFDA4AF), Color(0xFFFFF1F2), Color(0xFFE11D48)],
        isBevel: true, hasStroke: true, strokeColor: const Color(0xFF881337), strokeWidth: 1.5,
        hasShadow: true, shadowColor: const Color(0xFF881337).withOpacity(0.4), shadowBlur: 15, shadowOffsetX: 5, shadowOffsetY: 5,
      ),
    },
    // 8
    {
      'title': 'Fire & Lava',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.deepOrange,
      'builder': (String text) => DesignElement(
        id: 'fire_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFEA580C), Color(0xFFFBBF24)],
        isBevel: true, hasShadow: true, shadowColor: const Color(0xFFDC2626), shadowBlur: 20, shadowOffsetX: 0, shadowOffsetY: 5,
      ),
    },
    // 9
    {
      'title': 'Ice / Frozen',
      'icon': Icons.ac_unit_rounded,
      'color': Colors.lightBlueAccent,
      'builder': (String text) => DesignElement(
        id: 'ice_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFE0F2FE), Color(0xFF38BDF8)],
        isGlass: true, isInnerShadow: true, hasStroke: true, strokeColor: Colors.white, strokeWidth: 1.0,
      ),
    },
    // 10
    {
      'title': 'Emerald Stone',
      'icon': Icons.hexagon_rounded,
      'color': const Color(0xFF10B981),
      'builder': (String text) => DesignElement(
        id: 'emerald_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFF047857), Color(0xFF34D399)],
        isBevel: true, hasStroke: true, strokeColor: const Color(0xFF064E3B), strokeWidth: 2.0,
        text3dDepth: 5.0, text3dColor: const Color(0xFF064E3B),
      ),
    },
    // 11
    {
      'title': 'Cyberpunk 2077',
      'icon': Icons.memory_rounded,
      'color': const Color(0xFFFDE047),
      'builder': (String text) => DesignElement(
        id: 'cyberpunk_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: const Color(0xFFFDE047),
        hasStroke: true, strokeColor: const Color(0xFF22D3EE), strokeWidth: 2.0,
        text3dDepth: 8.0, text3dColor: const Color(0xFFE11D48),
        hasShadow: true, shadowColor: const Color(0xFFE11D48), shadowBlur: 10, shadowOffsetX: -5, shadowOffsetY: 5,
      ),
    },
    // 12
    {
      'title': 'Hollow Outline',
      'icon': Icons.check_box_outline_blank_rounded,
      'color': const Color(0xFFF59E0B),
      'builder': (String text) => DesignElement(
        id: 'hollow_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.transparent,
        hasStroke: true, strokeColor: const Color(0xFFF59E0B), strokeWidth: 4.0,
        text3dDepth: 8.0, text3dColor: const Color(0xFFB45309),
      ),
    },
    // 13
    {
      'title': 'Bubblegum',
      'icon': Icons.bubble_chart_rounded,
      'color': const Color(0xFFF472B6),
      'builder': (String text) => DesignElement(
        id: 'bubble_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFF472B6), Color(0xFFC084FC)],
        isBevel: true,
        hasShadow: true, shadowColor: const Color(0xFF831843).withOpacity(0.3), shadowBlur: 15, shadowOffsetX: 0, shadowOffsetY: 10,
      ),
    },
    // 14
    {
      'title': 'Dark Engraved',
      'icon': Icons.vertical_align_bottom_rounded,
      'color': const Color(0xFF334155),
      'builder': (String text) => DesignElement(
        id: 'engraved_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: const Color(0xFF334155),
        isInnerShadow: true,
        hasShadow: true, shadowColor: Colors.white, shadowBlur: 2, shadowOffsetX: 1.5, shadowOffsetY: 1.5, // White shadow creates cutout effect
      ),
    },
    // 15
    {
      'title': 'Retro Synthwave',
      'icon': Icons.waves_rounded,
      'color': const Color(0xFFD946EF),
      'builder': (String text) => DesignElement(
        id: 'synthwave_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
        hasStroke: true, strokeColor: Colors.white, strokeWidth: 1.5,
        text3dDepth: 10.0, text3dColor: const Color(0xFF0F172A),
      ),
    },
    // 16
    {
      'title': 'Chocolate Wood',
      'icon': Icons.park_rounded,
      'color': const Color(0xFF78350F),
      'builder': (String text) => DesignElement(
        id: 'wood_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFB45309), Color(0xFF78350F)],
        isInnerShadow: true, isBevel: true,
        hasShadow: true, shadowColor: Colors.black54, shadowBlur: 8, shadowOffsetX: 5, shadowOffsetY: 5,
      ),
    },
    // 17
    {
      'title': 'Ghost Phantom',
      'icon': Icons.visibility_off_rounded,
      'color': Colors.grey.shade400,
      'builder': (String text) => DesignElement(
        id: 'ghost_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.white, opacity: 0.6,
        hasShadow: true, shadowColor: Colors.white, shadowBlur: 25, shadowOffsetX: 0, shadowOffsetY: 0,
      ),
    },
    // 18
    {
      'title': 'Toxic Green',
      'icon': Icons.coronavirus_rounded,
      'color': const Color(0xFF84CC16),
      'builder': (String text) => DesignElement(
        id: 'toxic_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: const Color(0xFFBEF264),
        hasStroke: true, strokeColor: const Color(0xFF3F6212), strokeWidth: 2.0,
        hasShadow: true, shadowColor: const Color(0xFF84CC16), shadowBlur: 20, shadowOffsetX: 0, shadowOffsetY: 0,
      ),
    },
    // 19
    {
      'title': 'Sunset Glow',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFFF97316),
      'builder': (String text) => DesignElement(
        id: 'sunset_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFEAB308), Color(0xFFF97316), Color(0xFFBE123C)],
        hasShadow: true, shadowColor: const Color(0xFFF97316).withOpacity(0.5), shadowBlur: 30, shadowOffsetX: 0, shadowOffsetY: 10,
      ),
    },
    // 20
    {
      'title': 'Candy Foil',
      'icon': Icons.cake_rounded,
      'color': const Color(0xFF6366F1),
      'builder': (String text) => DesignElement(
        id: 'candy_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFF3B82F6), Color(0xFFEC4899), Color(0xFFEAB308)],
        isBevel: true, hasStroke: true, strokeColor: Colors.white, strokeWidth: 1.5,
      ),
    },
    // 21
    {
      'title': 'Chrome Metal',
      'icon': Icons.sports_motorsports_rounded,
      'color': const Color(0xFF475569),
      'builder': (String text) => DesignElement(
        id: 'chrome_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFF8FAFC), Color(0xFF475569), Color(0xFF0F172A), Color(0xFFF8FAFC)],
        isBevel: true, hasStroke: true, strokeColor: Colors.black, strokeWidth: 1.5,
      ),
    },
    // 22
    {
      'title': 'Blueprint Outline',
      'icon': Icons.architecture_rounded,
      'color': const Color(0xFF2563EB),
      'builder': (String text) => DesignElement(
        id: 'blueprint_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.transparent,
        hasStroke: true, strokeColor: Colors.white, strokeWidth: 2.5,
        hasShadow: true, shadowColor: const Color(0xFF1D4ED8), shadowBlur: 10, shadowOffsetX: -2, shadowOffsetY: 2,
      ),
    },
    // 23
    {
      'title': 'Blood Red',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF991B1B),
      'builder': (String text) => DesignElement(
        id: 'blood_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFFDC2626), Color(0xFF7F1D1D)],
        isInnerShadow: true,
        hasShadow: true, shadowColor: const Color(0xFF991B1B), shadowBlur: 15, shadowOffsetX: 0, shadowOffsetY: 5,
      ),
    },
    // 24
    {
      'title': 'Cosmic Space',
      'icon': Icons.rocket_launch_rounded,
      'color': const Color(0xFF4C1D95),
      'builder': (String text) => DesignElement(
        id: 'cosmic_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        elementColor: Colors.white,
        textGradient: const [Color(0xFF1E1B4B), Color(0xFF4C1D95), Color(0xFFDB2777)],
        hasStroke: true, strokeColor: Colors.white, strokeWidth: 1.0,
        hasShadow: true, shadowColor: Colors.pinkAccent, shadowBlur: 20, shadowOffsetX: 0, shadowOffsetY: 0,
      ),
    },
    // 25
    {
      'title': 'Pure White 3D',
      'icon': Icons.view_in_ar_outlined,
      'color': Colors.grey.shade300,
      'builder': (String text) => DesignElement(
        id: 'purewhite_effect', x: 0, y: 0, content: text, isText: true, fontSize: 60, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
        textColor: Colors.white,
        text3dDepth: 15.0, text3dColor: const Color(0xFFE2E8F0),
        hasShadow: true, shadowColor: Colors.black12, shadowBlur: 20, shadowOffsetX: 10, shadowOffsetY: 10,
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
    DesignElement finalElement = _previewElement.clone();
    finalElement.x = 60;
    finalElement.y = 200;
    finalElement.width = 300;
    finalElement.height = 150;

    // Har effect ke hisaab se suitable background color (Neon ya Ghost ke liye dark, baqi ke liye white)
    Color canvasBgColor = Colors.white;
    if (_selectedEffectIndex == 2 || _selectedEffectIndex == 14 || _selectedEffectIndex == 16 || _selectedEffectIndex == 21) {
      canvasBgColor = const Color(0xFF1E293B); 
    } else if (_selectedEffectIndex == 13) {
      canvasBgColor = const Color(0xFFF1F5F9);
    }

    ProjectModel proj = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Pro Effect Design',
      lastModified: DateTime.now().millisecondsSinceEpoch,
      pages: [
        DesignPage(
          title: 'Page 1',
          pageColor: canvasBgColor,
          elements: [finalElement],
        )
      ],
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProWorkspaceScreen(project: proj)),
    );
  }

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
    // Neon glow ya Ghost effect ke liye canvas dark ho jayega live preview me
    Color previewBgColor = const Color(0xFFE2E8F0);
    if (_selectedEffectIndex == 2 || _selectedEffectIndex == 14 || _selectedEffectIndex == 16 || _selectedEffectIndex == 21) {
      previewBgColor = const Color(0xFF1E293B); 
    }

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
                color: previewBgColor,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                image: previewBgColor == const Color(0xFFE2E8F0) ? const DecorationImage(
                  image: AssetImage('assets/images/transparent_bg_grid.png'), // Grid background
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Choose Style (انداز منتخب کریں)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('${_selectedEffectIndex + 1} / ${_effectsLibrary.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                      ],
                    ),
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
