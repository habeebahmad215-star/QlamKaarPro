import 'package:flutter/material.dart';
import '../models/design_models.dart';

class WorkspaceToolbars {
  static Widget buildTopToolBtn(BuildContext context, IconData icon, String label, VoidCallback? onTap, {Color color = const Color(0xFF1E293B)}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ 
            Icon(icon, size: 22, color: color), 
            const SizedBox(height: 2), 
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)) 
          ],
        ),
      ),
    );
  }

  static Widget buildToolBtn(BuildContext context, IconData icon, String label, [VoidCallback? onTap, Color? color]) { 
    Color c = color ?? Colors.black87;
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 54, 
        margin: const EdgeInsets.symmetric(horizontal: 3), 
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2), 
        decoration: BoxDecoration(
          color: c.withOpacity(0.06), 
          borderRadius: BorderRadius.circular(10), 
          border: Border.all(color: c.withOpacity(0.12), width: 0.8)
        ), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Icon(icon, size: 20, color: c), 
            const SizedBox(height: 4), 
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w800))
          ]
        )
      )
    ); 
  }

  static Widget buildDefaultBottomBar(
    BuildContext context, 
    VoidCallback showAddNewModal, 
    VoidCallback toggleGrid, 
    VoidCallback showResizeModal, 
    VoidCallback showBackgroundStudio, 
    VoidCallback addText,
    VoidCallback addGalleryImage,
    VoidCallback addShape,
  ) {
    return Container(
      height: 140, 
      alignment: Alignment.center, 
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          InkWell(
            onTap: showAddNewModal, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), 
              decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)), 
              child: const Icon(Icons.add, color: Colors.white)
            )
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, 
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  buildToolBtn(context, Icons.format_paint, 'Background', showBackgroundStudio, const Color(0xFF10B981)),
                  buildToolBtn(context, Icons.text_fields, 'Text', addText, Colors.orange),
                  buildToolBtn(context, Icons.image, 'Gallery', addGalleryImage, Colors.blue),
                  buildToolBtn(context, Icons.category, 'Shapes', addShape, Colors.pink),
                  buildToolBtn(context, Icons.grid_on, 'Grid', toggleGrid), 
                  buildToolBtn(context, Icons.aspect_ratio, 'Resize', showResizeModal), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 REMOVED POSITION BUTTON & MADE 'ALIGN' THE MASTER BUTTON 🔥
  static Widget buildAdvancedSelectedBar({
    required BuildContext context,
    required DesignElement sel,
    required Map<String, VoidCallback> actions,
  }) {
    List<Widget> topRow = [];
    List<Widget> bottomRow = [];

    Widget btn(IconData icon, String label, String actionKey, [Color? color]) {
      return buildToolBtn(context, icon, label, actions[actionKey], color);
    }

    if (sel.isText) {
      topRow.addAll([
        btn(Icons.close_rounded, 'Deselect', 'deselect', Colors.redAccent),
        btn(Icons.edit_rounded, 'Edit', 'edit', const Color(0xFF10B981)),
        btn(Icons.text_fields_rounded, 'Size', 'size'),
        btn(Icons.font_download_rounded, 'Font', 'font'),
        btn(Icons.format_paint_rounded, 'Word Style', 'wordStyle', const Color(0xFF10B981)),
        btn(Icons.palette_rounded, 'Color', 'color', const Color(0xFF8B5CF6)),
        btn(Icons.border_color_rounded, 'Stroke', 'stroke'),
        btn(Icons.brightness_6_rounded, 'Shadow', 'shadow'),
        btn(Icons.opacity_rounded, 'Opacity', 'opacity'),
        btn(Icons.lock_outline_rounded, 'Lock', 'lock', Colors.orange),
      ]);
      bottomRow.addAll([
        btn(Icons.delete_outline_rounded, 'Delete', 'delete', Colors.red),
        btn(Icons.copy_rounded, 'Duplicate', 'duplicate', Colors.blue),
        btn(Icons.gradient_rounded, 'Gradient', 'gradient'),
        btn(Icons.format_color_fill_rounded, 'Text BG', 'textBg'),
        btn(Icons.height_rounded, 'Spacing', 'spacing'),
        btn(Icons.format_align_center_rounded, 'Align', 'align'), // Master Button
        btn(Icons.format_bold_rounded, 'Bold', 'bold'),
        btn(Icons.open_with_rounded, 'Move', 'move'),
        btn(Icons.more_horiz_rounded, 'More', 'more', Colors.grey.shade800),
      ]);
    } else if (sel.isBorder || sel.isTable) {
      topRow.addAll([
        btn(Icons.close_rounded, 'Deselect', 'deselect', Colors.redAccent),
        btn(Icons.fullscreen_rounded, 'Fit Page', 'fitPage', const Color(0xFF10B981)),
        btn(Icons.straighten_rounded, 'Size', 'size'),
        if(sel.isBorder) btn(Icons.line_weight_rounded, 'Setup', 'setup'),
        if(sel.isTable) btn(Icons.table_rows_rounded, 'Edit Table', 'editTable', const Color(0xFF10B981)),
        btn(Icons.palette_rounded, 'Color', 'color', const Color(0xFF8B5CF6)),
        btn(Icons.opacity_rounded, 'Opacity', 'opacity'),
        btn(Icons.lock_outline_rounded, 'Lock', 'lock', Colors.orange),
      ]);
      bottomRow.addAll([
        btn(Icons.delete_outline_rounded, 'Delete', 'delete', Colors.red),
        btn(Icons.copy_rounded, 'Duplicate', 'duplicate', Colors.blue),
        btn(Icons.format_align_center_rounded, 'Align', 'align'), // Master Button
        btn(Icons.open_with_rounded, 'Move', 'move'),
        btn(Icons.arrow_upward_rounded, 'Bring Fwd', 'bringFwd'),
        btn(Icons.arrow_downward_rounded, 'Send Bwd', 'sendBwd'),
        btn(Icons.more_horiz_rounded, 'More', 'more', Colors.grey.shade800),
      ]);
    } else if (sel.imageBytes != null) {
      topRow.addAll([
        btn(Icons.close_rounded, 'Deselect', 'deselect', Colors.redAccent),
        btn(Icons.straighten_rounded, 'Size', 'size'),
        btn(Icons.photo_filter_rounded, 'Filters', 'filters', const Color(0xFF10B981)),
        btn(Icons.crop_rounded, 'Crop', 'crop'),
        btn(Icons.format_paint_rounded, 'Tint', 'tint', const Color(0xFF8B5CF6)),
        btn(Icons.opacity_rounded, 'Opacity', 'opacity'),
        btn(Icons.flip_rounded, 'Flip H', 'flipH'),
        btn(Icons.flip_camera_android_rounded, 'Flip V', 'flipV'),
        btn(Icons.lock_outline_rounded, 'Lock', 'lock', Colors.orange),
      ]);
      bottomRow.addAll([
        btn(Icons.delete_outline_rounded, 'Delete', 'delete', Colors.red),
        btn(Icons.copy_rounded, 'Duplicate', 'duplicate', Colors.blue),
        btn(Icons.brightness_6_rounded, 'Shadow', 'shadow'),
        btn(Icons.auto_awesome_motion_rounded, 'Blend', 'blend'),
        btn(Icons.format_align_center_rounded, 'Align', 'align'), // Master Button
        btn(Icons.open_with_rounded, 'Move', 'move'),
        btn(Icons.arrow_upward_rounded, 'Bring Fwd', 'bringFwd'),
        btn(Icons.arrow_downward_rounded, 'Send Bwd', 'sendBwd'),
        btn(Icons.more_horiz_rounded, 'More', 'more', Colors.grey.shade800),
      ]);
    } else {
      // Shape
      topRow.addAll([
        btn(Icons.close_rounded, 'Deselect', 'deselect', Colors.redAccent),
        btn(Icons.straighten_rounded, 'Size', 'size'),
        btn(Icons.palette_rounded, 'Color', 'color', const Color(0xFF8B5CF6)),
        btn(Icons.border_color_rounded, 'Stroke', 'stroke'),
        btn(Icons.brightness_6_rounded, 'Shadow', 'shadow'),
        btn(Icons.rounded_corner_rounded, 'Radius', 'radius'),
        btn(Icons.opacity_rounded, 'Opacity', 'opacity'),
        btn(Icons.lock_outline_rounded, 'Lock', 'lock', Colors.orange),
      ]);
      bottomRow.addAll([
        btn(Icons.delete_outline_rounded, 'Delete', 'delete', Colors.red),
        btn(Icons.copy_rounded, 'Duplicate', 'duplicate', Colors.blue),
        btn(Icons.format_align_center_rounded, 'Align', 'align'), // Master Button
        btn(Icons.open_with_rounded, 'Move', 'move'),
        btn(Icons.arrow_upward_rounded, 'Bring Fwd', 'bringFwd'),
        btn(Icons.arrow_downward_rounded, 'Send Bwd', 'sendBwd'),
        btn(Icons.flip_rounded, 'Flip H', 'flipH'),
        btn(Icons.flip_camera_android_rounded, 'Flip V', 'flipV'),
        btn(Icons.more_horiz_rounded, 'More', 'more', Colors.grey.shade800),
      ]);
    }

    return Container(
      height: 140, 
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: topRow)),
          const SizedBox(height: 6),
          SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: bottomRow)),
        ],
      ),
    );
  }
}
