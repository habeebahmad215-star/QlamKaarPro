import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

class BackgroundStudioModal extends StatefulWidget {
  final Color currentColor;
  final List<Color>? currentGradient;
  final Uint8List? currentImageBytes;
  final Function(Color color, List<Color>? gradient, Uint8List? imageBytes) onApply;

  const BackgroundStudioModal({
    Key? key,
    required this.currentColor,
    this.currentGradient,
    this.currentImageBytes,
    required this.onApply,
  }) : super(key: key);

  @override
  State<BackgroundStudioModal> createState() => _BackgroundStudioModalState();
}

class _BackgroundStudioModalState extends State<BackgroundStudioModal> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        // Gallery image apply karte waqt Color white aur Gradient null kar denge
        widget.onApply(Colors.white, null, bytes);
      }
    } catch (e) {
      debugPrint("BG Image Error: $e");
    }
  }

  // Standard Professional Colors Palette
  final List<Color> _standardColors = [
    Colors.white, Colors.black, Colors.red, Colors.pink, Colors.purple, 
    Colors.deepPurple, Colors.indigo, Colors.blue, Colors.lightBlue, 
    Colors.cyan, Colors.teal, Colors.green, Colors.lightGreen, 
    Colors.lime, Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey, const Color(0xFFD4AF37) // Pro Gold
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Apple Jaisa Smooth Light Grayish White
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Background Studio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54), 
                    padding: EdgeInsets.zero, 
                    constraints: const BoxConstraints(), 
                    onPressed: () => Navigator.pop(context)
                  )
                ],
              ),
            ),
            
            // Custom Professional TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              ),
              child: TabBar(
                isScrollable: true,
                indicatorColor: const Color(0xFF8B5CF6),
                indicatorWeight: 3,
                labelColor: const Color(0xFF8B5CF6),
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.format_color_fill, size: 18), text: 'Colors'),
                  Tab(icon: Icon(Icons.gradient, size: 18), text: 'Gradients'),
                  Tab(icon: Icon(Icons.image, size: 18), text: 'Gallery'),
                  Tab(icon: Icon(Icons.layers_clear, size: 18), text: 'Clear'),
                ],
              ),
            ),
            
            const SizedBox(height: 10),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: Solid Colors
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _standardColors.length,
                    itemBuilder: (context, index) {
                      Color c = _standardColors[index];
                      // Check if this color is currently active
                      bool isSelected = widget.currentImageBytes == null && widget.currentGradient == null && widget.currentColor.value == c.value;
                      return GestureDetector(
                        onTap: () => widget.onApply(c, null, null),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.black12, width: isSelected ? 3 : 1),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                          ),
                          child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 18) : null,
                        ),
                      );
                    },
                  ),

                  // TAB 2: Gradients
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: AppConstants.proGradientPalette.length,
                    itemBuilder: (context, index) {
                      List<Color> g = AppConstants.proGradientPalette[index];
                      bool isSelected = widget.currentGradient == g;
                      return GestureDetector(
                        onTap: () => widget.onApply(Colors.white, g, null),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: g),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: isSelected ? 2 : 0),
                            boxShadow: [
                              if (isSelected) const BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 6, spreadRadius: 1)
                            ]
                          ),
                          child: isSelected ? const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 20)) : null,
                        ),
                      );
                    },
                  ),

                  // TAB 3: Gallery Pick
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_rounded, size: 60, color: Colors.black26),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0
                          ),
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 20),
                          label: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        const Text('Upload your own background image.', style: TextStyle(color: Colors.black54, fontSize: 11))
                      ],
                    ),
                  ),

                  // TAB 4: Transparent Background
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400, width: 2)
                          ),
                          child: const Icon(Icons.layers_clear, size: 36, color: Colors.black45),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0
                          ),
                          onPressed: () => widget.onApply(Colors.transparent, null, null),
                          child: const Text('Make Transparent (PNG)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        const Text('Perfect for logos & stickers design.', style: TextStyle(color: Colors.black54, fontSize: 11))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
