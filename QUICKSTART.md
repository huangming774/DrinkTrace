# 快速开始

## 方式一：使用启动脚本（推荐）

在项目根目录运行：

```powershell
.\setup.ps1
```

脚本会自动完成：
- 检查 Flutter 环境
- 获取依赖包
- 生成必要的代码

## 方式二：手动执行

### 1. 获取依赖

```bash
flutter pub get
```

如果遇到网络问题（502 Bad Gateway），请配置镜像：

```powershell
# Windows PowerShell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

### 2. 生成代码

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

这会生成：
- ObjectBox 数据库代码
- Dart Mappable 序列化代码

### 3. 运行应用

```bash
flutter run
```

## 常见问题

### Q: 提示 "502 Bad Gateway" 错误
A: 这是 pub.dev 镜像的网络问题，请配置国内镜像或稍后重试。

### Q: 代码生成失败
A: 确保先成功执行了 `flutter pub get`，然后再运行 build_runner。

### Q: 找不到某些类或方法
A: 运行代码生成命令：`flutter pub run build_runner build --delete-conflicting-outputs`

## 项目特点

✨ **现代化 UI 设计**
- 柔和的配色方案
- 流畅的动画效果
- 卡片式布局

🎯 **核心功能**
- 今日饮品统计
- 饮品记录管理
- 评分和心情记录

🛠️ **技术亮点**
- Signals 6.0 响应式状态管理
- ObjectBox 高性能本地数据库
- Go Router 声明式路由
- Dart Mappable 类型安全序列化

