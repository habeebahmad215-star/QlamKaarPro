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
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const HomeScreen(),
    );
  }
}

// ================= HOME SCREEN =================
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showNewDesignModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Design', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildInputBox('WIDTH', '1080')),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.lock_outline, color: Colors.grey)),
                Expanded(child: _buildInputBox('HEIGHT', '1080')),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                  child: const Text('px', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProWorkspaceScreen()));
                },
                child: const Text('Create Design', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: val,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))]),
                    child: const Icon(Icons.draw, size: 55, color: Color(0xFF6D28D9)),
                  ),
                  const SizedBox(height: 15),
                  const Text('قلمکار پرو', style: TextStyle(fontFamily: 'JameelNoori', fontSize: 55, color: Colors.white, height: 1.2)),
                  const Text('Professional Urdu Designer', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2.0, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
                children: [
                  _buildMenuCard(context, 'نیا ڈیزائن', 'New Design', Icons.add_to_photos, const Color(0xFF8B5CF6), true),
                  _buildMenuCard(context, 'آن لائن ڈیزائن', 'Templates', Icons.cloud_download, const Color(0xFF10B981), false),
                  _buildMenuCard(context, 'میرے ڈیزائن', 'My Folder', Icons.folder_special, const Color(0xFFF59E0B), false),
                  _buildMenuCard(context, 'رہنمائی', 'Tutorials', Icons.play_circle_fill, const Color(0xFFEF4444), false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String urduText, String engText, IconData icon, Color color, bool isNewDesign) {
    return InkWell(
      onTap: () {
        if (isNewDesign) {
          _showNewDesignModal(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$engText jald aa raha hai!')));
        }
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 35)),
            const SizedBox(height: 12),
            Text(urduText, style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 28, color: Colors.black87, height: 1.0)),
            Text(engText, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}

// ================= WORKSPACE ELEMENTS =================
class DesignElement {
  String id;
  double x, y;
  String content;
  bool isText;
  double fontSize;
  Color textColor;
  bool hasStroke;
  bool hasShadow;
  double opacity;
  String fontFamily;

  DesignElement({
    required this.id, required this.x, required this.y, required this.content,
    this.isText = true, this.fontSize = 45.0, this.textColor = Colors.black, 
    this.hasStroke = false, this.hasShadow = false, this.opacity = 1.0,
    this.fontFamily = 'JameelNoori',
  });

  DesignElement clone() {
    return DesignElement(
      id: id, x: x, y: y, content: content, isText: isText, fontSize: fontSize, 
      textColor: textColor, hasStroke: hasStroke, hasShadow: hasShadow, 
      opacity: opacity, fontFamily: fontFamily,
    );
  }
}

// ================= MAIN EDITOR SCREEN =================
class ProWorkspaceScreen extends StatefulWidget {
  const ProWorkspaceScreen({Key? key}) : super(key: key);

  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> {
  List<DesignElement> elements = [];
  String? selectedId;
  Color pageColor = Colors.white;

  // ==== TEXT COMPOSER (Green Button Wala Page) ====
  void _showTextComposerDialog({DesignElement? existingElement}) {
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header Toggle
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: const Text('English', style: TextStyle(color: Colors.grey))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Text('اردو', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              // Text Area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15), color: Colors.grey.shade50),
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 28),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'یہاں لکھیں...', hintTextDirection: TextDirection.rtl),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildComposerTool(Icons.paste, 'Paste'),
                  _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()),
                  _buildComposerTool(Icons.auto_awesome, 'AI'),
                  _buildComposerTool(Icons.translate, 'Translate'),
                ],
              ),
              const SizedBox(height: 20),
              // Final Add to Design Button
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), // Green Color like demo
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          if (existingElement != null) {
                            setState(() => existingElement.content = controller.text);
                          } else {
                            var newEl = DesignElement(id: Random().nextInt(10000).toString(), x: 50, y: 150, content: controller.text);
                            setState(() { elements.add(newEl); selectedId = newEl.id; });
                          }
                        }
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Add to design', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ==== "ADD NEW" GRID MODAL ====
  void showAddNewModal() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15,
                children: [
                  _buildGridItem(Icons.image, 'Gallery Pic', Colors.blue.shade100, Colors.blue),
                  _buildGridItem(Icons.collections, 'Stock Images', Colors.indigo.shade100, Colors.indigo),
                  _buildGridItem(Icons.folder, 'My Folder', Colors.teal.shade100, Colors.teal),
                  _buildGridItem(Icons.text_fields, 'Add Text', Colors.orange.shade100, Colors.orange, () {
                    Navigator.pop(context);
                    _showTextComposerDialog();
                  }),
                  _buildGridItem(Icons.play_circle_outline, 'Video', Colors.pink.shade100, Colors.pink),
                  _buildGridItem(Icons.music_note, 'Audio', Colors.green.shade100, Colors.green),
                  _buildGridItem(Icons.auto_awesome, 'AI Images', Colors.purple.shade100, Colors.purple),
                  _buildGridItem(Icons.build, 'Tools', Colors.grey.shade300, Colors.grey.shade800),
                  _buildGridItem(Icons.border_outer, 'Borders', Colors.amber.shade100, Colors.amber.shade800),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, Color bgColor, Color iconColor, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ==== ACTIONS ====
  void deleteSelected() {
    if (selectedId != null) setState(() { elements.removeWhere((e) => e.id == selectedId); selectedId = null; });
  }

  void duplicateSelected() {
    if (selectedId != null) {
      DesignElement sel = elements.firstWhere((e) => e.id == selectedId);
      setState(() {
        var newEl = sel.clone()..id = Random().nextInt(10000).toString()..x += 20..y += 20;
        elements.add(newEl);
        selectedId = newEl.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = selectedId != null;
    DesignElement? sel;
    if (hasSelection) sel = elements.firstWhere((e) => e.id == selectedId);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.undo, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.redo, color: Colors.black), onPressed: () {}),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text('Save Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      
      body: GestureDetector(
        onTap: () => setState(() => selectedId = null), // Click outside to deselect
        child: Center(
          child: AspectRatio(
            aspectRatio: 1 / 1.414,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: pageColor, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Stack(
                clipBehavior: Clip.none,
                children: elements.map((e) {
                  bool isSel = e.id == selectedId;
                  List<Shadow> shadows = [];
                  if (e.hasShadow) shadows.add(const Shadow(color: Colors.black45, offset: Offset(3, 3), blurRadius: 5));
                  if (e.hasStroke) shadows.addAll([const Shadow(color: Colors.white, offset: Offset(-1.5, -1.5)), const Shadow(color: Colors.white, offset: Offset(1.5, 1.5))]);

                  Widget textWidget = Text(
                    e.content,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: e.fontFamily, fontSize: e.fontSize, color: e.textColor, fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal, shadows: shadows),
                  );

                  return Positioned(
                    left: e.x, top: e.y,
                    child: GestureDetector(
                      onTap: () => setState(() => selectedId = e.id),
                      onPanUpdate: (d) => setState(() { selectedId = e.id; e.x += d.delta.dx; e.y += d.delta.dy; }),
                      child: isSel 
                        // 🔥 DEMO VIDEO WALA SELECTION BOX
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // The Text with Purple Border
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5)),
                                  child: textWidget,
                                ),
                                // Rotate Handle (Top)
                                const Positioned(
                                  top: -20, left: 0, right: 0,
                                  child: Center(child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.refresh, size: 14, color: Colors.black))),
                                ),
                                // Resize Handle (Bottom Right)
                                Positioned(
                                  bottom: -5, right: -5,
                                  child: Container(width: 15, height: 15, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFF8B5CF6)), shape: BoxShape.circle)),
                                ),
                                // Floating Mini Toolbar (Bottom)
                                Positioned(
                                  bottom: -45, left: 0, right: 0,
                                  child: Center(
                                    child: Material(
                                      elevation: 4, borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.open_with, size: 20, color: Colors.black54),
                                            const SizedBox(width: 15),
                                            InkWell(onTap: duplicateSelected, child: const Icon(Icons.copy, size: 20, color: Colors.black54)),
                                            const SizedBox(width: 15),
                                            InkWell(onTap: deleteSelected, child: const Icon(Icons.delete_outline, size: 20, color: Colors.black54)),
                                            const SizedBox(width: 15),
                                            const Icon(Icons.menu, size: 20, color: Colors.black54),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(padding: const EdgeInsets.all(25), child: textWidget),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(child: Container(color: Colors.white, child: hasSelection ? _buildSelectedToolBar(sel) : _buildDefaultBottomBar())),
    );
  }

  // ==== BOTTOM TOOLBARS ====
  Widget _buildDefaultBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // ADD NEW Purple Box with X
          InkWell(
            onTap: showAddNewModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(15)),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.close, color: Color(0xFF8B5CF6), size: 28), SizedBox(height: 2), Text('ADD NEW', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold))]),
            ),
          ),
          _buildToolBtn(Icons.aspect_ratio, 'Resize Paper'),
          _buildToolBtn(Icons.layers_clear, 'Transparent BG'),
          _buildToolBtn(Icons.format_color_fill, 'BG Color', () => setState(() => pageColor = pageColor == Colors.white ? Colors.amber.shade100 : Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSelectedToolBar(DesignElement? sel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sub Toolbar (Scrollable)
        Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 10),
                _buildToolBtn(Icons.delete_outline, 'Delete', deleteSelected),
                _buildToolBtn(Icons.text_fields, 'Size', () => setState(() => sel!.fontSize = sel.fontSize == 45 ? 65 : 45)),
                _buildToolBtn(Icons.border_color, 'Stroke', () => setState(() => sel!.hasStroke = !sel.hasStroke)),
                _buildToolBtn(Icons.brightness_6, 'Shadow', () => setState(() => sel!.hasShadow = !sel.hasShadow)),
                _buildToolBtn(Icons.copy, 'Duplicate', duplicateSelected),
                _buildToolBtn(Icons.opacity, 'Opacity'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Main Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // DESELECT Button
              InkWell(
                onTap: () => setState(() => selectedId = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5CF6)), borderRadius: BorderRadius.circular(20)),
                  child: Row(children: const [Icon(Icons.remove_circle_outline, color: Color(0xFF8B5CF6), size: 18), SizedBox(width: 5), Text('DESELECT', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12))]),
                ),
              ),
              const Expanded(child: SizedBox()),
              _buildToolBtn(Icons.edit, 'Edit', () => _showTextComposerDialog(existingElement: sel)),
              _buildToolBtn(Icons.font_download, 'Font'),
              _buildToolBtn(Icons.palette, 'Color', () => setState(() => sel!.textColor = sel.textColor == Colors.black ? Colors.red : Colors.black)),
              _buildToolBtn(Icons.gradient, 'Gradient'),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildToolBtn(IconData icon, String label, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.grey.shade700, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700))]),
      ),
    );
  }
}
