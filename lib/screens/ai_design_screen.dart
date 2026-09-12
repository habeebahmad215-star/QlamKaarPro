import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  bool _imageGenerated = false;

  // AI Background Remover Variables
  File? _selectedImageForBg;
  bool _isRemovingBg = false;
  bool _bgRemoved = false;

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
  // Simulated AI Functions (Connect APIs Later)
  // ==========================================
  
  Future<void> _generateAIImage() async {
    if (_promptController.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _isGeneratingImage = true; _imageGenerated = false; });
    
    // Simulate API Call delay
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() { _isGeneratingImage = false; _imageGenerated = true; });
    HapticFeedback.heavyImpact();
  }

  Future<void> _pickAndRemoveBg() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() { 
        _selectedImageForBg = File(image.path); 
        _isRemovingBg = true; 
        _bgRemoved = false; 
      });
      
      // Simulate Background Removal API delay
      await Future.delayed(const Duration(seconds: 3));
      
      setState(() { _isRemovingBg = false; _bgRemoved = true; });
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _writeAIContent() async {
    if (_topicController.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _isWritingContent = true; _generatedContent = ''; });
    
    // Simulate OpenAI Text Generation API delay
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() { 
      _isWritingContent = false; 
      _generatedContent = 'یہ ایک مصنوعی ذہانت (AI) سے تیار کردہ نمونہ تحریر ہے۔ آپ کا موضوع تھا: "${_topicController.text}"۔\n\nقلمکار پرو کے ذریعے آپ اپنے خیالات کو باآسانی خوبصورت الفاظ اور ڈیزائن میں تبدیل کر سکتے ہیں۔ مستقبل میں یہاں اصل تحریر نظر آئے گی۔'; 
    });
    HapticFeedback.heavyImpact();
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
          
          if (_imageGenerated)
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.download_rounded, color: Color(0xFF8B5CF6)), onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image Saved!'))); })
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
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop'), // Placeholder beautiful image
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
                  decoration: BoxDecoration(color: const Color(0xFFFDF2F8), shape: BoxShape.circle),
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
                        Text('AI is working its magic... ✨', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      ],
                    ),
                  )
                else if (_bgRemoved)
                  Column(
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200, // Typically PNG transparent background check pattern goes here
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(_selectedImageForBg!),
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
                              onPressed: () => setState((){ _selectedImageForBg = null; _bgRemoved = false; }),
                              icon: const Icon(Icons.refresh_rounded, color: Colors.black87, size: 18),
                              label: const Text('Try Again', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            )
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transparent Image Saved!'))); },
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              label: const Text('Save HD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'مثال: یوم آزادی پر تقریر...', hintTextDirection: TextDirection.rtl, hintStyle: TextStyle(color: Colors.black26)),
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
