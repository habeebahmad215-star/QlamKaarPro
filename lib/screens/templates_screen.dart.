import 'package:flutter/material.dart';
import 'pro_workspace_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy template data for UI preview
    final List<Map<String, dynamic>> templates = [
      {'title': 'Jumma Mubarak', 'category': 'Islamic', 'color1': const Color(0xFF10B981), 'color2': const Color(0xFF047857), 'icon': Icons.mosque_rounded},
      {'title': 'Poetry Quote', 'category': 'Social Media', 'color1': const Color(0xFF6366F1), 'color2': const Color(0xFF4338CA), 'icon': Icons.format_quote_rounded},
      {'title': 'Milad-un-Nabi', 'category': 'Islamic', 'color1': const Color(0xFFF59E0B), 'color2': const Color(0xFFD97706), 'icon': Icons.star_border_rounded},
      {'title': 'Business Card', 'category': 'Professional', 'color1': const Color(0xFF3B82F6), 'color2': const Color(0xFF1D4ED8), 'icon': Icons.badge_rounded},
      {'title': 'Wedding Card', 'category': 'Events', 'color1': const Color(0xFFEC4899), 'color2': const Color(0xFFBE185D), 'icon': Icons.favorite_rounded},
      {'title': 'News Post', 'category': 'Social Media', 'color1': const Color(0xFFEF4444), 'color2': const Color(0xFFB91C1C), 'icon': Icons.article_rounded},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Templates', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TabBar(
                isScrollable: true,
                indicatorColor: const Color(0xFF6366F1),
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Islamic'),
                  Tab(text: 'Social Media'),
                  Tab(text: 'Professional'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Grid of Templates
            Expanded(
              child: TabBarView(
                children: [
                  _buildTemplateGrid(context, templates), // All
                  _buildTemplateGrid(context, templates.where((t) => t['category'] == 'Islamic').toList()),
                  _buildTemplateGrid(context, templates.where((t) => t['category'] == 'Social Media').toList()),
                  _buildTemplateGrid(context, templates.where((t) => t['category'] == 'Professional').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGrid(BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(child: Text('No templates found.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Taller cards
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            // Action: Open workspace with a blank canvas for now
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProWorkspaceScreen()));
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [item['color1'], item['color2']],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: (item['color2'] as Color).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Stack(
              children: [
                // Background Pattern (subtle)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(item['icon'], size: 100, color: Colors.white),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(item['category'], style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
