import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:yinji/services/objectbox_service.dart';
import 'package:yinji/services/ai_service.dart';
import 'package:yinji/models/drink_record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:yinji/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yinji/utils/isolate_pool.dart';
import 'dart:io';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ObjectBoxService _objectBoxService;
  final Signal<int> _totalRecords = signal(0);
  final Signal<int> _teaCount = signal(0);
  final Signal<int> _alcoholCount = signal(0);
  final Signal<int> _milkTeaCount = signal(0);
  bool _isInitialized = false;
  
  // 用户信息
  String _userNickname = '饮品爱好者';
  String _userSignature = '记录每一杯美好';
  String _userAvatar = '🍵';
  String? _userAvatarPath; // 自定义头像路径
  
  // 每日目标设置
  double _caffeineLimit = 800; // mg
  double _waterGoal = 2000; // ml
  double _alcoholGoal = 0; // mg
  
  // 设置状态
  bool _waterReminder = true;
  bool _drinkReminder = false;
  bool _healthTips = true;
  bool _darkMode = false;
  bool _autoBackup = true;
  bool _statistics = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNickname = prefs.getString('userNickname') ?? '饮品爱好者';
      _userSignature = prefs.getString('userSignature') ?? '记录每一杯美好';
      _userAvatar = prefs.getString('userAvatar') ?? '🍵';
      _userAvatarPath = prefs.getString('userAvatarPath');
      _caffeineLimit = prefs.getDouble('caffeineLimit') ?? 800;
      _waterGoal = prefs.getDouble('waterGoal') ?? 2000;
      _alcoholGoal = prefs.getDouble('alcoholGoal') ?? 0;
      _waterReminder = prefs.getBool('waterReminder') ?? true;
      _drinkReminder = prefs.getBool('drinkReminder') ?? false;
      _healthTips = prefs.getBool('healthTips') ?? true;
      _darkMode = prefs.getBool('darkMode') ?? false;
      _autoBackup = prefs.getBool('autoBackup') ?? true;
      _statistics = prefs.getBool('statistics') ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userNickname', _userNickname);
    await prefs.setString('userSignature', _userSignature);
    await prefs.setString('userAvatar', _userAvatar);
    if (_userAvatarPath != null) {
      await prefs.setString('userAvatarPath', _userAvatarPath!);
    } else {
      await prefs.remove('userAvatarPath');
    }
    await prefs.setDouble('caffeineLimit', _caffeineLimit);
    await prefs.setDouble('waterGoal', _waterGoal);
    await prefs.setDouble('alcoholGoal', _alcoholGoal);
    await prefs.setBool('waterReminder', _waterReminder);
    await prefs.setBool('drinkReminder', _drinkReminder);
    await prefs.setBool('healthTips', _healthTips);
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('autoBackup', _autoBackup);
    await prefs.setBool('statistics', _statistics);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      _updateStats();
    }
  }

  Future<void> _initializeData() async {
    _objectBoxService = await ObjectBoxService.create();
    _isInitialized = true;
    _updateStats();
  }

  void _updateStats() {
    final allRecords = _objectBoxService.getAllRecords();
    _totalRecords.value = allRecords.length;

    int tea = 0;
    int alcohol = 0;
    int milkTea = 0;

    for (var record in allRecords) {
      switch (record.category) {
        case '茶':
          tea++;
          break;
        case '酒':
          alcohol++;
          break;
        case '奶茶':
          milkTea++;
          break;
      }
    }

    _teaCount.value = tea;
    _alcoholCount.value = alcohol;
    _milkTeaCount.value = milkTea;
    
    // 强制刷新UI
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F1E8);
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);
    final subtextColor = isDark ? Colors.white70 : Colors.black.withOpacity(0.5);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
                '我的',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                color: textColor,
                ),
              ),
              const SizedBox(height: 24),
            _buildStatsCard(),
            const SizedBox(height: 20),
            _buildGoalsCard(),
            const SizedBox(height: 20),
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: '提醒设置',
              onTap: () => _showNotificationSettings(context),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.backup_outlined,
              title: '数据备份',
              onTap: () => _showDataBackup(context),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.share_outlined,
              title: '分享给朋友',
              onTap: () => _showShareDialog(context),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: '帮助与反馈',
              onTap: () => _showHelpAndFeedback(context),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.psychology_outlined,
              title: 'AI配置',
              onTap: () => _showAISettings(context),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: '通用设置',
              onTap: () => _showGeneralSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);
    final subtextColor = isDark ? Colors.white70 : Colors.black.withOpacity(0.5);
    
    return GestureDetector(
      onTap: () => _showEditProfileDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
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
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE8E4D8),
                    shape: BoxShape.circle,
                    image: _userAvatarPath != null
                        ? DecorationImage(
                            image: FileImage(File(_userAvatarPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _userAvatarPath == null
                      ? Center(
                          child: Text(
                            _userAvatar,
                            style: const TextStyle(fontSize: 40),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userNickname,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userSignature,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  color: subtextColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Watch((context) => _buildStatItem(
                      count: _totalRecords.value,
                      label: '总记录',
                      color: const Color(0xFF2C2C2C),
                    )),
                Watch((context) => _buildStatItem(
                      count: _teaCount.value,
                      label: '茶',
                      color: const Color(0xFF7CB342),
                    )),
                Watch((context) => _buildStatItem(
                      count: _alcoholCount.value,
                      label: '酒',
                      color: const Color(0xFFE57373),
                    )),
                Watch((context) => _buildStatItem(
                      count: _milkTeaCount.value,
                      label: '奶茶',
                      color: const Color(0xFFD4A574),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? Colors.white70 : Colors.black.withOpacity(0.5);
    
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
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
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '每日目标',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSliderItem(
            label: '咖啡因上限 (mg)',
            value: _caffeineLimit,
            min: 0,
            max: 1000,
            divisions: 20,
            color: const Color(0xFFD4A574),
            onChanged: (value) {
              setState(() {
                _caffeineLimit = value;
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 20),
          _buildSliderItem(
            label: '饮水目标 (ml)',
            value: _waterGoal,
            min: 0,
            max: 5000,
            divisions: 50,
            color: const Color(0xFF42A5F5),
            onChanged: (value) {
              setState(() {
                _waterGoal = value;
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 20),
          _buildSliderItem(
            label: '酒精摄入目标 (mg)',
            value: _alcoholGoal,
            min: 0,
            max: 500,
            divisions: 50,
            color: const Color(0xFFE57373),
            onChanged: (value) {
              setState(() {
                _alcoholGoal = value;
              });
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? Colors.white70 : Colors.black.withOpacity(0.6);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: subtextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toInt()}${label.contains('mg') ? 'mg' : 'ml'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);
    final iconBgColor = isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF5F1E8);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: textColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '提醒设置',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 20),
              _buildPersistentSwitchItem('每日饮水提醒', _waterReminder, (value) {
                setModalState(() => _waterReminder = value);
                setState(() => _waterReminder = value);
                _saveSettings();
              }),
              _buildPersistentSwitchItem('饮品记录提醒', _drinkReminder, (value) {
                setModalState(() => _drinkReminder = value);
                setState(() => _drinkReminder = value);
                _saveSettings();
              }),
              _buildPersistentSwitchItem('健康建议推送', _healthTips, (value) {
                setModalState(() => _healthTips = value);
                setState(() => _healthTips = value);
                _saveSettings();
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDataBackup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据备份',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton('导出数据', Icons.upload_outlined, () async {
              Navigator.pop(context);
              await _exportData(context);
            }),
            const SizedBox(height: 12),
            _buildActionButton('分享数据', Icons.share_outlined, () async {
              Navigator.pop(context);
              await _shareData(context);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Future<void> _exportData(BuildContext context) async {
    try {
      final records = _objectBoxService.getAllRecords();
      
      // ✅ 使用线程池处理 JSON 编码
      final jsonString = await globalIsolatePool.execute(
        records,
        (records) {
          final data = records.map((r) => {
            'name': r.name,
            'category': r.category,
            'emoji': r.emoji,
            'price': r.price,
            'rating': r.rating,
            'mood': r.mood,
            'comment': r.comment,
            'timestamp': r.timestamp.toIso8601String(),
          }).toList();
          
          return jsonEncode({
            'version': '1.0.0',
            'exportTime': DateTime.now().toIso8601String(),
            'records': data,
          });
        },
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/yinji_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      
      if (context.mounted) {
        _showMessage(context, '数据已导出到：${file.path}');
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, '导出失败：$e');
      }
    }
  }
  
  Future<void> _shareData(BuildContext context) async {
    try {
      final records = _objectBoxService.getAllRecords();
      
      // ✅ 使用线程池处理 JSON 编码
      final jsonString = await globalIsolatePool.execute(
        records,
        (records) {
          final data = records.map((r) => {
            'name': r.name,
            'category': r.category,
            'emoji': r.emoji,
            'price': r.price,
            'rating': r.rating,
            'mood': r.mood,
            'comment': r.comment,
            'timestamp': r.timestamp.toIso8601String(),
          }).toList();
          
          return jsonEncode({
            'version': '1.0.0',
            'exportTime': DateTime.now().toIso8601String(),
            'records': data,
          });
        },
      );
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/yinji_backup.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '饮迹数据备份 - ${records.length} 条记录',
      );
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, '分享失败：$e');
      }
    }
  }

  void _showShareDialog(BuildContext context) {
    final totalRecords = _totalRecords.value;
    final shareText = '我在使用「饮迹」记录饮品生活，已经记录了 $totalRecords 杯饮品！一起来记录每一杯美好吧 🍵';
    
    Share.share(shareText);
  }

  void _showHelpAndFeedback(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '帮助与反馈',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF666666)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionButton('使用帮助', Icons.help_outline, () {
              Navigator.pop(context);
              _showHelpDialog(context);
            }),
            const SizedBox(height: 12),
            _buildActionButton('意见反馈', Icons.feedback_outlined, () {
              Navigator.pop(context);
              _showFeedbackDialog(context);
            }),
            const SizedBox(height: 12),
            _buildActionButton('关于我们', Icons.info_outline, () {
              Navigator.pop(context);
              _showAboutDialog(context);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Color(0xFF42A5F5),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '使用帮助',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                '📝 如何添加饮品记录？',
                '点击底部中间的"+"按钮，填写饮品信息后保存即可。',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '📊 如何查看统计数据？',
                '点击底部"统计"标签，可以查看饮品比例、消费统计、活跃度热力图等数据。',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '📖 如何写日记？',
                '点击底部"日记"标签，可以记录每天的饮品心情和感受。',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '🤖 如何使用AI顾问？',
                '在首页点击右上角"AI顾问"按钮，AI会根据你的饮品记录提供健康建议。需要先在"我的-AI配置"中设置API。',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '💾 如何备份数据？',
                '在"我的-数据备份"中可以导出或分享你的饮品记录数据。',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '知道了',
              style: TextStyle(color: Color(0xFF7CB342)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    final contactController = TextEditingController();
    String selectedType = '功能建议';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.feedback_outlined,
                            color: Color(0xFFFFB74D),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '意见反馈',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF666666)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
              ),
              const SizedBox(height: 24),
                const Text(
                  '反馈类型',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['功能建议', 'Bug反馈', '使用问题', '其他'].map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedType = type;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFB74D) : const Color(0xFFF5F1E8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  '反馈内容',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: '请详细描述您的问题或建议...',
                    filled: true,
                    fillColor: const Color(0xFFF5F1E8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '联系方式（选填）',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactController,
                  decoration: InputDecoration(
                    hintText: '邮箱或微信号，方便我们联系您',
                    filled: true,
                    fillColor: const Color(0xFFF5F1E8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (feedbackController.text.trim().isEmpty) {
                        _showMessage(context, '请输入反馈内容');
                        return;
                      }
                      
                      // 这里可以实现实际的反馈提交逻辑
                      // 比如发送到服务器或通过邮件发送
                      
                      Navigator.pop(context);
                      _showTopMessage(
                        context,
                        title: '提交成功',
                        message: '感谢您的反馈，我们会认真处理！',
                        isSuccess: true,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB74D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '提交反馈',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGeneralSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '通用设置',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF666666)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildPersistentSwitchItem('深色模式', _darkMode, (value) async {
                setModalState(() => _darkMode = value);
                setState(() => _darkMode = value);
                await _saveSettings();
                
                // 切换应用主题
                final myAppState = MyApp.of(context);
                if (myAppState != null) {
                  myAppState.toggleTheme(value);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? '已开启深色模式' : '已关闭深色模式'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }),
              _buildPersistentSwitchItem('自动备份', _autoBackup, (value) {
                setModalState(() => _autoBackup = value);
                setState(() => _autoBackup = value);
                _saveSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? '已开启自动备份' : '已关闭自动备份'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }),
              _buildPersistentSwitchItem('统计分析', _statistics, (value) {
                setModalState(() => _statistics = value);
                setState(() => _statistics = value);
                _saveSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? '已开启统计分析' : '已关闭统计分析'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildActionButton('清除所有数据', Icons.delete_outline, () {
                Navigator.pop(context);
                _showClearDataDialog(context);
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '清除所有数据',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
        content: const Text(
          '确定要清除所有饮品记录吗？此操作无法撤销！',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final records = _objectBoxService.getAllRecords();
              for (var record in records) {
                _objectBoxService.deleteRecord(record.id);
              }
              _updateStats();
              Navigator.pop(context);
              
              // 等待一下确保数据库操作完成
              await Future.delayed(const Duration(milliseconds: 100));
              
              // 强制刷新整个应用
              if (context.mounted) {
                // 通过重新加载根widget来刷新所有页面
                final myAppState = MyApp.of(context);
                if (myAppState != null) {
                  myAppState.setState(() {});
                }
                _showMessage(context, '已清除所有数据');
              }
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Color(0xFFE57373)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentSwitchItem(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                      fontSize: 16,
              color: Color(0xFF2C2C2C),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: OCLiquidGlass(
              borderRadius: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 20),
                curve: Curves.easeInOut,
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: value 
                      ? const Color(0xFF7CB342).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: value
                        ? const Color(0xFF7CB342).withOpacity(0.6)
                        : Colors.grey.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: value ? const Color(0xFF7CB342) : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (value ? const Color(0xFF7CB342) : Colors.grey).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F1E8),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2C2C2C), size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2C2C2C),
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
        behavior: SnackBarBehavior.fixed,
        backgroundColor: const Color(0xFF2C2C2C),
      ),
    );
  }
  
  void _showTopMessage(BuildContext context, {
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFF7CB342) : const Color(0xFFE57373),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '关于饮迹',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本：v1.0.0',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            SizedBox(height: 8),
            Text(
              '饮迹 - 记录每一杯美好',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            SizedBox(height: 8),
            Text(
              '让饮品记录变得简单而有趣',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '确定',
              style: TextStyle(color: Color(0xFF7CB342)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nicknameController = TextEditingController(text: _userNickname);
    final signatureController = TextEditingController(text: _userSignature);
    String selectedAvatar = _userAvatar;
    String? selectedAvatarPath = _userAvatarPath;
    
    final avatarOptions = ['🍵', '☕', '🥤', '🍺', '🍷', '🥃', '🧃', '🧋', '🍹', '🥛', '🍶', '🫖'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '编辑个人信息',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF666666)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '选择头像',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // 从相册选择按钮
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          maxHeight: 512,
                          imageQuality: 85,
                        );
                        
                        if (image != null) {
                          // 保存图片到应用目录
                          final directory = await getApplicationDocumentsDirectory();
                          final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          final savedImage = await File(image.path).copy('${directory.path}/$fileName');
                          
                          setModalState(() {
                            selectedAvatarPath = savedImage.path;
                            selectedAvatar = ''; // 清空emoji选择
                          });
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: selectedAvatarPath != null
                              ? const Color(0xFF7CB342).withOpacity(0.2)
                              : const Color(0xFFF5F1E8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedAvatarPath != null
                                ? const Color(0xFF7CB342)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selectedAvatarPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(selectedAvatarPath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Color(0xFF666666),
                                size: 28,
                              ),
                      ),
                    ),
                    // Emoji选项
                    ...avatarOptions.map((avatar) {
                      final isSelected = avatar == selectedAvatar && selectedAvatarPath == null;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedAvatar = avatar;
                            selectedAvatarPath = null; // 清空自定义头像
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF7CB342).withOpacity(0.2)
                                : const Color(0xFFF5F1E8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFF7CB342)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                child: Center(
                  child: Text(
                              avatar,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '昵称',
                    style: TextStyle(
                      fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(
                    hintText: '请输入昵称',
                    filled: true,
                    fillColor: const Color(0xFFF5F1E8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '个性签名',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: signatureController,
                  decoration: InputDecoration(
                    hintText: '请输入个性签名',
                    filled: true,
                    fillColor: const Color(0xFFF5F1E8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _userAvatar = selectedAvatar;
                        _userAvatarPath = selectedAvatarPath;
                        _userNickname = nicknameController.text.isEmpty 
                            ? '饮品爱好者' 
                            : nicknameController.text;
                        _userSignature = signatureController.text.isEmpty 
                            ? '记录每一杯美好' 
                            : signatureController.text;
                      });
                      _saveSettings();
                      Navigator.pop(context);
                      _showMessage(context, '保存成功');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7CB342),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showAISettings(BuildContext context) async {
    // 先获取根 ScaffoldMessenger
    final rootScaffoldMessenger = ScaffoldMessenger.of(context);
    
    final prefs = await SharedPreferences.getInstance();
    final apiKeyController = TextEditingController(
      text: prefs.getString('openai_api_key') ?? '',
    );
    final apiUrlController = TextEditingController(
      text: prefs.getString('openai_api_url') ?? 'https://api.openai.com/v1/chat/completions',
    );
    final modelController = TextEditingController(
      text: prefs.getString('openai_model') ?? 'gpt-5.2',
    );
    
    // ✅ 预设配置（饮迹使用固定的 API 地址、模型和 Key）
    final presets = {
      '饮迹': {
        'url': 'https://api.gptapi.us/v1/chat/completions', // 固定的 API 地址
        'model': 'gpt-oss-120b', // 固定的模型
        'key': 'sk-VQMiYLEzrfLqkXxH4b6a6b6c6a0c4a5eB2d5Fc0c8b8e8c8c', // 固定的 API Key
        'models': ['gpt-oss-120b'],
      },
      'OpenAI': {
        'url': 'https://api.openai.com/v1/chat/completions',
        'model': 'GPT 5 Mini',
        'models': ['GPT 5 Mini', 'gpt-5', 'gpt-5-pro'],
      },
      'DeepSeek': {
        'url': 'https://api.deepseek.com',
        'model': 'deepseek-chat',
        'models': ['deepseek-chat', 'deepseek-coder'],
      },
      '智谱AI': {
        'url': 'https://open.bigmodel.cn/api/paas/v4',
        'model': 'glm-4.7',
        'models': ['glm-4.6v', 'glm-4.6', 'glm-4.7'],
      },
      '通义千问': {
        'url': 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
        'model': 'qwen3-max',
        'models': ['qwen3-max', 'qwq-plus-2025-03-05', 'qwen3.5-plus'],
      },
      'Moonshot': {
        'url': 'https://api.moonshot.cn',
        'model': 'kimi-k2.5',
        'models': ['kimi-k2-thinking-turbo', 'kimi-k2-thinking', 'kimi-k2.5'],
      },
      '自定义': {
        'url': '',
        'model': '',
        'models': [],
      },
    };
    
    String selectedPreset = prefs.getString('ai_preset') ?? '饮迹';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'AI配置',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF666666)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 预设选择
                const Text(
                  'API提供商',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets.keys.map((preset) {
                    final isSelected = selectedPreset == preset;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedPreset = preset;
                          if (preset == '饮迹') {
                            // 饮迹预设：自动填充固定的 URL、模型和 API Key
                            apiUrlController.text = presets[preset]!['https://integrate.api.nvidia.com'] as String;
                            modelController.text = presets[preset]!['openai/gpt-oss-120b'] as String;
                            apiKeyController.text = presets[preset]!['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'] as String;
                          } else if (preset == '自定义') {
                            // 自定义时清空所有字段
                            apiUrlController.text = '';
                            modelController.text = '';
                            apiKeyController.text = '';
                          }
                          // 其他预设不自动填充
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFFF5F1E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          preset,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                // API Key 输入框（饮迹预设时隐藏）
                if (selectedPreset != '饮迹') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'API Key',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: apiKeyController,
                    decoration: InputDecoration(
                      hintText: '请输入API Key',
                      filled: true,
                      fillColor: const Color(0xFFF5F1E8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: const Icon(Icons.key, color: Color(0xFF667eea)),
                    ),
                    obscureText: true,
                  ),
                ],
                
                // API 地址和模型（饮迹预设时隐藏）
                if (selectedPreset != '饮迹') ...[
                  const SizedBox(height: 20),
                  const Text(
                    'API地址',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: apiUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://api.example.com/v1/chat/completions',
                      filled: true,
                      fillColor: const Color(0xFFF5F1E8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: const Icon(Icons.link, color: Color(0xFF667eea)),
                    ),
                    enabled: selectedPreset == '自定义',
                  ),
                  
                  const SizedBox(height: 20),
                  const Text(
                    '模型',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: modelController,
                    decoration: InputDecoration(
                      hintText: '例如: gpt-5.2',
                      filled: true,
                      fillColor: const Color(0xFFF5F1E8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: const Icon(Icons.model_training, color: Color(0xFF667eea)),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF667eea),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '支持的API提供商',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667eea),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• OpenAI、DeepSeek、智谱AI、通义千问、Moonshot\n• 任何兼容OpenAI格式的API\n• 配置后可使用AI健康顾问功能',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF667eea),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 测试按钮
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // 获取要测试的配置
                      String testApiKey;
                      String testApiUrl;
                      String testModel;
                      
                      if (selectedPreset == '饮迹') {
                        // 饮迹预设使用写死的配置
                        testApiKey = presets['饮迹']!['key'] as String;
                        testApiUrl = presets['饮迹']!['url'] as String;
                        testModel = presets['饮迹']!['model'] as String;
                      } else {
                        // 其他预设使用用户输入的配置
                        testApiKey = apiKeyController.text;
                        testApiUrl = apiUrlController.text;
                        testModel = modelController.text;
                        
                        if (testApiKey.isEmpty) {
                          _showTopMessage(
                            context,
                            title: '提示',
                            message: '请先输入API Key',
                            isSuccess: false,
                          );
                          return;
                        }
                        if (testApiUrl.isEmpty) {
                          _showTopMessage(
                            context,
                            title: '提示',
                            message: '请先输入API地址',
                            isSuccess: false,
                          );
                          return;
                        }
                        if (testModel.isEmpty) {
                          _showTopMessage(
                            context,
                            title: '提示',
                            message: '请先输入模型名称',
                            isSuccess: false,
                          );
                          return;
                        }
                      }
                      
                      // 显示加载提示
                      final overlay = Overlay.of(context);
                      late OverlayEntry loadingEntry;
                      loadingEntry = OverlayEntry(
                        builder: (context) => Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 20,
                          right: 20,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667eea),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '正在测试连接...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      overlay.insert(loadingEntry);
                      
                      // 临时保存配置并测试
                      await prefs.setString('openai_api_key', testApiKey);
                      await prefs.setString('openai_api_url', testApiUrl);
                      await prefs.setString('openai_model', testModel);
                      
                      final aiService = AIService();
                      await aiService.initialize();
                      final testResponse = await aiService.getHealthAdvice([]);
                      
                      // 移除加载提示
                      loadingEntry.remove();
                      
                      if (context.mounted) {
                        // 判断是否成功
                        bool isSuccess = !testResponse.contains('请先在') && 
                                        !testResponse.contains('API Key无效') &&
                                        !testResponse.contains('请求超时') &&
                                        !testResponse.contains('API调用次数超限') &&
                                        !testResponse.contains('AI服务异常') &&
                                        !testResponse.contains('发生错误');
                        
                        if (isSuccess) {
                          _showTopMessage(
                            context,
                            title: '测试成功',
                            message: '连接正常，模型 $testModel 可用',
                            isSuccess: true,
                          );
                        } else {
                          _showTopMessage(
                            context,
                            title: '测试失败',
                            message: testResponse,
                            isSuccess: false,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('测试'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF667eea),
                      side: const BorderSide(color: Color(0xFF667eea), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await prefs.setString('ai_preset', selectedPreset);
                      
                      // 如果是饮迹预设，使用写死的配置
                      if (selectedPreset == '饮迹') {
                        await prefs.setString('openai_api_key', presets['饮迹']!['key'] as String);
                        await prefs.setString('openai_api_url', presets['饮迹']!['url'] as String);
                        await prefs.setString('openai_model', presets['饮迹']!['model'] as String);
                      } else {
                        // 其他预设使用用户输入的配置
                        await prefs.setString('openai_api_key', apiKeyController.text);
                        await prefs.setString('openai_api_url', apiUrlController.text);
                        await prefs.setString('openai_model', modelController.text);
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showMessage(context, 'AI配置保存成功');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '保存配置',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

