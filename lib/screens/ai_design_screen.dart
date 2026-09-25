import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';

// ============================================================================
// 🔥 AAPKI API KEYS 🔥
// Ab Gemini aur HuggingFace ki keys ki zaroorat nahi! Dono 100% Free ho gaye.
// ============================================================================
const String REMOVE_BG_API_KEY = "ViZorV1xopiwHEdvEiERE2XN"; // Sirf BG Remover ke liye
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
  // REAL API INTEGRATIONS (100% FREE & SMART)
  // ==========================================
  
  // 1. Pollinations AI Image (Using FLUX Model for ChatGPT Prompts)
  Future<void> _generateAIImage() async {
    if (_promptController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _isGeneratingImage = true; _generatedImageBytes = null; });
    
    try {
      // Prompt ko safe banaya
      String safePrompt = Uri.encodeComponent(_promptController.text.trim());
      int randomSeed = DateTime.now().millisecondsSinceEpoch % 100000;
      
      // 🔥 FIX: Added model=flux ! Ye ChatGPT ke complex prompts ko exactly samajhta hai
      String imageUrl = 'https://image.pollinations.ai/prompt/$safePrompt?width=1024&height=1024&nologo=true&model=flux&seed=$randomSeed';

      final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 45)); 

      if (response.statusCode == 200) {
        setState(() { _generatedImageBytes = response.bodyBytes; });
        HapticFeedback.heavyImpact();
      } else {
        throw Exception('Server ne image generate nahi ki. Error Code: ${response.statusCode}');
      }
    } on SocketException {
      _showErrorSnackBar('Network Error: Internet connect nahi hai.');
    } on TimeoutException {
      _showErrorSnackBar('Server bohot busy hai (Timeout). Thodi der baad try karein.');
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
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
        request.fields['size'] = 'auto'; 
        request.files.add(await http.MultipartFile.fromPath('image_file', _selectedImageForBg!.path));
        
        var response = await request.send().timeout(const Duration(seconds: 30));
        
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
      } on SocketException {
         _showErrorSnackBar('Network Error: Internet connect nahi hai.');
      } on TimeoutException {
         _showErrorSnackBar('Internet slow hai ya server reply nahi kar raha (Timeout).');
      } catch (e) {
         _showErrorSnackBar('BG Error: ${e.toString().replaceAll('Exception: ', '')}');
      } finally {
        setState(() { _isRemovingBg = false; });
      }
    }
  }

  // 3. Pollinations Text AI (NO API KEY REQUIRED, REPLACED GEMINI)
  Future<void> _writeAIContent() async {
    if (_topicController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _isWritingContent = true; _generatedContent = ''; });
    
    try {
      // Smart prompt to force pure Urdu response
      String aiPrompt = "Write a beautiful, professional, and engaging text in pure Urdu language using Nastaliq script about: '${_topicController.text.trim()}'. The text should be ready to be used in a graphic design poster. Do not use English words. Keep it short and structured.";
      String safePrompt = Uri.encodeComponent(aiPrompt);
      
      // Direct GET request for text generation
      final response = await http.get(
        Uri.parse('https://text.pollinations.ai/$safePrompt')
      ).timeout(const Duration(seconds: 30)); 

      if (response.statusCode == 200) {
        String aiText = response.body.trim();
        if (aiText.isNotEmpty) {
           setState(() { _generatedContent = aiText; });
           HapticFeedback.heavyImpact();
        } else {
           throw Exception('AI ne koi text generate nahi kiya.');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } on SocketException {
      _showErrorSnackBar('Network Error: Server connect nahi ho raha.');
    } on TimeoutException {
      _showErrorSnackBar('API timeout! Internet check karein.');
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() { _isWritingContent = false; });
    }
  }

  // UI Helper for Errors
  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ));
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
                const Text('ChatGPT ka koi bhi English prompt yahan paste karein...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: _promptController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Type or Paste your detailed ChatGPT prompt here...', hintStyle: TextStyle(color: Colors.black26)),
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
                      backgroundColor: const Color(0xFF10B981), 
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
