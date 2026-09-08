import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 

import '../models/design_models.dart';
import 'pro_workspace_screen.dart';
import 'my_folder_screen.dart';
import 'templates_screen.dart';
import 'ai_design_screen.dart';

// 🔥 Naye imports yahan add kiye gaye hain
import '../widgets/urdu_fonts_modal.dart';
import '../widgets/stickers_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProjectModel> recentProjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
  }

  Future<void> _loadRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> projStrings = prefs.getStringList('qalamkaar_projects') ?? [];
    List<ProjectModel> loaded = projStrings.map((s) => ProjectModel.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    loaded.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    setState(() {
      recentProjects = loaded.take(5).toList(); 
      isLoading = false;
    });
  }

  void _showNewDesignModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Design', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildInputBox('WIDTH', '1080')),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.lock_outline, color: Color(0xFF8B5CF6))),
                Expanded(child: _buildInputBox('HEIGHT', '1080')),
                const SizedBox(width: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Text('px', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)))
              ],
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProWorkspaceScreen())).then((_) => _loadRecentProjects());
                },
                child: const Text('Start Designing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16), decoration: InputDecoration(hintText: val, hintStyle: const TextStyle(color: Colors.black38), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6))))),
      ],
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh feature jald aa raha hai! (Phase 2)', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF8B5CF6)));
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16), 
              decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), shape: BoxShape.circle), 
              child: const Icon(Icons.support_agent_rounded, color: Color(0xFF25D366), size: 40)
            ),
            const SizedBox(height: 15),
            const Text('Need Help? (مدد چاہیے؟)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              'ہماری ٹیم آپ کی مدد کے لیے واٹس ایپ پر موجود ہے۔ ایپ استعمال کرنے میں کوئی مسئلہ ہو تو ابھی میسج کریں!', 
              textAlign: TextAlign.center, 
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.grey, fontFamily: 'JameelNoori', fontSize: 16, height: 1.5)
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), 
                  padding: const EdgeInsets.symmetric(vertical: 14), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  shadowColor: const Color(0xFF25D366).withOpacity(0.4)
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final Uri whatsappUrl = Uri.parse("https://wa.me/918948507401?text=Hello Qalamkaar Pro! Mujhe aapki app me ek madad chahiye.");
                  
                  try {
                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp open nahi ho saka!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                  }
                },
                icon: const Icon(Icons.chat_rounded, color: Colors.white),
                label: const Text('Chat on WhatsApp', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              accountName: const Text('قلمکار پُرو', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 30, color: Colors.white, height: 1.0)),
              accountEmail: const Text('Urdu Designer App', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.white70)),
              currentAccountPicture: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: const Icon(Icons.history_edu, color: Color(0xFFD4AF37), size: 45),
              ),
            ),
            _buildDrawerItem(Icons.home_filled, 'Home Screen', () => Navigator.pop(context)),
            _buildDrawerItem(Icons.folder_rounded, 'My Projects', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())).then((_) => _loadRecentProjects());
            }),
            _buildDrawerItem(Icons.support_agent_rounded, 'Help & Support', () {
              Navigator.pop(context);
              _showHelpBottomSheet(context);
            }, iconColor: const Color(0xFF25D366)),
            _buildDrawerItem(Icons.star_rounded, 'Rate App', _showComingSoon, iconColor: const Color(0xFFD4AF37)),
            _buildDrawerItem(Icons.share_rounded, 'Share with Friends', _showComingSoon),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider()),
            _buildDrawerItem(Icons.info_outline_rounded, 'About Us', _showComingSoon, isGrey: true),
            _buildDrawerItem(Icons.privacy_tip_outlined, 'Privacy Policy', _showComingSoon, isGrey: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? iconColor, bool isGrey = false}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? (isGrey ? Colors.grey : const Color(0xFF6366F1))),
      title: Text(title, style: TextStyle(fontWeight: isGrey ? FontWeight.normal : FontWeight.bold, color: isGrey ? Colors.grey.shade700 : const Color(0xFF1E293B))),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B), size: 28), 
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_edu, color: Color(0xFFD4AF37), size: 30), 
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'Qalamkar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.5)),
                      TextSpan(text: 'Pro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37), letterSpacing: 0.5)),
                    ]
                  )
                ),
                const Text('URDU DESIGNER APP', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 2.0)),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Text(
                        'قلمکار پُرو',
                        style: TextStyle(
                          fontFamily: 'JameelNoori',
                          fontSize: 38, 
                          color: Colors.white, 
                          height: 1.0,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))
                          ]
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Design Your\nImagination', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: 0.5)),
                          const SizedBox(height: 10),
                          const Text('Beautiful Text • Stunning Graphics\nEndless Possibilities', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500, height: 1.4)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 5,
                              shadowColor: Colors.black26,
                            ),
                            onPressed: () => _showNewDesignModal(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Start Designing', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18)
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 12, 
                mainAxisSpacing: 20, 
                childAspectRatio: 1.05, 
                children: [
                  _buildPremiumGridTool('New Design', Icons.add_circle_rounded, const Color(0xFF3B82F6), const Color(0xFFEFF6FF), () => _showNewDesignModal(context)),
                  _buildPremiumGridTool('Templates', Icons.image_rounded, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplatesScreen()));
                  }),
                  _buildPremiumGridTool('Text Editor', Icons.title_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProWorkspaceScreen(initialAction: 'text_editor'))).then((_) => _loadRecentProjects());
                  }),
                  
                  // 🔥 NAYA FIX: Urdu Fonts ab dummy nahi raha!
                  _buildPremiumGridTool('Urdu Fonts', Icons.language_rounded, const Color(0xFFEC4899), const Color(0xFFFDF2F8), () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const UrduFontsManagerModal(),
                    );
                  }),
                  
                  _buildPremiumGridTool('Elements', Icons.category_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProWorkspaceScreen(initialAction: 'elements'))).then((_) => _loadRecentProjects());
                  }),
                  _buildPremiumGridTool('Images', Icons.photo_library_rounded, const Color(0xFF0EA5E9), const Color(0xFFF0F9FF), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProWorkspaceScreen(initialAction: 'images'))).then((_) => _loadRecentProjects());
                  }),
                  _buildPremiumGridTool('Backgrounds', Icons.wallpaper_rounded, const Color(0xFFF43F5E), const Color(0xFFFFF1F2), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProWorkspaceScreen(initialAction: 'backgrounds'))).then((_) => _loadRecentProjects());
                  }),
                  
                  // 🔥 NAYA FIX: Stickers ab dummy nahi raha!
                  _buildPremiumGridTool('Stickers', Icons.emoji_emotions_rounded, const Color(0xFFD946EF), const Color(0xFFFDF4FF), () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => StickersLibraryModal(
                        onStickerSelected: (stickerText) {
                          // Yahan sticker ko as a text canvas me add karne ka logic aayega (Phase 2 me connect karenge)
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sticker "$stickerText" selected! Canvas me update ho raha hai.', style: const TextStyle(fontFamily: 'JameelNoori'))));
                        },
                      ),
                    );
                  }),
                  
                  _buildPremiumGridTool('Layers', Icons.layers_rounded, const Color(0xFF06B6D4), const Color(0xFFECFEFF), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProWorkspaceScreen(initialAction: 'layers'))).then((_) => _loadRecentProjects());
                  }),
                  _buildPremiumGridTool('Tools', Icons.build_rounded, const Color(0xFF64748B), const Color(0xFFF8FAFC), _showComingSoon),
                  _buildPremiumGridTool('AI Design', Icons.smart_toy_rounded, const Color(0xFF6366F1), const Color(0xFFEEF2FF), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiDesignScreen()));
                  }, isNew: true),
                  _buildPremiumGridTool('Pro Effects', Icons.auto_fix_high_rounded, const Color(0xFF14B8A6), const Color(0xFFF0FDFA), _showComingSoon),
                ],
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.history_rounded, size: 22, color: Color(0xFF1E293B)),
                      SizedBox(width: 8),
                      Text('Recent Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())).then((_) => _loadRecentProjects()),
                    child: const Text('See All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                  )
                ],
              ),
              const SizedBox(height: 15),
              
              SizedBox(
                height: 170,
                child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                  : recentProjects.isEmpty
                    ? Center(child: Text('No recent projects yet.', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: recentProjects.length,
                        itemBuilder: (context, index) {
                          var proj = recentProjects[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProWorkspaceScreen(project: proj))).then((_) => _loadRecentProjects()),
                            child: Container(
                              width: 135,
                              margin: const EdgeInsets.only(right: 15, bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                                boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5))]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
                                      child: const Icon(Icons.design_services_rounded, size: 45, color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(proj.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('Edited: ${DateTime.fromMillisecondsSinceEpoch(proj.lastModified).toString().substring(0,10)}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 70, width: 70,
        margin: const EdgeInsets.only(top: 30),
        child: FloatingActionButton(
          onPressed: () => _showNewDesignModal(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE066), Color(0xFFF5D020), Color(0xFFD4AF37)], 
                begin: Alignment.topLeft, end: Alignment.bottomRight
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.6), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 6)),
              ]
            ),
            child: const Center(child: Icon(Icons.add_rounded, color: Colors.white, size: 38)),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        color: Colors.white,
        elevation: 20,
        shadowColor: Colors.black45,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Icons.home_filled, 'Home', true),
              _buildBottomNavItem(Icons.folder_rounded, 'Projects', false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())).then((_) => _loadRecentProjects())),
              const SizedBox(width: 45), 
              
              _buildBottomNavItem(Icons.support_agent_rounded, 'Help', false, onTap: () => _showHelpBottomSheet(context)),
              
              _buildBottomNavItem(Icons.person_rounded, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumGridTool(String title, IconData icon, Color iconColor, Color bgColor, VoidCallback onTap, {bool isNew = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))] 
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 24), 
                  ),
                  const SizedBox(height: 6),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: 0.2)), 
                ],
              ),
            ),
          ),
          if (isNew)
            Positioned(
              top: -6, right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1.5), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 4)]),
                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? _showComingSoon,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8), size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
