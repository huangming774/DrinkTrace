# Flutter 埋点 SDK 集成指南

本文档介绍如何在 Flutter App 中集成 Cloudflare Workers 埋点系统。

## 目录

- [快速开始](#快速开始)
- [SDK 实现](#sdk-实现)
- [API 说明](#api-说明)
- [使用示例](#使用示例)
- [最佳实践](#最佳实践)

---

## 快速开始

### 1. 添加依赖

在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  device_info_plus: ^9.1.0
  package_info_plus: ^5.0.0
  shared_preferences: ^2.2.0
  uuid: ^4.2.0
```

### 2. 安装依赖

```bash
flutter pub get
```

---

## SDK 实现

### 创建 Analytics SDK 文件

创建 `lib/analytics/analytics_sdk.dart`：

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 埋点事件数据模型
class AnalyticsEvent {
  final String eventName;
  final String deviceId;
  final String platform;
  final String? osVersion;
  final String? deviceModel;
  final int timestamp;
  final Map<String, dynamic>? payload;

  AnalyticsEvent({
    required this.eventName,
    required this.deviceId,
    required this.platform,
    this.osVersion,
    this.deviceModel,
    required this.timestamp,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
        'event_name': eventName,
        'device_id': deviceId,
        'platform': platform,
        'os_version': osVersion,
        'device_model': deviceModel,
        'timestamp': timestamp,
        'payload': payload,
      };
}

/// 埋点 SDK 配置
class AnalyticsConfig {
  final String endpoint;
  final int batchSize;
  final Duration flushInterval;
  final bool debugMode;

  AnalyticsConfig({
    required this.endpoint,
    this.batchSize = 20,
    this.flushInterval = const Duration(seconds: 30),
    this.debugMode = false,
  });
}

/// 埋点 SDK 主类
class AnalyticsSDK {
  static final AnalyticsSDK _instance = AnalyticsSDK._internal();
  factory AnalyticsSDK() => _instance;
  AnalyticsSDK._internal();

  AnalyticsConfig? _config;
  String? _deviceId;
  String? _platform;
  String? _osVersion;
  String? _deviceModel;
  
  final List<AnalyticsEvent> _eventQueue = [];
  Timer? _flushTimer;
  bool _initialized = false;

  /// 初始化 SDK
  Future<void> init(AnalyticsConfig config) async {
    if (_initialized) return;
    
    _config = config;
    await _initDeviceInfo();
    _startFlushTimer();
    _initialized = true;
    
    _log('AnalyticsSDK initialized');
  }

  /// 初始化设备信息
  Future<void> _initDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 获取或生成设备 ID
    _deviceId = prefs.getString('analytics_device_id');
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('analytics_device_id', _deviceId!);
    }

    // 获取设备和平台信息
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _platform = 'Android';
      _osVersion = 'Android ${androidInfo.version.release}';
      _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _platform = 'iOS';
      _osVersion = 'iOS ${iosInfo.systemVersion}';
      _deviceModel = iosInfo.utsname.machine ?? 'Unknown';
    } else {
      _platform = Platform.operatingSystem;
      _osVersion = Platform.operatingSystemVersion;
      _deviceModel = 'Unknown';
    }
  }

  /// 启动定时上报定时器
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_config!.flushInterval, (_) => flush());
  }

  /// 上报单个事件
  void track(String eventName, {Map<String, dynamic>? properties}) {
    if (!_initialized) {
      throw Exception('AnalyticsSDK not initialized. Call init() first.');
    }

    final event = AnalyticsEvent(
      eventName: eventName,
      deviceId: _deviceId!,
      platform: _platform!,
      osVersion: _osVersion,
      deviceModel: _deviceModel,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      payload: properties,
    );

    _eventQueue.add(event);
    _log('Event queued: $eventName');

    // 达到批次大小立即上报
    if (_eventQueue.length >= _config!.batchSize) {
      flush();
    }
  }

  /// 立即上报所有事件
  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;

    final eventsToSend = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      final response = await http.post(
        Uri.parse('${_config!.endpoint}/ingest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventsToSend.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        _log('Flushed ${eventsToSend.length} events');
      } else {
        _log('Failed to flush events: ${response.statusCode}', isError: true);
        // 失败时重新加入队列
        _eventQueue.insertAll(0, eventsToSend);
      }
    } catch (e) {
      _log('Error flushing events: $e', isError: true);
      // 失败时重新加入队列
      _eventQueue.insertAll(0, eventsToSend);
    }
  }

  /// 页面浏览事件快捷方法
  void trackPageView(String pageName, {Map<String, dynamic>? properties}) {
    track('page_view', properties: {
      'page': pageName,
      ...?properties,
    });
  }

  /// 点击事件快捷方法
  void trackClick(String elementName, {Map<String, dynamic>? properties}) {
    track('click', properties: {
      'element': elementName,
      ...?properties,
    });
  }

  /// 自定义事件快捷方法
  void trackCustom(String eventName, {Map<String, dynamic>? properties}) {
    track(eventName, properties: properties);
  }

  /// 日志输出
  void _log(String message, {bool isError = false}) {
    if (_config?.debugMode ?? false) {
      if (isError) {
        print('[AnalyticsSDK] ERROR: $message');
      } else {
        print('[AnalyticsSDK] $message');
      }
    }
  }

  /// 销毁 SDK
  void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}
```

---

## API 说明

### AnalyticsSDK 方法

| 方法 | 说明 | 参数 |
|------|------|------|
| `init(config)` | 初始化 SDK | `AnalyticsConfig` |
| `track(eventName, properties)` | 上报自定义事件 | 事件名, 属性字典 |
| `trackPageView(pageName, properties)` | 上报页面浏览 | 页面名, 属性字典 |
| `trackClick(elementName, properties)` | 上报点击事件 | 元素名, 属性字典 |
| `flush()` | 立即上报队列中的事件 | - |
| `dispose()` | 销毁 SDK（应用退出时调用） | - |

### AnalyticsConfig 配置

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `endpoint` | String | 必填 | Workers 服务地址 |
| `batchSize` | int | 20 | 每批上报事件数 |
| `flushInterval` | Duration | 30秒 | 定时上报间隔 |
| `debugMode` | bool | false | 调试模式开关 |

---

## 使用示例

### 1. 初始化（main.dart）

```dart
import 'package:flutter/material.dart';
import 'analytics/analytics_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化埋点 SDK
  await AnalyticsSDK().init(
    AnalyticsConfig(
      endpoint: 'https://your-worker.your-subdomain.workers.dev',
      batchSize: 20,
      flushInterval: Duration(seconds: 30),
      debugMode: true, // 开发环境开启调试
    ),
  );
  
  runApp(const MyApp());
}
```

### 2. 页面埋点

```dart
import 'analytics/analytics_sdk.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // 页面进入时上报
    AnalyticsSDK().trackPageView('home_page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Column(
        children: [
          // 点击事件埋点
          ElevatedButton(
            onPressed: () {
              AnalyticsSDK().trackClick('buy_button', properties: {
                'product_id': '12345',
                'price': 99.99,
                'currency': 'CNY',
              });
              // 执行业务逻辑
            },
            child: const Text('立即购买'),
          ),
        ],
      ),
    );
  }
}
```

### 3. 自定义事件

```dart
// 用户登录
AnalyticsSDK().track('user_login', properties: {
  'user_id': 'user_123',
  'login_type': 'wechat', // wechat, phone, email
  'timestamp': DateTime.now().toIso8601String(),
});

// 商品浏览
AnalyticsSDK().track('product_view', properties: {
  'product_id': 'sku_456',
  'category': 'electronics',
  'brand': 'Apple',
  'price': 6999.00,
});

// 加入购物车
AnalyticsSDK().track('add_to_cart', properties: {
  'product_id': 'sku_789',
  'quantity': 2,
  'from_page': 'product_detail',
});

// 支付完成
AnalyticsSDK().track('purchase_complete', properties: {
  'order_id': 'ORDER_20240101_001',
  'total_amount': 199.98,
  'payment_method': 'alipay',
  'item_count': 3,
});
```

### 4. 应用生命周期埋点

```dart
import 'package:flutter/material.dart';
import 'analytics/analytics_sdk.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 应用启动
    AnalyticsSDK().track('app_launch', properties: {
      'launch_time': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AnalyticsSDK().dispose(); // 应用退出时上报剩余事件
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台
        AnalyticsSDK().track('app_background');
        AnalyticsSDK().flush(); // 立即上报
        break;
      case AppLifecycleState.resumed:
        // 应用回到前台
        AnalyticsSDK().track('app_foreground');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: const HomePage(),
    );
  }
}
```

---

## 最佳实践

### 1. 事件命名规范

```dart
// ✅ 推荐：使用小写下划线命名
AnalyticsSDK().track('user_login');
AnalyticsSDK().track('purchase_complete');
AnalyticsSDK().track('video_play_start');

// ❌ 避免：使用驼峰命名或中文
AnalyticsSDK().track('userLogin');
AnalyticsSDK().track('用户登录');
```

### 2. 属性设计规范

```dart
// ✅ 推荐：使用规范的属性名和类型
AnalyticsSDK().track('purchase', properties: {
  'order_id': 'ORDER_001',      // 字符串
  'amount': 199.99,              // 数值
  'is_first_purchase': true,     // 布尔值
  'item_count': 3,               // 整数
  'items': ['sku1', 'sku2'],     // 数组
});

// ❌ 避免：属性名不一致或类型混乱
AnalyticsSDK().track('purchase', properties: {
  'orderID': 'ORDER_001',        // 命名不规范
  'amount': '199.99',            // 金额用字符串
});
```

### 3. 性能优化

```dart
class AnalyticsConfig {
  // 生产环境建议配置
  AnalyticsConfig production() => AnalyticsConfig(
    endpoint: 'https://your-worker.workers.dev',
    batchSize: 50,                    // 增大批次大小
    flushInterval: Duration(minutes: 1), // 延长上报间隔
    debugMode: false,                 // 关闭调试
  );
  
  // 开发环境建议配置
  AnalyticsConfig development() => AnalyticsConfig(
    endpoint: 'https://dev-worker.workers.dev',
    batchSize: 5,                     // 小批次便于调试
    flushInterval: Duration(seconds: 10), // 短间隔快速验证
    debugMode: true,                  // 开启调试
  );
}
```

### 4. 错误处理

```dart
// 包装埋点调用，避免影响业务逻辑
void safeTrack(String eventName, {Map<String, dynamic>? properties}) {
  try {
    AnalyticsSDK().track(eventName, properties: properties);
  } catch (e) {
    // 记录到本地日志，不上报
    debugPrint('Analytics error: $e');
  }
}

// 使用
safeTrack('important_event', properties: {'key': 'value'});
```

### 5. 用户属性追踪

```dart
// 在登录后设置用户属性
void onUserLogin(User user) {
  AnalyticsSDK().track('user_login', properties: {
    'user_id': user.id,
    'user_type': user.type,        // vip, normal
    'registration_date': user.createdAt,
    'age_group': user.ageGroup,    // 18-24, 25-34, etc.
    'city': user.city,
  });
}
```

---

## 查看数据

部署完成后，访问你的 Workers 地址查看数据面板：

```
https://your-worker.your-subdomain.workers.dev/
```

面板包含：
- 📊 今日日活（DAU）
- 📈 近7天事件趋势
- 📱 平台分布饼图
- 📊 设备型号分布

---

## 常见问题

### Q: 如何测试埋点是否成功？

A: 开启 `debugMode: true`，查看控制台输出：
```
[AnalyticsSDK] Event queued: page_view
[AnalyticsSDK] Flushed 5 events
```

### Q: 事件上报失败怎么办？

A: SDK 会自动重试，失败的事件会保留在队列中等待下次上报。

### Q: 如何查看上报的数据？

A: 访问 Workers 的 Dashboard 页面，或使用 API：
```bash
curl https://your-worker.workers.dev/api/trend
curl https://your-worker.workers.dev/api/dau
```

---

## 完整示例项目

```
lib/
├── main.dart
├── analytics/
│   ├── analytics_sdk.dart      # SDK 主文件
│   └── analytics_events.dart   # 预定义事件（可选）
├── pages/
│   ├── home_page.dart
│   └── product_page.dart
└── widgets/
    └── trackable_button.dart   # 可追踪的按钮组件
```

### analytics_events.dart（可选）

```dart
/// 预定义事件常量，避免拼写错误
class AnalyticsEvents {
  static const String appLaunch = 'app_launch';
  static const String appForeground = 'app_foreground';
  static const String appBackground = 'app_background';
  static const String pageView = 'page_view';
  static const String click = 'click';
  static const String userLogin = 'user_login';
  static const String userLogout = 'user_logout';
  static const String purchase = 'purchase';
  static const String addToCart = 'add_to_cart';
  static const String productView = 'product_view';
}

/// 预定义属性常量
class AnalyticsProperties {
  static const String userId = 'user_id';
  static const String pageName = 'page_name';
  static const String productId = 'product_id';
  static const String amount = 'amount';
  static const String orderId = 'order_id';
}
```

---

如有问题，请检查 Workers 日志或联系开发团队。
