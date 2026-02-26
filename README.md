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
