import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yinji/screens/home_screen.dart';
import 'package:yinji/screens/stats_screen.dart';
import 'package:yinji/screens/diary_screen.dart';
import 'package:yinji/screens/profile_screen.dart';
import 'package:yinji/widgets/add_drink_dialog.dart';
import 'package:yinji/models/drink_record.dart';
import 'package:yinji/models/drink_stats.dart';
import 'package:yinji/services/objectbox_service.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'dart:ui';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/diary',
                builder: (context, state) => const DiaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: OCLiquidGlass(
                borderRadius: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_rounded,
                        label: '记录',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.bar_chart_rounded,
                        label: '统计',
                        index: 1,
                      ),
                      const SizedBox(width: 64),
                      _buildNavItem(
                        icon: Icons.book_rounded,
                        label: '日记',
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.person_rounded,
                        label: '我的',
                        index: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: -1,
            bottom: 43,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => _showAddDrinkDialog(context),
                        child: const Center(
                          child: Icon(Icons.add, color: Color(0xFF667eea), size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
    );
  }

  void _showAddDrinkDialog(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddDrinkDialog(),
    );
    
    if (result != null && context.mounted) {
      // 导入必要的类
      final objectBoxService = await ObjectBoxService.create();
      final record = DrinkRecord(
        name: result['name'],
        category: result['category'],
        emoji: result['emoji'],
        price: result['price'],
        rating: result['rating'],
        mood: result['mood'].toString().split(' ').last,
        comment: result['comment'],
        imagePath: result['imagePath'],
        volume: result['volume'] ?? 500.0,
        alcoholDegree: result['alcoholDegree'] ?? 0.0,
        timestamp: DateTime.now(),
      );
      
      objectBoxService.addRecord(record);

      // ✅ 触发全局数据刷新信号
      dataRefreshSignal.value = DateTime.now().millisecondsSinceEpoch;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('添加成功'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: const Color(0xFF2C2C2C),
          ),
        );

        // ✅ 切换到首页
        navigationShell.goBranch(0);
      }
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => navigationShell.goBranch(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF007AFF).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  color: isSelected 
                      ? const Color(0xFF007AFF) 
                      : const Color(0xFF8E8E93),
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected 
                      ? const Color(0xFF007AFF) 
                      : const Color(0xFF8E8E93),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
