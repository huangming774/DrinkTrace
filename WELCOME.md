# 🎉 欢迎使用饮迹

一个精美的饮品记录应用，帮助你追踪每日的饮品消费。

## ⚡ 快速开始

### 方法 1：一键启动（推荐）

```powershell
.\setup.ps1
```

### 方法 2：手动配置

```bash
# 1. 配置镜像（如果网络有问题）
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"

# 2. 获取依赖
flutter pub get

# 3. 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 运行
flutter run
```

## 📱 功能特性

### 今日统计
- 🍵 茶类饮品计数
- 🍷 酒类饮品计数
- 🧋 奶茶类饮品计数

### 记录管理
- ✍️ 添加饮品记录
- ⭐ 评分（1-5星）
- 😊 心情标记
- 💰 价格记录
- 📝 备注说明

### 界面设计
- 🎨 温暖的配色方案
- 🎯 简洁的卡片布局
- ✨ 流畅的交互体验

## 🛠️ 技术栈

- **Flutter** - 跨平台 UI 框架
- **Signals 6.0** - 响应式状态管理
- **ObjectBox** - 高性能本地数据库
- **Go Router** - 声明式路由（Navigator 2.0）
- **Dart Mappable** - 类型安全序列化
- **Dio** - 网络请求
- **Cached Network Image** - 图片缓存

## 📚 文档

- `README.md` - 完整项目说明
- `QUICKSTART.md` - 快速开始指南
- `PROJECT_OVERVIEW.md` - 项目架构概览
- `FILES.md` - 文件清单

## ❓ 常见问题

**Q: 提示 502 Bad Gateway 错误？**
A: 配置国内镜像后重试 `flutter pub get`

**Q: 找不到某些类或方法？**
A: 运行代码生成：`flutter pub run build_runner build`

**Q: 如何添加新的饮品记录？**
A: 点击右下角的 ➕ 按钮

## 🎯 开发状态

- ✅ UI 框架完成
- ✅ 基础组件完成
- ✅ 路由配置完成
- 🚧 数据库集成（需要运行代码生成）
- 🚧 统计页面
- 🚧 个人中心

## 💬 技术支持

如有问题，请查看：
1. `QUICKSTART.md` - 快速开始指南
2. `PROJECT_OVERVIEW.md` - 技术架构说明
3. Flutter 官方文档：https://flutter.dev

---

**开始使用**: 运行 `.\setup.ps1` 或 `flutter pub get` 开始你的饮品记录之旅！ 🚀

