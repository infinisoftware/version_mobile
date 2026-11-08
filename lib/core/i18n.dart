import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLanguages = ['en', 'fr', 'es'];
const _languageKey = 'tge-lang';

/// English by default, like the website. The choice is remembered on the phone.
class LanguageController extends Notifier<String> {
  @override
  String build() {
    _restore();
    final device = PlatformDispatcher.instance.locale.languageCode;
    return supportedLanguages.contains(device) ? device : 'en';
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    if (saved != null && supportedLanguages.contains(saved)) state = saved;
  }

  Future<void> select(String language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }
}

final languageProvider = NotifierProvider<LanguageController, String>(LanguageController.new);

typedef Translate = String Function(String en, String fr, String es);

final translateProvider = Provider<Translate>((ref) {
  final language = ref.watch(languageProvider);
  return (en, fr, es) => switch (language) {
        'fr' => fr,
        'es' => es,
        _ => en,
      };
});
