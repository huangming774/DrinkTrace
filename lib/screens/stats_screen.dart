import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:yinji/services/objectbox_service.dart';
import 'package:yinji/models/drink_record.dart';
import 'package:yinji/models/drink_stats.dart';
import 'package:yinji/screens/achievement_screen.dart';
import 'package:yinji/utils/app_theme.dart';
import 'dart:math' as math;
import 'dart:isolate';

enum StatsPeriod { week, month, all }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late ObjectBoxService _objectBoxService;
  final Signal<StatsPeriod> _selectedPeriod = signal(StatsPeriod.week);
  final Signal<List<DrinkRecord>> _records = signal([]);
  final Signal<List<int>> _heatMapData = signal([]); // ✅ 缓存热力图数据
  bool _isInitialized = false;
  
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
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _updateRecords() async {
    final allRecords = _objectBoxService.getAllRecords();
    final now = DateTime.now();
    
    List<DrinkRecord> filteredRecords;
    switch (_selectedPeriod.value) {
      case StatsPeriod.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        filteredRecords = allRecords.where((r) => r.timestamp.isAfter(weekAgo)).toList();
        break;
      case StatsPeriod.month:
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        filteredRecords = allRecords.where((r) => r.timestamp.isAfter(monthAgo)).toList();
        break;
      case StatsPeriod.all:
        filteredRecords = allRecords;
        break;
    }
    
    _records.value = filteredRecords;
    
    // ✅ 异步更新热力图数据
    _updateHeatMapData();
  }
  
  // ✅ 异步计算热力图数据（使用 Isolate）
  Future<void> _updateHeatMapData() async {
    final allRecords = _objectBoxService.getAllRecords();
    
    final heatMapData = await Isolate.run(() {
      final now = DateTime.now();
      final data = List<int>.filled(84, 0); // 12周 * 7天
      
      for (var record in allRecords) {
        final diff = now.difference(record.timestamp).inDays;
        if (diff >= 0 && diff < 84) {
          data[83 - diff]++;
        }
      }
      
      return data;
    });
    
    _heatMapData.value = heatMapData;
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
      body: RefreshIndicator(
        onRefresh: () async {
          _updateRecords();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '统计',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AchievementScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB74D).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '成就',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              // ✅ 添加 RepaintBoundary 隔离重绘
              RepaintBoundary(
                child: Watch((context) => _buildDrinkRatioCard()),
              ),
              const SizedBox(height: 20),
              Watch((context) => _buildConsumptionStatsCard()),
              const SizedBox(height: 20),
              // ✅ 添加 RepaintBoundary 隔离重绘
              RepaintBoundary(
                child: Watch((context) => _buildHeatMapCard()),
              ),
              const SizedBox(height: 20),
              Watch((context) => _buildMoodDistributionCard()),
              const SizedBox(height: 20),
              // ✅ 添加 RepaintBoundary 隔离重绘
              RepaintBoundary(
                child: Watch((context) => _buildDailyTrendCard()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Watch((context) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildPeriodButton('本周', StatsPeriod.week),
            ),
            Expanded(
              child: _buildPeriodButton('本月', StatsPeriod.month),
            ),
            Expanded(
              child: _buildPeriodButton('全部', StatsPeriod.all),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPeriodButton(String label, StatsPeriod period) {
    final isSelected = _selectedPeriod.value == period;
    return GestureDetector(
      onTap: () {
        _selectedPeriod.value = period;
        _updateRecords();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.backgroundColor(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: AppTheme.textColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkRatioCard() {
    final records = _records.value;
    final teaCount = records.where((r) => r.category == '茶').length;
    final alcoholCount = records.where((r) => r.category == '酒').length;
    final milkTeaCount = records.where((r) => r.category == '奶茶').length;
    final total = teaCount + alcoholCount + milkTeaCount;

    final teaPercent = total > 0 ? (teaCount / total * 100).round() : 0;
    final alcoholPercent = total > 0 ? (alcoholCount / total * 100).round() : 0;
    final milkTeaPercent = total > 0 ? (milkTeaCount / total * 100).round() : 0;

    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '饮品比例',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: DonutChartPainter(
                  teaPercent: teaPercent / 100,
                  alcoholPercent: alcoholPercent / 100,
                  milkTeaPercent: milkTeaPercent / 100,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('🍵', '茶', '$teaPercent%'),
              _buildLegendItem('🍷', '酒', '$alcoholPercent%'),
              _buildLegendItem('🧋', '奶茶', '$milkTeaPercent%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, String label, String percent) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          percent,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.subtextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildConsumptionStatsCard() {
    final records = _records.value;
    final totalSpent = records.fold<double>(0, (sum, r) => sum + r.price);
    final avgSpent = records.isNotEmpty ? totalSpent / records.length : 0;
    
    final categoryCount = <String, int>{};
    for (var record in records) {
      categoryCount[record.category] = (categoryCount[record.category] ?? 0) + 1;
    }
    String favoriteDrink = '🍵';
    if (categoryCount.isNotEmpty) {
      final maxCategory = categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      favoriteDrink = maxCategory == '茶' ? '🍵' : maxCategory == '酒' ? '🍷' : '🧋';
    }

    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '消费统计',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '总消费',
                  '¥${totalSpent.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '日均消费',
                  '¥${avgSpent.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '记录次数',
                  '${records.length}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '最爱饮品',
                  favoriteDrink,
                  isEmoji: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isEmoji = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.subtextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isEmoji ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatMapCard() {
    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '活跃度热力图',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 20),
          _buildHeatMap(),
        ],
      ),
    );
  }

  Widget _buildHeatMap() {
    // ✅ 使用缓存的热力图数据
    final heatMapData = _heatMapData.value.isEmpty 
        ? List<int>.filled(84, 0) 
        : _heatMapData.value;
    const cellSize = 16.0;
    const cellSpacing = 4.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppTheme.subtextColor(context),
            ),
            const SizedBox(width: 6),
            Text(
              '最近12周记录情况',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.subtextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 星期标签
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: ['一', '三', '五', '日'].map((day) => 
                  SizedBox(
                    height: cellSize + cellSpacing,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(width: 8),
            // 热力图主体
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(12, (weekIndex) {
                    return Column(
                      children: [
                        // 周数标签
                        SizedBox(
                          width: cellSize + cellSpacing,
                          height: 20,
                          child: weekIndex % 4 == 0
                              ? Center(
                                  child: Text(
                                    '${12 - weekIndex}周',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        // 7天的格子
                        ...List.generate(7, (dayIndex) {
                          final dataIndex = weekIndex * 7 + dayIndex;
                          final count = dataIndex < heatMapData.length ? heatMapData[dataIndex] : 0;
                          return Container(
                            width: cellSize,
                            height: cellSize,
                            margin: EdgeInsets.only(
                              right: cellSpacing,
                              bottom: dayIndex < 6 ? cellSpacing : 0,
                            ),
                            decoration: BoxDecoration(
                              color: _getHeatMapColor(count),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '少',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (index) {
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: _getHeatMapColor(index),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(
              '多',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }



  Color _getHeatMapColor(int count) {
    if (count == 0) return const Color(0xFFE8E4D8);
    if (count == 1) return const Color(0xFFD4E8C4);
    if (count == 2) return const Color(0xFFB8D99A);
    if (count == 3) return const Color(0xFF9BC76F);
    return const Color(0xFF7CB342);
  }

  Widget _buildMoodDistributionCard() {
    final records = _records.value;
    final moodCount = <String, int>{};
    
    for (var record in records) {
      moodCount[record.mood] = (moodCount[record.mood] ?? 0) + 1;
    }

    final maxCount = moodCount.values.isEmpty ? 1 : moodCount.values.reduce(math.max);

    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '情绪分布',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 24),
          _buildMoodBar('疲惫', moodCount['疲惫'] ?? 0, maxCount),
          const SizedBox(height: 12),
          _buildMoodBar('工作', moodCount['工作'] ?? 0, maxCount),
          const SizedBox(height: 12),
          _buildMoodBar('开心', moodCount['开心'] ?? 0, maxCount),
          const SizedBox(height: 12),
          _buildMoodBar('放松', moodCount['放松'] ?? 0, maxCount),
          const SizedBox(height: 12),
          _buildMoodBar('焦虑', moodCount['焦虑'] ?? 0, maxCount),
        ],
      ),
    );
  }

  Widget _buildMoodBar(String mood, int count, int maxCount) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;
    
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            mood,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.subtextColor(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF7CB342),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTrendCard() {
    final records = _records.value;
    final now = DateTime.now();
    
    // 获取最近7天的数据
    final last7Days = <DateTime, int>{};
    for (var i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      last7Days[date] = 0;
    }
    
    // 统计每天的记录数
    for (var record in records) {
      final recordDate = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      if (last7Days.containsKey(recordDate)) {
        last7Days[recordDate] = last7Days[recordDate]! + 1;
      }
    }

    final dates = last7Days.keys.toList()..sort();
    final counts = dates.map((d) => last7Days[d]!).toList();
    final maxCount = counts.isEmpty ? 1 : counts.reduce(math.max);
    final totalCount = counts.fold<int>(0, (sum, count) => sum + count);
    final avgCount = totalCount / 7;

    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最近7天趋势',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '日均 ${avgCount.toStringAsFixed(1)} 杯',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtextColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final date = dates[index];
                final count = counts[index];
                final isToday = date.year == now.year && 
                               date.month == now.month && 
                               date.day == now.day;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildBarColumn(
                      date,
                      count,
                      maxCount,
                      isToday,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarColumn(DateTime date, int count, int maxCount, bool isToday) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;
    final height = 140 * percentage;
    final weekday = ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isToday ? const Color(0xFF42A5F5) : const Color(0xFF2C2C2C),
              ),
            ),
          )
        else
          const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: math.max(height, 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isToday
                  ? [
                      const Color(0xFF42A5F5),
                      const Color(0xFF64B5F6),
                    ]
                  : [
                      const Color(0xFF7CB342),
                      const Color(0xFF9BC76F),
                    ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: count > 0
                ? [
                    BoxShadow(
                      color: (isToday ? const Color(0xFF42A5F5) : const Color(0xFF7CB342))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          weekday,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday 
                ? const Color(0xFF42A5F5) 
                : Colors.black.withOpacity(0.6),
          ),
        ),
        Text(
          '${date.month}/${date.day}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.black.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistributionCard() {
    final records = _records.value;
    final ratingCount = <int, int>{};
    
    for (var i = 1; i <= 5; i++) {
      ratingCount[i] = 0;
    }
    
    for (var record in records) {
      ratingCount[record.rating] = (ratingCount[record.rating] ?? 0) + 1;
    }

    final maxCount = ratingCount.values.isEmpty ? 1 : ratingCount.values.reduce(math.max);

    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '评分分布',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 1; i <= 5; i++)
                  _buildRatingBar(i, ratingCount[i] ?? 0, maxCount),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 1; i <= 5; i++)
                SizedBox(
                  width: 50,
                  child: Text(
                    '$i⭐',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtextColor(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating, int count, int maxCount) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;
    final height = 100 * percentage;
    
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: math.max(height, 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFFFB74D),
                  const Color(0xFFFFB74D).withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDistributionCard() {
    final records = _records.value;
    final timeSlots = <String, int>{
      '早晨\n6-9': 0,
      '上午\n9-12': 0,
      '下午\n12-18': 0,
      '晚上\n18-22': 0,
      '深夜\n22-6': 0,
    };
    
    for (var record in records) {
      final hour = record.timestamp.hour;
      if (hour >= 6 && hour < 9) {
        timeSlots['早晨\n6-9'] = timeSlots['早晨\n6-9']! + 1;
      } else if (hour >= 9 && hour < 12) {
        timeSlots['上午\n9-12'] = timeSlots['上午\n9-12']! + 1;
      } else if (hour >= 12 && hour < 18) {
        timeSlots['下午\n12-18'] = timeSlots['下午\n12-18']! + 1;
      } else if (hour >= 18 && hour < 22) {
        timeSlots['晚上\n18-22'] = timeSlots['晚上\n18-22']! + 1;
      } else {
        timeSlots['深夜\n22-6'] = timeSlots['深夜\n22-6']! + 1;
      }
    }

    final maxCount = timeSlots.values.isEmpty ? 1 : timeSlots.values.reduce(math.max);

    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '时段分布',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 24),
          ...timeSlots.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTimeSlotBar(entry.key, entry.value, maxCount),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimeSlotBar(String timeSlot, int count, int maxCount) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;
    
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            timeSlot,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.subtextColor(context),
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF42A5F5),
                      Color(0xFF64B5F6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double teaPercent;
  final double alcoholPercent;
  final double milkTeaPercent;

  DonutChartPainter({
    required this.teaPercent,
    required this.alcoholPercent,
    required this.milkTeaPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 40.0;

    final teaPaint = Paint()
      ..color = const Color(0xFF7CB342)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final alcoholPaint = Paint()
      ..color = const Color(0xFFD4704B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final milkTeaPaint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;
    
    if (teaPercent > 0) {
      final sweepAngle = 2 * math.pi * teaPercent;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        teaPaint,
      );
      startAngle += sweepAngle;
    }

    if (alcoholPercent > 0) {
      final sweepAngle = 2 * math.pi * alcoholPercent;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        alcoholPaint,
      );
      startAngle += sweepAngle;
    }

    if (milkTeaPercent > 0) {
      final sweepAngle = 2 * math.pi * milkTeaPercent;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        milkTeaPaint,
      );
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.teaPercent != teaPercent ||
        oldDelegate.alcoholPercent != alcoholPercent ||
        oldDelegate.milkTeaPercent != milkTeaPercent;
  }
}

class LineChartPainter extends CustomPainter {
  final List<String> dates;
  final List<int> counts;
  final int maxCount;

  LineChartPainter({
    required this.dates,
    required this.counts,
    required this.maxCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dates.isEmpty || counts.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF42A5F5).withOpacity(0.3),
          const Color(0xFF42A5F5).withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pointPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1;

    // 绘制网格线
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (var i = 0; i < counts.length; i++) {
      final x = size.width * i / (counts.length - 1);
      final y = size.height - (size.height * counts[i] / maxCount);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    for (var point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.dates != dates ||
        oldDelegate.counts != counts ||
        oldDelegate.maxCount != maxCount;
  }
}
