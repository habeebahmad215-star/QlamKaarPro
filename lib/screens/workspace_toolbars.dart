import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/design_models.dart';
import 'workspace_controller.dart';
import 'workspace_modals.dart';

class WorkspaceToolbars {
  static Widget buildTopToolBtn(BuildContext context, IconData icon, String label, VoidCallback? onTap, {Color color = const Color(0xFF1E293B)}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(icon, size: 22, color: color), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)) ])),
    );
  }

  static Widget buildToolBtn(BuildContext context, IconData icon, String label, [VoidCallback? onTap, Color? color]) { 
    Color c = color ?? Colors.black87;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: Container(width: 54, margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2), decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.12), width: 0.8)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20, color: c), const SizedBox(height: 4), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w800))]))
    ); 
  }

  static Widget buildDefaultBottomBar(BuildContext context, WorkspaceController ctrl, WorkspaceModals modals) {
    return Container(
      height: 140, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: [
        InkWell(onTap: () => modals.showAddNewModal(context), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: Colors.white))),
        const SizedBox(width: 8), Container(width: 1, height: 40, color: Colors.grey.shade300), const SizedBox(width: 4),
        Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: [
          buildToolBtn(context, Icons.grid_on, 'Grid', () { ctrl.showGrid = !ctrl.showGrid; ctrl.triggerUpdate(); }), 
          buildToolBtn(context, Icons.aspect_ratio, 'Resize', () => modals.showResizeModal(context)), 
          buildToolBtn(context, Icons.image, 'BG Image', () => modals.setCanvasBackground(context)),
          buildToolBtn(context, Icons.format_color_fill, 'BG Color', () => modals.showCanvasBgColorModal(context)),
          buildToolBtn(context, Icons.gradient, 'BG Gradient', () => modals.showCanvasBgGradientModal(context)),
          buildToolBtn(context, Icons.layers_clear, 'Clear BG', () { ctrl.saveState(); ctrl.pageColor = Colors.white; ctrl.bgImageBytes = null; ctrl.bgGradient = null; ctrl.triggerUpdate(); }),
        ]))),
      ]),
    );
  }

  static Widget buildSelectedToolBar(BuildContext context, WorkspaceController ctrl, WorkspaceModals modals, DesignElement sel) {
    List<Widget> topRow = []; List<Widget> bottomRow = [];

    if (sel.isText) {
      topRow.add(buildToolBtn(context, Icons.delete_outline_rounded, 'Delete', ctrl.deleteSelected, Colors.red));
      topRow.add(buildToolBtn(context, Icons.text_fields_rounded, 'Size', () => modals.showSizeSliderModal(context, sel)));
      topRow.add(buildToolBtn(context, Icons.format_paint_rounded, 'Word Style', () => modals.showMultiStyleModal(context, sel, ctrl.availableFontsData), const Color(0xFF10B981)));
      topRow.add(buildToolBtn(context, Icons.border_color_rounded, 'Stroke', () => modals.showAdvancedStrokeModal(context, sel)));
      topRow.add(buildToolBtn(context, Icons.brightness_6_rounded, 'Shadow', () => modals.showAdvancedShadowModal(context, sel)));
      topRow.add(buildToolBtn(context, Icons.copy_rounded, 'Duplicate', ctrl.duplicateSelected, Colors.blue));
      topRow.add(buildToolBtn(context, Icons.opacity_rounded, 'Opacity', () => modals.showOpacityModal(context, sel)));
      topRow.add(buildToolBtn(context, Icons.content_copy_rounded, 'Copy', () { Clipboard.setData(ClipboardData(text: sel.content)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text Copied!'))); }));
      topRow.add(buildToolBtn(context, Icons.flip_rounded, 'Flip H', () { ctrl.saveState(); sel.flipX = !sel.flipX; ctrl.triggerUpdate(); }));
      topRow.add(buildToolBtn(context, Icons.flip_camera_android_rounded, 'Flip V', () { ctrl.saveState(); sel.flipY = !sel.flipY; ctrl.triggerUpdate(); }));
      topRow.add(buildToolBtn(context, Icons.open_with_rounded, 'Move', () => modals.showMoveModal(context, sel)));
      topRow.add(buildToolBtn(context, Icons.lock_outline_rounded, 'Lock', () { ctrl.saveState(); sel.isLocked = true; ctrl.selectedId = null; ctrl.triggerUpdate(); }, Colors.orange));

      bottomRow.add(buildToolBtn(context, Icons.close_rounded, 'Deselect', () { ctrl.selectedId = null; ctrl.triggerUpdate(); }, Colors.redAccent));
      bottomRow.add(buildToolBtn(context, Icons.edit_rounded, 'Edit', () => modals.showTextComposerDialog(context, existingElement: sel)));
      bottomRow.add(buildToolBtn(context, Icons.font_download_rounded, 'Font', () => modals.showFontPickerModal(context, sel, ctrl.availableFontsData, ctrl.customFonts)));
      bottomRow.add(buildToolBtn(context, Icons.palette_rounded, 'Colour', () => modals.showColorPickerModal(context, sel), const Color(0xFF8B5CF6)));
      bottomRow.add(buildToolBtn(context, Icons.gradient_rounded, 'Gradient', () => modals.showGradientPickerModal(context, sel)));
      bottomRow.add(buildToolBtn(context, Icons.format_bold_rounded, 'Bold', () { ctrl.saveState(); sel.isBold = !sel.isBold; ctrl.triggerUpdate(); }));
      bottomRow.add(buildToolBtn(context, Icons.height_rounded, 'Spacing', () => modals.showSpacingModal(context, sel)));
      bottomRow.add(buildToolBtn(context, Icons.format_color_fill_rounded, 'Text BG', () => modals.showTextBgPickerModal(context, sel)));
      bottomRow.add(buildToolBtn(context, Icons.auto_awesome_rounded, 'Effect', () => modals.showTextEffectsModal(context, sel), const Color(0xFF10B981)));
      bottomRow.add(buildToolBtn(context, Icons.format_align_center_rounded, 'Align', () => modals.toggleAlignment(context, sel)));
      bottomRow.add(buildToolBtn(context, Icons.more_horiz_rounded, 'More', () => modals.showMoreOptionsModal(context, sel), Colors.grey.shade800));
    } else if (sel.isBorder) {
      topRow.add(buildToolBtn(context, Icons.close_rounded, 'Deselect', () { ctrl.selectedId = null; ctrl.triggerUpdate(); }, Colors.redAccent));
      topRow.add(buildToolBtn(context, Icons.fullscreen_rounded, 'Fit Page', () => modals.fitBorderToPage(context, sel), const Color(0xFF10B981)));
      topRow.add(buildToolBtn(context, Icons.straighten_rounded, 'Size', () => modals.showElementSizeModal(context, sel), const Color(0xFF10B981)));
      topRow.add(buildToolBtn(context, Icons.palette_rounded, 'Colour', () => modals.showColorPickerModal(context, sel), const Color(0xFF8B5CF6)));
      topRow.add(buildToolBtn(context, Icons.line_weight_rounded, 'Setup', () => modals.showBorderSettingsModal(context, sel)));
      topRow.add(buildToolBtn(context, Icons.opacity_rounded, 'Opacity', () => modals.showOpacityModal(context, sel)));
      topRow.add(buildToolBtn(context, Icons.copy_rounded, 'Duplicate', ctrl.duplicateSelected, Colors.blue));
      topRow.add(buildToolBtn(context, Icons.delete_outline_rounded, 'Delete', ctrl.deleteSelected, Colors.red));

      bottomRow.add(buildToolBtn(context, Icons.center_focus_strong_rounded, 'Position', () => modals.showAlignmentModal(context, sel)));
      bottomRow.add(buildToolBtn(context, Icons.open_with_rounded, 'Move', () => modals.showMoveModal(context, sel)));
      bottomRow.add(buildToolBtn(context, Icons.arrow_upward_rounded, 'Bring Fwd', () => ctrl.bringForward()));
      bottomRow.add(buildToolBtn(context, Icons.arrow_downward_rounded, 'Send Bwd', () => ctrl.sendBackward()));
    } else {
      topRow.add(buildToolBtn(context, Icons.close_rounded, 'Deselect', () { ctrl.selectedId = null; ctrl.triggerUpdate(); }, Colors.redAccent));
      if (sel.isTable) topRow.add(buildToolBtn(context, Icons.table_rows_rounded, 'Edit Table', () => modals.showTableEditorModal(context, sel), const Color(0xFF10B981)));
      if (sel.isTable) topRow.add(buildToolBtn(context, Icons.font_download_rounded, 'Font', () => modals.showFontPickerModal(context, sel, ctrl.availableFontsData, ctrl.customFonts)));
      if (sel.isTable) topRow.add(buildToolBtn(context, Icons.text_fields_rounded, 'Size', () => modals.showSizeSliderModal(context, sel)));
      if (!sel.isTable) topRow.add(buildToolBtn(context, Icons.straighten_rounded, 'Size', () => modals.showElementSizeModal(context, sel), const Color(0xFF10B981)));
      
      topRow.add(buildToolBtn(context, Icons.palette_rounded, 'Colour', () => modals.showColorPickerModal(context, sel), const Color(0xFF8B5CF6)));
      topRow.add(buildToolBtn(context, Icons.copy_rounded, 'Duplicate', ctrl.duplicateSelected, Colors.blue));
      topRow.add(buildToolBtn(context, Icons.delete_outline_rounded, 'Delete', ctrl.deleteSelected, Colors.red));

      if (!sel.isTable) bottomRow.add(buildToolBtn(context, Icons.border_color_rounded, 'Stroke', () => modals.showAdvancedStrokeModal(context, sel)));
      if (!sel.isTable) bottomRow.add(buildToolBtn(context, Icons.brightness_6_rounded, 'Shadow', () => modals.showAdvancedShadowModal(context, sel)));
      if (sel.imageBytes != null && !sel.isTinted) bottomRow.add(buildToolBtn(context, Icons.photo_filter_rounded, 'Filters', () => modals.showImageFiltersModal(context, sel)));
      if (sel.imageBytes != null) bottomRow.add(buildToolBtn(context, Icons.crop_rounded, 'Crop', () => modals.showShapeClipModal(context, sel)));
      bottomRow.add(buildToolBtn(context, Icons.more_horiz_rounded, 'More', () => modals.showMoreOptionsModal(context, sel), Colors.grey.shade800));
    }

    return Container(
      height: 140, color: Colors.white, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: topRow)),
          const SizedBox(height: 6),
          SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: bottomRow)),
        ],
      ),
    );
  }
}
