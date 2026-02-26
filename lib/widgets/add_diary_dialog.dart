import 'package:flutter/material.dart';

class AddDiaryDialog extends StatefulWidget {
  const AddDiaryDialog({super.key});

  @override
  State<AddDiaryDialog> createState() => _AddDiaryDialogState();
}

class _AddDiaryDialogState extends State<AddDiaryDialog> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _selectedMood = '😊 开心';

  final List<String> _moods = [
    '😊 开心',
    '😌 平静',
    '😔 难过',
    '😤 生气',
    '😰 焦虑',
    '🤔 思考',
    '😴 疲惫',
    '🎉 兴奋',
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
    _titleController.dispose();
    _contentController.dispose();
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
                            '写日记',
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
                      
                      // 标题
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: '标题',
                          hintText: '今天发生了什么...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 心情选择
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
                      
                      // 内容
                      TextField(
                        controller: _contentController,
                        maxLines: 12,
                        decoration: InputDecoration(
                          labelText: '内容',
                          hintText: '记录今天的心情和想法...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 保存按钮
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('请填写标题和内容'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: const Color(0xFFE57373),
                                ),
                              );
                              return;
                            }
                            
                            Navigator.pop(context, {
                              'title': _titleController.text,
                              'content': _contentController.text,
                              'mood': _selectedMood,
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
}
