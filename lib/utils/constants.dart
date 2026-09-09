import 'package:flutter/material.dart';

class AppConstants {
  static const Map<String, List<String>> urduPoetryLibrary = {
    'اقوال زریں': [
      'علم وہ واحد دولت ہے جو بانٹنے سے بڑھتی ہے۔',
      'وقت ایک ایسا خزانہ ہے جسے سوچ سمجھ کر خرچ کرنا چاہیے۔',
      'خاموشی سب سے بہترین جواب ہے بے وقوف کے لیے۔',
      'اچھے اخلاق سے دشمن بھی دوست بن جاتے ہیں۔'
    ],
    'شاعری': [
      'ہزاروں سال نرگس اپنی بے نوری پہ روتی ہے\nبڑی مشکل سے ہوتا ہے چمن میں دیدہ ور پیدا',
      'عمل سے زندگی بنتی ہے جنت بھی جہنم بھی\nیہ خاکی اپنی فطرت میں نہ نوری ہے نہ ناری',
      'خودی کو کر بلند اتنا کہ ہر تقدیر سے پہلے\nخدا بندے سے خود پوچھے بتا تیری رضا کیا ہے'
    ],
    'دعا': [
      'یا اللہ! ہمیں سیدھے راستے پر چلنے کی توفیق عطا فرما۔',
      'اے رب! میرے علم میں اضافہ فرما۔',
      'یا رب العزت! ہماری پریشانیوں کو دور فرما۔ (آمین)'
    ]
  };

  static const List<Color> proColorPalette = [
    Colors.black, Colors.white, Colors.red, Colors.green, Colors.blue, Colors.yellow,
    Colors.orange, Colors.purple, Colors.teal, Colors.cyan, Colors.pink, Colors.amber,
    Colors.brown, Colors.grey, Colors.indigo, Colors.lime, Color(0xFFD4AF37), // Premium Gold
    Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFFE91E63), Color(0xFF3F51B5), Color(0xFF009688)
  ];

  static const List<List<Color>> proGradientPalette = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF10B981), Color(0xFF3B82F6)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    [Color(0xFF000000), Color(0xFF434343)],
    [Color(0xFFD4AF37), Color(0xFFFFF200)],
    [Color(0xFFE2E2E2), Color(0xFFFFFFFF)],
    [Color(0xFF141E30), Color(0xFF243B55)],
    [Color(0xFF8360C3), Color(0xFF2EBF91)],
  ];

  static const List<BlendMode> blendModes = [
    BlendMode.srcOver,
    BlendMode.multiply,
    BlendMode.screen,
    BlendMode.overlay,
    BlendMode.darken,
    BlendMode.lighten,
    BlendMode.colorDodge,
    BlendMode.colorBurn,
    BlendMode.hardLight,
    BlendMode.softLight,
    BlendMode.difference,
  ];
}
