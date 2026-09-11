import 'package:flutter/material.dart';
import 'dart:math';
import '../models/design_models.dart';
import 'pro_workspace_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({Key? key}) : super(key: key);

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final List<String> categories = ['All (سب)', 'Islamic (اسلامی)', 'Poetry (شاعری)', 'Social Media'];
  late final List<Map<String, dynamic>> premiumTemplates;

  @override
  void initState() {
    super.initState();
    _initializeTemplates();
  }

  void _initializeTemplates() {
    premiumTemplates = [
      {
        'title': 'Juma Mubarak',
        'category': 'Islamic (اسلامی)',
        'gradient': const [Color(0xFF065F46), Color(0xFF022C22)],
        'accent': const Color(0xFF10B981),
        'icon': Icons.mosque_rounded,
        'tag': 'PRO',
        'onLoad': () => _generateJumaMubarakTemplate(),
      },
      {
        'title': 'Iqbal Poetry',
        'category': 'Poetry (شاعری)',
        'gradient': const [Color(0xFF1E293B), Color(0xFF020617)],
        'accent': const Color(0xFF64748B),
        'icon': Icons.auto_stories_rounded,
        'tag': 'FREE',
        'onLoad': () => _generatePoetryTemplate(),
      },
      {
        'title': 'News Thumbnail',
        'category': 'Social Media',
        'gradient': const [Color(0xFF991B1B), Color(0xFF450A0A)],
        'accent': const Color(0xFFEF4444),
        'icon': Icons.smart_display_rounded,
        'tag': 'PRO',
        'onLoad': () => _generateNewsThumbnailTemplate(),
      },
      {
        'title': 'Aqwal-e-Zareen',
        'category': 'Poetry (شاعری)',
        'gradient': const [Color(0xFF854D0E), Color(0xFF422006)],
        'accent': const Color(0xFFCA8A04),
        'icon': Icons.format_quote_rounded,
        'tag': 'FREE',
        'onLoad': () => _generateAqwalTemplate(),
      },
    ];
  }

  // ---------------------------------------------------------
  // 🔥 SMART TEMPLATE GENERATOR (Fixed Coordinates for Mobile) 🔥
  // ---------------------------------------------------------

  ProjectModel _generateJumaMubarakTemplate() {
    String pId = DateTime.now().millisecondsSinceEpoch.toString();
    return ProjectModel(
      id: pId,
      name: 'Juma Mubarak Pro',
      lastModified: DateTime.now().millisecondsSinceEpoch,
      pages: [
        DesignPage(
          title: 'Page 1',
          pageColor: const Color(0xFF064E3B), 
          bgGradient: const [Color(0xFF047857), Color(0xFF022C22)],
          canvasRatio: 1.0, 
          elements: [
            DesignElement(
              id: 'el_1_$pId', x: 30, y: 60, 
              content: 'جمعہ مبارک', 
              fontFamily: 'JameelNoori', 
              fontSize: 65, // Adjusted for mobile canvas
              textColor: const Color(0xFFFDE047), 
              hasShadow: true, shadowColor: Colors.black54, shadowBlur: 10, shadowOffsetY: 5,
              isBevel: true, 
              textAlign: TextAlign.center,
            ),
            DesignElement(
              id: 'el_2_$pId', x: 20, y: 160, 
              content: 'اللہ تعالیٰ آپ کو اور آپ کے اہل خانہ کو\nاپنی بے شمار رحمتوں سے نوازے', 
              fontFamily: 'JameelNoori', 
              fontSize: 26, // Perfect fit
              textColor: Colors.white, 
              lineHeight: 1.8,
              textAlign: TextAlign.center,
              hasShadow: true, shadowColor: Colors.black87, shadowBlur: 5,
            ),
          ]
        )
      ]
    );
  }

  ProjectModel _generatePoetryTemplate() {
    String pId = DateTime.now().millisecondsSinceEpoch.toString();
    return ProjectModel(
      id: pId,
      name: 'Poetry Aesthetic',
      lastModified: DateTime.now().millisecondsSinceEpoch,
      pages: [
        DesignPage(
          title: 'Page 1',
          pageColor: const Color(0xFF1E293B),
          canvasRatio: 1.0,
          elements: [
            DesignElement(
              id: 'el_1_$pId', x: 10, y: 70, 
              content: 'ہزاروں سال نرگس اپنی بے نوری پہ روتی ہے\nبڑی مشکل سے ہوتا ہے چمن میں دیدہ ور پیدا', 
              fontFamily: 'JameelNoori', 
              fontSize: 28, // Fit inside canvas
              textColor: Colors.white, 
              lineHeight: 2.2,
              textAlign: TextAlign.center,
              hasShadow: true, shadowColor: Colors.black, shadowBlur: 10,
            ),
            DesignElement(
              id: 'el_2_$pId', x: 100, y: 220, 
              content: 'علامہ اقبالؒ', 
              fontFamily: 'JameelNoori', 
              fontSize: 24, 
              textColor: const Color(0xFFFDE047), 
              textBgColor: Colors.white.withOpacity(0.1),
              textBgRadius: 10,
              textAlign: TextAlign.center,
            ),
          ]
        )
      ]
    );
  }

  ProjectModel _generateNewsThumbnailTemplate() {
    String pId = DateTime.now().millisecondsSinceEpoch.toString();
    return ProjectModel(
      id: pId,
      name: 'YouTube News Thumbnail',
      lastModified: DateTime.now().millisecondsSinceEpoch,
      pages: [
        DesignPage(
          title: 'Page 1',
          pageColor: const Color(0xFF171717),
          canvasRatio: 16 / 9, // Wide ratio
          bgGradient: const [Color(0xFF991B1B), Color(0xFF450A0A)],
          elements: [
            DesignElement(
              id: 'el_1_$pId', x: 20, y: 20, 
              content: ' BREAKING NEWS ', 
              fontFamily: 'BombayBlack', 
              fontSize: 35, // Proper scaling for 16:9 height
              textColor: Colors.white, 
              textBgColor: const Color(0xFF000000), 
              isBold: true,
            ),
            DesignElement(
              id: 'el_2_$pId', x: 20, y: 80, 
              content: 'آج کی سب سے بڑی\nاور اہم خبر!', 
              fontFamily: 'BombayBlack', 
              fontSize: 45, 
              textColor: const Color(0xFFFDE047), 
              textAlign: TextAlign.right,
              lineHeight: 1.2,
              hasStroke: true, strokeColor: Colors.black, strokeWidth: 5.0,
              hasShadow: true, shadowColor: Colors.black, shadowBlur: 10, shadowOffsetY: 5,
            ),
          ]
        )
      ]
    );
  }

  ProjectModel _generateAqwalTemplate() {
    String pId = DateTime.now().millisecondsSinceEpoch.toString();
    return ProjectModel(
      id: pId,
      name: 'Aqwal Quote',
      lastModified: DateTime.now().millisecondsSinceEpoch,
      pages: [
        DesignPage(
          title: 'Page 1',
          pageColor: const Color(0xFFFFFBEB), 
          canvasRatio: 1.0, 
          elements: [
            DesignElement(
              id: 'el_1_$pId', x: 220, y: 20, 
              content: '❝', 
              fontFamily: 'JameelNoori', 
              fontSize: 80, 
              textColor: const Color(0xFFD4AF37).withOpacity(0.4), 
            ),
            DesignElement(
              id: 'el_2_$pId', x: 20, y: 100, 
              content: 'خاموشی سب سے بہترین جواب ہے\nبے وقوف انسان کے لیے۔', 
              fontFamily: 'JameelNoori', 
              fontSize: 32, 
              textColor: const Color(0xFF451A03), 
              lineHeight: 2.0,
              textAlign: TextAlign.center,
              isGlass: true, 
            ),
          ]
        )
      ]
    );
  }

  // ---------------------------------------------------------
  // 🎨 PREMIUM UI BUILDER
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Softer, premium background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text('Premium Templates', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.2)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1))),
              child: TabBar(
                isScrollable: true,
                labelColor: const Color(0xFF8B5CF6),
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: const Color(0xFF8B5CF6),
                indicatorWeight: 3.0,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: categories.map((c) => Tab(text: c)).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: categories.map((category) {
            List<Map<String, dynamic>> filteredList = category == 'All (سب)' 
                ? premiumTemplates 
                : premiumTemplates.where((t) => t['category'] == category).toList();

            if (filteredList.isEmpty) return _buildEmptyState();

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.82, // Optimized ratio for zero text cutoff
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                var template = filteredList[index];
                return _buildTemplateCard(template, context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, BuildContext context) {
    return GestureDetector(
      onTap: () {
        ProjectModel loadedProject = template['onLoad']();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProWorkspaceScreen(project: loadedProject)),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias, // 🔥 Ensures NO bleed over rounded corners
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Area (Abstract Design Logic)
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: template['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.antiAlias,
                  children: [
                    // Decorative Background Shapes
                    Positioned(
                      top: -20, right: -20,
                      child: CircleAvatar(radius: 50, backgroundColor: template['accent'].withOpacity(0.3)),
                    ),
                    Positioned(
                      bottom: -30, left: -10,
                      child: CircleAvatar(radius: 40, backgroundColor: template['accent'].withOpacity(0.2)),
                    ),
                    // Main Icon
                    Center(
                      child: Icon(template['icon'], size: 55, color: Colors.white.withOpacity(0.85)),
                    ),
                    // Pro/Free Tag
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: template['tag'] == 'PRO' 
                              ? const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFD97706)]) 
                              : LinearGradient(colors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.2)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: template['tag'] == 'PRO' ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                        ),
                        child: Text(
                          template['tag'],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: template['tag'] == 'PRO' ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Details Area (Clean Typography)
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      template['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template['category'],
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.style_outlined, size: 60, color: const Color(0xFF8B5CF6).withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text(
            'مزید ٹیمپلیٹس جلد آرہے ہیں!',
            style: TextStyle(fontSize: 22, color: Color(0xFF64748B), fontFamily: 'JameelNoori'),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
