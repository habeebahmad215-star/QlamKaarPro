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
  
  // 🔥 Aapke upload kiye gaye 100% workable fonts
  final List<Map<String, String>> preloadedFonts = [
    {'name': 'JameelNoori', 'title': 'جمیل نوری نستعلیق', 'desc': 'Classic Standard Urdu Font'},
    {'name': 'AlviNastaleeq', 'title': 'علوی نستعلیق', 'desc': 'Beautiful Nasta\'liq Style'},
    {'name': 'Mehr', 'title': 'مہر نستعلیق', 'desc': 'Modern & Elegant Font'},
    {'name': 'BombayBlack', 'title': 'بمبئی بلیک', 'desc': 'Thick Header & Title Font'},
    {'name': 'AlMajeed', 'title': 'المجید قرآنی فونٹ', 'desc': 'Classic Arabic/Quranic Font'},
  ];

  List<String> importedFonts = [];
  String selectedFontName = 'JameelNoori'; 

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
          selectedFontName = fontName; 
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
      height: MediaQuery.of(context).size.height * 0.85,
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
              const Expanded(
                child: Text(
                  'Urdu Fonts (فونٹس)', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _importFont,
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text('Add Font', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 20),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text('Live Preview', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                const SizedBox(height: 10),
                Text(
                  'قلم کار پرو - فن خطاطی اور ڈیزائننگ', 
                  textAlign: TextAlign.center, 
                  textDirection: TextDirection.rtl, 
                  style: TextStyle(fontSize: 24, color: const Color(0xFF1E293B), fontFamily: selectedFontName), 
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Text('Pre-installed Premium Fonts', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 12, letterSpacing: 0.5)),
                ),
                
                ...preloadedFonts.map((font) {
                  bool isSelected = selectedFontName == font['name'];
                  return Card(
                    elevation: 0,
                    color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade200, width: isSelected ? 1.5 : 1.0), 
                      borderRadius: BorderRadius.circular(16)
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() { 
                          selectedFontName = font['name']!; 
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(font['name']!, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B), fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(font['desc']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                font['title']!, 
                                textAlign: TextAlign.right, 
                                textDirection: TextDirection.rtl, 
                                style: TextStyle(fontFamily: font['name'], fontSize: 24, color: Colors.black87), 
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, 
                              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300, 
                              size: 20
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                
                if (importedFonts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 8.0, left: 4.0),
                    child: Text('My Custom Fonts', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 12, letterSpacing: 0.5)),
                  ),
                  ...importedFonts.map((fName) {
                    bool isSelected = selectedFontName == fName;
                    return Card(
                      elevation: 0,
                      color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade200, width: isSelected ? 1.5 : 1.0), 
                        borderRadius: BorderRadius.circular(16)
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() { 
                            selectedFontName = fName; 
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fName, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B), fontSize: 14)),
                                    const Text('Imported TTF', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text('نمونہ تحریر', textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: fName, fontSize: 24, color: Colors.black87)),
                              const SizedBox(width: 12),
                              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
