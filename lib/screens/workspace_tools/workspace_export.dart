import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProExportEngine {
  static void showExportMenu({
    required BuildContext context,
    required GlobalKey canvasKey,
    required double currentCanvasW,
    required double currentCanvasH,
    required VoidCallback onExportStart,
    required VoidCallback onExportEnd,
  }) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent, 
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _buildGlassContainer(
          context,
          height: 380, // Height increased for new Pro options
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pro Print & Export', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  IconButton(icon: const Icon(Icons.close), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context))
                ]
              ),
              const Text('Banner aur Flex printing ke liye 4K/8K select karein', style: TextStyle(fontSize: 11, color: Colors.black54)),
              const Divider(color: Colors.black12),
              const SizedBox(height: 5),
              
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildExportOption(Icons.hd, 'Standard HD (1080p)', 'Social Media, WhatsApp status ke liye', Colors.blue, () {
                      Navigator.pop(context);
                      _renderAndSave(context, canvasKey, currentCanvasW, currentCanvasH, 1920.0, 'JPG', onExportStart, onExportEnd);
                    }),
                    const SizedBox(height: 8),
                    _buildExportOption(Icons.four_k, 'Ultra 4K Resolution', 'Posters aur A4 size printing ke liye', Colors.purple, () {
                      Navigator.pop(context);
                      _renderAndSave(context, canvasKey, currentCanvasW, currentCanvasH, 3840.0, 'JPG', onExportStart, onExportEnd);
                    }),
                    const SizedBox(height: 8),
                    _buildExportOption(Icons.photo_size_select_large, '8K Banner Quality', 'Bade Flex aur Banners ke liye (Heavy File)', Colors.red, () {
                      Navigator.pop(context);
                      _renderAndSave(context, canvasKey, currentCanvasW, currentCanvasH, 7680.0, 'JPG', onExportStart, onExportEnd);
                    }),
                    const SizedBox(height: 8),
                    _buildExportOption(Icons.picture_as_pdf, 'Save as PDF (Print Ready)', 'High-Quality Document format', Colors.orange, () {
                      Navigator.pop(context);
                      _renderAndSave(context, canvasKey, currentCanvasW, currentCanvasH, 3840.0, 'PDF', onExportStart, onExportEnd);
                    }),
                  ],
                ),
              )
            ]
          )
        );
      }
    );
  }

  // 🔥 THE MAGIC ENGINE: Dynamic Canvas Scaler 🔥
  static Future<void> _renderAndSave(
    BuildContext context, GlobalKey canvasKey, double logicalW, double logicalH, 
    double targetWidth, String format, VoidCallback onStart, VoidCallback onEnd
  ) async {
    onStart();
    
    // UI ko wait karna hoga taaki selection borders hide ho jayein
    await Future.delayed(const Duration(milliseconds: 400));
    
    try {
      RenderRepaintBoundary boundary = canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Ye Math formula screen size ko 4K/8K pixels mein convert karta hai
      double pixelRatio = targetWidth / logicalW;
      
      // Hardware Crash Limit Safeguard (Phone hang na ho isliye max limit 15 hai)
      if (pixelRatio > 15.0) pixelRatio = 15.0;

      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) throw Exception("Failed to generate engine render");
      
      Uint8List pngBytes = byteData.buffer.asUint8List();
      
      if (format == 'JPG' || format == 'PNG') {
        final result = await ImageGallerySaver.saveImage(
          pngBytes, 
          quality: 100, 
          name: "QalamKaarPro_${targetWidth.toInt()}p_${DateTime.now().millisecondsSinceEpoch}"
        );
        if (result != null && result['isSuccess'] == true) {
          _showSuccessDialog(context, 'Saved Successfully!', 'Aapka High-Resolution design gallery mein aa gaya hai.');
        }
      } else if (format == 'PDF') {
        final pdf = pw.Document();
        final imagePdf = pw.MemoryImage(pngBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(image.width.toDouble(), image.height.toDouble()), 
            margin: pw.EdgeInsets.zero, 
            build: (pw.Context context) { 
              return pw.Center(child: pw.Image(imagePdf)); 
            }
          )
        );
        Uint8List pdfBytes = await pdf.save();
        await Printing.sharePdf(
          bytes: pdfBytes, 
          filename: "QalamKaarPro_Print_${DateTime.now().millisecondsSinceEpoch}.pdf"
        );
      }
    } catch (e) {
      debugPrint('Export Engine Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hardware limit reached! Try exporting in a lower quality.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      onEnd();
    }
  }

  static Widget _buildGlassContainer(BuildContext context, {required Widget child, required double height}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: -5)]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildExportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: color, shape: BoxShape.circle), 
              child: Icon(icon, color: Colors.white, size: 18)
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54))
                ]
              )
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14)
          ]
        )
      )
    );
  }

  static void _showSuccessDialog(BuildContext context, String title, String message) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), 
              onPressed: () => Navigator.pop(context), 
              child: const Text('OK', style: TextStyle(color: Colors.white))
            )
          ]
        )
      )
    );
  }
}
