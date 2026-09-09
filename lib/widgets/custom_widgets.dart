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

class CurvedTextWidget extends StatelessWidget {
  final String text; final double radius; final TextStyle style; final double letterSpacing;
  const CurvedTextWidget({Key? key, required this.text, required this.radius, required this.style, this.letterSpacing = 0.0}) : super(key: key);
  @override Widget build(BuildContext context) {
    if (radius == 0 || text.isEmpty) return Text(text, style: style.copyWith(letterSpacing: letterSpacing), textAlign: TextAlign.center);
    List<String> words = text.split(' ').reversed.toList(); 
    double totalAngle = words.length * (0.3 + (letterSpacing * 0.02)); 
    double startAngle = -totalAngle / 2;
    return SizedBox(width: radius.abs() * 2.5, height: radius.abs() * 2.5, child: Stack(alignment: Alignment.center, children: List.generate(words.length, (index) {
      double angle = startAngle + index * (0.3 + (letterSpacing * 0.02));
      if(radius < 0) angle = -angle; 
      return Transform(transform: Matrix4.identity()..translate(radius * sin(angle), -radius * cos(angle))..rotateZ(radius > 0 ? angle : angle + pi), alignment: Alignment.center, child: Text(words[index], style: style));
    })));
  }
}

// 🔥 INPAGE 3 / MS WORD STYLE PROFESSIONAL TABLE 🔥
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
      child: Directionality(
        textDirection: TextDirection.rtl, // InPage Standard (Right to Left)
        child: Table(
          border: hasBorder ? TableBorder.all(color: borderColor, width: 2.0) : null,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            for (int i = 0; i < tableData[0].length; i++) i: const FlexColumnWidth()
          },
          children: tableData.asMap().entries.map((row) {
            bool isHeader = row.key == 0; 
            return TableRow(
              decoration: isHeader ? BoxDecoration(color: borderColor.withOpacity(0.15)) : null,
              children: row.value.map((cellText) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                  child: Text(
                    cellText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      color: textColor,
                      fontSize: isHeader ? 18 : 16,
                      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
