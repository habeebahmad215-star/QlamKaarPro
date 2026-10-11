import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../models/design_models.dart';

class MarksheetStudioModal extends StatefulWidget {
  const MarksheetStudioModal({Key? key}) : super(key: key);

  @override
  State<MarksheetStudioModal> createState() => _MarksheetStudioModalState();
}

class _MarksheetStudioModalState extends State<MarksheetStudioModal> {
  final TextEditingController schoolCtrl = TextEditingController(text: 'مدرسہ دارالعلوم');
  final TextEditingController examCtrl = TextEditingController(text: 'سالانہ امتحانات 2026');
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController fatherCtrl = TextEditingController();
  final TextEditingController classCtrl = TextEditingController();
  final TextEditingController rollCtrl = TextEditingController();

  List<Map<String, TextEditingController>> subjects = [];

  @override
  void initState() {
    super.initState();
    // Default 4 Subjects
    _addSubject('قرآن مجید (یادداشت)', '100', '');
    _addSubject('صحت حروف لب و لہجہ', '100', '');
    _addSubject('تجوید عملی / قواعد', '100', '');
    _addSubject('دینیات / نماز', '100', '');
  }

  void _addSubject(String name, String total, String obtained) {
    subjects.add({
      'name': TextEditingController(text: name),
      'total': TextEditingController(text: total),
      'obtained': TextEditingController(text: obtained),
    });
    setState(() {});
  }

  void _generateMarksheet() {
    double cw = MediaQuery.of(context).size.width - 32; 
    double ch = cw * 1.414; // Perfect A4 Ratio
    
    int grandTotal = 0;
    int grandObtained = 0;
    
    List<List<String>> tableData = [
      ['مضمون', 'کل نمبر', 'حاصل کردہ']
    ];

    for (var sub in subjects) {
      int t = int.tryParse(sub['total']!.text) ?? 0;
      int o = int.tryParse(sub['obtained']!.text) ?? 0;
      grandTotal += t;
      grandObtained += o;
      
      String subName = "${sub['name']!.text}\u200F";
      tableData.add([subName, t.toString(), o.toString()]);
    }

    tableData.add(['\u200Fمیزان (Total)\u200F', grandTotal.toString(), grandObtained.toString()]);

    double percentage = grandTotal > 0 ? (grandObtained / grandTotal) * 100 : 0;
    String grade = _calculateGrade(percentage);

    List<DesignElement> elements = [];

    // --- Border ---
    elements.add(DesignElement(
      id: Random().nextInt(10000).toString(),
      x: cw * 0.03, y: cw * 0.03,
      content: 'Border', width: cw * 0.94, height: ch - (cw * 0.06),
      isText: false, isBorder: true, borderStyle: '0',
      elementColor: const Color(0xFFD4AF37), 
      strokeWidth: 3.0, cornerRadius: 0.0,
    ));

    // --- School Name ---
    elements.add(_createTextEl(schoolCtrl.text, cw * 0.05, ch * 0.05, cw * 0.9, cw * 0.08, true, const Color(0xFF1E293B)));

    // --- Exam Name ---
    elements.add(_createTextEl(examCtrl.text, cw * 0.05, ch * 0.13, cw * 0.9, cw * 0.045, false, const Color(0xFF8B5CF6)));

    // --- Marksheet Title ---
    elements.add(_createTextEl('مارک شیٹ / نتیجہ کارڈ', cw * 0.25, ch * 0.19, cw * 0.5, cw * 0.04, true, Colors.white, bgColor: const Color(0xFFD4AF37)));

    // --- Student Details ---
    double infoY1 = ch * 0.26;
    double infoY2 = ch * 0.30;

    var nameEl = _createTextEl("نام طالب علم: ${nameCtrl.text}", cw * 0.5, infoY1, cw * 0.45, cw * 0.035, false, Colors.black);
    nameEl.textAlign = TextAlign.right;
    elements.add(nameEl);

    var fatherEl = _createTextEl("ولدیت: ${fatherCtrl.text}", cw * 0.05, infoY1, cw * 0.45, cw * 0.035, false, Colors.black);
    fatherEl.textAlign = TextAlign.right;
    elements.add(fatherEl);

    var classEl = _createTextEl("درجہ: ${classCtrl.text}", cw * 0.5, infoY2, cw * 0.45, cw * 0.035, false, Colors.black);
    classEl.textAlign = TextAlign.right;
    elements.add(classEl);

    var rollEl = _createTextEl("رول نمبر: ${rollCtrl.text}", cw * 0.05, infoY2, cw * 0.45, cw * 0.035, false, Colors.black);
    rollEl.textAlign = TextAlign.right;
    elements.add(rollEl);

    // --- Marks Table ---
    double tableY = ch * 0.35;
    elements.add(DesignElement(
      id: Random().nextInt(10000).toString(),
      x: cw * 0.05, y: tableY,
      content: 'Table', isText: false, isTable: true,
      width: cw * 0.9, height: (tableData.length * 30).toDouble(),
      tableData: tableData,
      elementColor: const Color(0xFFD4AF37), textColor: Colors.black, fontFamily: 'JameelNoori'
    ));

    // --- Result Text ---
    double resultY = tableY + (tableData.length * 30).toDouble() + (ch * 0.03);
    String resultText = "کل فیصد : ${percentage.toStringAsFixed(1)}%\nحتمی گریڈ : $grade\u200F";
    var resEl = _createTextEl(resultText, cw * 0.05, resultY, cw * 0.9, cw * 0.045, true, Colors.black);
    resEl.textAlign = TextAlign.center;
    resEl.lineHeight = 1.8;
    elements.add(resEl);

    // --- Signature Lines ---
    double signY = ch * 0.88;
    elements.add(_createTextEl('دستخط مہتمم/پرنسپل', cw * 0.55, signY, cw * 0.4, cw * 0.035, false, Colors.black));
    elements.add(_createTextEl('دستخط ناظمِ امتحان', cw * 0.05, signY, cw * 0.4, cw * 0.035, false, Colors.black));

    Navigator.pop(context, elements);
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 80) return 'A+ (ممتاز)';
    if (percentage >= 70) return 'A (بہت اچھا)';
    if (percentage >= 60) return 'B (اچھا)';
    if (percentage >= 50) return 'C (مقبول)';
    if (percentage >= 40) return 'D (پاس)';
    return 'F (فیل)';
  }

  DesignElement _createTextEl(String text, double x, double y, double w, double size, bool isBold, Color color, {Color? bgColor}) {
    var el = DesignElement(
      id: Random().nextInt(10000).toString(),
      x: x, y: y, content: text,
      isText: true, width: w, height: size * 2.5, fontSize: size
    );
    el.fontFamily = 'JameelNoori';
    el.textColor = color;
    el.isBold = isBold;
    el.textAlign = TextAlign.center;
    if (bgColor != null) {
      el.textBgColor = bgColor;
      el.cornerRadius = 8.0;
    }
    return el;
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 KEYBOARD FIX: Yahan se screen bottom insets ko detect karegi
    double bottomKeyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      // Padding automatically utni badh jayegi jitna bada keyboard aayega
      padding: EdgeInsets.only(bottom: bottomKeyboardInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎓 Marksheet Studio', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                ]
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text('ادارے کی معلومات', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'JameelNoori', fontSize: 18, color: Colors.black54)),
                  _buildInput('ادارے کا نام', schoolCtrl),
                  _buildInput('امتحان کا نام / سال', examCtrl),
                  const Divider(),
                  const Text('طالب علم کی معلومات', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'JameelNoori', fontSize: 18, color: Colors.black54)),
                  Row(children: [Expanded(child: _buildInput('ولدیت', fatherCtrl)), const SizedBox(width: 10), Expanded(child: _buildInput('نام طالب علم', nameCtrl))]),
                  Row(children: [Expanded(child: _buildInput('رول نمبر', rollCtrl)), const SizedBox(width: 10), Expanded(child: _buildInput('درجہ / کلاس', classCtrl))]),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue, elevation: 0),
                        onPressed: () => _addSubject('نیا مضمون', '100', ''), 
                        icon: const Icon(Icons.add, size: 16), label: const Text('Add Subject')
                      ),
                      const Text('مضامین اور نمبرات', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'JameelNoori', fontSize: 18, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...subjects.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var sub = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(()=> subjects.removeAt(idx))),
                          Expanded(flex: 2, child: _buildCompactInput('حاصل کردہ', sub['obtained']!)),
                          const SizedBox(width: 5),
                          Expanded(flex: 2, child: _buildCompactInput('کل نمبر', sub['total']!)),
                          const SizedBox(width: 5),
                          Expanded(flex: 3, child: _buildCompactInput('مضمون', sub['name']!)),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20), // Bottom padding for better scrolling
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _generateMarksheet,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Generate Professional Marksheet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 16),
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10))
      ),
    );
  }

  Widget _buildCompactInput(String hint, TextEditingController ctrl) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center, textDirection: TextDirection.rtl,
        keyboardType: hint == 'مضمون' ? TextInputType.text : TextInputType.number,
        style: const TextStyle(fontFamily: 'JameelNoori', fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 10), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.all(8))
      ),
    );
  }
}
