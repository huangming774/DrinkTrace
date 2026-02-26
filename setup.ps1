# 饮迹项目启动脚本

Write-Host "=== 饮迹项目初始化 ===" -ForegroundColor Green

# 检查 Flutter 是否安装
Write-Host "`n1. 检查 Flutter 环境..." -ForegroundColor Yellow
flutter --version

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 未找到 Flutter，请先安装 Flutter SDK" -ForegroundColor Red
    exit 1
}

# 获取依赖
Write-Host "`n2. 获取项目依赖..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "警告: 依赖获取失败，可能是网络问题" -ForegroundColor Red
    Write-Host "尝试配置国内镜像后重试..." -ForegroundColor Yellow
    $env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
    $env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
    flutter pub get
}

# 生成代码
Write-Host "`n3. 生成代码..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

# 完成
Write-Host "`n=== 初始化完成 ===" -ForegroundColor Green
Write-Host "`n运行以下命令启动应用:" -ForegroundColor Cyan
Write-Host "flutter run" -ForegroundColor White

