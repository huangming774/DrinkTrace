# 饮迹 - 饮品记录应用

一个使用 Flutter 开发的饮品记录应用，帮助你追踪每日的饮品消费。

## 技术栈

- **状态管理**: Signals 6.0
- **本地数据库**: ObjectBox
- **网络请求**: Dio
- **路由**: Go Router (Navigator 2.0)
- **图片缓存**: Cached Network Image
- **序列化**: Dart Mappable

## 安装步骤

1. 确保已安装 Flutter SDK (3.10.8+)

2. 获取依赖包：
```bash
flutter pub get
```

如果遇到网络问题，可以配置国内镜像后重试：
```bash
# Windows PowerShell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

3. 生成代码（ObjectBox 和 Dart Mappable）：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. 运行应用：
```bash
flutter run
```

## 开发说明

### 代码生成

项目使用了以下代码生成工具：
- **ObjectBox Generator**: 生成数据库相关代码
- **Dart Mappable**: 生成序列化代码

每次修改模型文件后，需要重新运行代码生成：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

或者使用 watch 模式自动生成：
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## 功能特性

- ✅ 今日饮品统计（茶、酒、奶茶）
- ✅ 饮品记录列表
- ✅ 评分和心情记录
- 🚧 添加新记录
- 🚧 统计图表
- 🚧 个人中心

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── models/                # 数据模型
│   ├── drink_record.dart  # 饮品记录模型
│   └── drink_stats.dart   # 统计数据
├── screens/               # 页面
│   ├── home_screen.dart   # 首页
│   ├── stats_screen.dart  # 统计页
│   └── profile_screen.dart # 个人中心
├── widgets/               # 组件
│   └── drink_card.dart    # 饮品卡片
├── router/                # 路由
│   └── app_router.dart    # 路由配置
└── services/              # 服务层（待开发）
```

## 注意事项

如果遇到网络问题无法下载依赖，可以尝试：

1. 使用国内镜像：
```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

2. 或者等待网络稳定后重试 `flutter pub get`
