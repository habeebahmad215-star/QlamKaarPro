import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';

// ============================================================================
// 🔥 AAPKI ASLI API KEYS YAHAN SET KAREIN 🔥
// ============================================================================
const String GEMINI_API_KEY = "AQ.Ab8RN6KR7Ko-mPJ6bW0qkojCJvZ91zd3RfeQE8cLo-KknbD2lA";
const String REMOVE_BG_API_KEY = "ViZorV1xopiwHEdvEiERE2XN";
const String HUGGING_FACE_API_KEY = "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";
// ============================================================================

class AiDesignScreen extends StatefulWidget {
  const AiDesignScreen({Key? key}) : super(key: key);

  @override
  State<AiDesignScreen> createState() => _AiDesignScreenState();
}

class _AiDesignScreenState extends State<AiDesignScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  // AI Image Generator Variables
  final TextEditingController _promptController = TextEditingController();
  bool _isGeneratingImage = false;
  Uint8List? _generatedImageBytes;

  // AI Background Remover Variables
  File? _selectedImageForBg;
  bool _isRemovingBg = false;
  Uint8List? _bgRemovedBytes;

  // AI Content Writer Variables
  final TextEditingController _topicController = TextEditingController();
  bool _isWritingContent = false;
  String _generatedContent = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  // ==========================================
  // REAL API INTEGRATIONS (WITH SMART ERROR HANDLING)
  // ==========================================
  
  // 1. Hugging Face Image Generation API
  Future<void> _generateAIImage() async {
    if (_promptController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _isGeneratingImage = true; _generatedImageBytes = null; });
    
    try {
      final response = await http.post(
        // Lighter and faster model for free API
        Uri.parse('https://api-inference.huggingface.co/models/runwayml/stable-diffusion-v1-5'),
        headers: {
          'Authorization': 'Bearer $HUGGING_FACE_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': _promptController.text,
          // Ye option API ko batata hai ki jab tak model load na ho, wait karo, error mat do
          'options': {'wait_for_model': true} 
        }),
      );

      if (response.statusCode == 200) {
        setState(() { _generatedImageBytes = response.bodyBytes; });
        HapticFeedback.heavyImpact();
      } else {
        // Asal error server se nikal kar dikhayega
        String errorMsg = 'Server Error ${response.statusCode}';
        try {
          var data = jsonDecode(response.body);
          if (data['error'] != null) errorMsg = data['error'].toString();
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fail: ${e.toString().replaceAll('Exception: ', '')}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      setState(() { _isGeneratingImage = false; });
    }
  }

  // 2. Remove.BG API
  Future<void> _pickAndRemoveBg() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() { 
        _selectedImageForBg = File(image.path); 
        _isRemovingBg = true; 
        _bgRemovedBytes = null; 
      });
      
      try {
        var request = http.MultipartRequest('POST', Uri.parse('https://api.remove.bg/v1.0/removebg'));
        request.headers['X-Api-Key'] = REMOVE_BG_API_KEY;
        request.files.add(await http.MultipartFile.fromPath('image_file', _selectedImageForBg!.path));
        
        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          setState(() { _bgRemovedBytes = responseData; });
          HapticFeedback.heavyImpact();
        } else {
          String err = 'Error ${response.statusCode}';
          var respString = await response.stream.bytesToString();
          try {
            var data = jsonDecode(respString);
            if (data['errors'] != null) err = data['errors'][0]['title'];
          } catch (_) {}
          throw Exception(err);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('BG Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() { _isRemovingBg = false; });
      }
    }
  }

  // 3. Google Gemini API (Text Generation)
  Future<void> _writeAIContent() async {
    if (_topicController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _isWritingContent = true; _generatedContent = ''; });
    
    try {
      // MASLA YAHAN FIX KIYA HAI: Direct URL ke andar ?key= lagakar bhej diya
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "Write a beautiful, professional, and engaging text in pure Urdu language about: '${_topicController.text}'. The text should be ready to be used in a graphic design poster. Do not use English words. Keep it structured."}
              ]
            }
          ]
        })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiText = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() { _generatedContent = aiText.trim(); });
        HapticFeedback.heavyImpact();
      } else {
        String errorMsg = 'Error ${response.statusCode}';
        try {
          var data = jsonDecode(response.body);
          if (data['error'] != null) errorMsg = data['error']['message'].toString();
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gemini Error: ${e.toString().replaceAll('Exception: ', '')}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() { _isWritingContent = false; });
    }
  }

  // Save Image Function
  Future<void> _saveImageToGallery(Uint8List bytes) async {
    final result = await ImageGallerySaver.saveImage(bytes, quality: 100, name: "QalamKaarAI_${DateTime.now().millisecondsSinceEpoch}");
    if (result != null && result['isSuccess'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Gallery successfully! ✅'), backgroundColor: Color(0xFF10B981)));
    }
  }

  // ==========================================
  // Ultra-Premium Glassmorphism Widget
  // ==========================================
  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.smart_toy_rounded, color: Color(0xFF8B5CF6), size: 24),
            SizedBox(width: 8),
            Text('AI Magic Tools', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'AI Image'),
                Tab(text: 'BG Remover'),
                Tab(text: 'AI Writer'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildAiImageTab(),
          _buildBgRemoverTab(),
          _buildAiWriterTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: AI Image Generator
  // ==========================================
  Widget _buildAiImageTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Describe Your Imagination', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                const Text('English ya Roman Urdu mein likhein...', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: _promptController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'E.g. A beautiful golden 3D Islamic logo with dark background...', hintStyle: TextStyle(color: Colors.black26)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5)
                    ),
                    onPressed: _isGeneratingImage ? null : _generateAIImage,
                    child: _isGeneratingImage 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Generate AI Image ✨', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ),
          
          if (_generatedImageBytes != null)
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.download_rounded, color: Color(0xFF8B5CF6)), onPressed: () => _saveImageToGallery(_generatedImageBytes!))
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      image: DecorationImage(
                        image: MemoryImage(_generatedImageBytes!), 
                        fit: BoxFit.cover
                      )
                    ),
                  ),
                ],
              )
            )
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: AI Background Remover
  // ==========================================
  Widget _buildBgRemoverTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Color(0xFFFDF2F8), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFEC4899), size: 40),
                ),
                const SizedBox(height: 15),
                const Text('Magic Eraser', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                const Text('Apni photo upload karein aur 1 click mein background hamesha ke liye hatayein.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 25),
                
                if (_selectedImageForBg == null)
                  InkWell(
                    onTap: _pickAndRemoveBg,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.5), width: 2, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.upload_file_rounded, color: Color(0xFFEC4899), size: 40),
                          SizedBox(height: 10),
                          Text('Upload Image', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
                        ],
                      ),
                    ),
                  )
                else if (_isRemovingBg)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: const [
                        CircularProgressIndicator(color: Color(0xFFEC4899)),
                        SizedBox(height: 15),
                        Text('Removing Background... ✨', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      ],
                    ),
                  )
                else if (_bgRemovedBytes != null)
                  Column(
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300, 
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: MemoryImage(_bgRemovedBytes!),
                            fit: BoxFit.contain
                          )
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () => setState((){ _selectedImageForBg = null; _bgRemovedBytes = null; }),
                              icon: const Icon(Icons.refresh_rounded, color: Colors.black87, size: 18),
                              label: const Text('Try Another', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            )
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                              onPressed: () => _saveImageToGallery(_bgRemovedBytes!),
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              label: const Text('Save HD PNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          ),
                        ],
                      )
                    ],
                  )
              ],
            )
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: AI Urdu Content Writer
  // ==========================================
  Widget _buildAiWriterTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Urdu Writer ✍️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                const Text('Aapko kis mauzu (topic) par likhna hai?', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: _topicController,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 20),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'مثال: یوم آزادی پر پوسٹ...', hintTextDirection: TextDirection.rtl, hintStyle: TextStyle(color: Colors.black26)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF10B981), // Emerald Green
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: const Color(0xFF10B981).withOpacity(0.5)
                    ),
                    onPressed: _isWritingContent ? null : _writeAIContent,
                    child: _isWritingContent 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Write Content (لکھیں)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ),
          
          if (_generatedContent.isNotEmpty)
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Generated Draft', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.copy_rounded, color: Color(0xFF10B981)), onPressed: () { 
                        Clipboard.setData(ClipboardData(text: _generatedContent));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text Copied!'))); 
                      })
                    ],
                  ),
                  const Divider(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      _generatedContent,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 18, height: 1.6, color: Colors.black87),
                    ),
                  ),
                ],
              )
            )
        ],
      ),
    );
  }
}
