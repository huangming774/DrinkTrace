# 项目文件清单

## 核心代码文件

### 应用入口
- `lib/main.dart` - 应用主入口，配置主题和路由

### 数据模型
- `lib/models/drink_record.dart` - 饮品记录实体（ObjectBox + Dart Mappable）
- `lib/models/drink_stats.dart` - 统计数据（Signals 响应式状态）

### 页面
- `lib/screens/home_screen.dart` - 首页（今日统计 + 最近记录）
- `lib/screens/stats_screen.dart` - 统计页面（待开发）
- `lib/screens/profile_screen.dart` - 个人中心（待开发）

### 组件
- `lib/widgets/drink_card.dart` - 饮品记录卡片组件
- `lib/widgets/add_drink_dialog.dart` - 添加饮品对话框

### 路由
- `lib/router/app_router.dart` - Go Router 配置（Navigator 2.0）

### 服务
- `lib/services/objectbox_service.dart` - ObjectBox 数据库服务

## 配置文件

- `pubspec.yaml` - 项目依赖配置
- `build.yaml` - 代码生成配置
- `.gitignore` - Git 忽略规则（已添加生成文件）

## 文档

- `README.md` - 项目说明文档
- `QUICKSTART.md` - 快速开始指南
- `PROJECT_OVERVIEW.md` - 项目概览
- `FILES.md` - 本文件清单

## 脚本

- `setup.ps1` - Windows PowerShell 初始化脚本

## 依赖包

### 生产依赖
- `signals: ^6.0.0` - 响应式状态管理
- `signals_flutter: ^6.0.0` - Signals Flutter 集成
- `objectbox: ^4.0.3` - 本地数据库
- `objectbox_flutter_libs: ^4.0.3` - ObjectBox Flutter 库
- `dio: ^5.7.0` - HTTP 客户端
- `cached_network_image: ^3.4.1` - 图片缓存
- `dart_mappable: ^4.2.2` - 序列化
- `go_router: ^14.6.2` - 路由管理
- `path_provider: ^2.1.4` - 路径工具
- `path: ^1.9.0` - 路径处理

### 开发依赖
- `build_runner: ^2.4.13` - 代码生成运行器
- `objectbox_generator: ^4.0.3` - ObjectBox 代码生成
- `dart_mappable_builder: ^4.2.3` - Dart Mappable 代码生成
- `flutter_lints: ^6.0.0` - 代码规范

## 下一步操作

1. **获取依赖**
   ```bash
   flutter pub get
   ```

2. **生成代码**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

## 注意事项

⚠️ 由于网络问题，依赖包可能未完全下载。请在网络稳定时执行：
```powershell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

⚠️ 代码生成文件（*.g.dart, *.mapper.dart）需要在获取依赖后生成。

⚠️ ObjectBox 需要原生平台支持，不支持 Web 平台。

