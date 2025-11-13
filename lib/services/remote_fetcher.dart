import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RemoteFetcher<T> {
  final String url;
  final Duration interval;
  final T Function(dynamic json) parser;

  Timer? _timer;
  T? _last;
  bool _isFetching = false;

  RemoteFetcher({required this.url, required this.interval, required this.parser});

  T? get last => _last;

  void start() {
    if (_timer != null) return;
    _fetchOnce();
    _timer = Timer.periodic(interval, (_) => _fetchOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchOnce() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final jsonBody = json.decode(res.body);
        _last = parser(jsonBody);
      }
    } catch (_) {
      // ignore
    } finally {
      _isFetching = false;
    }
  }
}
