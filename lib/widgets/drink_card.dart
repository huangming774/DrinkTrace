import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';

/// 异步检查文件是否存在并显示图片（优化版）
class _AsyncImageWidget extends StatefulWidget {
  final String? imagePath;
  final String emoji;
  final double width;
  final double height;
  final double borderRadius;
  final bool? preloadedExists; // ✅ 预加载的存在性检查结果

  const _AsyncImageWidget({
    required this.imagePath,
    required this.emoji,
    required this.width,
    required this.height,
    required this.borderRadius,
    this.preloadedExists,
  });

  @override
  State<_AsyncImageWidget> createState() => _AsyncImageWidgetState();
}

class _AsyncImageWidgetState extends State<_AsyncImageWidget> {
  bool? _fileExists;

  @override
  void initState() {
    super.initState();
    // ✅ 优先使用预加载结果
    if (widget.preloadedExists != null) {
      _fileExists = widget.preloadedExists;
    } else {
      _checkFileExists();
    }
  }

  @override
  void didUpdateWidget(_AsyncImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      if (widget.preloadedExists != null) {
        setState(() => _fileExists = widget.preloadedExists);
      } else {
        _checkFileExists();
      }
    }
  }

  Future<void> _checkFileExists() async {
    if (widget.imagePath == null) {
      if (mounted) setState(() => _fileExists = false);
      return;
    }
    try {
      final exists = await File(widget.imagePath!).exists();
      if (mounted) {
        setState(() => _fileExists = exists);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fileExists = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fileExists == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.file(
          File(widget.imagePath!),
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
          // ✅ 限制缓存尺寸，减少内存占用
          cacheWidth: (widget.width * MediaQuery.of(context).devicePixelRatio).toInt(),
          cacheHeight: (widget.height * MediaQuery.of(context).devicePixelRatio).toInt(),
        ),
      );
    }
    return Center(
      child: Text(
        widget.emoji,
        style: TextStyle(fontSize: widget.width * 0.5),
      ),
    );
  }
}

class DrinkCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String category;
  final String time;
  final String mood;
  final int rating;
  final double price;
  final String comment;
  final String? imagePath;
  final VoidCallback? onDelete;
  final bool? imageExists; // ✅ 预加载的图片存在性

  const DrinkCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.category,
    required this.time,
    required this.mood,
    required this.rating,
    required this.price,
    required this.comment,
    this.imagePath,
    this.onDelete,
    this.imageExists,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('${emoji}_${name}_${time}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      onDismissed: (direction) {
        if (onDelete != null) {
          onDelete!();
        }
      },
      child: GestureDetector(
        onTap: () => _showDetailDialog(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧图标/图片
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _AsyncImageWidget(
                      imagePath: imagePath,
                      emoji: emoji,
                      width: 80,
                      height: 80,
                      borderRadius: 16,
                      preloadedExists: imageExists, // ✅ 传递预加载结果
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 中间内容区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题和分类
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C2C2C),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: const Color(0xFFFFB74D),
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 时间和心情
                        Row(
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                mood,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 价格
                        Text(
                          '¥${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _AsyncImageWidget(
                          imagePath: imagePath,
                          emoji: emoji,
                          width: 80,
                          height: 80,
                          borderRadius: 20,
                          preloadedExists: imageExists, // ✅ 传递预加载结果
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getCategoryTextColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 使用 FutureBuilder 异步检查文件是否存在
                  if (imagePath != null)
                    FutureBuilder<bool>(
                      future: File(imagePath!).exists(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(imagePath!),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildDetailRow(Icons.access_time, '时间', time),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.mood, '心情', mood),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: const Color(0xFFFFB74D),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '评分',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFB74D),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.attach_money, '价格', '¥${price.toStringAsFixed(0)}'),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1E8).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '备注',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comment,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2C2C2C),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '关闭',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF007AFF),
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (category) {
      case '茶':
        return const Color(0xFFE8F5E9);
      case '酒':
        return const Color(0xFFFFEBEE);
      case '奶茶':
        return const Color(0xFFFFF8E1);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getCategoryTextColor() {
    switch (category) {
      case '茶':
        return const Color(0xFF4CAF50);
      case '酒':
        return const Color(0xFFE57373);
      case '奶茶':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF757575);
    }
  }
}

