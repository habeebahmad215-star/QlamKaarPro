import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QalamKaar Pro',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const EditorScreen(),
    );
  }
}

// Stateful widget zaroori hai taaki slider ghumaane par screen update ho sake
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // Yeh variable hamare text ka size control karega (shuruwat mein 30 hai)
  double _textSize = 30.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QalamKaar Pro - Editor'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Canvas Area: Jahan aapka design/text dikhega
          Expanded(
            child: Center(
              child: Text(
                'مدرسہ اسلامیہ نصیرالعلوم', // Aapka test Urdu text
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'JameelNoori', // Aapka Jameel font
                  fontSize: _textSize,       // Yahan slider wala size apply ho raha hai
                ),
              ),
            ),
          ),
          
          // Slider Control Area: Niche ka hissa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ]
            ),
            child: Column(
              children: [
                Text(
                  'Text Size: ${_textSize.toInt()}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Slider(
                  value: _textSize,
                  min: 10.0,   // Sabse chota size
                  max: 120.0,  // Sabse bada size
                  activeColor: Colors.teal,
                  onChanged: (double newValue) {
                    setState(() {
                      _textSize = newValue; // Jaise hi slider hilega, size update hoga
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
