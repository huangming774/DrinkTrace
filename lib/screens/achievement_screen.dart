import 'package:flutter/material.dart';
import 'package:yinji/services/objectbox_service.dart';
import 'dart:isolate';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  late ObjectBoxService _objectBoxService;
  bool _isInitialized = false;
  int _totalRecords = 0;
  int _teaCount = 0;
  int _alcoholCount = 0;
  int _milkTeaCount = 0;
  int _consecutiveDays = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _objectBoxService = await ObjectBoxService.create();
    await _loadStats();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadStats() async {
    final allRecords = _objectBoxService.getAllRecords();
    _totalRecords = allRecords.length;
    _teaCount = allRecords.where((r) => r.category == '茶').length;
    _alcoholCount = allRecords.where((r) => r.category == '酒').length;
    _milkTeaCount = allRecords.where((r) => r.category == '奶茶').length;
    _consecutiveDays = _calculateConsecutiveDays();
  }

  Future<void> _refreshData() async {
    await _loadStats();
    if (mounted) {
      setState(() {});
    }
  }

  int _calculateConsecutiveDays() {
    final allRecords = _objectBoxService.getAllRecords();
    if (allRecords.isEmpty) return 0;

    allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    int consecutive = 1;
    DateTime lastDate = DateTime(
      allRecords.first.timestamp.year,
      allRecords.first.timestamp.month,
      allRecords.first.timestamp.day,
    );

    for (int i = 1; i < allRecords.length; i++) {
      final currentDate = DateTime(
        allRecords[i].timestamp.year,
        allRecords[i].timestamp.month,
        allRecords[i].timestamp.day,
      );
      
      final diff = lastDate.difference(currentDate).inDays;
      if (diff == 1) {
        consecutive++;
        lastDate = currentDate;
      } else if (diff > 1) {
        break;
      }
    }
    
    return consecutive;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F1E8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalAchievements = 33;
    final unlockedAchievements = _getUnlockedCount();
    final percentage = (unlockedAchievements / totalAchievements * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2C2C2C)),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFFFB74D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '成就徽章',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '解锁更多成就，记录精彩时刻',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              _buildProgressCard(unlockedAchievements, totalAchievements, percentage),
              const SizedBox(height: 32),
              _buildCategorySection('☕️', '咖啡因', _teaCount, 7, [
                Achievement('咖啡新手', '记录第一杯咖啡', 1, _teaCount >= 1, _teaCount),
                Achievement('咖啡爱好者', '连续7天记录咖啡', 7, _consecutiveDays >= 7, _consecutiveDays),
                Achievement('咖啡大师', '记录50杯咖啡', 50, _teaCount >= 50, _teaCount),
                Achievement('咖啡传奇', '记录100杯咖啡', 100, _teaCount >= 100, _teaCount),
                Achievement('茶道探索者', '尝试5种不同的茶', 5, false, 0),
                Achievement('茶艺大师', '尝试10种不同的茶', 10, false, 0),
                Achievement('品茶专家', '记录30杯茶饮', 30, _teaCount >= 30, _teaCount),
              ]),
              const SizedBox(height: 24),
              _buildCategorySection('🧋', '奶茶控', _milkTeaCount, 5, [
                Achievement('奶茶初体验', '记录第一杯奶茶', 1, _milkTeaCount >= 1, _milkTeaCount),
                Achievement('奶茶爱好者', '记录10杯奶茶', 10, _milkTeaCount >= 10, _milkTeaCount),
                Achievement('奶茶达人', '记录30杯奶茶', 30, _milkTeaCount >= 30, _milkTeaCount),
                Achievement('珍珠猎人', '尝试5种不同的奶茶', 5, false, 0),
                Achievement('奶茶收藏家', '尝试15种不同的奶茶', 15, false, 0),
              ]),
              const SizedBox(height: 24),
              _buildCategorySection('🍷', '酒精', _alcoholCount, 5, [
                Achievement('初次小酌', '记录第一杯酒精饮品', 1, _alcoholCount >= 1, _alcoholCount),
                Achievement('品酒师', '记录10杯酒精饮品', 10, _alcoholCount >= 10, _alcoholCount),
                Achievement('理性饮酒', '饮酒后等待完全代谢再驾车', 1, false, 0),
                Achievement('调酒探索者', '尝试3种不同的鸡尾酒', 3, false, 0),
                Achievement('酒类鉴赏家', '尝试10种不同的酒类', 10, false, 0),
              ]),
              const SizedBox(height: 24),
              _buildCategorySection('🔥', '连续记录', _consecutiveDays, 5, [
                Achievement('坚持3天', '连续3天记录饮品', 3, _consecutiveDays >= 3, _consecutiveDays),
                Achievement('一周达人', '连续7天记录饮品', 7, _consecutiveDays >= 7, _consecutiveDays),
                Achievement('半月坚持', '连续15天记录饮品', 15, _consecutiveDays >= 15, _consecutiveDays),
                Achievement('月度冠军', '连续30天记录饮品', 30, _consecutiveDays >= 30, _consecutiveDays),
                Achievement('百日坚持', '连续100天记录饮品', 100, _consecutiveDays >= 100, _consecutiveDays),
              ]),
              const SizedBox(height: 24),
              _buildCategorySection('💰', '消费记录', 0, 3, [
                Achievement('节俭达人', '单日消费不超过20元', 20, false, 0),
                Achievement('品质生活', '累计消费达到1000元', 1000, false, 0),
                Achievement('消费大户', '累计消费达到5000元', 5000, false, 0),
              ]),
              const SizedBox(height: 24),
              _buildCategorySection('⭐', '特殊成就', 0, 8, [
                Achievement('日记新手', '写下第一篇日记', 1, false, 0),
                Achievement('记录生活', '连续7天写日记', 7, false, 0),
                Achievement('挑战者', '完成第一个每日挑战', 1, false, 0),
                Achievement('夜猫子', '在晚上10点后记录咖啡', 1, false, 0),
                Achievement('早起鸟', '在早上6点前记录饮品', 1, false, 0),
                Achievement('社交达人', '分享5次记录', 5, false, 0),
                Achievement('完美主义', '连续7天评分都是5星', 7, false, 0),
                Achievement('探索者', '尝试20种不同饮品', 20, _totalRecords >= 20, _totalRecords),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(int unlocked, int total, int percentage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已解锁',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlocked/$total',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFB74D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    String emoji,
    String title,
    int current,
    int total,
    List<Achievement> achievements,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const Spacer(),
            Text(
              '${achievements.where((a) => a.isUnlocked).length}/$total',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...achievements.map((achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAchievementCard(achievement),
            )),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? Colors.white
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? const Color(0xFFE8E4D8)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement.isUnlocked ? Icons.check_circle : Icons.lock,
              color: achievement.isUnlocked
                  ? const Color(0xFF7CB342)
                  : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: achievement.isUnlocked
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey,
                      ),
                    ),
                    if (!achievement.isUnlocked) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: achievement.isUnlocked
                        ? Colors.black.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${achievement.current}/${achievement.target}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getUnlockedCount() {
    int count = 0;
    // 咖啡因成就
    if (_teaCount >= 1) count++;
    if (_consecutiveDays >= 7) count++;
    if (_teaCount >= 50) count++;
    if (_teaCount >= 100) count++;
    if (_teaCount >= 30) count++;
    
    // 奶茶成就
    if (_milkTeaCount >= 1) count++;
    if (_milkTeaCount >= 10) count++;
    if (_milkTeaCount >= 30) count++;
    
    // 酒精成就
    if (_alcoholCount >= 1) count++;
    if (_alcoholCount >= 10) count++;
    
    // 连续记录成就
    if (_consecutiveDays >= 3) count++;
    if (_consecutiveDays >= 7) count++;
    if (_consecutiveDays >= 15) count++;
    if (_consecutiveDays >= 30) count++;
    if (_consecutiveDays >= 100) count++;
    
    // 特殊成就
    if (_totalRecords >= 20) count++;
    
    return count;
  }
}

class Achievement {
  final String title;
  final String description;
  final int target;
  final bool isUnlocked;
  final int current;

  Achievement(this.title, this.description, this.target, this.isUnlocked, [this.current = 0]);
}
