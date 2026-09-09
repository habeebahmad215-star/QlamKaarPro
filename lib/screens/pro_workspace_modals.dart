part of 'pro_workspace_screen.dart';

extension ProWorkspaceBottomBars on _ProWorkspaceScreenState {
  
  Widget _buildDefaultBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          InkWell(onTap: showAddNewModal, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: Colors.white))),
          const SizedBox(width: 8),
          Container(width: 1, height: 40, color: Colors.grey.shade300), 
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToolBtn(Icons.grid_on, 'Grid', () { setState(() => _showGrid = !_showGrid); _triggerCanvasUpdate(); }), 
                  _buildToolBtn(Icons.aspect_ratio, 'Resize', _showResizeModal), 
                  _buildToolBtn(Icons.image, 'BG Image', _setCanvasBackground),
                  _buildToolBtn(Icons.format_color_fill, 'BG Color', _showCanvasBgColorModal),
                  _buildToolBtn(Icons.gradient, 'BG Gradient', _showCanvasBgGradientModal),
                  _buildToolBtn(Icons.layers_clear, 'Clear BG', () { saveState(); setState((){ pageColor = Colors.white; bgImageBytes = null; bgGradient = null; }); _triggerCanvasUpdate(); }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedToolBar(DesignElement sel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.grey.shade50, padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 10),
                if (sel.isText || sel.isTable) _buildToolBtn(Icons.text_fields, 'Size', () => showSizeSliderModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.height, 'Spacing', () => showSpacingModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.format_bold, 'Bold', () { saveState(); setState(() => sel.isBold = !sel.isBold); _triggerCanvasUpdate(); }),
                if (sel.isText) _buildToolBtn(Icons.format_color_fill, 'Text BG', () => _showTextBgPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.gradient, 'Gradient', () => _showGradientPickerModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.data_usage, 'Curve', () => _showCurveModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.texture, 'Texture', () => _addTextureToText(sel)),
                if (sel.isText && sel.textTextureBytes != null) _buildToolBtn(Icons.layers_clear, 'Clear Textr', () { saveState(); setState(() => sel.textTextureBytes = null); _triggerCanvasUpdate(); }),
                if (sel.isText) _buildToolBtn(Icons.format_align_left, 'Align Text', () => _toggleAlignment(sel)),
                _buildToolBtn(Icons.center_focus_strong, 'Position', () => _showAlignmentModal(sel)),
                if (sel.isText) _buildToolBtn(Icons.view_in_ar_outlined, '3D Block', () => _show3DBlockModal(sel)),
                if (sel.imageBytes != null || sel.isShape) _buildToolBtn(Icons.format_paint, 'Color', () => _showColorPickerModal(sel)),
                if (sel.imageBytes != null) _buildToolBtn(Icons.auto_awesome_motion, 'Blend', () => _showBlendModeModal(sel)),
                if (!sel.isBorder) _buildToolBtn(Icons.border_color, 'Stroke', () => _showAdvancedStrokeModal(sel)),
                if (!sel.isBorder && !sel.isTable) _buildToolBtn(Icons.brightness_6, 'Shadow', () => _showAdvancedShadowModal(sel)),
                if (!sel.isText && !sel.isBorder && !sel.isTable) _buildToolBtn(Icons.rounded_corner, 'Radius', () => _showRadiusModal(sel)),
                if (sel.imageBytes != null && !sel.isTinted) _buildToolBtn(Icons.photo_filter, 'Filters', () => _showImageFiltersModal(sel)),
                if (sel.imageBytes != null) _buildToolBtn(Icons.crop, 'Crop Shape', () => _showShapeClipModal(sel)),
                if (sel.isTable) _buildToolBtn(Icons.table_rows, 'Edit Table', () => _showTableEditorModal(sel)),
                _buildToolBtn(Icons.flip, 'Flip H', () { saveState(); setState(() => sel.flipX = !sel.flipX); _triggerCanvasUpdate(); }),
                _buildToolBtn(Icons.flip_camera_android, 'Flip V', () { saveState(); setState(() => sel.flipY = !sel.flipY); _triggerCanvasUpdate(); }),
                _buildToolBtn(Icons.opacity, 'Opacity', () { showModalBottomSheet(context: context, builder: (ctx) => Container(height: 150, padding: const EdgeInsets.all(20), child: Slider(value: sel.opacity, min: 0.0, max: 1.0, onChanged: (v){ setState(()=>sel.opacity=v); _triggerCanvasUpdate(); }))); }),
                _buildToolBtn(Icons.rotate_right, 'Rotate', () => showRotationModal(sel)), 
                _buildToolBtn(Icons.view_in_ar, 'Perspective', () => show3DModal(sel)), 
                _buildToolBtn(Icons.open_with, 'Nudge', () => showNudgeModal(sel)),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Yahan Delete, Duplicate aur Edit ko safely line mein lagaya gaya hai
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                InkWell(onTap: () { setState(() => selectedId = null); _triggerCanvasUpdate(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: const Text('Deselect', style: TextStyle(fontWeight: FontWeight.bold)))),
                const SizedBox(width: 15),
                _buildToolBtn(Icons.copy, 'Duplicate', duplicateSelected),
                _buildToolBtn(Icons.delete_outline, 'Delete', deleteSelected),
                const SizedBox(width: 15),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 15),
                if (sel.isText) _buildToolBtn(Icons.edit, 'Edit', () => _showTextComposerDialog(existingElement: sel)),
                if (sel.isText || sel.isTable) _buildToolBtn(Icons.font_download, 'Font', () => showFontPickerModal(sel)),
                if (sel.isText || sel.isBorder || sel.isShape || sel.isTinted || sel.isTable) _buildToolBtn(Icons.palette, 'Color', () => _showColorPickerModal(sel)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTopBtn(IconData icon, String label, [VoidCallback? onTap]) { 
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: Row(children: [Icon(icon, size: 16, color: Colors.black87), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))]))); 
  }
  
  Widget _buildToolBtn(IconData icon, String label, [VoidCallback? onTap]) { 
    return InkWell(onTap: onTap, child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 22, color: Colors.black87), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87))]))); 
  }
}
