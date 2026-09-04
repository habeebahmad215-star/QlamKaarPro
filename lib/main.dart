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
      // Ab app direct Editor ke bajaye HomeScreen par khulegi
      home: const HomeScreen(), 
    );
  }
}

// 📱 NAYI SCREEN: Home Screen (Main Menu)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QalamKaar Pro'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Urdu mein Welcome Text
            const Text(
              'خوش آمدید', 
              style: TextStyle(
                fontFamily: 'JameelNoori',
                fontSize: 45,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Design your thoughts...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 50),
            
            // Naya Design Banane ka Button
            ElevatedButton.icon(
              onPressed: () {
                // Yeh code aapko Editor Screen par le jayega
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditorScreen()),
                );
              },
              icon: const Icon(Icons.brush),
              label: const Text('Naya Design (New Design)', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Mere Designs ka Dummy Button (Future ke liye)
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yeh feature jald hi joda jayega!')),
                );
              },
              icon: const Icon(Icons.folder),
              label: const Text('Mere Designs (My Projects)', style: TextStyle(fontSize: 18)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                foregroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🎨 PURANI SCREEN: Editor Screen (Jahan Slider laga hai)
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  double _textSize = 30.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Canvas Area
          Expanded(
            child: Center(
              child: Text(
                'مدرسہ اسلامیہ نصیرالعلوم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'JameelNoori',
                  fontSize: _textSize,
                ),
              ),
            ),
          ),
          
          // Slider Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: const [
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
                  min: 10.0,
                  max: 120.0,
                  activeColor: Colors.teal,
                  onChanged: (double newValue) {
                    setState(() {
                      _textSize = newValue;
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
