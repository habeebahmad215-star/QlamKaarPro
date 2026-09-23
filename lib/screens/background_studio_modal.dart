import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Naya import internet se image lane ke liye
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
  bool _isDownloading = false; // Loading spinner dikhane ke liye
  int _selectedCategoryIndex = 0;

  // True Stock Library (Premium Categories & Image URLs)
  final List<Map<String, dynamic>> _stockCategories = [
    {
      'name': 'Islamic',
      'images': [
        'https://images.unsplash.com/photo-1564507004663-b6dfb3c824d5?w=600&q=80',
        'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=600&q=80',
        'https://images.unsplash.com/photo-1519817914152-2a67e5a87474?w=600&q=80',
        'https://images.unsplash.com/photo-1585036156171-384164a8c675?w=600&q=80',
      ]
    },
    {
      'name': 'Paper',
      'images': [
        'https://images.unsplash.com/photo-1603484435773-4c910360a0a8?w=600&q=80',
        'https://images.unsplash.com/photo-1601662528567-526cd06f6582?w=600&q=80',
        'https://images.unsplash.com/photo-1586075010923-2dd4570fb338?w=600&q=80',
        'https://images.unsplash.com/photo-1618365908648-e71bd5716cba?w=600&q=80',
      ]
    },
    {
      'name': 'Abstract',
      'images': [
        'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=600&q=80',
        'https://images.unsplash.com/photo-1550684376-efcbd6e3f031?w=600&q=80',
        'https://images.unsplash.com/photo-1550684847-75cb75415714?w=600&q=80',
        'https://images.unsplash.com/photo-1550684377-df84e8bb0dc0?w=600&q=80',
      ]
    }
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        widget.onApply(Colors.white, null, bytes);
      }
    } catch (e) {
      debugPrint("BG Image Error: $e");
    }
  }

  // Internet se High-Quality Stock Image download aur apply karne ka function
  Future<void> _applyStockImage(String url) async {
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        widget.onApply(Colors.white, null, response.bodyBytes);
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Internet check karein.'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // Standard Professional Colors Palette
  final List<Color> _standardColors = [
    Colors.white, Colors.black, Colors.red, Colors.pink, Colors.purple, 
    Colors.deepPurple, Colors.indigo, Colors.blue, Colors.lightBlue, 
    Colors.cyan, Colors.teal, Colors.green, Colors.lightGreen, 
    Colors.lime, Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey, const Color(0xFFD4AF37)
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 480, // Height thodi badha di taaki Stock Grid achhi dikhe
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC), 
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DefaultTabController(
            length: 5, // TABS 4 se 5 kar diye
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
                      Tab(icon: Icon(Icons.wallpaper, size: 18), text: 'Stock'), // NAYA STOCK TAB
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

                      // TAB 3: TRUE STOCK LIBRARY (Phase 3 Masterpiece)
                      Column(
                        children: [
                          // Categories Horizontal Selector
                          SizedBox(
                            height: 45,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _stockCategories.length,
                              itemBuilder: (ctx, i) {
                                bool isSelected = _selectedCategoryIndex == i;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(_stockCategories[i]['name']),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300)),
                                    labelStyle: TextStyle(color: isSelected ? const Color(0xFF8B5CF6) : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                                    onSelected: (val) => setState(() => _selectedCategoryIndex = i),
                                  ),
                                );
                              }
                            ),
                          ),
                          // Stock Images Grid
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, 
                                crossAxisSpacing: 10, 
                                mainAxisSpacing: 10, 
                                childAspectRatio: 0.8 // Portrait style images
                              ),
                              itemCount: _stockCategories[_selectedCategoryIndex]['images'].length,
                              itemBuilder: (ctx, i) {
                                String url = _stockCategories[_selectedCategoryIndex]['images'][i];
                                return InkWell(
                                  onTap: () => _applyStockImage(url),
                                  borderRadius: BorderRadius.circular(10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          url, 
                                          fit: BoxFit.cover,
                                          loadingBuilder: (ctx, child, progress) {
                                            if (progress == null) return child;
                                            return Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6))));
                                          },
                                          errorBuilder: (ctx, err, stack) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey)),
                                        ),
                                        // Premium Gradient Overlay on images
                                        Positioned(
                                          bottom: 0, left: 0, right: 0,
                                          child: Container(
                                            height: 30,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black54, Colors.transparent])
                                            ),
                                          )
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }
                            ),
                          )
                        ],
                      ),

                      // TAB 4: Gallery Pick
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

                      // TAB 5: Transparent Background
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
        ),
        
        // Downloading Overlay (Jab user kisi Stock image par click karega)
        if (_isDownloading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  SizedBox(height: 16),
                  Text("Applying Pro Background...", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)))
                ],
              ),
            ),
          )
      ],
    );
  }
}
