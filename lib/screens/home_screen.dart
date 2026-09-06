import 'package:flutter/material.dart';
import 'pro_workspace_screen.dart';
import 'my_folder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showNewDesignModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Design', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildInputBox('WIDTH', '1080')),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.lock_outline, color: Colors.grey)),
                Expanded(child: _buildInputBox('HEIGHT', '1080')),
                const SizedBox(width: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: const Text('px', style: TextStyle(fontWeight: FontWeight.bold)))
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProWorkspaceScreen()));
                },
                child: const Text('Create Design', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, String val) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(height: 5), TextField(textAlign: TextAlign.center, decoration: InputDecoration(hintText: val, filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35))),
              child: Column(
                children: [
                  Container(padding: const EdgeInsets.all(18), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))]), child: const Icon(Icons.draw, size: 55, color: Color(0xFF6D28D9))),
                  const SizedBox(height: 15),
                  const Text('قلمکار پرو', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 55, color: Colors.white, height: 1.2)),
                  const Text('Professional Urdu Designer', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2.0, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
                children: [
                  _buildMenuCard(context, 'نیا ڈیزائن', 'New Design', Icons.add_to_photos, const Color(0xFF8B5CF6), isNewDesign: true),
                  _buildMenuCard(context, 'آن لائن ڈیزائن', 'Templates', Icons.cloud_download, const Color(0xFF10B981), isNewDesign: false),
                  _buildMenuCard(context, 'میرے ڈیزائن', 'My Folder', Icons.folder_special, const Color(0xFFF59E0B), isMyFolder: true),
                  _buildMenuCard(context, 'رہنمائی', 'Tutorials', Icons.play_circle_fill, const Color(0xFFEF4444), isNewDesign: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String urduText, String engText, IconData icon, Color color, {bool isNewDesign = false, bool isMyFolder = false}) {
    return InkWell(
      onTap: () {
        if (isNewDesign) _showNewDesignModal(context);
        else if (isMyFolder) Navigator.push(context, MaterialPageRoute(builder: (context) => const MyFolderScreen()));
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$engText jald aa raha hai!')));
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 35)),
            const SizedBox(height: 12),
            Text(urduText, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 28, color: Colors.black87, height: 1.0)),
            Text(engText, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}
