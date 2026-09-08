import 'package:flutter/material.dart';

class StickersLibraryModal extends StatelessWidget {
  final Function(String stickerText) onStickerSelected;

  const StickersLibraryModal({Key? key, required this.onStickerSelected}) : super(key: key);

  static const Map<String, List<String>> stickerCategories = {
    'اسلامی (Islamic)': ['﷽', 'ﷺ', 'جل جلالہ', 'رضی اللہ عنہ', 'رحمۃ اللہ علیہ', 'الحمدللہ', 'سبحان اللہ', 'ماشاء اللہ', 'لا الہ الا اللہ'],
    'فریم و بیجز (Badges)': ['★ ✧ ★', '✿ ❀ ✿', '❖ ❖ ❖', '✦ ── ✦', '◈ ━━ ◈', '⟡ ── ⟡'],
    'علامات (Symbols)': ['➔', '➤', '❖', '✿', '★', '❤️', '🔥', '👑', '💎', '📌'],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: stickerCategories.keys.length,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Stickers & Symbols (اسٹیکرز)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            TabBar(
              isScrollable: true,
              labelColor: const Color(0xFF8B5CF6),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF8B5CF6),
              tabs: stickerCategories.keys.map((k) => Tab(text: k)).toList(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                children: stickerCategories.keys.map((catKey) {
                  List items = stickerCategories[catKey]!;
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      String item = items[index];
                      return InkWell(
                        onTap: () {
                          onStickerSelected(item);
                          Navigator.pop(context);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200, width: 1.5),
                          ),
                          child: Text(
                            item,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontSize: 18, fontFamily: 'JameelNoori', color: Colors.black87),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
