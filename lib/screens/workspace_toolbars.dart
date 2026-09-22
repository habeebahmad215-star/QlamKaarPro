import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/design_models.dart';

class WorkspaceToolbars {
  
  // Top App Bar Actions / Tool Buttons
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
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // Generic Tool Button for Bottom Bars
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

  // Default Bottom Bar (When no element is selected)
  static Widget buildDefaultBottomBar(BuildContext context, VoidCallback onAddModalTapped, VoidCallback onGridTapped, VoidCallback onResizeTapped, VoidCallback onBgImageTapped, VoidCallback onBgColorTapped, VoidCallback onBgGradientTapped, VoidCallback onClearBgTapped) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          InkWell(
            onTap: onAddModalTapped, 
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
              child: Row(
                children: [
                  buildToolBtn(context, Icons.grid_on, 'Grid', onGridTapped), 
                  buildToolBtn(context, Icons.aspect_ratio, 'Resize', onResizeTapped), 
                  buildToolBtn(context, Icons.image, 'BG Image', onBgImageTapped),
                  buildToolBtn(context, Icons.format_color_fill, 'BG Color', onBgColorTapped),
                  buildToolBtn(context, Icons.gradient, 'BG Gradient', onBgGradientTapped),
                  buildToolBtn(context, Icons.layers_clear, 'Clear BG', onClearBgTapped),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
