import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../config.dart';
import 'remote_fetcher.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  late RemoteFetcher<Map<String, dynamic>> homeFetcher;
  late RemoteFetcher<Map<String, dynamic>> calculatorFetcher;
  late RemoteFetcher<Map<String, dynamic>> goldFetcher;
  late RemoteFetcher<Map<String, dynamic>> cryptoFetcher;
  late RemoteFetcher<Map<String, dynamic>> sdgFetcher;
  late RemoteFetcher<Map<String, dynamic>> newsFetcher;

  Map<String, dynamic>? homeData;
  Map<String, dynamic>? calculatorData;
  Map<String, dynamic>? goldData;
  Map<String, dynamic>? cryptoData;

  Future<void> init() async {
    homeFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: homeJsonUrl,
      interval: const Duration(hours: 8),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    calculatorFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: calculatorJsonUrl,
      interval: const Duration(hours: 8),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    goldFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: goldJsonUrl,
      interval: const Duration(hours: 8),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    // A short-poll fetcher that reads the central currency JSON (where you
    // manually edit SDG). When SDG changes in that JSON we lock it for
    // `sdgLockDays` so other automated sources won't override it.
    sdgFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: currencyJsonUrl,
      interval: Duration(seconds: sdgPollIntervalSeconds),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    newsFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: newsJsonUrl,
      interval: const Duration(hours: 12),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    cryptoFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: cryptoJsonUrl,
      interval: const Duration(seconds: 10),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getString('sync_home');
    final c = prefs.getString('sync_calculator');
    final g = prefs.getString('sync_gold');
    final x = prefs.getString('sync_crypto');
    // If news isn't present in SharedPreferences yet, attempt to load the
    // bundled `api/news.json` asset so the app shows news out-of-the-box.
    if (!prefs.containsKey('sync_news')) {
      try {
        final bundled = await rootBundle.loadString('api/news.json');
        if (bundled.isNotEmpty) {
          await prefs.setString('sync_news', bundled);
        }
      } catch (_) {
        // asset may not be available in some test environments; ignore
      }
    }

    if (h != null) homeData = json.decode(h);
    if (c != null) calculatorData = json.decode(c);
    if (g != null) goldData = json.decode(g);
    if (x != null) cryptoData = json.decode(x);

    homeFetcher.start();
    calculatorFetcher.start();
    goldFetcher.start();
    cryptoFetcher.start();
  sdgFetcher.start();
  newsFetcher.start();

    Timer.periodic(const Duration(seconds: 5), (_) => _collect());
  }

  Future<void> _collect() async {
    bool changed = false;
    final prefs = await SharedPreferences.getInstance();

    // Helper to apply SDG lock override to any fetched map that contains a
    // top-level 'rates' map.
    Map<String, dynamic> applySdgLock(Map<String, dynamic> fetched, SharedPreferences p) {
      try {
        final lockedUntil = p.getInt('sdg_locked_until') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (lockedUntil > now && p.containsKey('sdg_manual_value')) {
          final manual = p.getDouble('sdg_manual_value');
          if (manual != null) {
            if (fetched.containsKey('rates') && fetched['rates'] is Map) {
              final rates = Map<String, dynamic>.from(fetched['rates']);
              rates['SDG'] = manual;
              final copy = Map<String, dynamic>.from(fetched);
              copy['rates'] = rates;
              return copy;
            }
          }
        }
      } catch (_) {}
      return fetched;
    }

    if (homeFetcher.last != null) {
      var value = homeFetcher.last!;
      value = applySdgLock(value, prefs);
      if (!mapEquals(value, homeData)) {
        homeData = value;
        await prefs.setString('sync_home', json.encode(value));
        changed = true;
      }
    }

    if (calculatorFetcher.last != null) {
      var value = calculatorFetcher.last!;
      value = applySdgLock(value, prefs);
      if (!mapEquals(value, calculatorData)) {
        calculatorData = value;
        await prefs.setString('sync_calculator', json.encode(value));
        changed = true;
      }
    }

    if (goldFetcher.last != null) {
      var value = goldFetcher.last!;
      value = applySdgLock(value, prefs);
      if (!mapEquals(value, goldData)) {
        goldData = value;
        await prefs.setString('sync_gold', json.encode(value));
        changed = true;
      }
    }

    if (cryptoFetcher.last != null) {
      final value = cryptoFetcher.last!;
      if (!mapEquals(value, cryptoData)) {
        cryptoData = value;
        await prefs.setString('sync_crypto', json.encode(value));
        changed = true;
      }
    }

    // Handle the dedicated SDG poller (currency.json). If it contains a SDG
    // rate and that rate differs from the stored manual value, we treat that
    // as a manual update and lock SDG for `sdgLockDays`.
    if (sdgFetcher.last != null) {
      final fetched = sdgFetcher.last!;
      try {
        if (fetched.containsKey('rates') && fetched['rates'] is Map) {
          final rates = fetched['rates'] as Map<String, dynamic>;
          if (rates.containsKey('SDG')) {
            final newSdg = (rates['SDG'] as num).toDouble();
            final prevManual = prefs.getDouble('sdg_manual_value');
            if (prevManual == null || prevManual != newSdg) {
              // Manual change detected on GitHub -> lock for sdgLockDays
              final until = DateTime.now().add(Duration(days: sdgLockDays)).millisecondsSinceEpoch;
              await prefs.setInt('sdg_locked_until', until);
              await prefs.setDouble('sdg_manual_value', newSdg);
              changed = true;
            }
          }
        }
      } catch (_) {}
    }

    // News handling: refresh the cached 3 news items
    if (newsFetcher.last != null) {
      final fetchedNews = newsFetcher.last!;
      try {
        if (!mapEquals(fetchedNews, prefs.getString('sync_news') != null ? json.decode(prefs.getString('sync_news')!) : null)) {
          await prefs.setString('sync_news', json.encode(fetchedNews));
          changed = true;
        }
      } catch (_) {}
    }

    if (changed) notifyListeners();
  }

  Map<String, dynamic>? getHomeData() => homeData;
  Map<String, dynamic>? getCalculatorData() => calculatorData;
  Map<String, dynamic>? getGoldData() => goldData;
  Map<String, dynamic>? getCryptoData() => cryptoData;

  void disposeService() {
    homeFetcher.stop();
    calculatorFetcher.stop();
    goldFetcher.stop();
    cryptoFetcher.stop();
    sdgFetcher.stop();
    newsFetcher.stop();
  }
}
