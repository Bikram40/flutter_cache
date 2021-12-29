class FutureRequests {
  static FutureRequests? _instance;

  FutureRequests._internal();

  static FutureRequests get get => _getInstance();

  static FutureRequests _getInstance() {
    if (_instance == null) {
      _instance = FutureRequests._internal();
    }
    return _instance!;
  }

  Map<String, Future<dynamic>> futureRequests = {};

  bool checkAlreadyRequested(String key) {
    return futureRequests.containsKey(key);
  }

  getFuture(String key, Function function) async {
    if (checkAlreadyRequested(key)) {
      print('flutter_cache : GETTING FROM FUTURE LIST :: $key');
    } else {
      print('flutter_cache : ADDING TO FUTURE LIST :: $key');
      addFutureRequests(key, function());
    }
    try {
      return await futureRequests[key]!;
    } catch (e) {
      return '';
    }
  }

  removeFuture(String key) {
    futureRequests.remove(key);
  }

  addFutureRequests(String key, Future<dynamic> future) {
    futureRequests[key] = future;
  }
}
