import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const QalamKaarProApp());
}

class QalamKaarProApp extends StatelessWidget {
  const QalamKaarProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QalamKaar Pro',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      home: const ProWorkspaceScreen(),
    );
  }
}

class DesignElement {
  String id;
  double x, y;
  String content;
  Uint8List? imageBytes;
  bool isText;
  double fontSize;
  Color textColor;
  bool hasStroke;
  bool hasShadow;
  double opacity;
  bool isBold;
  bool isItalic;
  TextAlign textAlign;
  String fontFamily;
  
  bool isBorder;
  bool isShape;
  Color elementColor;
  double width;
  double height;
  double borderWidth;
  String borderStyle;

  DesignElement({
    required this.id, required this.x, required this.y, required this.content,
    this.imageBytes, this.isText = true, this.fontSize = 36.0, 
    this.textColor = Colors.black, this.hasStroke = false, 
    this.hasShadow = false, this.opacity = 1.0,
    this.isBold = false, this.isItalic = false, this.textAlign = TextAlign.center,
    this.fontFamily = 'JameelNoori',
    this.isBorder = false, this.isShape = false,
    this.elementColor = const Color(0xFFD4AF37),
    this.width = 0, this.height = 0,
    this.borderWidth = 5.0, this.borderStyle = 'royal_islamic',
  });

  DesignElement clone() {
    return DesignElement(
      id: id, x: x, y: y, content: content, imageBytes: imageBytes,
      isText: isText, fontSize: fontSize, textColor: textColor,
      hasStroke: hasStroke, hasShadow: hasShadow, opacity: opacity,
      isBold: isBold, isItalic: isItalic, textAlign: textAlign,
      fontFamily: fontFamily, isBorder: isBorder, isShape: isShape,
      elementColor: elementColor, width: width, height: height,
      borderWidth: borderWidth, borderStyle: borderStyle,
    );
  }
}

class DesignPage {
  String title;
  List<DesignElement> elements;
  Color pageColor;

  DesignPage({required this.title, required this.elements, required this.pageColor});
}

class ProWorkspaceScreen extends StatefulWidget {
  const ProWorkspaceScreen({Key? key}) : super(key: key);

  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> {
  List<DesignPage> pages = [
    DesignPage(
      title: 'Page 1',
      elements: [DesignElement(id: 'demo1', x: 80, y: 150, content: 'حبیب احمد خان')],
      pageColor: Colors.white,
    )
  ];
  int currentPageIndex = 0;

  List<List<DesignElement>> undoStack = [];
  List<List<DesignElement>> redoStack = [];
  String? selectedId;
  double canvasRatio = 1 / 1.414; 
  
  List<String> availableFonts = ['JameelNoori', 'Amiri', 'Bombay', 'Mehr'];
  final ImagePicker _picker = ImagePicker();

  List<DesignElement> get elements => pages[currentPageIndex].elements;
  set elements(List<DesignElement> val) => pages[currentPageIndex].elements = val;

  Color get pageColor => pages[currentPageIndex].pageColor;
  set pageColor(Color val) => pages[currentPageIndex].pageColor = val;

  void saveState() {
    undoStack.add(elements.map((e) => e.clone()).toList());
    redoStack.clear(); 
  }

  void undoAction() {
    if (undoStack.isNotEmpty) {
      redoStack.add(elements.map((e) => e.clone()).toList());
      setState(() {
        elements = undoStack.removeLast();
        selectedId = null;
      });
    }
  }

  void redoAction() {
    if (redoStack.isNotEmpty) {
      undoStack.add(elements.map((e) => e.clone()).toList());
      setState(() {
        elements = redoStack.removeLast();
        selectedId = null;
      });
    }
  }

  void addTextBox() {
    saveState();
    setState(() => elements.add(DesignElement(id: Random().nextInt(10000).toString(), x: 60, y: 100, content: 'نیا ٹیکسٹ')));
    Navigator.pop(context);
  }

  // ================= 50+ STOCK DYNAMIC LIBRARIES FOR ALL CATEGORIES =================
  
  void showGenericStockModal(String categoryTitle, String styleName, IconData categoryIcon) {
    Navigator.pop(context);
    
    List<Map<String, dynamic>> stockList = [];
    List<Color> themeColors = [
      const Color(0xFFD4AF37), const Color(0xFF8B5CF6), const Color(0xFF047857), 
      const Color(0xFF1E3A8A), const Color(0xFFDC2626), const Color(0xFF0D9488), 
      const Color(0xFFD97706), const Color(0xFF4338CA)
    ];

    for (int i = 1; i <= 50; i++) {
      stockList.add({
        'title': '$categoryTitle #$i',
        'style': styleName,
        'color': themeColors[(i - 1) % themeColors.length],
        'icon': categoryIcon,
      });
    }

    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 15),
            Text('$categoryTitle Library (50+ Pro Stock)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
            const Text('Click any style to apply instantly', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.4,
                ),
                itemCount: stockList.length,
                itemBuilder: (context, index) {
                  var item = stockList[index];
                  return InkWell(
                    onTap: () {
                      saveState();
                      setState(() {
                        if (styleName.contains('shape') || styleName == 'badge') {
                          elements.add(DesignElement(
                            id: Random().nextInt(10000).toString(),
                            x: 90, y: 180,
                            content: styleName == 'badge' ? 'circle' : 'rectangle',
                            isText: false, isShape: true,
                            elementColor: item['color'],
                            width: 220, height: 90,
                          ));
                        } else {
                          elements.insert(0, DesignElement(
                            id: Random().nextInt(10000).toString(),
                            x: 0, y: 0,
                            content: item['title'],
                            isText: false, isBorder: true,
                            borderStyle: styleName,
                            elementColor: item['color'],
                            borderWidth: 5.0,
                          ));
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: item['color'], width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item['icon'], color: item['color'], size: 30),
                          const SizedBox(height: 6),
                          Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item['color']), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  // =========================================================================

  Future<void> addImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        saveState();
        setState(() {
          elements.add(DesignElement(
            id: Random().nextInt(10000).toString(),
            x: 80, y: 80,
            content: '',
            imageBytes: bytes,
            isText: false,
          ));
        });
      }
    } catch (e) {}
    Navigator.pop(context);
  }

  void showPagesPanel() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 400,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pages (صفحات)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        bool isCurrent = currentPageIndex == index;
                        return Card(
                          color: isCurrent ? const Color(0xFFF3E8FF) : Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: ListTile(
                            leading: Icon(Icons.description, color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey),
                            title: Text(pages[index].title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                            trailing: pages.length > 1 
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      pages.removeAt(index);
                                      if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1;
                                    });
                                    setModalState(() {});
                                  },
                                )
                              : null,
                            onTap: () {
                              setState(() {
                                currentPageIndex = index;
                                selectedId = null;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                      onPressed: () {
                        setState(() {
                          pages.add(DesignPage(
                            title: 'Page ${pages.length + 1}',
                            elements: [DesignElement(id: Random().nextInt(10000).toString(), x: 60, y: 100, content: 'نیا صفحہ')],
                            pageColor: Colors.white,
                          ));
                          currentPageIndex = pages.length - 1;
                          selectedId = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Add New Page (نیا صفحہ جوڑیں)', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void deleteSelected() {
    if (selectedId != null) {
      saveState();
      setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; });
    }
  }

  void duplicateSelected() {
    if (selectedId != null) {
      saveState();
      DesignElement sel = elements.firstWhere((e) => e.id == selectedId);
      setState(() {
        elements.add(sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20);
      });
    }
  }

  void bringForward() {
    if (selectedId == null) return;
    saveState();
    int idx = elements.indexWhere((e) => e.id == selectedId);
    if (idx < elements.length - 1) {
      setState(() {
        var item = elements.removeAt(idx);
        elements.insert(idx + 1, item);
      });
    }
  }

  void sendBackward() {
    if (selectedId == null) return;
    saveState();
    int idx = elements.indexWhere((e) => e.id == selectedId);
    if (idx > 0) {
      setState(() {
        var item = elements.removeAt(idx);
        elements.insert(idx - 1, item);
      });
    }
  }

  void showFontPickerModal(DesignElement sel) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 350, padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Font (فونٹ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: availableFonts.length,
                itemBuilder: (context, index) {
                  String fontName = availableFonts[index];
                  return ListTile(
                    title: Text('حبیب احمد خان - $fontName', style: TextStyle(fontFamily: fontName, fontSize: 24)),
                    trailing: sel.fontFamily == fontName ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)) : null,
                    onTap: () {
                      saveState();
                      setState(() => sel.fontFamily = fontName);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showLayersPanel() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 400,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Layers (پرتیں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: elements.isEmpty 
                      ? const Center(child: Text('No elements yet.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: elements.length,
                          itemBuilder: (context, index) {
                            int actualIndex = elements.length - 1 - index;
                            DesignElement e = elements[actualIndex];
                            bool isSel = selectedId == e.id;
                            
                            return Card(
                              color: isSel ? const Color(0xFFF3E8FF) : Colors.white,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: e.isText ? e.textColor : Colors.blueGrey,
                                  child: Icon(e.isText ? Icons.title : (e.isBorder ? Icons.filter_frames : Icons.category), size: 16, color: Colors.white),
                                ),
                                title: Text(e.isText ? e.content.replaceAll('\n', ' ') : (e.isBorder ? e.content : 'Shape'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.arrow_upward, size: 20, color: Colors.black54), onPressed: () {
                                      if (actualIndex < elements.length - 1) {
                                        saveState();
                                        setState(() {
                                          var item = elements.removeAt(actualIndex);
                                          elements.insert(actualIndex + 1, item);
                                        });
                                        setModalState((){});
                                      }
                                    }),
                                    IconButton(icon: const Icon(Icons.arrow_downward, size: 20, color: Colors.black54), onPressed: () {
                                      if (actualIndex > 0) {
                                        saveState();
                                        setState(() {
                                          var item = elements.removeAt(actualIndex);
                                          elements.insert(actualIndex - 1, item);
                                        });
                                        setModalState((){});
                                      }
                                    }),
                                  ],
                                ),
                                onTap: () {
                                  setState(() => selectedId = e.id);
                                  setModalState((){}); 
                                },
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showResizeModal() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 250, padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Design / Resize Paper', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSizeOption('1:1', 'Square', 1.0, Icons.crop_square),
                _buildSizeOption('16:9', 'YouTube', 16 / 9, Icons.crop_16_9),
                _buildSizeOption('A4', 'Document', 1 / 1.414, Icons.insert_drive_file_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption(String ratioTxt, String label, double ratio, IconData icon) {
    return InkWell(
      onTap: () {
        saveState();
        setState(() => canvasRatio = ratio);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF8B5CF6), size: 30)),
          const SizedBox(height: 8), Text(ratioTxt, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void showAddNewModal() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 15),
              const Text('Add Design Elements (شامل کریں)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 10),
              
              const Text('Essentials', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
                children: [
                  _buildGridItem(Icons.image, 'Gallery Pic', Colors.blue, addImageFromGallery),
                  _buildGridItem(Icons.text_fields, 'Add Text', Colors.deepOrange, addTextBox),
                  _buildGridItem(Icons.folder, 'My Folder', Colors.cyan, () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Pro Categories & Libraries (50+ Stock Each)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
                children: [
                  _buildGridItem(Icons.filter_frames, 'Frames', Colors.teal, () => showGenericStockModal('Frames', 'royal_islamic', Icons.filter_frames)),
                  _buildGridItem(Icons.brightness_7, 'Islamic Arches', Colors.amber.shade800, () => showGenericStockModal('Islamic Arches', 'vintage_frame', Icons.brightness_7)),
                  _buildGridItem(Icons.star, 'Badges', Colors.indigo, () => showGenericStockModal('Badges', 'badge', Icons.star)),
                  _buildGridItem(Icons.crop_square, 'Corners', Colors.deepPurple, () => showGenericStockModal('Corners', 'floral_corner', Icons.crop_square)),
                  _buildGridItem(Icons.category, 'Shapes', Colors.pink, () => showGenericStockModal('Shapes', 'shape_rect', Icons.category)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 22)),
            const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = selectedId != null;
    DesignElement? sel;
    var foundElements = elements.where((e) => e.id == selectedId);
    if (foundElements.isNotEmpty) sel = foundElements.first;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopBtn(Icons.menu, ''), 
              _buildTopBtn(Icons.layers, 'Layers', showLayersPanel),
              _buildTopBtn(Icons.auto_stories, 'Pages', showPagesPanel),
              _buildTopBtn(Icons.undo, 'Undo', undoAction), 
              _buildTopBtn(Icons.redo, 'Redo', redoAction),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: const [Icon(Icons.save, color: Colors.white, size: 16), SizedBox(width: 4), Text('Save Pro', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))]),
              ),
            ],
          ),
        ),
      ),
      
      body: GestureDetector(
        onTap: () => setState(() => selectedId = null),
        child: Center(
          child: AspectRatio(
            aspectRatio: canvasRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: pageColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: elements.map((e) {
                      bool isSel = e.id == selectedId;
                      
                      List<Shadow> textShadows = [];
                      if (e.hasShadow) textShadows.add(const Shadow(color: Colors.black54, offset: Offset(3, 3), blurRadius: 5));
                      if (e.hasStroke) {
                        Color strokeCol = e.textColor == Colors.black ? Colors.white : Colors.black;
                        textShadows.addAll([
                          Shadow(color: strokeCol, offset: const Offset(-1.5, -1.5)), Shadow(color: strokeCol, offset: const Offset(1.5, -1.5)),
                          Shadow(color: strokeCol, offset: const Offset(1.5, 1.5)), Shadow(color: strokeCol, offset: const Offset(-1.5, 1.5)),
                        ]);
                      }

                      if (e.isBorder) {
                        return Positioned.fill(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedId = e.id),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: e.elementColor, width: e.borderWidth),
                                borderRadius: BorderRadius.circular(10),
                                color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.05) : Colors.transparent,
                              ),
                              child: Stack(
                                children: [
                                  if (e.borderStyle == 'royal_islamic') ...[
                                    const Positioned(top: 4, left: 4, child: Text('☪', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18))),
                                    const Positioned(top: 4, right: 4, child: Text('☪', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18))),
                                    const Positioned(bottom: 4, left: 4, child: Text('❖', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16))),
                                    const Positioned(bottom: 4, right: 4, child: Text('❖', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16))),
                                  ],
                                  if (e.borderStyle == 'vintage_frame') ...[
                                    const Positioned(top: 2, left: 2, child: Text('╔', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 20, fontWeight: FontWeight.bold))),
                                    const Positioned(top: 2, right: 2, child: Text('╗', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 20, fontWeight: FontWeight.bold))),
                                    const Positioned(bottom: 2, left: 2, child: Text('╚', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 20, fontWeight: FontWeight.bold))),
                                    const Positioned(bottom: 2, right: 2, child: Text('╝', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 20, fontWeight: FontWeight.bold))),
                                  ],
                                  if (e.borderStyle == 'floral_corner') ...[
                                    const Positioned(top: 2, left: 2, child: Text('❦', style: TextStyle(color: Color(0xFF047857), fontSize: 20))),
                                    const Positioned(top: 2, right: 2, child: Text('❦', style: TextStyle(color: Color(0xFF047857), fontSize: 20))),
                                    const Positioned(bottom: 2, left: 2, child: Text('❦', style: TextStyle(color: Color(0xFF047857), fontSize: 20))),
                                    const Positioned(bottom: 2, right: 2, child: Text('❦', style: TextStyle(color: Color(0xFF047857), fontSize: 20))),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Positioned(
                        left: e.x, top: e.y,
                        child: GestureDetector(
                          onPanStart: (d) => saveState(), 
                          onTap: () => setState(() => selectedId = e.id),
                          onPanUpdate: (d) => setState(() { selectedId = e.id; e.x += d.delta.dx; e.y += d.delta.dy; }),
                          child: Opacity(
                            opacity: e.opacity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: isSel ? BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5)) : null,
                                  child: e.isText 
                                    ? SizedBox(
                                        width: 300,
                                        child: TextField(
                                          onTap: () => setState(() => selectedId = e.id),
                                          maxLines: null, textAlign: e.textAlign,
                                          controller: TextEditingController(text: e.content)..selection = TextSelection.fromPosition(TextPosition(offset: e.content.length)),
                                          onChanged: (val) { saveState(); e.content = val; },
                                          style: TextStyle(
                                            fontFamily: e.fontFamily,
                                            fontSize: e.fontSize, 
                                            color: e.textColor, 
                                            fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal,
                                            height: 2.0, 
                                            shadows: textShadows.isNotEmpty ? textShadows : null, 
                                          ),
                                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                        ),
                                      )
                                    : e.isShape
                                        ? Container(
                                            width: e.width, height: e.height,
                                            decoration: BoxDecoration(
                                              color: e.elementColor,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))],
                                            ),
                                            child: Center(
                                              child: Text(e.content.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                                            ),
                                          )
                                        : (e.imageBytes != null 
                                            ? Image.memory(e.imageBytes!, width: 150, height: 150, fit: BoxFit.cover) 
                                            : const SizedBox()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(color: Colors.white, child: SafeArea(child: hasSelection ? _buildSmartEditingTray(sel) : _buildDefaultBottomBar())),
    );
  }

  Widget _buildDefaultBottomBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          InkWell(
            onTap: showAddNewModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.add, color: Color(0xFF8B5CF6)), Text('ADD NEW', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold))]),
            ),
          ),
          const SizedBox(width: 20),
          _buildBottomBtn(Icons.aspect_ratio, 'Resize Paper', showResizeModal),
          const SizedBox(width: 20),
          _buildBottomBtn(Icons.format_color_fill, 'BG Color', () { saveState(); setState(() => pageColor = pageColor == Colors.white ? Colors.amber.shade100 : Colors.white); }),
        ],
      ),
    );
  }

  Widget _buildSmartEditingTray(DesignElement? sel) {
    if (sel == null) return const SizedBox();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Row(
            children: [
              if (sel.isText) ...[
                _buildEditBtn(Icons.font_download, 'Font', () => showFontPickerModal(sel)),
                _buildEditBtn(Icons.text_fields, 'Size', () { saveState(); setState(() => sel.fontSize = sel.fontSize == 45 ? 24 : 45); }),
                _buildEditBtn(Icons.palette, 'Color', () { saveState(); setState(() => sel.textColor = sel.textColor == Colors.black ? Colors.red : Colors.black); }),
                _buildEditBtn(Icons.border_color, 'Stroke', () { saveState(); setState(() => sel.hasStroke = !sel.hasStroke); }),
                _buildEditBtn(Icons.brightness_6, 'Shadow', () { saveState(); setState(() => sel.hasShadow = !sel.hasShadow); }),
                _buildEditBtn(Icons.format_bold, 'Bold', () { saveState(); setState(() => sel.isBold = !sel.isBold); }),
              ],
              if (sel.isBorder) ...[
                _buildEditBtn(Icons.palette, 'Theme Color', () { 
                  saveState(); 
                  setState(() => sel.elementColor = sel.elementColor == const Color(0xFFD4AF37) ? const Color(0xFF047857) : const Color(0xFFD4AF37)); 
                }),
                _buildEditBtn(Icons.line_weight, 'Width', () { 
                  saveState(); 
                  setState(() => sel.borderWidth = sel.borderWidth == 5.0 ? 8.0 : 5.0); 
                }),
              ],
              if (sel.isShape) ...[
                _buildEditBtn(Icons.palette, 'Shape Color', () { 
                  saveState(); 
                  setState(() => sel.elementColor = sel.elementColor == const Color(0xFF8B5CF6) ? const Color(0xFFD97706) : const Color(0xFF8B5CF6)); 
                }),
              ],
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => selectedId = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.remove_circle_outline, color: Color(0xFF8B5CF6), size: 20), SizedBox(height: 2), Text('DESELECT', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold))]),
                ),
              ),
              const SizedBox(width: 15),
              _buildEditBtn(Icons.delete_outline, 'Delete', deleteSelected),
              _buildEditBtn(Icons.content_copy, 'Duplicate', duplicateSelected),
              _buildEditBtn(Icons.opacity, 'Opacity', () { saveState(); setState(() => sel.opacity = sel.opacity == 1.0 ? 0.5 : 1.0); }),
              _buildEditBtn(Icons.flip_to_front, 'Front', bringForward),
              _buildEditBtn(Icons.flip_to_back, 'Back', sendBackward),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBtn(IconData icon, String label, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade800, size: 22),
          if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBottomBtn(IconData icon, String label, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEditBtn(IconData icon, String label, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
