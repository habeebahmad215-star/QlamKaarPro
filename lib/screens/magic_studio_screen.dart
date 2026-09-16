import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/design_models.dart';
import 'pro_workspace_screen.dart';

class MagicStudioScreen extends StatefulWidget {
  const MagicStudioScreen({Key? key}) : super(key: key);

  @override
  State<MagicStudioScreen> createState() => _MagicStudioScreenState();
}

class _MagicStudioScreenState extends State<MagicStudioScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // 🔥 MAGIC TOOL 1: NAME ART STUDIO (Working)
  void _openNameArtStudio() {
    TextEditingController nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Icon(Icons.brush_rounded, size: 50, color: Color(0xFFD4AF37)),
              const SizedBox(height: 10),
              const Text('Name Art Calligraphy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const Text('اپنا نام لکھیں اور جادو دیکھیں', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 28),
                decoration: InputDecoration(
                  hintText: 'نام یہاں لکھیں...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      Navigator.pop(ctx);
                      _generateNameArtCanvas(nameController.text);
                    }
                  },
                  child: const Text('Generate Magic Art ✨', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _generateNameArtCanvas(String text) {
    ProjectModel proj = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Magic Name Art',
      lastModified: DateTime.now().millisecondsSinceEpoch,
      pages: [
        DesignPage(
          title: 'Page 1',
          pageColor: const Color(0xFF0F172A), // Dark Royal Background
          elements: [
            DesignElement(
              id: 'magic_name', x: 40, y: 300, content: text, isText: true, fontSize: 100, fontFamily: 'JameelNoori', textAlign: TextAlign.center,
              elementColor: Colors.white,
              textGradient: const [Color(0xFFD4AF37), Color(0xFFFFF200)], // Gold Gradient
              isBevel: true, hasStroke: true, strokeColor: Colors.black87, strokeWidth: 2.0,
              hasShadow: true, shadowColor: const Color(0xFFD4AF37).withOpacity(0.5), shadowBlur: 30, shadowOffsetX: 0, shadowOffsetY: 10,
            )
          ],
        )
      ],
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProWorkspaceScreen(project: proj)));
  }

  // 🔥 MAGIC TOOL 2: AUTO POST GENERATOR (Working)
  void _openAutoPostGenerator() {
    TextEditingController postController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Icon(Icons.auto_awesome_motion_rounded, size: 50, color: Color(0xFF8B5CF6)),
              const SizedBox(height: 10),
              const Text('Auto Post Maker', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const Text('شاعری یا اقوال لکھیں، پوسٹ خود بنے گی', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: postController,
                maxLines: 3,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 22),
                decoration: InputDecoration(
                  hintText: 'اپنی تحریر یہاں لکھیں...',
                  filled: true, fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (postController.text.isNotEmpty) {
                      Navigator.pop(ctx);
                      _generateAutoPost(postController.text);
                    }
                  },
                  child: const Text('Create Magic Post ✨', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _generateAutoPost(String text) {
    ProjectModel proj = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Magic Post',
      lastModified: DateTime.now().millisecondsSinceEpoch,
      pages: [
        DesignPage(
          title: 'Page 1',
          pageColor: Colors.white,
          bgGradient: const [Color(0xFF1A2980), Color(0xFF26D0CE)], // Premium Blue Gradient
          elements: [
            // Frame/Border
            DesignElement(id: 'border_1', x: 20, y: 20, content: 'Border', isText: false, isBorder: true, width: 1040, height: 1040, elementColor: Colors.white.withOpacity(0.5), strokeWidth: 3, borderStyle: '0', cornerRadius: 20),
            // The Text
            DesignElement(id: 'post_text', x: 50, y: 400, content: text, isText: true, fontSize: 50, fontFamily: 'JameelNoori', textAlign: TextAlign.center, width: 980, textColor: Colors.white, hasShadow: true, shadowColor: Colors.black45, shadowBlur: 10, shadowOffsetY: 5),
            // Watermark Logo Text
            DesignElement(id: 'watermark', x: 450, y: 950, content: 'قلمکار پُرو', isText: true, fontSize: 30, fontFamily: 'JameelNoori', textColor: Colors.white70),
          ],
        )
      ],
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProWorkspaceScreen(project: proj)));
  }

  void _showComingSoonPremium(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Color(0xFFEC4899), size: 60),
            const SizedBox(height: 15),
            Text(feature, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text('یہ بلین ڈالر فیچر اگلے اپڈیٹ میں شامل کیا جائے گا۔ جڑے رہیں!', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'JameelNoori', fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Awesome!', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      )
    );
  }

  Widget _buildMagicCard({required String title, required String urduTitle, required String desc, required IconData icon, required List<Color> colors, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: colors[0].withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20, top: -20,
              child: Icon(icon, size: 120, color: Colors.white.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.5))),
                    child: Icon(icon, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                            const SizedBox(width: 8),
                            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 18),
                          ],
                        ),
                        Text(urduTitle, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 18, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated Magic Background
                  Positioned.fill(
                    child: Image.asset('assets/images/transparent_bg_grid.png', repeat: ImageRepeat.repeat, color: Colors.white.withOpacity(0.05)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF4F46E5).withOpacity(0.8), const Color(0xFF0F172A)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30, left: 24,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Magic Studio ✨', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
                          Text('آٹو میٹک ڈیزائن ٹولز کا مجموعہ', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 20, color: Color(0xFFA5B4FC))),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMagicCard(
                  title: 'Brand Kit', urduTitle: 'برانڈ کٹ', desc: 'Save Logos, Colors & Fonts forever.',
                  icon: Icons.branding_watermark_rounded, colors: [const Color(0xFFF59E0B), const Color(0xFFEA580C)],
                  onTap: () => _showComingSoonPremium('Brand Kit Studio'),
                ),
                _buildMagicCard(
                  title: 'Magic Resize', urduTitle: 'میجک ری سائز', desc: '1-Click resize to YT, Insta, Facebook.',
                  icon: Icons.aspect_ratio_rounded, colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                  onTap: () => _showComingSoonPremium('Magic AI Resize'),
                ),
                _buildMagicCard(
                  title: 'Name Art Studio', urduTitle: 'نام آرٹ اور خطاطی', desc: 'Generate 3D Gold Islamic Calligraphy.',
                  icon: Icons.brush_rounded, colors: [const Color(0xFFD4AF37), const Color(0xFFB45309)],
                  onTap: _openNameArtStudio, // 🔥 100% WORKING
                ),
                _buildMagicCard(
                  title: 'Auto Post Maker', urduTitle: 'آٹو پوسٹ جنریٹر', desc: 'Type text, AI creates the design.',
                  icon: Icons.auto_awesome_motion_rounded, colors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                  onTap: _openAutoPostGenerator, // 🔥 100% WORKING
                ),
                _buildMagicCard(
                  title: 'Smart Mockups', urduTitle: 'اسمارٹ موک اپس', desc: 'Put your design on Mobile, T-Shirt, 3D.',
                  icon: Icons.devices_rounded, colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                  onTap: () => _showComingSoonPremium('Smart Mockups Engine'),
                ),
                _buildMagicCard(
                  title: 'Community PLP', urduTitle: 'پراجیکٹ شیئرنگ', desc: 'Share editable design links with friends.',
                  icon: Icons.share_rounded, colors: [const Color(0xFFEC4899), const Color(0xFFBE185D)],
                  onTap: () => _showComingSoonPremium('Community PLP Cloud'),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
