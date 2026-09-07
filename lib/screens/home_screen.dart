import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/design_models.dart';
import 'pro_workspace_screen.dart';
import 'my_folder_screen.dart';

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
                const Text('New Design', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh feature jald aa raha hai!', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF8B5CF6)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Bohat hi light aur premium grey/blue background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B), size: 28), onPressed: _showComingSoon),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_edu, color: Color(0xFFD4AF37), size: 30), // Qalam (Feather) Icon
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'Qalamkar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: 0.5)),
                      TextSpan(text: 'Pro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Color(0xFFD4AF37), letterSpacing: 0.5)),
                    ]
                  )
                ),
                const Text('URDU DESIGNER APP', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 2.0)),
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
              // 🌟 1. ADVANCED HERO BANNER (With Watermark & Soft Glow)
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Stack(
                  children: [
                    // Right Side Big Urdu Watermark
                    Positioned(
                      right: 15,
                      top: 15,
                      child: Opacity(
                        opacity: 0.15,
                        child: const Text('قلمکار', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 90, color: Colors.white, height: 1.0)),
                      ),
                    ),
                    // Right Bottom Feather Icon
                    Positioned(
                      right: -15,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.1,
                        child: const Icon(Icons.history_edu, size: 140, color: Colors.white),
                      ),
                    ),
                    // Main Text Content
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Design Your\nImagination', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          const Text('Beautiful Text • Stunning Graphics', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 5,
                              shadowColor: Colors.black26,
                            ),
                            onPressed: () => _showNewDesignModal(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Start Designing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 16)
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 🌟 2. SOFT PASTEL 12-ITEM GRID TOOLS
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildGridTool('New Design', Icons.add_circle, const Color(0xFF93C5FD), const Color(0xFF3B82F6), () => _showNewDesignModal(context)),
                  _buildGridTool('Templates', Icons.image, const Color(0xFFC4B5FD), const Color(0xFF8B5CF6), _showComingSoon),
                  _buildGridTool('Text Editor', Icons.title, const Color(0xFF6EE7B7), const Color(0xFF10B981), _showComingSoon),
                  _buildGridTool('Urdu Fonts', Icons.language, const Color(0xFFF9A8D4), const Color(0xFFEC4899), _showComingSoon),
                  
                  _buildGridTool('Elements', Icons.category, const Color(0xFFFDE047), const Color(0xFFF59E0B), _showComingSoon),
                  _buildGridTool('Images', Icons.photo_library, const Color(0xFF5EEAD4), const Color(0xFF0D9488), _showComingSoon),
                  _buildGridTool('Backgrounds', Icons.wallpaper, const Color(0xFFFDBA74), const Color(0xFFEA580C), _showComingSoon),
                  _buildGridTool('Stickers', Icons.emoji_emotions, const Color(0xFFD8B4FE), const Color(0xFFC026D3), _showComingSoon),
                  
                  _buildGridTool('Layers', Icons.layers, const Color(0xFF7DD3FC), const Color(0xFF0284C7), _showComingSoon),
                  _buildGridTool('Tools', Icons.build_rounded, const Color(0xFFFDA4AF), const Color(0xFFE11D48), _showComingSoon),
                  _buildGridTool('AI Design', Icons.smart_toy_rounded, const Color(0xFFA5B4FC), const Color(0xFF4F46E5), _showComingSoon, isNew: true),
                  _buildGridTool('Pro Effects', Icons.auto_fix_high, const Color(0xFF86EFAC), const Color(0xFF16A34A), _showComingSoon),
                ],
              ),

              const SizedBox(height: 30),

              // 🌟 3. RECENT PROJECTS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.history_rounded, size: 20, color: Color(0xFF1E293B)),
                      SizedBox(width: 8),
                      Text('Recent Projects', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())).then((_) => _loadRecentProjects()),
                    child: const Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                  )
                ],
              ),
              const SizedBox(height: 15),
              
              SizedBox(
                height: 170,
                child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                  : recentProjects.isEmpty
                    ? Center(child: Text('No recent projects yet.', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)))
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
                                boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5))]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                                      child: const Icon(Icons.design_services_rounded, size: 45, color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(proj.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('Edited: ${DateTime.fromMillisecondsSinceEpoch(proj.lastModified).toString().substring(0,10)}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
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
      
      // 🌟 4. BOTTOM NAVIGATION BAR WITH GLOWING FAB
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
              gradient: const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFD4AF37), Color(0xFFB8860B)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 20, spreadRadius: 3, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5, spreadRadius: 1, offset: const Offset(0, -2))
              ]
            ),
            child: const Center(child: Icon(Icons.add_rounded, color: Color(0xFF1E293B), size: 36)),
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
              _buildBottomNavItem(Icons.folder_rounded, 'Projects', false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen()))),
              const SizedBox(width: 45), // Big Space for Glowing FAB
              _buildBottomNavItem(Icons.school_rounded, 'Tutorials', false),
              _buildBottomNavItem(Icons.person_rounded, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 HELPER: SOFT PASTEL GRID TOOL
  Widget _buildGridTool(String title, IconData icon, Color colorLight, Color colorDark, VoidCallback onTap, {bool isNew = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colorLight.withOpacity(0.85), colorDark.withOpacity(0.95)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: colorDark.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))]
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
                ],
              ),
            ),
          ),
          if (isNew)
            Positioned(
              top: -6, right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1.5), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4)]),
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
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
