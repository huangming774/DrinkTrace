import 'dart:isolate';
import 'dart:async';

/// Isolate 线程池管理器
/// 用于复用 Isolate，避免频繁创建销毁的开销
class IsolatePool {
  final int poolSize;
  final List<_IsolateWorker> _workers = [];
  int _currentIndex = 0;
  bool _isInitialized = false;

  IsolatePool({this.poolSize = 4});

  /// 初始化线程池
  Future<void> init() async {
    if (_isInitialized) return;
    
    for (int i = 0; i < poolSize; i++) {
      final worker = _IsolateWorker();
      await worker.spawn();
      _workers.add(worker);
    }
    
    _isInitialized = true;
  }

  /// 执行任务（自动负载均衡）
  Future<R> execute<T, R>(T data, R Function(T) task) async {
    if (!_isInitialized) {
      await init();
    }

    // 轮询选择 worker
    final worker = _workers[_currentIndex];
    _currentIndex = (_currentIndex + 1) % poolSize;

    return await worker.execute(data, task);
  }

  /// 销毁线程池
  Future<void> dispose() async {
    for (var worker in _workers) {
      await worker.kill();
    }
    _workers.clear();
    _isInitialized = false;
  }
}

/// 单个 Isolate Worker
class _IsolateWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _responseMap = <int, Completer>{};
  int _nextId = 0;

  /// 启动 Isolate
  Future<void> spawn() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    
    // 获取 SendPort
    _sendPort = await receivePort.first as SendPort;
    
    // 监听响应
    final responsePort = ReceivePort();
    responsePort.listen((message) {
      final id = message['id'] as int;
      final completer = _responseMap.remove(id);
      if (message['error'] != null) {
        completer?.completeError(message['error']);
      } else {
        completer?.complete(message['result']);
      }
    });
    
    _sendPort!.send(responsePort.sendPort);
  }

  /// 执行任务
  Future<R> execute<T, R>(T data, R Function(T) task) async {
    final id = _nextId++;
    final completer = Completer<R>();
    _responseMap[id] = completer;

    _sendPort!.send({
      'id': id,
      'data': data,
      'task': task,
    });

    return await completer.future;
  }

  /// 终止 Isolate
  Future<void> kill() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
  }

  /// Isolate 入口函数
  static void _isolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    SendPort? responsePort;

    receivePort.listen((message) {
      if (message is SendPort) {
        responsePort = message;
        return;
      }

      final id = message['id'] as int;
      final data = message['data'];
      final task = message['task'] as Function;

      try {
        final result = task(data);
        responsePort!.send({'id': id, 'result': result});
      } catch (e) {
        responsePort!.send({'id': id, 'error': e});
      }
    });
  }
}

/// 全局线程池实例
final globalIsolatePool = IsolatePool(poolSize: 4);

