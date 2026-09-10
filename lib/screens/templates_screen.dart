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
  // Categories for the TabBar
  final List<String> categories = ['All (سب)', 'Islamic (اسلامی)', 'Poetry (شاعری)', 'Social Media'];

  // Smart Pre-built Templates Data
  late final List<Map<String, dynamic>> premiumTemplates;

  @override
  void initState() {
    super.initState();
    _initializeTemplates();
  }

  void _initializeTemplates() {
    // یوزرز کے لیے بہترین اور خوبصورت بنے بنائے ڈیزائنز
    premiumTemplates = [
      {
        'title': 'Juma Mubarak',
        'category': 'Islamic (اسلامی)',
        'gradient': const [Color(0xFF047857), Color(0xFF064E3B)], // Emerald to Dark Green
        'icon': Icons.mosque_rounded,
        'tag': 'PRO',
        'onLoad': () => _generateJumaMubarakTemplate(),
      },
      {
        'title': 'Iqbal Poetry',
        'category': 'Poetry (شاعری)',
        'gradient': const [Color(0xFF1E293B), Color(0xFF0F172A)], // Slate to Black
        'icon': Icons.auto_stories_rounded,
        'tag': 'FREE',
        'onLoad': () => _generatePoetryTemplate(),
      },
      {
        'title': 'News Thumbnail',
        'category': 'Social Media',
        'gradient': const [Color(0xFFDC2626), Color(0xFF991B1B)], // Red to Dark Red
        'icon': Icons.video_youtube_rounded,
        'tag': 'PRO',
        'onLoad': () => _generateNewsThumbnailTemplate(),
      },
      {
        'title': 'Aqwal-e-Zareen',
        'category': 'Poetry (شاعری)',
        'gradient': const [Color(0xFFD4AF37), Color(0xFFB8860B)], // Gold Palette
        'icon': Icons.format_quote_rounded,
        'tag': 'FREE',
        'onLoad': () => _generateAqwalTemplate(),
      },
    ];
  }

  // ---------------------------------------------------------
  // 🔥 TEMPLATE GENERATOR LOGIC (Error-Free Magic) 🔥
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
          pageColor: const Color(0xFF064E3B), // Base dark green
          bgGradient: const [Color(0xFF047857), Color(0xFF022C22)],
          canvasRatio: 1.0, // 1:1 Square Post
          elements: [
            DesignElement(
              id: 'el_1_$pId', x: 120, y: 150, 
              content: 'جمعہ مبارک', 
              fontFamily: 'JameelNoori', 
              fontSize: 130, 
              textColor: const Color(0xFFD4AF37), // Gold
              hasShadow: true, shadowColor: Colors.black54, shadowBlur: 15, shadowOffsetY: 8,
              isBevel: true, // 3D Pop Effect
            ),
            DesignElement(
              id: 'el_2_$pId', x: 80, y: 350, 
              content: 'اللہ تعالیٰ آپ کو اور آپ کے اہل خانہ کو\nاپنی بے شمار رحمتوں سے نوازے', 
              fontFamily: 'JameelNoori', 
              fontSize: 45, 
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
              id: 'el_1_$pId', x: 50, y: 150, 
              content: 'ہزاروں سال نرگس اپنی بے نوری پہ روتی ہے\nبڑی مشکل سے ہوتا ہے چمن میں دیدہ ور پیدا', 
              fontFamily: 'JameelNoori', 
              fontSize: 50, 
              textColor: Colors.white, 
              lineHeight: 2.2,
              textAlign: TextAlign.center,
              hasShadow: true, shadowColor: Colors.black, shadowBlur: 10,
            ),
            DesignElement(
              id: 'el_2_$pId', x: 300, y: 400, 
              content: 'علامہ اقبالؒ', 
              fontFamily: 'JameelNoori', 
              fontSize: 35, 
              textColor: const Color(0xFFFDE047), // Soft yellow
              textBgColor: Colors.white.withOpacity(0.1),
              textBgRadius: 15,
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
          canvasRatio: 16 / 9, // YouTube Ratio
          bgGradient: const [Color(0xFF991B1B), Color(0xFF450A0A)],
          elements: [
            DesignElement(
              id: 'el_1_$pId', x: 30, y: 30, 
              content: ' BREAKING NEWS ', 
              fontFamily: 'BombayBlack', 
              fontSize: 70, 
              textColor: Colors.white, 
              textBgColor: const Color(0xFF000000), 
              isBold: true,
            ),
            DesignElement(
              id: 'el_2_$pId', x: 30, y: 180, 
              content: 'آج کی سب سے بڑی\nاور اہم خبر!', 
              fontFamily: 'BombayBlack', 
              fontSize: 90, 
              textColor: const Color(0xFFFDE047), 
              textAlign: TextAlign.right,
              lineHeight: 1.2,
              hasStroke: true, strokeColor: Colors.black, strokeWidth: 8.0,
              hasShadow: true, shadowColor: Colors.black, shadowBlur: 15, shadowOffsetY: 10,
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
          pageColor: const Color(0xFFFFFBEB), // Very soft gold/yellow
          canvasRatio: 1.0, 
          elements: [
            DesignElement(
              id: 'el_1_$pId', x: 350, y: 50, 
              content: '❝', 
              fontFamily: 'JameelNoori', 
              fontSize: 150, 
              textColor: const Color(0xFFD4AF37).withOpacity(0.4), 
            ),
            DesignElement(
              id: 'el_2_$pId', x: 80, y: 180, 
              content: 'خاموشی سب سے بہترین جواب ہے\nبے وقوف انسان کے لیے۔', 
              fontFamily: 'JameelNoori', 
              fontSize: 55, 
              textColor: const Color(0xFF451A03), // Dark brown
              lineHeight: 2.0,
              textAlign: TextAlign.center,
              isGlass: true, // Smart premium effect
            ),
          ]
        )
      ]
    );
  }

  // ---------------------------------------------------------
  // 🎨 UI BUILDER
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text('Premium Templates', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF8B5CF6),
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: const Color(0xFF8B5CF6),
            indicatorWeight: 3.0,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: categories.map((c) => Tab(text: c)).toList(),
          ),
        ),
        body: TabBarView(
          children: categories.map((category) {
            
            // Filter templates based on selected category tab
            List<Map<String, dynamic>> filteredList = category == 'All (سب)' 
                ? premiumTemplates 
                : premiumTemplates.where((t) => t['category'] == category).toList();

            if (filteredList.isEmpty) {
              return _buildEmptyState();
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Canva style tall cards
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
        // Generate the project model safely
        ProjectModel loadedProject = template['onLoad']();
        
        // Navigate to the Workspace and pass the full generated project
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProWorkspaceScreen(project: loadedProject),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Area (Gradient + Icon)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: template['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(template['icon'], size: 60, color: Colors.white.withOpacity(0.7)),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: template['tag'] == 'PRO' ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          template['tag'],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: template['tag'] == 'PRO' ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Details Area
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      template['title'],
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to edit (ایڈٹ کریں)',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'JameelNoori'),
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
          Icon(Icons.style_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'مزید ٹیمپلیٹس جلد آرہے ہیں!',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontFamily: 'JameelNoori'),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
