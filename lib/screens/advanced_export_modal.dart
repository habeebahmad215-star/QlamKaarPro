import 'package:flutter/material.dart';

class AdvancedExportModal extends StatefulWidget {
  final double currentCanvasW;
  final double currentCanvasH;
  final Function(String format, String fileName, double pixelRatio) onExport;

  const AdvancedExportModal({
    Key? key,
    required this.currentCanvasW,
    required this.currentCanvasH,
    required this.onExport,
  }) : super(key: key);

  @override
  State<AdvancedExportModal> createState() => _AdvancedExportModalState();
}

class _AdvancedExportModalState extends State<AdvancedExportModal> {
  late TextEditingController _nameController;
  String _selectedFormat = 'JPG';
  late double _currentWidth;
  late double _currentHeight;
  
  // Safe limit taaki 8000px par low-end mobile crash na ho
  final double _maxWidth = 4000.0; 

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Qalamkaar_Design');
    _currentWidth = widget.currentCanvasW > 0 ? widget.currentCanvasW : 1000;
    _currentHeight = widget.currentCanvasH > 0 ? widget.currentCanvasH : 1000;
    _applyPreset('Print'); // PDF ke liye by default High Quality (Print) set rakha hai
  }

  // Preset Buttons Logic
  void _applyPreset(String preset) {
    double targetW = widget.currentCanvasW;
    if (preset == 'Low') targetW = 500;
    else if (preset == 'Social') targetW = 1080;
    else if (preset == 'Print') targetW = 3000; // InPage jaisi sharp quality ke liye

    if (targetW > _maxWidth) targetW = _maxWidth;

    double ratio = targetW / widget.currentCanvasW;
    setState(() {
      _currentWidth = targetW;
      _currentHeight = widget.currentCanvasH * ratio;
    });
  }

  // Slider Logic
  void _onSliderChanged(double val) {
    setState(() {
      _currentWidth = val;
      _currentHeight = widget.currentCanvasH * (val / widget.currentCanvasW);
    });
  }

  Widget _buildFormatOption(String title, String subtitle, String format, IconData icon) {
    bool isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent, width: 1.5)
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF8B5CF6) : Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF8B5CF6) : Colors.black87)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 20)
          ],
        ),
      ),
    );
  }

  Widget _buildPresetBtn(String label, String res, String preset) {
    return InkWell(
      onTap: () => _applyPreset(preset),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(res, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double currentPixelRatio = _currentWidth / widget.currentCanvasW;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Save Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              children: [
                const Text('FILE NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.description_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0)
                  ),
                ),
                const SizedBox(height: 20),

                const Text('FILE TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                _buildFormatOption('JPG', 'Best for sharing', 'JPG', Icons.image),
                _buildFormatOption('PNG', 'Best for complex images', 'PNG', Icons.layers_clear),
                // CRASH WALA VECTOR BUTTON HATA DIYA, AB SIRF ULTRA-HD PDF HAI
                _buildFormatOption('Ultra HD Print PDF', 'InPage jaisi No-Blur Quality', 'PDF', Icons.picture_as_pdf),
                
                const SizedBox(height: 20),

                const Text('QUALITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildPresetBtn('Low Res', '500px', 'Low')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildPresetBtn('Social', '1080px', 'Social')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildPresetBtn('Print', '3000px', 'Print')),
                  ],
                ),

                const SizedBox(height: 20),

                const Text('CUSTOM SIZE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                      child: Text('${_currentWidth.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('X', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                      child: Text('${_currentHeight.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    const Text('px', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))
                  ],
                ),
                const SizedBox(height: 10),
                Slider(
                  value: _currentWidth.clamp(100.0, _maxWidth),
                  min: 100.0,
                  max: _maxWidth,
                  activeColor: const Color(0xFF8B5CF6),
                  onChanged: _onSliderChanged,
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0
                    ),
                    onPressed: () {
                      widget.onExport(_selectedFormat, _nameController.text, currentPixelRatio);
                    },
                    icon: const Icon(Icons.save_alt, color: Colors.white, size: 20),
                    label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
