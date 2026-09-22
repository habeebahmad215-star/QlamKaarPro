import 'package:flutter/material.dart';

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
    bool showGrid, 
    VoidCallback toggleGrid, 
    VoidCallback showResizeModal, 
    VoidCallback setCanvasBackground, 
    VoidCallback showCanvasBgColorModal, 
    VoidCallback showCanvasBgGradientModal, 
    VoidCallback clearBg
  ) {
    return Container(
      height: 140, 
      alignment: Alignment.center, 
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, 
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  buildToolBtn(context, Icons.grid_on, 'Grid', toggleGrid), 
                  buildToolBtn(context, Icons.aspect_ratio, 'Resize', showResizeModal), 
                  buildToolBtn(context, Icons.image, 'BG Image', setCanvasBackground),
                  buildToolBtn(context, Icons.format_color_fill, 'BG Color', showCanvasBgColorModal),
                  buildToolBtn(context, Icons.gradient, 'BG Gradient', showCanvasBgGradientModal),
                  buildToolBtn(context, Icons.layers_clear, 'Clear BG', clearBg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
