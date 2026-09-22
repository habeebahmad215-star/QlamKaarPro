import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../models/design_models.dart'; // Aapke models ka path sahi hona chahiye

class VectorPdfService {
  
  // Safe Color Converter (Flutter Color to PDF Color)
  static PdfColor _toPdfColor(Color c) {
    return PdfColor(c.red / 255.0, c.green / 255.0, c.blue / 255.0, c.opacity);
  }

  // RTL Check for Urdu/Arabic
  static bool _isRTL(String text) {
    if (text.isEmpty) return false;
    int char = text.codeUnitAt(0);
    return (char >= 0x0590 && char <= 0x06FF);
  }

  // 100% Isolated Vector Export Function
  static Future<void> exportTrueVectorPdf({
    required BuildContext context,
    required List<DesignElement> elements,
    required double canvasWidth,
    required double canvasHeight,
    required Color backgroundColor,
  }) async {
    
    try {
      // 1. Initialize Document
      final pdf = pw.Document();

      // 2. Load Urdu Font safely (Fallback mechanism to prevent crash)
      pw.Font? urduFont;
      try {
        // Note: Make sure 'assets/fonts/JameelNoori.ttf' is in pubspec.yaml
        // Agar nahi hai, toh ye crash nahi karega, default font lega.
        final fontData = await rootBundle.load("assets/fonts/JameelNoori.ttf");
        if (fontData.lengthInBytes > 0) {
          urduFont = pw.Font.ttf(fontData);
        }
      } catch (e) {
        debugPrint("Vector PDF Font Warning: Custom font not found. Using default.");
      }

      // 3. Build Vector Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(canvasWidth, canvasHeight),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            
            // Background Color Box
            pw.Widget background = pw.Container(
              width: canvasWidth,
              height: canvasHeight,
              color: _toPdfColor(backgroundColor),
            );

            // Map all canvas elements to Vector PDF elements
            List<pw.Widget> pdfElements = elements.map((e) {
              
              pw.Widget widgetContent;

              if (e.isText) {
                // TRUE VECTOR TEXT (Ye kabhi nahi fatega)
                widgetContent = pw.Text(
                  e.content,
                  textDirection: _isRTL(e.content) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  textAlign: e.textAlign == TextAlign.center ? pw.TextAlign.center 
                             : (e.textAlign == TextAlign.right ? pw.TextAlign.right : pw.TextAlign.left),
                  style: pw.TextStyle(
                    font: urduFont,
                    fontSize: e.fontSize,
                    color: _toPdfColor(e.textColor),
                    letterSpacing: e.letterSpacing,
                    lineSpacing: e.lineHeight,
                  ),
                );
              } 
              else if (e.imageBytes != null) {
                // Raster Images inside PDF
                widgetContent = pw.Image(
                  pw.MemoryImage(e.imageBytes!), 
                  width: e.width, 
                  height: e.height,
                  fit: pw.BoxFit.fill
                );
              } 
              else {
                // Shapes / Borders mapped to Vector Containers
                widgetContent = pw.Container(
                  width: e.width,
                  height: e.height,
                  decoration: pw.BoxDecoration(
                    color: e.isShape ? _toPdfColor(e.elementColor) : null,
                    border: e.isBorder ? pw.Border.all(
                      color: _toPdfColor(e.elementColor), 
                      width: e.strokeWidth
                    ) : null,
                  )
                );
              }

              // Exact Positioning & Rotation
              return pw.Positioned(
                left: e.x,
                top: e.y,
                child: pw.Transform.rotateBox(
                  angle: -e.angle, // PDF package uses inverse angle sometimes
                  child: pw.SizedBox(
                    width: e.width,
                    child: widgetContent,
                  ),
                ),
              );
            }).toList();

            // Stack background and all elements
            return pw.Stack(
              children: [
                background,
                ...pdfElements,
              ],
            );
          },
        ),
      );

      // 4. Save and Share
      final Uint8List bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes, 
        filename: "QalamKaar_Vector_${DateTime.now().millisecondsSinceEpoch}.pdf"
      );

    } catch (e, stackTrace) {
      debugPrint("Vector PDF Error: $e\n$stackTrace");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vector Export Failed: $e'))
        );
      }
    }
  }
}
