library flutter_cache;

import 'dart:convert';

import 'package:flutter_cache/Cache.dart';
import 'package:get_storage/get_storage.dart';

import 'Future_requests.dart';

/*
* This function will return cached data if exist, 
* If not exist, will create new cached data.
* 
* @return Cache.content
*/
Future remember(String key, var data, int? expiredAt,
    {bool isDebug = false}) async {
  if (await load(key) == null) {
    data = await FutureRequests.get.getFuture(key, data, isDebug: isDebug);
    if (data != null) {
      FutureRequests.get.removeFuture(key, isDebug: isDebug);
      return write(key, data, expiredAt);
    } else {
      return data;
    }
  }
  return load(key);
}

/*
* This will overwrite data if exist and create new if not.
*
* @return Cache.content
*/
Future write(String key, var data, [int? expiredAfter]) async {
  // if (data != null) {
  Cache cache = new Cache(key, data);
  if (expiredAfter != null) cache.setExpiredAfter(expiredAfter);
  cache.save(cache);
  // }
  return load(key);
}

/*
* load saved cached data.
*
* @return Cache.content
*/
Future load(String key, [var defaultValue, bool list = false]) async {
  GetStorage prefs = GetStorage('cache');

  // Guard
  if (prefs.read(key) == null) return defaultValue;

  if (Cache.isExpired(prefs.read(key + 'ExpiredAt'))) {
    destroy(key, withFuture: false);
    return null;
  }

  Map keys = jsonDecode(prefs.read(key)!);
  Cache cache = new Cache.rebuild(key);
  String? cacheType = prefs.read(keys['type']);
  var cacheContent;

  if (cacheType == 'String') cacheContent = prefs.read(keys['content']);

  if (cacheType == 'Map')
    cacheContent = jsonDecode(prefs.read(keys['content'])!);

  if (cacheType == 'List<String>') cacheContent = prefs.read(keys['content']);

  if (cacheType == 'List<Map>')
    cacheContent =
        prefs.read(keys['content'])!.map((i) => jsonDecode(i)).toList();

  cache.setContent(cacheContent, keys['content']);
  cache.setType(cacheType, keys['type']);

  return cache.content;
}

/*
* will clear all shared preference data
*
* @return void
*/
void clear() async {
  GetStorage getStorage = GetStorage('cache');
  FutureRequests.get.removeAll();
  getStorage.erase();
}

/*
* unset single shared preference key
*
* @return void
*/

Future<void> destroy(String key, {bool withFuture = true}) async {
  if (withFuture) {
    FutureRequests.get.removeFuture(key);
  }
  GetStorage prefs = GetStorage('cache');
  if (prefs.read(key) != null) {
    Map keys = jsonDecode(prefs.read(key)!);
    prefs.remove(key);
    prefs.remove(keys['content']);
    prefs.remove(keys['type']);
    prefs.remove(key + 'ExpiredAt');
  }
}
