import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../models/design_models.dart';

class VectorPdfService {
  
  static PdfColor _toPdfColor(Color c) {
    return PdfColor(c.red / 255.0, c.green / 255.0, c.blue / 255.0, c.opacity);
  }

  static bool _isRTL(String text) {
    if (text.isEmpty) return false;
    int char = text.codeUnitAt(0);
    return (char >= 0x0590 && char <= 0x06FF);
  }

  static Future<void> exportTrueVectorPdf({
    required BuildContext context,
    required List<DesignElement> elements,
    required double canvasWidth,
    required double canvasHeight,
    required Color backgroundColor,
  }) async {
    
    try {
      // ----- ATTEMPT 1: Try with Local Jameel Noori Font -----
      pw.Font? localFont;
      try {
        final fontData = await rootBundle.load("assets/jameel.ttf");
        localFont = pw.Font.ttf(fontData);
      } catch (e) {
        debugPrint("Local font load failed: $e");
      }

      Uint8List? pdfBytes;
      
      try {
        // Try to generate PDF. If Jameel Noori crashes the shaper, it throws here.
        pdfBytes = await _generatePdfBytes(
          elements, canvasWidth, canvasHeight, backgroundColor, localFont
        );
      } catch (e) {
        debugPrint("Attempt 1 Failed (No element crash with Jameel Noori): $e");
        pdfBytes = null; // Mark as failed
      }

      // ----- ATTEMPT 2: Fallback to Highly Optimized Noto Nastaliq -----
      // Agar pehla attempt fail hua, toh yeh automatically Google Fonts se safe Nastaliq uthayega
      if (pdfBytes == null) {
        debugPrint("Starting Attempt 2 with Safe Google Fonts Fallback...");
        pw.Font safeGoogleFont = await PdfGoogleFonts.notoNastaliqUrduRegular();
        
        pdfBytes = await _generatePdfBytes(
          elements, canvasWidth, canvasHeight, backgroundColor, safeGoogleFont
        );
      }

      // ----- SHARE PDF -----
      if (pdfBytes != null) {
        await Printing.sharePdf(
          bytes: pdfBytes, 
          filename: "QalamKaar_Vector_${DateTime.now().millisecondsSinceEpoch}.pdf"
        );
      } else {
        throw Exception("Both local and fallback rendering failed.");
      }

    } catch (e) {
      debugPrint("Vector PDF Final Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vector Export Failed: Please check internet connection for safe font download.'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  // Helper method: Yeh asal PDF banata hai
  static Future<Uint8List> _generatePdfBytes(
    List<DesignElement> elements, 
    double canvasWidth, 
    double canvasHeight, 
    Color backgroundColor, 
    pw.Font? primaryFont
  ) async {
    
    final pdf = pw.Document();
    
    // Fallback font English/Numbers aur spaces ke liye (Crash se bachane ke liye zaroori)
    final fallbackFont = pw.Font.helvetica(); 

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(canvasWidth, canvasHeight),
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(
            font: primaryFont ?? fallbackFont,
            fontFallback: [fallbackFont, pw.Font.times()],
          ),
        ),
        build: (pw.Context ctx) {
          
          pw.Widget background = pw.Container(
            width: canvasWidth,
            height: canvasHeight,
            color: _toPdfColor(backgroundColor),
          );

          List<pw.Widget> pdfElements = [];
          
          for (var e in elements) {
            if (e.isHidden) continue;
            
            pw.Widget widgetContent;

            if (e.isText && e.content.trim().isNotEmpty) {
              widgetContent = pw.Text(
                e.content,
                textDirection: _isRTL(e.content) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                textAlign: e.textAlign == TextAlign.center ? pw.TextAlign.center 
                           : (e.textAlign == TextAlign.right ? pw.TextAlign.right : pw.TextAlign.left),
                style: pw.TextStyle(
                  font: primaryFont ?? fallbackFont,
                  fontFallback: [fallbackFont], // Empty ya missing char par Helvetica chalega
                  fontSize: e.fontSize,
                  color: _toPdfColor(e.textColor),
                  letterSpacing: e.letterSpacing,
                  lineSpacing: e.lineHeight,
                ),
              );
            } 
            else if (e.imageBytes != null) {
              widgetContent = pw.Image(
                pw.MemoryImage(e.imageBytes!), 
                width: e.width, 
                height: e.height,
                fit: pw.BoxFit.fill
              );
            } 
            else if (e.isShape || e.isBorder) {
              widgetContent = pw.Container(
                width: e.width,
                height: e.height,
                decoration: pw.BoxDecoration(
                  color: e.isShape ? _toPdfColor(e.elementColor) : null,
                  border: e.isBorder ? pw.Border.all(
                    color: _toPdfColor(e.elementColor), 
                    width: e.strokeWidth > 0 ? e.strokeWidth : 1.0
                  ) : null,
                  borderRadius: e.cornerRadius > 0 ? pw.BorderRadius.circular(e.cornerRadius) : null,
                )
              );
            } else {
              widgetContent = pw.SizedBox(width: e.width, height: e.height);
            }

            pdfElements.add(
              pw.Positioned(
                left: e.x,
                top: e.y,
                child: pw.Transform.rotateBox(
                  angle: -e.angle, 
                  child: pw.SizedBox(
                    width: e.width,
                    child: widgetContent,
                  ),
                ),
              )
            );
          }

          return pw.Stack(
            children: [
              background,
              ...pdfElements,
            ],
          );
        },
      ),
    );

    // Agar local Jameel Noori isey crash karta hai, toh yeh error wapas bhejega aur Attempt 2 shuru hoga
    return await pdf.save(); 
  }
}
