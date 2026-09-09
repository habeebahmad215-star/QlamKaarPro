import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../models/design_models.dart';
import 'pro_workspace_screen.dart';

class MyFolderScreen extends StatefulWidget {
  const MyFolderScreen({Key? key}) : super(key: key);
  @override State<MyFolderScreen> createState() => _MyFolderScreenState();
}

class _MyFolderScreenState extends State<MyFolderScreen> {
  List<ProjectModel> savedProjects = [];
  bool isLoading = true;

  @override void initState() { super.initState(); _loadProjects(); }

  // 🔥 NAYA SAFE STORAGE LOGIC 🔥
  Future<File> _getProjectsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/qalamkaar_projects.json');
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    try {
      final file = await _getProjectsFile();
      if (await file.exists()) {
        String contents = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(contents);
        setState(() {
          savedProjects = jsonList.map((s) => ProjectModel.fromJson(s as Map<String, dynamic>)).toList();
          savedProjects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteProject(String id) async {
    if (!mounted) return;
    savedProjects.removeWhere((p) => p.id == id);
    try {
      final file = await _getProjectsFile();
      await file.writeAsString(jsonEncode(savedProjects.map((p) => p.toJson()).toList()));
    } catch (e) {
      debugPrint("Delete error: $e");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text('My Folder', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), elevation: 0),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : savedProjects.isEmpty 
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, size: 80, color: Colors.grey.shade400), const SizedBox(height: 15), const Text('Koi design save nahi hai.', style: TextStyle(fontSize: 18, color: Colors.grey))]))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.85),
              itemCount: savedProjects.length,
              itemBuilder: (context, index) {
                var proj = savedProjects[index];
                return InkWell(
                  onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ProWorkspaceScreen(project: proj))).then((_) => _loadProjects()); },
                  child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))), child: const Icon(Icons.design_services, size: 50, color: Color(0xFF8B5CF6)))), Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(proj.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), Text('Edited: ${DateTime.fromMillisecondsSinceEpoch(proj.lastModified).toString().substring(0,10)}', style: const TextStyle(fontSize: 10, color: Colors.grey))])), IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () { _deleteProject(proj.id); }, padding: EdgeInsets.zero, constraints: const BoxConstraints())]))])),
                );
              },
            ),
    );
  }
}
