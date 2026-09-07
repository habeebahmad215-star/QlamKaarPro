import 'package:flutter/material.dart';
import 'dart:async';

class AiDesignScreen extends StatefulWidget {
  const AiDesignScreen({Key? key}) : super(key: key);

  @override
  State<AiDesignScreen> createState() => _AiDesignScreenState();
}

class _AiDesignScreenState extends State<AiDesignScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  late AnimationController _animController;

  final List<String> _suggestions = [
    "جمعہ مبارک پوسٹ",
    "اسلامی اقوال (Islamic Quote)",
    "YouTube Thumbnail",
    "Business Logo",
    "Wedding Invitation",
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _startGeneration() async {
    if (_promptController.text.trim().isEmpty) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isGenerating = true;
    });

    // 3 seconds ki fake loading animation
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
      _showBetaDialog();
    }
  }

  void _showBetaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('AI is Learning!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text(
              'یہ فیچر ابھی بیٹا (Beta) ٹیسٹنگ میں ہے۔ بہت جلد آپ اپنے الفاظ لکھ کر مکمل ڈیزائن خودکار طریقے سے بنا سکیں گے!',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'JameelNoori', height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1121), // Deep Dark Blue/Black Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.smart_toy_rounded, color: Color(0xFFD946EF), size: 24),
            SizedBox(width: 8),
            Text('AI Magic ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glow Effects
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6366F1).withOpacity(0.15), filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80)),
            ),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFD946EF).withOpacity(0.15), filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80)),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('آج آپ کیا بنانا چاہتے ہیں؟', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'JameelNoori', fontSize: 36, color: Colors.white, height: 1.2)),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('Describe your design in words, and AI will create it.', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 40),
                  
                  // Glowing Text Input Area
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 20, spreadRadius: -5)
                      ]
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _promptController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: "مثال: ایک خوبصورت جمعہ مبارک پوسٹ جس میں سبز رنگ کی مسجد ہو...",
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: TextStyle(color: Colors.white30, fontFamily: 'JameelNoori', fontSize: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Suggestions
                  const Text('Suggestions:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _suggestions.map((s) => InkWell(
                      onTap: () {
                        _promptController.text = s;
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(s, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontFamily: 'JameelNoori', fontSize: 16)),
                      ),
                    )).toList(),
                  ),
                  
                  const Spacer(),
                  
                  // Generate Button
                  _isGenerating 
                  ? Center(
                      child: Column(
                        children: [
                          RotationTransition(
                            turns: _animController,
                            child: Container(
                              width: 60, height: 60,
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [Color(0xFF6366F1), Color(0xFFD946EF), Colors.transparent])),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0B1121))),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('AI is crafting your design...', style: TextStyle(color: Color(0xFFD946EF), fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ],
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFD946EF)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFD946EF).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))
                        ]
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _startGeneration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.auto_awesome, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Generate Magic', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
