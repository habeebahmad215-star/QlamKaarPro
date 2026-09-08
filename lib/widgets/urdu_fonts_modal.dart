import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class UrduFontsManagerModal extends StatefulWidget {
  const UrduFontsManagerModal({Key? key}) : super(key: key);

  @override
  State<UrduFontsManagerModal> createState() => _UrduFontsManagerModalState();
}

class _UrduFontsManagerModalState extends State<UrduFontsManagerModal> {
  final List<Map<String, String>> preloadedFonts = [
    {'name': 'JameelNoori', 'title': 'جمیل نوری نستعلیق', 'desc': 'Classic Standard Urdu Font'},
    {'name': 'Amiri', 'title': 'امیری عربی فونٹ', 'desc': 'Clean Arabic & Urdu Style'},
    {'name': 'Bombay', 'title': 'بمبئی بولڈ', 'desc': 'Thick Header & Title Font'},
    {'name': 'Mehr', 'title': 'مہر نستعلیق', 'desc': 'Modern & Elegant Font'},
  ];

  List<String> importedFonts = [];

  Future<void> _importFont() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
      );
      if (result != null && result.files.single.path != null) {
        String fontPath = result.files.single.path!;
        String fontName = result.files.single.name.replaceAll('.ttf', '').replaceAll('.otf', '');
        
        var fontLoader = FontLoader(fontName);
        fontLoader.addFont(Future.value(ByteData.view(File(fontPath).readAsBytesSync().buffer)));
        await fontLoader.load();
        
        setState(() {
          if (!importedFonts.contains(fontName)) {
            importedFonts.add(fontName);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Font "$fontName" successfully imported! 🎉', style: const TextStyle(fontFamily: 'JameelNoori'))),
          );
        }
      }
    } catch (e) {
      debugPrint("Font Import Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Urdu Fonts Library (اردو فونٹس)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _importFont,
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text('Add Font (.ttf)', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text('Preview: "قلم کار پرو - فن خطاطی اور اردو ڈیزائننگ"', textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Text('Pre-installed Professional Fonts:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
                ),
                ...preloadedFonts.map((font) => Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(font['title']!, style: TextStyle(fontFamily: font['name'], fontSize: 22, color: Colors.black87)),
                    subtitle: Text('${font['name']} • ${font['desc']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    trailing: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                  ),
                )),
                if (importedFonts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text('Custom Imported Fonts:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
                  ),
                  ...importedFonts.map((fName) => Card(
                    elevation: 0,
                    color: const Color(0xFFF3E8FF),
                    shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF8B5CF6)), borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(fName, style: TextStyle(fontFamily: fName, fontSize: 22, color: const Color(0xFF8B5CF6))),
                      subtitle: const Text('User Imported TTF', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      trailing: const Icon(Icons.star, color: Color(0xFF8B5CF6), size: 18),
                    ),
                  )),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
