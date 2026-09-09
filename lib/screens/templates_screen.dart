import 'package:flutter/material.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Templates', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded, 
                  size: 80, 
                  color: Color(0xFF8B5CF6)
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Premium Templates\nComing Soon!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, 
                  color: Color(0xFF1E293B)
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'بہت جلد آپ کو یہاں سینکڑوں خوبصورت اور پروفیشنل ٹیمپلیٹس ملیں گے تاکہ آپ ایک کلک میں ڈیزائن بنا سکیں۔',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 18, 
                  color: Colors.grey, 
                  fontFamily: 'JameelNoori',
                  height: 1.5
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)
                  )
                ),
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                label: const Text('Back to Home (واپس جائیں)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              )
            ],
          ),
        ),
      ),
    );
  }
}
