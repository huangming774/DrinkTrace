import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:isolate';

class AddDrinkDialog extends StatefulWidget {
  const AddDrinkDialog({super.key});

  @override
  State<AddDrinkDialog> createState() => _AddDrinkDialogState();
}

class _AddDrinkDialogState extends State<AddDrinkDialog> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  String _selectedCategory = '奶茶';
  String _selectedEmoji = '🧋';
  String _selectedMood = '😴 疲惫';
  int _rating = 3;
  String? _imagePath;
  double _volume = 500; // 容量 ml
  double _alcoholDegree = 40; // 酒精度数

  final Map<String, String> _categoryEmojis = {
    '茶': '🍵',
    '酒': '🍷',
    '奶茶': '🧋',
  };

  final List<String> _moods = [
    '😴 疲惫',
    '💼 工作',
    '🎉 开心',
    '😌 放松',
    '🤔 思考',
    '😰 焦虑',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _scaleAnimation.value) * MediaQuery.of(context).size.height * 0.3),
          child: Opacity(
            opacity: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
          children: [
            // 顶部拖动条
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '添加饮品记录',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 饮品名称
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '饮品名称',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 照片
                    const Text(
                      '照片',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: _imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          size: 40,
                                          color: Color(0xFF8E8E93),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '拍照',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF8E8E93),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.gallery),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    size: 40,
                                    color: Color(0xFF8E8E93),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '相册',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_imagePath != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 分类选择
                    const Text(
                      '分类',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _categoryEmojis.entries.map((entry) {
                        final isSelected = _selectedCategory == entry.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = entry.key;
                                _selectedEmoji = entry.value;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2C3E50)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    entry.value,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF2C2C2C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // 容量滑块（茶/奶茶）或酒精度滑块（酒）
                    if (_selectedCategory == '茶' || _selectedCategory == '奶茶') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '容量',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF42A5F5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_volume.toInt()} ml',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF42A5F5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF42A5F5),
                          inactiveTrackColor: const Color(0xFF42A5F5).withOpacity(0.2),
                          thumbColor: const Color(0xFF42A5F5),
                          overlayColor: const Color(0xFF42A5F5).withOpacity(0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 100,
                          max: 1000,
                          divisions: 18,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    if (_selectedCategory == '酒') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '容量',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF42A5F5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_volume.toInt()} ml',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF42A5F5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF42A5F5),
                          inactiveTrackColor: const Color(0xFF42A5F5).withOpacity(0.2),
                          thumbColor: const Color(0xFF42A5F5),
                          overlayColor: const Color(0xFF42A5F5).withOpacity(0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 100,
                          max: 1000,
                          divisions: 18,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '酒精度数',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE57373).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_alcoholDegree.toInt()}°',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE57373),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFFE57373),
                          inactiveTrackColor: const Color(0xFFE57373).withOpacity(0.2),
                          thumbColor: const Color(0xFFE57373),
                          overlayColor: const Color(0xFFE57373).withOpacity(0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        ),
                        child: Slider(
                          value: _alcoholDegree,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          onChanged: (value) {
                            setState(() {
                              _alcoholDegree = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // 价格
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '价格',
                        prefixText: '¥ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 评分
                    const Text(
                      '评分',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFB74D),
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    
                    // 心情
                    const Text(
                      '心情',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moods.map((mood) {
                        final isSelected = _selectedMood == mood;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMood = mood;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2C3E50)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              mood,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2C2C2C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // 备注
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 提交按钮
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'name': _nameController.text,
                            'category': _selectedCategory,
                            'emoji': _selectedEmoji,
                            'price': double.tryParse(_priceController.text) ?? 0,
                            'rating': _rating,
                            'mood': _selectedMood,
                            'comment': _commentController.text,
                            'imagePath': _imagePath,
                            'volume': _volume,
                            'alcoholDegree': _alcoholDegree,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '保存',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      // ✅ 降低初始尺寸限制
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        // ✅ 使用 Isolate 压缩图片
        final compressedPath = await _compressImageInIsolate(image.path);
        setState(() {
          _imagePath = compressedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取图片失败: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: const Color(0xFFE57373),
          ),
        );
      }
    }
  }
  
  // ✅ 在 Isolate 中压缩图片
  Future<String> _compressImageInIsolate(String imagePath) async {
    return await Isolate.run(() async {
      try {
        final bytes = await File(imagePath).readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) return imagePath;
        
        // 压缩到 800px
        final resized = img.copyResize(image, width: 800);
        final compressed = img.encodeJpg(resized, quality: 75);
        
        // 保存到临时目录
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(compressed);
        return file.path;
      } catch (e) {
        // 压缩失败，返回原路径
        return imagePath;
      }
    });
  }
}
