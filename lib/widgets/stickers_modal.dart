import 'package:flutter/material.dart';

// 🔥 1. Advanced Model Architecture (Future Ready for Images/SVGs)
class StickerModel {
  final String id;
  final String name;
  final String value;
  final bool isImage; // Future mein PNGs ke liye ise true karenge

  StickerModel({required this.id, required this.name, required this.value, this.isImage = false});
}

class StickersLibraryModal extends StatefulWidget {
  final Function(String stickerText) onStickerSelected;

  const StickersLibraryModal({Key? key, required this.onStickerSelected}) : super(key: key);

  @override
  State<StickersLibraryModal> createState() => _StickersLibraryModalState();
}

class _StickersLibraryModalState extends State<StickersLibraryModal> {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // 🔥 2. Premium Categories
  final List<String> _categories = [
    'All (سب)',
    'Islamic (اسلامی)',
    'Badges (بیجز)',
    'Shapes (اشکال)',
    'Symbols (علامات)',
  ];

  // 🔥 3. Structured Data
  final List<StickerModel> _allStickers = [
    // Islamic
    StickerModel(id: '1', name: 'Bismillah', value: '﷽'),
    StickerModel(id: '2', name: 'SAW', value: 'ﷺ'),
    StickerModel(id: '3', name: 'Jalla Jalalahoo', value: 'جل جلالہ'),
    StickerModel(id: '4', name: 'RA', value: 'رضی اللہ عنہ'),
    StickerModel(id: '5', name: 'Alhamdulillah', value: 'الحمدللہ'),
    StickerModel(id: '6', name: 'SubhanAllah', value: 'سبحان اللہ'),
    StickerModel(id: '7', name: 'MashaAllah', value: 'ماشاء اللہ'),
    
    // Badges
    StickerModel(id: '8', name: 'Star Badge', value: '★ ✧ ★'),
    StickerModel(id: '9', name: 'Flower Frame', value: '✿ ❀ ✿'),
    StickerModel(id: '10', name: 'Diamond Frame', value: '❖ ❖ ❖'),
    StickerModel(id: '11', name: 'Royal Line', value: '✦ ── ✦'),
    StickerModel(id: '12', name: 'Solid Divider', value: '◈ ━━ ◈'),
    
    // Shapes
    StickerModel(id: '13', name: 'Circle', value: '●'),
    StickerModel(id: '14', name: 'Square', value: '■'),
    StickerModel(id: '15', name: 'Triangle', value: '▲'),
    StickerModel(id: '16', name: 'Diamond', value: '◆'),
    
    // Symbols
    StickerModel(id: '17', name: 'Arrow Right', value: '➔'),
    StickerModel(id: '18', name: 'Pointer', value: '➤'),
    StickerModel(id: '19', name: 'Heart', value: '❤️'),
    StickerModel(id: '20', name: 'Fire', value: '🔥'),
    StickerModel(id: '21', name: 'Crown', value: '👑'),
    StickerModel(id: '22', name: 'Pin', value: '📌'),
  ];

  // Helper function to filter items based on category and search
  List<StickerModel> get _filteredStickers {
    List<StickerModel> filtered = _allStickers;

    // Filter by Category
    if (_selectedCategoryIndex == 1) {
      filtered = filtered.where((s) => int.parse(s.id) >= 1 && int.parse(s.id) <= 7).toList();
    } else if (_selectedCategoryIndex == 2) {
      filtered = filtered.where((s) => int.parse(s.id) >= 8 && int.parse(s.id) <= 12).toList();
    } else if (_selectedCategoryIndex == 3) {
      filtered = filtered.where((s) => int.parse(s.id) >= 13 && int.parse(s.id) <= 16).toList();
    } else if (_selectedCategoryIndex == 4) {
      filtered = filtered.where((s) => int.parse(s.id) >= 17 && int.parse(s.id) <= 22).toList();
    }

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) => 
        s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        s.value.contains(_searchQuery)
      ).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard open hone par height adjust karne ke liye
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset), // Smart keyboard handling
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Premium light background
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Title & Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Elements & Stickers', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 24,
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                ]
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search stickers... (تلاش کریں)',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF8B5CF6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Modern Pill Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategoryIndex = index;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected 
                        ? [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                        : [],
                    ),
                    child: Center(
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 15),

          // Stickers Grid
          Expanded(
            child: _filteredStickers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('No stickers found', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, 
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.0, 
                    ),
                    itemCount: _filteredStickers.length,
                    itemBuilder: (context, index) {
                      final sticker = _filteredStickers[index];
                      return InkWell(
                        onTap: () {
                          widget.onStickerSelected(sticker.value);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            sticker.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26, 
                              fontFamily: 'JameelNoori', 
                              color: Color(0xFF1E293B)
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
