# 饮迹 - Android 正式版本编译指南

## 前置准备

### 1. 生成签名密钥

首先需要创建一个用于签名 APK 的密钥库（keystore）：

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**参数说明：**
- `-keystore ~/upload-keystore.jks`：密钥库文件路径
- `-keyalg RSA`：加密算法
- `-keysize 2048`：密钥大小
- `-validity 10000`：有效期（天）
- `-alias upload`：密钥别名

**注意：** 请妥善保管密钥库文件和密码，丢失后将无法更新应用！

### 2. 配置签名信息

在项目根目录创建 `android/key.properties` 文件：

```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=upload
storeFile=C:/Users/你的用户名/upload-keystore.jks
```

**注意：** 
- 将路径改为你的实际密钥库路径
- 使用正斜杠 `/` 或双反斜杠 `\\`
- 不要将此文件提交到版本控制系统

### 3. 修改 build.gradle

编辑 `android/app/build.gradle`，在 `android {` 之前添加：

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

在 `buildTypes` 之前添加 `signingConfigs`：

```gradle
android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

## 编译步骤

### 方式一：编译 APK（推荐用于测试）

```bash
# 清理之前的构建
flutter clean

# 获取依赖
flutter pub get

# 生成代码（ObjectBox 和 Mappable）
flutter pub run build_runner build --delete-conflicting-outputs

# 编译 Release APK
flutter build apk --release
```

**输出位置：** `build/app/outputs/flutter-apk/app-release.apk`

### 方式二：编译 App Bundle（推荐用于 Google Play）

```bash
# 清理之前的构建
flutter clean

# 获取依赖
flutter pub get

# 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 编译 Release App Bundle
flutter build appbundle --release
```

**输出位置：** `build/app/outputs/bundle/release/app-release.aab`

### 方式三：分架构编译（减小 APK 体积）

```bash
# 编译 ARM64 版本（适用于大多数现代设备）
flutter build apk --release --target-platform android-arm64

# 编译 ARM32 版本（适用于旧设备）
flutter build apk --release --target-platform android-arm

# 编译 x86_64 版本（适用于模拟器和部分平板）
flutter build apk --release --target-platform android-x64
```

## 优化选项

### 1. 混淆代码（增强安全性）

在 `android/app/build.gradle` 中：

```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 2. 减小 APK 体积

```bash
# 使用 split-per-abi 为每个架构生成单独的 APK
flutter build apk --release --split-per-abi
```

这会生成三个 APK：
- `app-armeabi-v7a-release.apk` (ARM 32位)
- `app-arm64-v8a-release.apk` (ARM 64位)
- `app-x86_64-release.apk` (x86 64位)

### 3. 启用 R8 优化

在 `android/gradle.properties` 中添加：

```properties
android.enableR8=true
android.enableR8.fullMode=true
```

## 版本管理

### 修改版本号

编辑 `pubspec.yaml`：

```yaml
version: 1.0.0+1
```

格式：`主版本.次版本.修订版本+构建号`

例如：
- `1.0.0+1` - 第一个版本
- `1.0.1+2` - 第一次更新
- `1.1.0+3` - 功能更新

## 测试正式版本

### 安装到设备

```bash
# 安装 APK
flutter install --release

# 或者使用 adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 检查 APK 信息

```bash
# 查看 APK 大小
ls -lh build/app/outputs/flutter-apk/app-release.apk

# 查看 APK 内容
unzip -l build/app/outputs/flutter-apk/app-release.apk
```

## 常见问题

### 1. 签名错误

**错误：** `Execution failed for task ':app:validateSigningRelease'`

**解决：** 检查 `key.properties` 文件路径和密码是否正确

### 2. 内存不足

**错误：** `OutOfMemoryError: Java heap space`

**解决：** 在 `android/gradle.properties` 中添加：

```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError
```

### 3. 网络问题

**错误：** Gradle 下载失败

**解决：** 配置国内镜像，在 `android/build.gradle` 中：

```gradle
allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/jcenter' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        google()
        mavenCentral()
    }
}
```

## 发布检查清单

- [ ] 更新版本号
- [ ] 测试所有功能
- [ ] 检查权限配置
- [ ] 测试不同设备和系统版本
- [ ] 检查 APK 大小
- [ ] 验证签名
- [ ] 准备应用商店截图和描述
- [ ] 备份签名密钥

## 快速命令

```bash
# 一键编译（完整流程）
flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs && flutter build apk --release --split-per-abi

# 编译并安装
flutter build apk --release && flutter install --release

# 查看构建信息
flutter build apk --release --verbose
```

## 相关文档

- [Flutter 官方文档 - Android 发布](https://docs.flutter.dev/deployment/android)
- [Android 应用签名](https://developer.android.com/studio/publish/app-signing)
- [Google Play 发布指南](https://support.google.com/googleplay/android-developer/answer/9859152)

---

**饮迹 v1.0.0**  
记录每一杯美好 ☕🍷🧋

