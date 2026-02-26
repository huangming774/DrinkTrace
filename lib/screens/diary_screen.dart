import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:yinji/models/diary_entry.dart';
import 'package:yinji/services/objectbox_service.dart';
import 'package:yinji/widgets/add_diary_dialog.dart';
import 'package:yinji/utils/app_theme.dart';
import 'dart:ui';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late ObjectBoxService _objectBoxService;
  final Signal<List<DiaryEntry>> _diaries = signal([]);
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面显示时刷新数据
    if (_isInitialized) {
      _updateDiaries();
    }
  }

  Future<void> _initializeData() async {
    _objectBoxService = await ObjectBoxService.create();
    _updateDiaries();
    setState(() {
      _isInitialized = true;
    });
  }

  void _updateDiaries() {
    _diaries.value = _objectBoxService.getAllDiaries();
    
    // ✅ 移除不必要的 setState，Signals 会自动触发更新
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '日记',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Watch((context) {
              final diaries = _diaries.value;
              if (diaries.isEmpty) {
                return _buildEmptyState();
              }
              return Column(
                children: diaries.map((diary) => _buildDiaryCard(diary)).toList(),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 28),
            onPressed: () async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddDiaryDialog(),
              );
              
              if (result != null && mounted) {
                final diary = DiaryEntry(
                  title: result['title'],
                  content: result['content'],
                  mood: result['mood'],
                  timestamp: DateTime.now(),
                );
                
                _objectBoxService.addDiary(diary);
                _updateDiaries();
                
                if (mounted) {
                  _showMessage(context, '日记保存成功');
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDiaryCard(DiaryEntry diary) {
    final date = diary.timestamp;
    final dateStr = '${date.month}月${date.day}日';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key('diary_${diary.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.delete,
            color: Colors.white,
            size: 32,
          ),
        ),
        onDismissed: (direction) {
          _objectBoxService.deleteDiary(diary.id);
          _updateDiaries();
          _showMessage(context, '日记已删除');
        },
        child: GestureDetector(
          onTap: () => _showDiaryDetail(diary),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          diary.mood.split(' ')[0],
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diary.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$dateStr $timeStr',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.subtextColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      diary.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.subtextColor(context),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDiaryDetail(DiaryEntry diary) {
    final date = diary.timestamp;
    final dateStr = '${date.year}年${date.month}月${date.day}日';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        diary.mood.split(' ')[0],
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diary.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dateStr $timeStr',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.subtextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        diary.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textColor(context),
                          height: 1.8,
                        ),
                      ),
                    ),
                  ),
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
                      child: Text(
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1E8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book_outlined,
                size: 60,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '还没有日记',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮开始记录',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
    );
  }
}

