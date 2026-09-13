import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

// ============================================================================
// 🔥 SMART MEMORY CACHE ENGINE (ANTI-CRASH) 🔥
// Ye engine tasveeron ko duplicate hone se rokta hai aur RAM bachata hai
// ============================================================================
class ImageCacheManager {
  static final Map<String, Uint8List> _imageCache = {};

  static String cacheImage(Uint8List bytes) {
    String id = 'img_${DateTime.now().millisecondsSinceEpoch}_${bytes.length}';
    _imageCache[id] = bytes;
    return id;
  }

  static Uint8List? getImage(String? id) {
    if (id == null) return null;
    return _imageCache[id];
  }

  static void clearCache() {
    _imageCache.clear();
  }
}

class ProjectModel {
  String id; String name; List<DesignPage> pages; int lastModified;
  ProjectModel({required this.id, required this.name, required this.pages, required this.lastModified});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'lastModified': lastModified,
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id']?.toString() ?? '', 
    name: json['name']?.toString() ?? 'Project', 
    lastModified: (json['lastModified'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    pages: (json['pages'] as List<dynamic>?)?.map((p) => DesignPage.fromJson(p as Map<String, dynamic>)).toList() ?? [],
  );
}

class DesignPage {
  String title; List<DesignElement> elements; Color pageColor;
  
  // 🔥 BG Image ab Cache ID se handle hogi 🔥
  String? bgImageCacheId; 
  
  double canvasRatio; List<Color>? bgGradient; 

  DesignPage({
    required this.title, 
    required this.elements, 
    required this.pageColor, 
    Uint8List? bgImageBytes, 
    this.bgImageCacheId, 
    this.canvasRatio = 0.707, 
    this.bgGradient
  }) {
    if (bgImageBytes != null && bgImageCacheId == null) {
      bgImageCacheId = ImageCacheManager.cacheImage(bgImageBytes);
    }
  }

  // Getter & Setter for old code compatibility
  Uint8List? get bgImageBytes => ImageCacheManager.getImage(bgImageCacheId);
  set bgImageBytes(Uint8List? bytes) {
    if (bytes == null) {
      bgImageCacheId = null;
    } else {
      bgImageCacheId = ImageCacheManager.cacheImage(bytes);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title, 'pageColor': pageColor.value,
      // Save original bytes in JSON to persist data across app reboots
      'bgImageBytes': bgImageBytes != null ? base64Encode(bgImageBytes!) : null, 
      'canvasRatio': canvasRatio,
      'bgGradient': bgGradient?.map((c) => c.value).toList(),
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }

  factory DesignPage.fromJson(Map<String, dynamic> json) {
    Uint8List? bgBytes = json['bgImageBytes'] != null ? base64Decode(json['bgImageBytes'] as String) : null;
    String? cId = bgBytes != null ? ImageCacheManager.cacheImage(bgBytes) : null;

    return DesignPage(
      title: json['title']?.toString() ?? 'Page', 
      pageColor: Color((json['pageColor'] as num?)?.toInt() ?? 0xFFFFFFFF),
      bgImageCacheId: cId,
      canvasRatio: (json['canvasRatio'] as num?)?.toDouble() ?? 0.707,
      bgGradient: json['bgGradient'] != null ? (json['bgGradient'] as List<dynamic>).map((c) => Color((c as num).toInt())).toList() : null,
      elements: (json['elements'] as List<dynamic>?)?.map((e) => DesignElement.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class DesignElement {
  String id; double x, y; String content; 
  
  // 🔥 Main image and Texture image ab Cache ID ke through aayengi 🔥
  String? imageCacheId;
  String? textTextureCacheId;
  
  bool isText; double fontSize; Color textColor; double opacity; double angle;
  double pitch; double yaw; bool flipX; bool flipY;
  bool isLocked; bool isHidden; int imageFilter; 
  int clipShape; bool isTinted; Color? customGradColor1; Color? customGradColor2; 
  double cornerRadius; double letterSpacing; 
  double text3dDepth; Color text3dColor; double textCurveRadius; int blendModeIndex; 
  bool isBold; bool isItalic; TextAlign textAlign; double lineHeight; String fontFamily;
  bool isBorder; bool isShape; Color elementColor; double width; double height;
  double borderWidth; String borderStyle;
  Color? textBgColor; double textBgRadius; double wordSpacing; List<Color>? textGradient;
  bool hasStroke; Color strokeColor; double strokeWidth;
  bool hasShadow; Color shadowColor; double shadowBlur; double shadowOffsetX; double shadowOffsetY;
  String? groupId; 
  bool isTable; 
  List<List<String>>? tableData;
  bool isBevel;
  bool isInnerShadow;
  bool isGlass;

  DesignElement({
    required this.id, required this.x, required this.y, required this.content, 
    Uint8List? imageBytes, this.imageCacheId,
    this.isText = true, this.fontSize = 40.0, this.textColor = Colors.black, this.opacity = 1.0, this.angle = 0.0,
    this.pitch = 0.0, this.yaw = 0.0, this.clipShape = 0, this.flipX = false, this.flipY = false,
    this.isLocked = false, this.isHidden = false, this.imageFilter = 0,
    this.isTinted = false, this.customGradColor1, this.customGradColor2,
    this.cornerRadius = 0.0, Uint8List? textTextureBytes, this.textTextureCacheId, this.letterSpacing = 0.0, 
    this.text3dDepth = 0.0, this.text3dColor = Colors.black54,
    this.textCurveRadius = 0.0, this.blendModeIndex = 0, 
    this.isBold = false, this.isItalic = false, this.textAlign = TextAlign.center, this.lineHeight = 1.5, 
    this.fontFamily = 'JameelNoori', this.isBorder = false, this.isShape = false, 
    this.elementColor = const Color(0xFFD4AF37), this.width = 0, this.height = 0, 
    this.borderWidth = 5.0, this.borderStyle = 'royal_islamic', this.textBgColor, 
    this.textBgRadius = 10.0, this.wordSpacing = 0.0, this.textGradient,
    this.hasStroke = false, this.strokeColor = Colors.white, this.strokeWidth = 3.0,
    this.hasShadow = false, this.shadowColor = Colors.black54, this.shadowBlur = 5.0, 
    this.shadowOffsetX = 3.0, this.shadowOffsetY = 3.0,
    this.groupId,
    this.isTable = false, 
    this.tableData,
    this.isBevel = false,
    this.isInnerShadow = false,
    this.isGlass = false,
  }) {
    if (imageBytes != null && imageCacheId == null) {
      imageCacheId = ImageCacheManager.cacheImage(imageBytes);
    }
    if (textTextureBytes != null && textTextureCacheId == null) {
      textTextureCacheId = ImageCacheManager.cacheImage(textTextureBytes);
    }
  }

  // Getters & Setters so older UI code doesn't break
  Uint8List? get imageBytes => ImageCacheManager.getImage(imageCacheId);
  set imageBytes(Uint8List? bytes) {
    if (bytes == null) imageCacheId = null;
    else imageCacheId = ImageCacheManager.cacheImage(bytes);
  }

  Uint8List? get textTextureBytes => ImageCacheManager.getImage(textTextureCacheId);
  set textTextureBytes(Uint8List? bytes) {
    if (bytes == null) textTextureCacheId = null;
    else textTextureCacheId = ImageCacheManager.cacheImage(bytes);
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'x': x, 'y': y, 'content': content,
    // Converting bytes to base64 ONLY when saving to file permanently
    'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
    'isText': isText, 'fontSize': fontSize, 'textColor': textColor.value, 'opacity': opacity, 'angle': angle,
    'pitch': pitch, 'yaw': yaw, 'clipShape': clipShape, 'flipX': flipX, 'flipY': flipY,
    'isLocked': isLocked, 'isHidden': isHidden, 'imageFilter': imageFilter,
    'isTinted': isTinted, 'customGradColor1': customGradColor1?.value, 'customGradColor2': customGradColor2?.value,
    'cornerRadius': cornerRadius, 'textTextureBytes': textTextureBytes != null ? base64Encode(textTextureBytes!) : null, 'letterSpacing': letterSpacing,
    'text3dDepth': text3dDepth, 'text3dColor': text3dColor.value,
    'textCurveRadius': textCurveRadius, 'blendModeIndex': blendModeIndex,
    'isBold': isBold, 'isItalic': isItalic, 'textAlign': textAlign.index, 'lineHeight': lineHeight, 'fontFamily': fontFamily,
    'isBorder': isBorder, 'isShape': isShape, 'elementColor': elementColor.value, 'width': width, 'height': height,
    'borderWidth': borderWidth, 'borderStyle': borderStyle,
    'textBgColor': textBgColor?.value, 'textBgRadius': textBgRadius, 'wordSpacing': wordSpacing,
    'textGradient': textGradient?.map((c) => c.value).toList(),
    'hasStroke': hasStroke, 'strokeColor': strokeColor.value, 'strokeWidth': strokeWidth,
    'hasShadow': hasShadow, 'shadowColor': shadowColor.value, 'shadowBlur': shadowBlur, 'shadowOffsetX': shadowOffsetX, 'shadowOffsetY': shadowOffsetY,
    'groupId': groupId,
    'isTable': isTable, 
    'tableData': tableData, 
    'isBevel': isBevel,
    'isInnerShadow': isInnerShadow,
    'isGlass': isGlass,
  };

  factory DesignElement.fromJson(Map<String, dynamic> json) {
    int loadedClipShape = (json['clipShape'] as num?)?.toInt() ?? 0;
    if (json['isCircleCrop'] == true) loadedClipShape = 1; 

    // Handle initial load from json to cache
    Uint8List? iBytes = json['imageBytes'] != null ? base64Decode(json['imageBytes'] as String) : null;
    String? iCacheId = iBytes != null ? ImageCacheManager.cacheImage(iBytes) : null;

    Uint8List? tBytes = json['textTextureBytes'] != null ? base64Decode(json['textTextureBytes'] as String) : null;
    String? tCacheId = tBytes != null ? ImageCacheManager.cacheImage(tBytes) : null;

    return DesignElement(
      id: json['id']?.toString() ?? '', x: (json['x'] as num?)?.toDouble() ?? 0.0, y: (json['y'] as num?)?.toDouble() ?? 0.0, 
      content: json['content']?.toString() ?? '',
      imageCacheId: iCacheId,
      isText: json['isText'] as bool? ?? true, fontSize: (json['fontSize'] as num?)?.toDouble() ?? 40.0, 
      textColor: Color((json['textColor'] as num?)?.toInt() ?? 0xFF000000), opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0, 
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0, pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0, 
      yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0, clipShape: loadedClipShape, 
      flipX: json['flipX'] as bool? ?? false, flipY: json['flipY'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false, isHidden: json['isHidden'] as bool? ?? false, 
      imageFilter: (json['imageFilter'] as num?)?.toInt() ?? 0, isTinted: json['isTinted'] as bool? ?? false,
      customGradColor1: json['customGradColor1'] != null ? Color((json['customGradColor1'] as num).toInt()) : null,
      customGradColor2: json['customGradColor2'] != null ? Color((json['customGradColor2'] as num).toInt()) : null,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
      textTextureCacheId: tCacheId,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      text3dDepth: (json['text3dDepth'] as num?)?.toDouble() ?? 0.0,
      text3dColor: Color((json['text3dColor'] as num?)?.toInt() ?? 0x8A000000),
      textCurveRadius: (json['textCurveRadius'] as num?)?.toDouble() ?? 0.0,
      blendModeIndex: (json['blendModeIndex'] as num?)?.toInt() ?? 0,
      isBold: json['isBold'] as bool? ?? false, isItalic: json['isItalic'] as bool? ?? false, 
      textAlign: TextAlign.values[(json['textAlign'] as num?)?.toInt() ?? 1], lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.5, 
      fontFamily: json['fontFamily']?.toString() ?? 'JameelNoori',
      isBorder: json['isBorder'] as bool? ?? false, isShape: json['isShape'] as bool? ?? false, 
      elementColor: Color((json['elementColor'] as num?)?.toInt() ?? 0xFFD4AF37), 
      width: (json['width'] as num?)?.toDouble() ?? 0.0, height: (json['height'] as num?)?.toDouble() ?? 0.0,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 5.0, borderStyle: json['borderStyle']?.toString() ?? 'royal_islamic',
      textBgColor: json['textBgColor'] != null ? Color((json['textBgColor'] as num).toInt()) : null, 
      textBgRadius: (json['textBgRadius'] as num?)?.toDouble() ?? 10.0, wordSpacing: (json['wordSpacing'] as num?)?.toDouble() ?? 0.0,
      textGradient: json['textGradient'] != null ? (json['textGradient'] as List<dynamic>).map((c) => Color((c as num).toInt())).toList() : null,
      hasStroke: json['hasStroke'] as bool? ?? false, strokeColor: Color((json['strokeColor'] as num?)?.toInt() ?? 0xFFFFFFFF), strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      hasShadow: json['hasShadow'] as bool? ?? false, shadowColor: Color((json['shadowColor'] as num?)?.toInt() ?? 0x8A000000), 
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 5.0, shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble() ?? 3.0, shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble() ?? 3.0,
      groupId: json['groupId']?.toString(),
      isTable: json['isTable'] as bool? ?? false, 
      tableData: json['tableData'] != null ? List<List<String>>.from((json['tableData'] as List).map((row) => List<String>.from(row as List))) : null, 
      isBevel: json['isBevel'] as bool? ?? false,
      isInnerShadow: json['isInnerShadow'] as bool? ?? false,
      isGlass: json['isGlass'] as bool? ?? false,
    );
  }

  DesignElement clone() { 
    return DesignElement(
      id: id, x: x, y: y, content: content,
      // 🔥 MAGIC HERE: No duplicate RAM usage, only ID is copied
      imageCacheId: imageCacheId, 
      isText: isText, fontSize: fontSize, textColor: textColor, opacity: opacity, angle: angle,
      pitch: pitch, yaw: yaw, clipShape: clipShape, flipX: flipX, flipY: flipY,
      isLocked: isLocked, isHidden: isHidden, imageFilter: imageFilter,
      isTinted: isTinted, customGradColor1: customGradColor1, customGradColor2: customGradColor2,
      cornerRadius: cornerRadius, 
      // 🔥 MAGIC HERE: No duplicate RAM usage, only ID is copied
      textTextureCacheId: textTextureCacheId, 
      letterSpacing: letterSpacing,
      text3dDepth: text3dDepth, text3dColor: text3dColor,
      textCurveRadius: textCurveRadius, blendModeIndex: blendModeIndex,
      isBold: isBold, isItalic: isItalic, textAlign: textAlign, lineHeight: lineHeight, fontFamily: fontFamily,
      isBorder: isBorder, isShape: isShape, elementColor: elementColor, width: width, height: height,
      borderWidth: borderWidth, borderStyle: borderStyle,
      textBgColor: textBgColor, textBgRadius: textBgRadius, wordSpacing: wordSpacing, textGradient: textGradient,
      hasStroke: hasStroke, strokeColor: strokeColor, strokeWidth: strokeWidth,
      hasShadow: hasShadow, shadowColor: shadowColor, shadowBlur: shadowBlur, shadowOffsetX: shadowOffsetX, shadowOffsetY: shadowOffsetY,
      groupId: groupId,
      isTable: isTable,
      tableData: tableData?.map((row) => List<String>.from(row)).toList(),
      isBevel: isBevel,
      isInnerShadow: isInnerShadow,
      isGlass: isGlass,
    );
  }
}
