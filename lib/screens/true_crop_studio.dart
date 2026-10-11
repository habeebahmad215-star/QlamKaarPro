import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class TrueCropStudioModal extends StatefulWidget {
  final Uint8List imageBytes;
  const TrueCropStudioModal({Key? key, required this.imageBytes}) : super(key: key);

  @override
  State<TrueCropStudioModal> createState() => _TrueCropStudioModalState();
}

class _TrueCropStudioModalState extends State<TrueCropStudioModal> {
  final GlobalKey _cropKey = GlobalKey();
  bool _isCropping = false;

  Future<void> _performCrop() async {
    setState(() => _isCropping = true);
    try {
      RenderRepaintBoundary boundary = _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // HD Crop Quality
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Navigator.pop(context, byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint("Crop Error: $e");
      setState(() => _isCropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenW = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('True Image Trim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (_isCropping)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF8B5CF6), strokeWidth: 2)))),
          if (!_isCropping)
            TextButton.icon(
              onPressed: _performCrop,
              icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              label: const Text('CUT (کٹنگ)', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontFamily: 'JameelNoori')),
            )
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('تصویر کو انگلی سے سیٹ کریں اور کٹنگ کریں', style: TextStyle(color: Colors.white70, fontFamily: 'JameelNoori', fontSize: 18)),
          ),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Asli Image Jise Pan/Zoom kiya jayega
                  RepaintBoundary(
                    key: _cropKey,
                    child: Container(
                      width: screenW * 0.9,
                      height: screenW * 0.9, // 1:1 Perfect Square Box
                      color: Colors.transparent,
                      child: ClipRect(
                        child: InteractiveViewer(
                          panEnabled: true,
                          scaleEnabled: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  // Upar ka Border (Dikhane ke liye)
                  IgnorePointer(
                    child: Container(
                      width: screenW * 0.9,
                      height: screenW * 0.9,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF8B5CF6), width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), spreadRadius: 4000)] // Bahar andhera
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Pinch to Zoom, Drag to Move', style: TextStyle(color: Colors.white54, fontSize: 12)),
          )
        ],
      ),
    );
  }
}
