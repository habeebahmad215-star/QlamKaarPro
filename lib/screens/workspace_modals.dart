import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:async';
import '../models/design_models.dart';
import '../utils/constants.dart';
import 'workspace_components.dart';

mixin WorkspaceModals<T extends StatefulWidget> on State<T> {
  List<DesignElement> get elements;
  set elements(List<DesignElement> val);
  
  String? get selectedId;
  set selectedId(String? val);

  double get currentCanvasW;
  double get currentCanvasH;

  Map<String, Map<int, Map<String, dynamic>>> get textMultiStyles;
  set textMultiStyles(Map<String, Map<int, Map<String, dynamic>>> val);
  
  List<DesignPage> get pages;
  set pages(List<DesignPage> val);

  int get currentPageIndex;
  set currentPageIndex(int val);

  String get activeToolbarMenu;
  set activeToolbarMenu(String val);

  void triggerCanvasUpdate();
  void saveState();

  Widget buildGlassContainer(BuildContext context, {required Widget child, required double height, EdgeInsetsGeometry? padding}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: -5)]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  double getElWidth(DesignElement e) {
    if (e.isTable) return e.width > 80 ? e.width : 300;
    if (e.isBorder) return e.width > 50 ? e.width : 200; 
    return e.width > 80 ? e.width : 80;
  }

  double getElHeight(DesignElement e) {
    if (e.isTable) return e.height > 30 ? e.height : 150;
    if (e.isBorder) return e.height > 50 ? e.height : 200; 
    if (!e.isText && e.height > 20) return e.height;
    if (e.isShape) return 90;
    if (e.isText) {
      if (e.textCurveRadius != 0) {
        return e.textCurveRadius.abs() * 2.5 + 20;
      }
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: e.content.isEmpty ? 'Text' : e.content, 
          style: TextStyle(
            fontFamily: e.fontFamily, 
            fontSize: e.fontSize, 
            letterSpacing: e.letterSpacing, 
            wordSpacing: e.wordSpacing, 
            height: e.lineHeight,
            fontWeight: e.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: e.isItalic ? FontStyle.italic : FontStyle.normal,
          )
        ),
        textAlign: e.textAlign,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: e.width > 80 ? e.width : 80);
      
      return textPainter.size.height + (e.hasShadow ? e.shadowBlur * 2 : 0) + (e.hasStroke ? e.strokeWidth * 2 : 0) + 10;
    }
    return 150;
  }

  bool isRTLText(String text) {
    if (text.isEmpty) return false;
    int char = text.codeUnitAt(0);
    return (char >= 0x0590 && char <= 0x06FF);
  }

  void showPoetryLibrary(TextEditingController textController) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return buildGlassContainer(
          context,
          height: MediaQuery.of(context).size.height * 0.65,
          child: DefaultTabController(
            length: AppConstants.urduPoetryLibrary.keys.length,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Urdu Library اقوال / شاعری', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context))
                  ]
                ),
                TabBar(
                  isScrollable: true,
                  labelColor: const Color(0xFF8B5CF6),
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: const Color(0xFF8B5CF6),
                  tabs: AppConstants.urduPoetryLibrary.keys.map((k) => Tab(text: k)).toList()
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: AppConstants.urduPoetryLibrary.keys.map((category) {
                      return ListView.builder(
                        itemCount: AppConstants.urduPoetryLibrary[category]!.length,
                        itemBuilder: (context, index) {
                          String text = AppConstants.urduPoetryLibrary[category]![index];
                          return Card(
                            color: Colors.white.withOpacity(0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.white.withOpacity(0.8)), 
                              borderRadius: BorderRadius.circular(10)
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(
                                text, 
                                textDirection: TextDirection.rtl, 
                                textAlign: TextAlign.center, 
                                style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 16)
                              ),
                              onTap: () { 
                                int start = textController.selection.start;
                                int end = textController.selection.end;
                                if (start < 0 || end < 0) {
                                  textController.text += text;
                                  textController.selection = TextSelection.collapsed(offset: textController.text.length);
                                } else {
                                  String newText = textController.text.replaceRange(start, end, text);
                                  textController.value = TextEditingValue(
                                    text: newText,
                                    selection: TextSelection.collapsed(offset: start + text.length),
                                  );
                                }
                                Navigator.pop(context); 
                              }
                            )
                          );
                        }
                      );
                    }).toList()
                  )
                )
              ]
            )
          )
        );
      }
    );
  }

  void showTashkeelModal(TextEditingController controller) {
    final List<String> tashkeelList = ['َ', 'ِ', 'ُ', 'ً', 'ٍ', 'ٌ', 'ّ', 'ْ', 'ٓ', 'ٰ', 'ٖ', 'ٗ', 'ۖ', 'ۗ', 'ۘ', 'ۙ', 'ۚ'];
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return buildGlassContainer(
          context,
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tashkeel & Symbols اعراب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context))
                ]
              ),
              const Divider(color: Colors.black12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6, 
                    crossAxisSpacing: 8, 
                    mainAxisSpacing: 8
                  ),
                  itemCount: tashkeelList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () { 
                        int start = controller.selection.start;
                        int end = controller.selection.end;
                        String char = tashkeelList[index];
                        if (start < 0 || end < 0) {
                          controller.text += char;
                          controller.selection = TextSelection.collapsed(offset: controller.text.length);
                        } else {
                          String newText = controller.text.replaceRange(start, end, char);
                          controller.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: start + char.length),
                          );
                        }
                        Navigator.pop(context); 
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6), 
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white)
                        ),
                        alignment: Alignment.center,
                        child: Text(tashkeelList[index], style: const TextStyle(fontSize: 20, fontFamily: 'JameelNoori'))
                      )
                    );
                  }
                )
              )
            ]
          )
        );
      }
    );
  }

  void showTextComposerDialog({DesignElement? existingElement}) {
    TextEditingController controller = TextEditingController(text: existingElement?.content ?? '');
    bool isRTL = existingElement?.textAlign == TextAlign.right ? true : (existingElement?.textAlign == TextAlign.center ? true : false);

    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return buildGlassContainer(
              context,
              height: MediaQuery.of(context).size.height * 0.70,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => isRTL = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: !isRTL ? Colors.white : Colors.transparent, 
                              borderRadius: BorderRadius.circular(25), 
                              boxShadow: !isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []
                            ),
                            child: Text('English (LTR)', style: TextStyle(fontSize: 12, fontWeight: !isRTL ? FontWeight.bold : FontWeight.normal, color: !isRTL ? Colors.black : Colors.black54))
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setModalState(() => isRTL = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isRTL ? Colors.white : Colors.transparent, 
                              borderRadius: BorderRadius.circular(25), 
                              boxShadow: isRTL ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []
                            ),
                            child: Text('اردو (RTL)', style: TextStyle(fontSize: 12, fontWeight: isRTL ? FontWeight.bold : FontWeight.normal, color: isRTL ? Colors.black : Colors.black54))
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6), 
                        border: Border.all(color: Colors.white), 
                        borderRadius: BorderRadius.circular(15)
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: null,
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(fontSize: 18), 
                        decoration: InputDecoration(
                          border: InputBorder.none, 
                          hintText: isRTL ? 'یہاں لکھیں...' : 'Type here...'
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildComposerTool(Icons.paste, 'Paste', () async { 
                        ClipboardData? data = await Clipboard.getData('text/plain'); 
                        if(data != null && data.text != null) { 
                          int start = controller.selection.start;
                          int end = controller.selection.end;
                          String textToInsert = data.text!;
                          if (start < 0 || end < 0) {
                            controller.text += textToInsert;
                            controller.selection = TextSelection.collapsed(offset: controller.text.length);
                          } else {
                            String newText = controller.text.replaceRange(start, end, textToInsert);
                            controller.value = TextEditingValue(
                              text: newText,
                              selection: TextSelection.collapsed(offset: start + textToInsert.length),
                            );
                          }
                        } 
                      }),
                      _buildComposerTool(Icons.delete_outline, 'Clear', () => controller.clear()),
                      _buildComposerTool(Icons.auto_stories, 'شاعری', () => showPoetryLibrary(controller)),
                      _buildComposerTool(Icons.format_quote, 'اعراب', () => showTashkeelModal(controller)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 1, 
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12), 
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ), 
                          onPressed: () {
                            controller.dispose();
                            Navigator.pop(context);
                          }, 
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87))
                        )
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2, 
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6), 
                            padding: const EdgeInsets.symmetric(vertical: 12), 
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: () { 
                            if (controller.text.isNotEmpty) { 
                              saveState(); 
                              double calcW = (controller.text.length * 15.0) + 40; 
                              if(calcW > MediaQuery.of(context).size.width - 60) calcW = MediaQuery.of(context).size.width - 60;
                              if(calcW < 80) calcW = 80;
                              if (existingElement != null) { 
                                setState(() { 
                                  existingElement.content = controller.text; 
                                  existingElement.textAlign = isRTL ? TextAlign.right : TextAlign.left; 
                                  textMultiStyles.remove(existingElement.id);
                                }); 
                              } else { 
                                var newEl = DesignElement(
                                  id: Random().nextInt(10000).toString(), 
                                  x: 40, y: 100, 
                                  content: controller.text, 
                                  isText: true, 
                                  width: calcW, 
                                  height: 100, 
                                  fontSize: 30
                                );
                                newEl.textAlign = isRTL ? TextAlign.right : TextAlign.left; 
                                setState(() { 
                                  elements.add(newEl); 
                                  selectedId = newEl.id; 
                                  activeToolbarMenu = 'main'; 
                                }); 
                              } 
                              triggerCanvasUpdate(); 
                              controller.dispose();
                              Navigator.pop(context); 
                            } 
                          }, 
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18), 
                          label: const Text('Add to Design', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                        )
                      )
                    ],
                  )
                ],
              )
            );
          }
        );
      }
    ).whenComplete(() {
      try { controller.dispose(); } catch (e) {}
    });
  }

  Widget _buildComposerTool(IconData icon, String label, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap, 
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6)), 
          const SizedBox(height: 5), 
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
        ]
      )
    );
  }
    // 🔥 ADVANCED PRO MOVE TOOL
  void showMoveModal(DesignElement sel) {
    double stepSize = 5.0; 

    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent, 
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            void move(double dx, double dy) {
              setState(() {
                double ew = getElWidth(sel);
                double eh = getElHeight(sel);
                
                double newX = sel.x + dx;
                double newY = sel.y + dy;
                
                newX = newX.clamp(-ew + 30.0, currentCanvasW - 30.0);
                newY = newY.clamp(-eh + 30.0, currentCanvasH - 30.0);
                
                double actualDx = newX - sel.x;
                double actualDy = newY - sel.y;
                
                sel.x = newX;
                sel.y = newY;

                if (sel.groupId != null) {
                  for (var other in elements) {
                    if (other.id != sel.id && other.groupId == sel.groupId && !other.isLocked) {
                      other.x += actualDx;
                      other.y += actualDy;
                    }
                  }
                }
              });
              setModalState((){});
              triggerCanvasUpdate();
            }

            Widget buildDPadBtn(IconData icon, double dxMultiplier, double dyMultiplier, {bool isPrimary = false}) {
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  saveState(); 
                  move(dxMultiplier * stepSize, dyMultiplier * stepSize);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isPrimary ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isPrimary ? Colors.transparent : Colors.grey.shade300)
                  ),
                  child: Center(child: Icon(icon, size: 20, color: isPrimary ? Colors.white : Colors.black87)),
                ),
              );
            }

            Widget buildCompactInput(String label, double val, Function(double) onSubmit) {
              return Container(
                height: 28,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12)),
                child: Row(
                  children: [
                    Padding(padding: const EdgeInsets.only(left: 6), child: Text('$label:', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54))),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: val.toStringAsFixed(0))..selection = TextSelection.collapsed(offset: val.toStringAsFixed(0).length),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(bottom: 12)),
                        onSubmitted: (s) { if(double.tryParse(s) != null) onSubmit(double.parse(s)); },
                      )
                    )
                  ]
                )
              );
            }

            return buildGlassContainer(
              context,
              height: 200,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pro Nudge Tool', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                      IconButton(icon: const Icon(Icons.close, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const Divider(height: 10, color: Colors.black12),
                  
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(child: Row(children: [ Expanded(child: buildDPadBtn(Icons.north_west, -1, -1)), Expanded(child: buildDPadBtn(Icons.arrow_upward, 0, -1, isPrimary: true)), Expanded(child: buildDPadBtn(Icons.north_east, 1, -1)) ])),
                              Expanded(child: Row(children: [ 
                                Expanded(child: buildDPadBtn(Icons.arrow_back, -1, 0, isPrimary: true)), 
                                Expanded(
                                  child: InkWell(
                                    onTap: () { saveState(); setState(() { sel.x = (currentCanvasW / 2) - (getElWidth(sel) / 2); sel.y = (currentCanvasH / 2) - (getElHeight(sel) / 2); }); setModalState((){}); triggerCanvasUpdate(); },
                                    child: Container(margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)), child: const Icon(Icons.center_focus_strong, size: 18, color: Colors.blue))
                                  )
                                ), 
                                Expanded(child: buildDPadBtn(Icons.arrow_forward, 1, 0, isPrimary: true)) 
                              ])),
                              Expanded(child: Row(children: [ Expanded(child: buildDPadBtn(Icons.south_west, -1, 1)), Expanded(child: buildDPadBtn(Icons.arrow_downward, 0, 1, isPrimary: true)), Expanded(child: buildDPadBtn(Icons.south_east, 1, 1)) ])),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        Container(width: 1, color: Colors.black12),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.speed, size: 12, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  const Text('Speed:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                  const Spacer(),
                                  Text('${stepSize.toInt()} px', style: const TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                                ]
                              ),
                              SizedBox(
                                height: 35,
                                child: SliderTheme(
                                  data: SliderThemeData(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
                                  child: Slider(
                                    value: stepSize.clamp(1.0, 50.0),
                                    min: 1.0, max: 50.0,
                                    activeColor: const Color(0xFF8B5CF6),
                                    onChanged: (val) => setModalState(() => stepSize = val),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(child: buildCompactInput('X', sel.x, (val) { saveState(); setState(() => sel.x = val.clamp(-getElWidth(sel) + 30.0, currentCanvasW - 30.0)); setModalState((){}); triggerCanvasUpdate(); })),
                                  const SizedBox(width: 6),
                                  Expanded(child: buildCompactInput('Y', sel.y, (val) { saveState(); setState(() => sel.y = val.clamp(-getElHeight(sel) + 30.0, currentCanvasH - 30.0)); setModalState((){}); triggerCanvasUpdate(); })),
                                ]
                              )
                            ],
                          )
                        )
                      ],
                    )
                  )
                ],
              )
            );
          }
        );
      }
    );
  }

  void showPagesPanel() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return buildGlassContainer(
              context,
              height: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pages صفحات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context))
                    ]
                  ),
                  const Divider(color: Colors.black12),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        bool isCurrent = currentPageIndex == index;
                        return Card(
                          color: isCurrent ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.4),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: isCurrent ? const Color(0xFF8B5CF6) : Colors.transparent), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.description, color: isCurrent ? const Color(0xFF8B5CF6) : Colors.black54),
                            title: Text(pages[index].title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.blue, size: 18), 
                                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                  onPressed: () { setState(() { pages.add(DesignPage(title: '${pages[index].title} Copy', elements: pages[index].elements.map((e) => e.clone()).toList(), pageColor: pages[index].pageColor, bgGradient: pages[index].bgGradient, bgImageBytes: pages[index].bgImageBytes, canvasRatio: pages[index].canvasRatio)); }); setModalState((){}); }
                                ),
                                if(pages.length > 1) ...[
                                  const SizedBox(width: 15),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), 
                                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                    onPressed: () { setState(() { pages.removeAt(index); if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1; }); triggerCanvasUpdate(); setModalState((){}); }
                                  )
                                ]
                              ]
                            ),
                            onTap: () { setState(() { currentPageIndex = index; selectedId = null; }); triggerCanvasUpdate(); Navigator.pop(context); }
                          )
                        );
                      }
                    )
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () { setState(() { pages.add(DesignPage(title: 'Page ${pages.length + 1}', elements: [], pageColor: Colors.white)); }); setModalState((){}); },
                      child: const Text('Add New Page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  // 🔥 ADVANCED PRO LAYERS STUDIO (Drag & Drop + Grouping + Previews)
  void showLayersPanel() {
    Set<String> selectedForGroup = {};
    
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // Reverse list to match visual stacking (Top element in UI = Top element on Canvas)
            List<DesignElement> reversedElements = elements.reversed.toList();

            return buildGlassContainer(
              context,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header & Multi-Select Grouping Bar ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.layers, color: Color(0xFF1E293B)),
                          const SizedBox(width: 8),
                          const Text('Layers Studio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      Row(
                        children: [
                          if (selectedForGroup.length > 1)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10)), 
                              onPressed: () { 
                                saveState(); 
                                String gId = Random().nextInt(10000).toString(); 
                                setState(() { 
                                  for (var e in elements) { if (selectedForGroup.contains(e.id)) e.groupId = gId; } 
                                  selectedForGroup.clear(); 
                                }); 
                                triggerCanvasUpdate(); 
                                setModalState((){}); 
                              }, 
                              icon: const Icon(Icons.link, color: Colors.white, size: 14), 
                              label: const Text('Group', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                            ),
                          if (selectedForGroup.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10)), 
                              onPressed: () { 
                                saveState(); 
                                setState(() { 
                                  for (var e in elements) { if (selectedForGroup.contains(e.id)) e.groupId = null; } 
                                  selectedForGroup.clear(); 
                                }); 
                                triggerCanvasUpdate(); 
                                setModalState((){}); 
                              }, 
                              icon: const Icon(Icons.link_off, color: Colors.white, size: 14), 
                              label: const Text('Ungroup', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                            ),
                          ],
                          IconButton(icon: const Icon(Icons.close, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => Navigator.pop(context))
                        ]
                      )
                    ]
                  ),
                  const Divider(color: Colors.black12, height: 20),
                  
                  // --- Drag & Drop Reorderable List ---
                  Expanded(
                    child: reversedElements.isEmpty 
                      ? const Center(child: Text('Canvas is empty.', style: TextStyle(color: Colors.black54)))
                      : ReorderableListView.builder(
                          physics: const BouncingScrollPhysics(),
                          proxyDecorator: (child, index, animation) {
                            return Material(color: Colors.transparent, child: child); // Drag karte waqt background transparent
                          },
                          onReorder: (oldIndex, newIndex) {
                            saveState();
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              
                              // Convert reverse index to actual elements index
                              int actualOldIndex = elements.length - 1 - oldIndex;
                              int actualNewIndex = elements.length - 1 - newIndex;
                              
                              final DesignElement item = elements.removeAt(actualOldIndex);
                              elements.insert(actualNewIndex, item);
                            });
                            triggerCanvasUpdate();
                            setModalState((){});
                          },
                          itemCount: reversedElements.length,
                          itemBuilder: (context, index) {
                            DesignElement e = reversedElements[index];
                            bool isSel = selectedId == e.id;
                            bool isGroupChecked = selectedForGroup.contains(e.id);
                            
                            // Visual Preview Generator
                            Widget previewIcon;
                            if (e.isText) {
                               previewIcon = CircleAvatar(radius: 12, backgroundColor: e.textColor.withOpacity(0.2), child: Text("T", style: TextStyle(color: e.textColor, fontWeight: FontWeight.bold, fontSize: 12)));
                            } else if (e.imageBytes != null) {
                               previewIcon = ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.memory(e.imageBytes!, width: 24, height: 24, fit: BoxFit.cover));
                            } else {
                               previewIcon = Container(width: 24, height: 24, decoration: BoxDecoration(color: e.elementColor, borderRadius: BorderRadius.circular(e.isShape ? e.cornerRadius : 4), border: Border.all(color: Colors.black12)));
                            }

                            return Container(
                              key: ValueKey(e.id),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF8B5CF6).withOpacity(0.1) : (e.groupId != null ? Colors.blue.withOpacity(0.05) : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSel ? const Color(0xFF8B5CF6) : Colors.grey.shade200, width: isSel ? 1.5 : 1),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))]
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                
                                // Drag Handle (Left Side)
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.drag_indicator, color: Colors.black26, size: 20),
                                    Checkbox(
                                      value: isGroupChecked, 
                                      activeColor: const Color(0xFF8B5CF6), 
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) { setModalState((){ if(val == true) selectedForGroup.add(e.id); else selectedForGroup.remove(e.id); }); }
                                    ),
                                    previewIcon,
                                  ]
                                ),
                                
                                // Layer Title
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.isText ? e.content.replaceAll('\n', ' ') : (e.isBorder ? 'Border Element' : 'Graphic Element'), 
                                        maxLines: 1, overflow: TextOverflow.ellipsis, 
                                        style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.w500, fontSize: 13, color: isSel ? const Color(0xFF8B5CF6) : Colors.black87)
                                      )
                                    ),
                                    if (e.groupId != null) const Icon(Icons.link, size: 14, color: Colors.blue)
                                  ]
                                ),
                                
                                // One-Click Quick Actions (Right Side)
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30), 
                                      icon: Icon(e.isHidden ? Icons.visibility_off : Icons.visibility, size: 18, color: e.isHidden ? Colors.red : Colors.black45), 
                                      onPressed: () { saveState(); setState(() => e.isHidden = !e.isHidden); triggerCanvasUpdate(); setModalState((){}); }
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30), 
                                      icon: Icon(e.isLocked ? Icons.lock : Icons.lock_open, size: 18, color: e.isLocked ? Colors.orange : Colors.black45), 
                                      onPressed: () { saveState(); setState(() { e.isLocked = !e.isLocked; if(e.isLocked && selectedId == e.id) selectedId = null; }); triggerCanvasUpdate(); setModalState((){}); }
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30), 
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), 
                                      onPressed: () { 
                                        saveState(); 
                                        setState(() { 
                                          elements.removeWhere((item) => item.id == e.id); 
                                          if (selectedId == e.id) selectedId = null;
                                        }); 
                                        triggerCanvasUpdate(); 
                                        setModalState((){}); 
                                      }
                                    ),
                                  ]
                                ),
                                onTap: () { 
                                  if(!e.isLocked && !e.isHidden) { 
                                    setState(() => selectedId = e.id); 
                                    triggerCanvasUpdate(); 
                                    setModalState((){}); 
                                  } 
                                }
                              )
                            );
                          }
                        )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }
}
