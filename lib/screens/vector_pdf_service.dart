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
      final pdf = pw.Document();
      
      pw.Font? primaryFont;
      pw.Font? safeFallbackFont;

      // 1. CORRECT PATH: pubspec.yaml ke mutabiq exact path 'assets/jameel.ttf'
      try {
        final fontData = await rootBundle.load("assets/jameel.ttf");
        if (fontData.lengthInBytes > 0) {
          primaryFont = pw.Font.ttf(fontData);
        }
      } catch (e) {
        debugPrint("Local font load nahi hua. Error: $e");
      }

      // 2. Auto-Fallback (Taaki kabhi box na bane)
      try {
        safeFallbackFont = await PdfGoogleFonts.notoNastaliqUrduRegular();
      } catch (e) {
        debugPrint("Fallback font bhi load nahi hua.");
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(canvasWidth, canvasHeight),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            
            pw.Widget background = pw.Container(
              width: canvasWidth,
              height: canvasHeight,
              color: _toPdfColor(backgroundColor),
            );

            List<pw.Widget> pdfElements = elements.map((e) {
              pw.Widget widgetContent;

              if (e.isText) {
                widgetContent = pw.Text(
                  e.content,
                  textDirection: _isRTL(e.content) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  textAlign: e.textAlign == TextAlign.center ? pw.TextAlign.center 
                             : (e.textAlign == TextAlign.right ? pw.TextAlign.right : pw.TextAlign.left),
                  style: pw.TextStyle(
                    font: primaryFont ?? safeFallbackFont,
                    fontFallback: safeFallbackFont != null ? [safeFallbackFont] : [],
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
              else {
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

              return pw.Positioned(
                left: e.x,
                top: e.y,
                child: pw.Transform.rotateBox(
                  angle: -e.angle, 
                  child: pw.SizedBox(
                    width: e.width,
                    child: widgetContent,
                  ),
                ),
              );
            }).toList();

            return pw.Stack(
              children: [
                background,
                ...pdfElements,
              ],
            );
          },
        ),
      );

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
