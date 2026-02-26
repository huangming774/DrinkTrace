import 'package:flutter/material.dart';
import 'package:yinji/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yinji/utils/isolate_pool.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ 初始化全局线程池
  await globalIsolatePool.init();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('darkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用生命周期状态处理
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '饮迹',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5F1E8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F1E8),
        fontFamily: 'PingFang SC',
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C2C2C),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'PingFang SC',
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
