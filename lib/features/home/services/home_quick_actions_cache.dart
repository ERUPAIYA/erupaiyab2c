import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/secure_storage_service.dart';
import '../models/banner_model.dart';
import '../models/quick_action_model.dart';

class HomeQuickActionsCachePayload {
  const HomeQuickActionsCachePayload({
    required this.categories,
    required this.banners,
    required this.isNameEmailExist,
    required this.cachedAt,
  });

  final List<QuickActionCategory> categories;
  final Map<String, List<BannerModel>> banners;
  final bool? isNameEmailExist;
  final DateTime cachedAt;
}

class HomeQuickActionsCache {
  HomeQuickActionsCache({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageService.instance;

  static const _keyPayload = 'home_quick_actions_payload_v1';

  final FlutterSecureStorage _storage;

  Future<void> write(HomeQuickActionsCachePayload payload) async {
    final jsonMap = <String, dynamic>{
      'cached_at': payload.cachedAt.toIso8601String(),
      'is_name_email_exist': payload.isNameEmailExist,
      'categories': payload.categories.map(_categoryToJson).toList(),
      'banners': payload.banners.map(
        (key, value) => MapEntry(key, value.map(_bannerToJson).toList()),
      ),
    };
    await _storage.write(key: _keyPayload, value: jsonEncode(jsonMap));
  }

  Future<HomeQuickActionsCachePayload?> read() async {
    try {
      final raw = await _storage.read(key: _keyPayload);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt =
          DateTime.tryParse((decoded['cached_at'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
      final isNameEmailExist = decoded['is_name_email_exist'] as bool?;

      final categories = <QuickActionCategory>[];
      final rawCategories = decoded['categories'];
      if (rawCategories is List) {
        for (final item in rawCategories) {
          if (item is Map<String, dynamic>) {
            categories.add(_categoryFromJson(item));
          } else if (item is Map) {
            categories.add(
              _categoryFromJson(
                item.map((k, v) => MapEntry(k.toString(), v)),
              ),
            );
          }
        }
      }

      final banners = <String, List<BannerModel>>{};
      final rawBanners = decoded['banners'];
      if (rawBanners is Map) {
        for (final entry in rawBanners.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is List) {
            banners[key] = value
                .whereType<Map>()
                .map((e) => BannerModel.fromJson(
                      e.map((k, v) => MapEntry(k.toString(), v)),
                    ))
                .toList();
          }
        }
      }

      if (categories.isEmpty && banners.isEmpty) return null;
      return HomeQuickActionsCachePayload(
        categories: categories,
        banners: banners,
        isNameEmailExist: isNameEmailExist,
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _categoryToJson(QuickActionCategory category) {
    return <String, dynamic>{
      'category': category.category,
      'services': category.services
          .map(
            (s) => <String, dynamic>{
              'name': s.name,
              'icon': s.icon,
              'type': s.type,
              'Offers': s.offers,
            },
          )
          .toList(),
    };
  }

  static QuickActionCategory _categoryFromJson(Map<String, dynamic> json) {
    return QuickActionCategory(
      category: (json['category'] as String? ?? ''),
      services: (json['services'] is List ? (json['services'] as List) : const [])
          .whereType<Map>()
          .map((e) => QuickActionService.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .toList(),
    );
  }

  static Map<String, dynamic> _bannerToJson(BannerModel banner) {
    return <String, dynamic>{
      'id': banner.id,
      'title': banner.title,
      'image': banner.image,
      'redirect_url': banner.redirectUrl,
      'color_start': _colorToHex(banner.colorStart),
      'color_end': _colorToHex(banner.colorEnd),
    };
  }

  static String? _colorToHex(Color? color) {
    if (color == null) return null;
    return color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  }
}
