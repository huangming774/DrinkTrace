import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:yinji/models/drink_stats.dart';
import 'package:yinji/models/drink_record.dart';
import 'package:yinji/services/objectbox_service.dart';
import 'package:yinji/services/ai_service.dart';
import 'package:yinji/widgets/drink_card.dart';
import 'package:yinji/widgets/add_drink_dialog.dart';
import 'package:yinji/utils/app_theme.dart';
import 'package:yinji/utils/file_checker.dart';
import 'dart:ui';

final drinkStats = DrinkStats();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ObjectBoxService _objectBoxService;
  final Signal<List<DrinkRecord>> _todayRecords = signal([]);
  final Signal<List<DrinkRecord>> _recentRecords = signal([]);
  bool _isInitialized = false;
  Map<String, bool> _imageExistenceCache = {}; // ✅ 图片存在性缓存

  @override
  void initState() {
    super.initState();
    _initializeData();

    // ✅ 监听全局数据刷新信号
    effect(() {
      dataRefreshSignal.value; // 读取信号值以建立依赖
      if (_isInitialized) {
        _updateRecords();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面显示时刷新数据
    if (_isInitialized) {
      _updateRecords();
    }
  }

  Future<void> _initializeData() async {
    _objectBoxService = await ObjectBoxService.create();
    _updateRecords();
    setState(() {
      _isInitialized = true;
    });
  }

  void _updateRecords() async {
    final todayRecords = _objectBoxService.getTodayRecords();
    _todayRecords.value = todayRecords;
    
    final allRecords = _objectBoxService.getAllRecords();
    allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _recentRecords.value = allRecords.take(10).toList();
    
    drinkStats.updateStats(todayRecords);
    
    // ✅ 批量预加载图片存在性检查
    await _preloadImageExistence();
  }
  
  // ✅ 批量检查图片是否存在（使用 Isolate）
  Future<void> _preloadImageExistence() async {
    final paths = _recentRecords.value
        .where((r) => r.imagePath != null && r.imagePath!.isNotEmpty)
        .map((r) => r.imagePath!)
        .toList();
    
    if (paths.isEmpty) return;
    
    try {
      _imageExistenceCache = await FileChecker.batchCheckExists(paths);
      if (mounted) {
        setState(() {}); // 触发重建以使用缓存结果
      }
    } catch (e) {
      // 忽略错误，使用默认行为
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 18) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr = '${now.month}月${now.day}日 · ${weekdays[now.weekday - 1]}';
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.subtextColor(context),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showAIHealthAdvisor(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF667eea).withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                color: const Color(0xFF667eea),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'AI顾问',
                                style: TextStyle(
                                  color: const Color(0xFF667eea),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${_getGreeting()}，今天过得怎么样 ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context),
                          height: 1.2,
                        ),
                      ),
                      Text(
                        _getGreetingEmoji(),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTodayDrinks(),
                  const SizedBox(height: 32),
                  Text(
                    '最近记录',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentRecords(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayDrinks() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 30,
                offset: const Offset(-8, -8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今日记录',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.subtextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Watch((context) {
                          final total = drinkStats.teaCount.value +
                              drinkStats.alcoholCount.value +
                              drinkStats.milkTeaCount.value;
                          return Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                              height: 1,
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '杯',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.subtextColor(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Watch((context) {
                              final yesterdayCount = _getYesterdayCount();
                              final todayTotal = drinkStats.teaCount.value +
                                  drinkStats.alcoholCount.value +
                                  drinkStats.milkTeaCount.value;
                              final diff = todayTotal - yesterdayCount;
                              if (diff == 0) return const SizedBox.shrink();
                              final diffText = diff > 0 ? '+$diff' : '$diff';
                              final diffColor = diff > 0 ? const Color(0xFF7CB342) : const Color(0xFFE57373);
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: diffColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  diffText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: diffColor,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '摄入量',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.subtextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Watch((context) {
                          final totalMl = _getTodayTotalMl();
                          return Text(
                            '$totalMl',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF42A5F5),
                              height: 1,
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'ml',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.subtextColor(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Watch((context) {
                              final yesterdayMl = _getYesterdayTotalMl();
                              final todayMl = _getTodayTotalMl();
                              final diff = todayMl - yesterdayMl;
                              if (diff == 0) return const SizedBox.shrink();
                              final diffText = diff > 0 ? '+$diff' : '$diff';
                              final diffColor = diff > 0 ? const Color(0xFF7CB342) : const Color(0xFFE57373);
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: diffColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  diffText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: diffColor,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Watch((context) => _buildLiquidGlassStatCard(
                          label: '茶饮',
                          count: drinkStats.teaCount.value,
                          color: const Color(0xFF7CB342),
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Watch((context) => _buildLiquidGlassStatCard(
                          label: '酒类',
                          count: drinkStats.alcoholCount.value,
                          color: const Color(0xFFE57373),
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Watch((context) => _buildLiquidGlassStatCard(
                          label: '奶茶',
                          count: drinkStats.milkTeaCount.value,
                          color: const Color(0xFFFFB74D),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassStatCard({
    required String label,
    required int count,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getYesterdayCount() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final yesterdayEnd = yesterdayStart.add(const Duration(days: 1));
    
    final allRecords = _objectBoxService.getAllRecords();
    return allRecords.where((record) {
      return record.timestamp.isAfter(yesterdayStart) && 
             record.timestamp.isBefore(yesterdayEnd);
    }).length;
  }

  int _getTodayTotalMl() {
    final todayRecords = _todayRecords.value;
    return todayRecords.fold<int>(0, (sum, record) => sum + record.volume.toInt());
  }

  int _getYesterdayTotalMl() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final yesterdayEnd = yesterdayStart.add(const Duration(days: 1));
    
    final allRecords = _objectBoxService.getAllRecords();
    final yesterdayRecords = allRecords.where((record) {
      return record.timestamp.isAfter(yesterdayStart) && 
             record.timestamp.isBefore(yesterdayEnd);
    }).toList();
    
    return yesterdayRecords.fold<int>(0, (sum, record) => sum + record.volume.toInt());
  }

  Widget _buildRecentRecords() {
    return Watch((context) {
      final records = _recentRecords.value;
      
      if (records.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              '还没有记录，点击右下角添加吧',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.subtextColor(context),
              ),
            ),
          ),
        );
      }
      
      return Column(
        children: records.asMap().entries.map((entry) {
          final index = entry.key;
          final record = entry.value;
          final isLast = index == records.length - 1;
          
          final hour = record.timestamp.hour;
          final minute = record.timestamp.minute;
          final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间线
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.subtextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(record.category),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(record.category).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 100,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getCategoryColor(record.category).withOpacity(0.3),
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 卡片
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DrinkCard(
                    emoji: record.emoji,
                    name: record.name,
                    category: record.category,
                    time: timeStr,
                    mood: _getMoodWithEmoji(record.mood),
                    rating: record.rating,
                    price: record.price,
                    comment: record.comment ?? '',
                    imagePath: record.imagePath,
                    imageExists: record.imagePath != null 
                        ? _imageExistenceCache[record.imagePath] 
                        : null, // ✅ 传递预加载的存在性结果
                    onDelete: () {
                      _objectBoxService.deleteRecord(record.id);
                      _updateRecords();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('删除成功'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: const Color(0xFF2C2C2C),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      );
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '茶':
        return const Color(0xFF7CB342);
      case '酒':
        return const Color(0xFFE57373);
      case '奶茶':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  String _getMoodWithEmoji(String mood) {
    final moodMap = {
      '疲惫': '😴 疲惫',
      '工作': '💼 工作',
      '开心': '🎉 开心',
      '放松': '😌 放松',
      '思考': '🤔 思考',
      '焦虑': '😰 焦虑',
    };
    return moodMap[mood] ?? mood;
  }

  void _showAIHealthAdvisor(BuildContext context) {
    final todayRecords = _todayRecords.value;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _AIHealthAdvisorDialog(records: todayRecords),
      ),
    );
  }
}

class _AIHealthAdvisorDialog extends StatefulWidget {
  final List<DrinkRecord> records;

  const _AIHealthAdvisorDialog({required this.records});

  @override
  State<_AIHealthAdvisorDialog> createState() => _AIHealthAdvisorDialogState();
}

class _AIHealthAdvisorDialogState extends State<_AIHealthAdvisorDialog> {
  bool _isLoading = true;
  String _aiResponse = '';
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    _getAIAdvice();
  }

  Future<void> _getAIAdvice() async {
    setState(() {
      _isLoading = true;
    });

    await _aiService.initialize();
    final response = await _aiService.getHealthAdvice(widget.records);

    if (mounted) {
      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF5F1E8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI健康顾问',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '基于今日数据的个性化建议',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 内容
          Flexible(
            child: _isLoading
                ? _buildLoadingState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildAIResponse(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI正在分析您的数据...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请稍候',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAIResponse() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI建议',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _aiResponse,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF2C2C2C),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF667eea),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '建议仅供参考，如有健康问题请咨询专业医生',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF667eea),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
