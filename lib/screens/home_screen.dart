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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<ProjectModel> recentProjects = [];
  bool isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    
    _loadRecentProjects();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> projStrings = prefs.getStringList('qalamkaar_projects') ?? [];
    List<ProjectModel> loaded = projStrings.map((s) => ProjectModel.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    loaded.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    setState(() {
      recentProjects = loaded.take(5).toList(); // Sirf top 5 recent designs dikhayega
      isLoading = false;
    });
  }

  void _showNewDesignModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162A2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Design', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildInputBox('WIDTH', '1080')),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.lock_outline, color: Color(0xFFD4AF37))),
                Expanded(child: _buildInputBox('HEIGHT', '1080')),
                const SizedBox(width: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), decoration: BoxDecoration(color: const Color(0xFF0B171A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Text('px', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)))
              ],
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)]),
                boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProWorkspaceScreen())).then((_) => _loadRecentProjects());
                },
                child: const Text('Create Design', style: TextStyle(color: Color(0xFF022C22), fontSize: 18, fontWeight: FontWeight.bold)),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: val, hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: const Color(0xFF0B171A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4AF37))))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B171A), // Dark Teal/Slate background
      body: Stack(
        children: [
          // Subtle Islamic/Geometric Style Pattern Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                itemBuilder: (context, index) => const Icon(Icons.star_border, color: Colors.white, size: 40),
              ),
            ),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🌟 1. ROYAL HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 3D Emblem
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 5)),
                                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -2))
                                ]
                              ),
                              child: const Icon(Icons.draw, size: 35, color: Color(0xFF022C22)),
                            ),
                            // Greeting Text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text('خوش آمدید', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 32, color: Color(0xFFD4AF37), height: 1.2)),
                                Text('آج کیا تخلیق کریں گے؟', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 20, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),

                        // 🌟 2. THE HERO BUTTON (Create New Design)
                        GestureDetector(
                          onTap: () => _showNewDesignModal(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFAA7C11)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10)),
                              ],
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                                ),
                                const SizedBox(width: 20),
                                const Text('نیا ڈیزائن شروع کریں', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 35, color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 🌟 3. RECENT DESIGNS (HORIZONTAL SCROLL)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen())).then((_) => _loadRecentProjects()),
                              child: const Text('سب دیکھیں', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 20, color: Color(0xFFD4AF37))),
                            ),
                            const Text('حالیہ ڈیزائن', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 28, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        SizedBox(
                          height: 180,
                          child: isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                            : recentProjects.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: const Color(0xFF162A2C), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.folder_open, size: 50, color: Colors.white30),
                                      SizedBox(height: 10),
                                      Text('ابھی کوئی ڈیزائن نہیں ہے', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 20, color: Colors.white54))
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: recentProjects.length,
                                  itemBuilder: (context, index) {
                                    var proj = recentProjects[index];
                                    return GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProWorkspaceScreen(project: proj))).then((_) => _loadRecentProjects()),
                                      child: Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(right: 15),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF162A2C),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white12),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                width: double.infinity,
                                                decoration: const BoxDecoration(color: Color(0xFF0B171A), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                                child: const Icon(Icons.design_services, size: 40, color: Color(0xFFD4AF37)),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(proj.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 4),
                                                  Text(DateTime.fromMillisecondsSinceEpoch(proj.lastModified).toString().substring(0,10), style: const TextStyle(fontSize: 10, color: Colors.white54)),
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

                        // 🌟 4. PRO TOOLS SECTION
                        const Align(alignment: Alignment.centerRight, child: Text('پرو ٹولز', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 28, color: Colors.white))),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: _buildProToolCard('ٹیمپلیٹس', 'Templates', Icons.cloud_download, isPro: true)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildProToolCard('رہنمائی', 'Tutorials', Icons.play_circle_fill, isPro: false)),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProToolCard(String urduTitle, String engTitle, IconData icon, {bool isPro = false}) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$engTitle Tool jald aa raha hai! (Coming Soon)', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF022C22)));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF162A2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPro ? const Color(0xFFD4AF37).withOpacity(0.5) : Colors.white12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isPro ? const Color(0xFFD4AF37) : Colors.white70, size: 35),
                const SizedBox(height: 12),
                Text(urduTitle, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 26, color: Colors.white, height: 1.0)),
                Text(engTitle, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ],
            ),
            if (isPro)
              Positioned(
                top: -10, right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 5)]),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 10, color: Color(0xFF0B171A)),
                      SizedBox(width: 3),
                      Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0B171A))),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
