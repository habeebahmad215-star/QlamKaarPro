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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Design', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: const Text('px', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)))
              ],
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                boxShadow: [BoxShadow(color: const Color(0xFF764BA2).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: val, hintStyle: const TextStyle(color: Colors.black38), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8B5CF6))))),
      ],
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh feature jald aa raha hai!', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF8B5CF6)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Light Premium Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: Color(0xFF1E293B)), onPressed: _showComingSoon),
        // Title thoda left align kar diya kyunki right side se Pro badge hat gaya hai
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note, color: Color(0xFFD4AF37), size: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('QalamkarPro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 0.5)),
                Text('URDU DESIGNER APP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.5)),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HERO BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  image: const DecorationImage(
                    image: AssetImage('assets/transparent_pattern.png'), // Background texture
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  )
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Design\nYour Imagination\nin Urdu', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 8),
                    const Text('Beautiful Text • Stunning Graphics\nEndless Possibilities', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0
                      ),
                      onPressed: () => _showNewDesignModal(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Start Designing', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_forward, size: 16)
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. 12-ITEM GRID TOOLS
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
                children: [
                  _buildGridTool('New Design', Icons.add_circle, const Color(0xFF3B82F6), const Color(0xFF2563EB), () => _showNewDesignModal(context)),
                  _buildGridTool('Templates', Icons.image, const Color(0xFF8B5CF6), const Color(0xFF7C3AED), _showComingSoon),
                  _buildGridTool('Text Editor', Icons.title, const Color(0xFF10B981), const Color(0xFF059669), _showComingSoon),
                  _buildGridTool('Urdu Fonts', Icons.language, const Color(0xFFEC4899), const Color(0xFFDB2777), _showComingSoon),
                  
                  _buildGridTool('Elements', Icons.category, const Color(0xFFF59E0B), const Color(0xFFD97706), _showComingSoon),
                  _buildGridTool('Images', Icons.photo_library, const Color(0xFF14B8A6), const Color(0xFF0D9488), _showComingSoon),
                  _buildGridTool('Backgrounds', Icons.wallpaper, const Color(0xFFF97316), const Color(0xFFEA580C), _showComingSoon),
                  _buildGridTool('Stickers', Icons.emoji_emotions, const Color(0xFFD946EF), const Color(0xFFC026D3), _showComingSoon),
                  
                  _buildGridTool('Layers', Icons.layers, const Color(0xFF06B6D4), const Color(0xFF0891B2), _showComingSoon),
                  _buildGridTool('Tools', Icons.build, const Color(0xFFE11D48), const Color(0xFFBE123C), _showComingSoon),
                  _buildGridTool('AI Design', Icons.smart_toy, const Color(0xFF6366F1), const Color(0xFF4F46E5), _showComingSoon, isNew: true),
                  _buildGridTool('Pro Effects', Icons.auto_fix_high, const Color(0xFF22C55E), const Color(0xFF16A34A), _showComingSoon),
                ],
              ),

              const SizedBox(height: 25), // Pro banner yahan se hata diya gaya hai

              // 3. RECENT PROJECTS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.history, size: 18, color: Color(0xFF1E293B)),
                      SizedBox(width: 8),
                      Text('Recent Projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())).then((_) => _loadRecentProjects()),
                    child: const Text('See All ->', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                  )
                ],
              ),
              const SizedBox(height: 12),
              
              SizedBox(
                height: 160,
                child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                  : recentProjects.isEmpty
                    ? Center(child: Text('No recent projects yet.', style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: recentProjects.length,
                        itemBuilder: (context, index) {
                          var proj = recentProjects[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProWorkspaceScreen(project: proj))).then((_) => _loadRecentProjects()),
                            child: Container(
                              width: 130,
                              margin: const EdgeInsets.only(right: 12, bottom: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
                                      child: const Icon(Icons.design_services, size: 40, color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(proj.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text('Edited: ${DateTime.fromMillisecondsSinceEpoch(proj.lastModified).toString().substring(0,10)}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      
      // 4. BOTTOM NAVIGATION BAR (FAB STYLE)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 65, width: 65,
        margin: const EdgeInsets.only(top: 30),
        child: FloatingActionButton(
          onPressed: () => _showNewDesignModal(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)]),
              boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: const Center(child: Icon(Icons.add, color: Color(0xFF1E293B), size: 32)),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Icons.home_filled, 'Home', true),
              _buildBottomNavItem(Icons.folder, 'Projects', false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen()))),
              const SizedBox(width: 40), // Space for FAB
              _buildBottomNavItem(Icons.school, 'Tutorials', false),
              _buildBottomNavItem(Icons.person, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridTool(String title, IconData icon, Color color1, Color color2, VoidCallback onTap, {bool isNew = false}) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color1, color2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: color2.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 6),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          if (isNew)
            Positioned(
              top: -5, right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1)),
                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
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
          Icon(icon, color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
