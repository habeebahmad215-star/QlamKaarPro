import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:typed_data';

class TriangleClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { Path path = Path(); path.moveTo(size.width/2, 0); path.lineTo(size.width, size.height); path.lineTo(0, size.height); path.close(); return path; }
  @override bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HexagonClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { Path path = Path(); path.moveTo(size.width/2, 0); path.lineTo(size.width, size.height * 0.25); path.lineTo(size.width, size.height * 0.75); path.lineTo(size.width/2, size.height); path.lineTo(0, size.height * 0.75); path.lineTo(0, size.height * 0.25); path.close(); return path; }
  @override bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class StarClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { Path path = Path(); double halfWidth = size.width / 2; double halfHeight = size.height / 2; double radius = halfWidth; double innerRadius = radius / 2.5; double step = pi / 5; path.moveTo(halfWidth, 0); for (int i = 0; i < 10; i++) { double r = (i % 2 == 0) ? radius : innerRadius; double a = -pi/2 + step * i; path.lineTo(halfWidth + r * cos(a), halfHeight + r * sin(a)); } path.close(); return path; }
  @override bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class TextureTextWrapper extends StatefulWidget {
  final Uint8List? textureBytes;
  final Widget child;
  const TextureTextWrapper({Key? key, this.textureBytes, required this.child}) : super(key: key);
  @override State<TextureTextWrapper> createState() => _TextureTextWrapperState();
}

class _TextureTextWrapperState extends State<TextureTextWrapper> {
  ui.Image? _image;
  @override void initState() { super.initState(); _loadImage(); }
  @override void didUpdateWidget(TextureTextWrapper oldWidget) { super.didUpdateWidget(oldWidget); if (widget.textureBytes != oldWidget.textureBytes) _loadImage(); }
  Future<void> _loadImage() async { if (widget.textureBytes == null) { if (mounted) setState(() => _image = null); return; } final codec = await ui.instantiateImageCodec(widget.textureBytes!); final frame = await codec.getNextFrame(); if (mounted) setState(() => _image = frame.image); }
  @override Widget build(BuildContext context) { if (_image == null || widget.textureBytes == null) return widget.child; return ShaderMask(blendMode: BlendMode.srcATop, shaderCallback: (bounds) { final matrix = Matrix4.identity(); matrix.scale(bounds.width / _image!.width, bounds.height / _image!.height, 1.0); return ImageShader(_image!, TileMode.clamp, TileMode.clamp, matrix.storage); }, child: widget.child); }
}


// 🔥 YAHAN HAI NAYA SMART TEXT CURVE ENGINE 🔥
class CurvedTextWidget extends StatelessWidget {
  final String text; 
  final double radius; 
  final TextStyle style; 
  final double letterSpacing;
  
  const CurvedTextWidget({
    Key? key, 
    required this.text, 
    required this.radius, 
    required this.style, 
    this.letterSpacing = 0.0
  }) : super(key: key);

  @override 
  Widget build(BuildContext context) {
    if (radius == 0 || text.trim().isEmpty) {
      return Text(text, style: style.copyWith(letterSpacing: letterSpacing), textAlign: TextAlign.center);
    }

    // 1. Smart Language Detection
    bool isUrdu = text.contains(RegExp(r'[\u0600-\u06FF]'));
    
    // Urdu ko Words me todenge (Nastaliq safe rakhne ke liye), English ko Characters me (Smooth Curve ke liye)
    List<String> items = isUrdu ? text.split(' ') : text.split('');
    items = items.where((s) => s.isNotEmpty).toList(); 

    if (items.isEmpty) return const SizedBox();

    bool isBottomCurve = radius < 0;
    double safeRadius = radius.abs() < 50 ? 50 : radius.abs();

    // Space ki chaurai (width) nikalna taake words ke beech perfect gap rahe
    final spaceTp = TextPainter(text: TextSpan(text: ' ', style: style), textDirection: TextDirection.ltr)..layout();
    double spaceWidth = spaceTp.width > 0 ? spaceTp.width : (style.fontSize ?? 20) * 0.3;

    // 2. Har item ki exact width measure karna
    List<double> itemAngles = [];
    double totalArcAngle = 0;

    for (String item in items) {
      final tp = TextPainter(
        text: TextSpan(text: item, style: style),
        textDirection: TextDirection.ltr, 
      )..layout();
      
      double wAngle = tp.width / safeRadius;
      itemAngles.add(wAngle);
      
      double spacing = isUrdu ? (spaceWidth + letterSpacing) : letterSpacing;
      totalArcAngle += wAngle + (spacing / safeRadius);
    }

    // Aakhri extra space hatana
    double lastSpacing = (isUrdu ? spaceWidth + letterSpacing : letterSpacing) / safeRadius;
    totalArcAngle -= lastSpacing;

    // 3. Direction & Math Logic (Right-to-Left vs Left-to-Right)
    double startAngle;
    double directionMultiplier;

    if (isUrdu) {
      startAngle = totalArcAngle / 2; // Urdu: Start from Right (+ angle)
      directionMultiplier = -1;       // Move towards Left
    } else {
      startAngle = -totalArcAngle / 2; // English: Start from Left (- angle)
      directionMultiplier = 1;         // Move towards Right
    }

    // Agar Bottom Curve (U shape) hai toh direction reverse hogi
    if (isBottomCurve) {
      directionMultiplier *= -1;
      startAngle *= -1;
    }

    double currentAngle = startAngle;
    List<Widget> paintedItems = [];

    // 4. Transform and Paint
    for (int i = 0; i < items.length; i++) {
      double wAngle = itemAngles[i];
      double spacingAngle = (isUrdu ? spaceWidth + letterSpacing : letterSpacing) / safeRadius;

      // Is word/char ka center angle
      double centerAngle = currentAngle + (directionMultiplier * (wAngle / 2));

      paintedItems.add(
        Transform(
          transform: Matrix4.identity()
            ..translate(
              safeRadius * sin(centerAngle),
              isBottomCurve ? safeRadius * cos(centerAngle) : -safeRadius * cos(centerAngle),
            )
            ..rotateZ(isBottomCurve ? -centerAngle : centerAngle),
          alignment: Alignment.center,
          child: Text(items[i], style: style),
        )
      );

      currentAngle += directionMultiplier * (wAngle + spacingAngle);
    }

    return SizedBox(
      width: safeRadius * 2.5, 
      height: safeRadius * 2.5, 
      child: Stack(
        alignment: Alignment.center, 
        clipBehavior: Clip.none,
        children: paintedItems
      )
    );
  }
}

// 櫨 INPAGE / CANVA STYLE PROFESSIONAL TABLE 櫨
class CustomTableWidget extends StatelessWidget {
  final List<List<String>> tableData;
  final double width;
  final double height;
  final String fontFamily;
  final Color textColor;
  final Color borderColor;
  final bool hasBorder;

  const CustomTableWidget({
    Key? key,
    required this.tableData,
    required this.width,
    required this.height,
    required this.fontFamily,
    required this.textColor,
    required this.borderColor,
    required this.hasBorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tableData.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.fill,
        child: Directionality(
          textDirection: TextDirection.rtl, 
          child: Container(
            width: max(width, 400.0), 
            child: Table(
              border: hasBorder ? TableBorder.all(color: borderColor, width: 2.0) : null,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: tableData.asMap().entries.map((rowEntry) {
                bool isHeader = rowEntry.key == 0;
                return TableRow(
                  decoration: isHeader ? BoxDecoration(color: borderColor.withOpacity(0.15)) : null,
                  children: rowEntry.value.map((cellText) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                      child: Text(
                        cellText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          color: textColor,
                          fontSize: isHeader ? 26 : 22, 
                          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
