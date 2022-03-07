library flutter_cache;

import 'dart:convert';

import 'package:flutter_cache/Cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Future_requests.dart';

/*
* This function will return cached data if exist, 
* If not exist, will create new cached data.
* 
* @return Cache.content
*/
Future remember(String key, var data, [int? expiredAt]) async {
  if (await load(key) == null) {
    if (data is Function) {
      data = await FutureRequests.get.getFuture(key, data);
      // data = await data;
    }
    if (data != null) {
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
Future load(String key, [var defaultValue = null, bool list = false]) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Guard
  if (prefs.getString(key) == null) return defaultValue;

  if (Cache.isExpired(prefs.getInt(key + 'ExpiredAt'))) {
    destroy(key);
    return null;
  }

  Map keys = jsonDecode(prefs.getString(key)!);
  Cache cache = new Cache.rebuild(key);
  String? cacheType = prefs.getString(keys['type']);
  var cacheContent;

  if (cacheType == 'String') cacheContent = prefs.getString(keys['content']);

  if (cacheType == 'Map')
    cacheContent = jsonDecode(prefs.getString(keys['content'])!);

  if (cacheType == 'List<String>')
    cacheContent = prefs.getStringList(keys['content']);

  if (cacheType == 'List<Map>')
    cacheContent = prefs
        .getStringList(keys['content'])!
        .map((i) => jsonDecode(i))
        .toList();

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
  SharedPreferences prefs = await SharedPreferences.getInstance();
  FutureRequests.get.removeAll();
  prefs.clear();
}

/*
* unset single shared preference key
*
* @return void
*/

Future<void> destroy(String key) async {
  FutureRequests.get.removeFuture(key);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString(key) != null) {
    Map keys = jsonDecode(prefs.getString(key)!);
    prefs.remove(key);
    prefs.remove(keys['content']);
    prefs.remove(keys['type']);
    prefs.remove(key + 'ExpiredAt');
  }
}
