import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:horario/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

// Importaciones de tus módulos
import 'package:horario/screens/horario_screen.dart';
import 'package:horario/screens/welcome_setup_screen.dart';
import 'package:horario/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar zona horaria para programar alarmas exactas
  tz_data.initializeTimeZones();

  // Inicializar notificaciones usando la instancia global importada de horario_screen.dart
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await notificationsPlugin.initialize(initializationSettings);

  // Solicitar permisos de notificación (Necesario para Android 13+)
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isInitialized = false;
  static const _defaultPrimaryColor = Color(0xFF53D1B6);
  Color _primaryColor = _defaultPrimaryColor;

  String _profileName = 'Tu nombre';
  String _profileDetail = 'Organiza tu semana';
  String _headerImageUrl = '';
  bool _useHeaderImage = false;
  Uint8List? _headerImageBytes;

  Color _menuTextColor = Colors.white;
  Color _menuBackgroundColor = const Color(0xFF18232D);
  ThemeMode _themeMode = ThemeMode.dark;

  Color _screenBackgroundColor = const Color(0xFF0F1720);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isSetupDone = prefs.getBool('is_setup_done') ?? false;
    final colorValue = prefs.getInt('primary_color');
    if (mounted) {
      setState(() {
        _isInitialized = isSetupDone;
        if (colorValue != null) _primaryColor = Color(colorValue);
        _profileName = prefs.getString('profile_name') ?? _profileName;
        _profileDetail = prefs.getString('profile_detail') ?? _profileDetail;
        _headerImageUrl = prefs.getString('header_image_url') ?? '';
        _useHeaderImage = prefs.getBool('use_header_image') ?? false;

        final imageBase64 = prefs.getString('header_image_base64');
        if (imageBase64 != null && imageBase64.isNotEmpty) {
          _headerImageBytes = base64Decode(imageBase64);
        }

        final menuTextColorValue = prefs.getInt('menu_text_color');
        if (menuTextColorValue != null) {
          _menuTextColor = Color(menuTextColorValue);
        }

        final menuBackgroundColorValue = prefs.getInt('menu_background_color');
        if (menuBackgroundColorValue != null) {
          _menuBackgroundColor = Color(menuBackgroundColorValue);
        }

        _themeMode = prefs.getString('theme_mode') == 'light'
            ? ThemeMode.light
            : ThemeMode.dark;

        final menuBrightness = _themeMode == ThemeMode.light
            ? Brightness.light
            : Brightness.dark;

        _menuBackgroundColor = menuBackgroundForPrimary(
          _primaryColor,
          menuBrightness,
        );
        _menuTextColor = defaultTextColor(_menuBackgroundColor);
        _screenBackgroundColor = pageBackgroundForPrimary(
          _primaryColor,
          menuBrightness,
        );
      });
    }
  }

  Future<void> _completeSetup({
    required Color primaryColor,
    required String profileName,
    required String profileDetail,
    required DayLabelFormat dayFormat,
    required int weekStart, // <--- Añadido para recibir el inicio de semana
    required bool notificationsEnabled,
    required int notificationMinutes,
    required ThemeMode themeMode,
    required TimeFormat timeFormat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_setup_done', true);
    await prefs.setInt('primary_color', primaryColor.toARGB32());
    await prefs.setString('profile_name', profileName);
    await prefs.setString('profile_detail', profileDetail);
    await prefs.setString('day_label_format', dayFormat.name);
    await prefs.setInt(
      'week_start',
      weekStart,
    ); // <--- Guardado en preferencias
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    await prefs.setInt('notification_minutes', notificationMinutes);
    await prefs.setString(
      'theme_mode',
      themeMode == ThemeMode.light
          ? 'light'
          : themeMode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
    await prefs.setString('time_format', timeFormat.name);

    // Determinamos el brillo real para calcular el fondo correcto
    final brightness = themeMode == ThemeMode.light
        ? Brightness.light
        : themeMode == ThemeMode.dark
        ? Brightness.dark
        : WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final pageBackground = pageBackgroundForPrimary(primaryColor, brightness);
    final menuBackground = menuBackgroundForPrimary(primaryColor, brightness);

    setState(() {
      _isInitialized = true;
      _primaryColor = primaryColor;
      _profileName = profileName;
      _profileDetail = profileDetail;
      _themeMode = themeMode;
      _screenBackgroundColor = pageBackground;
      _menuBackgroundColor = menuBackground;
      _menuTextColor = defaultTextColor(menuBackground);
    });
  }

  Future<void> _setPrimaryColor(Color color) async {
    final brightness = _themeMode == ThemeMode.light
        ? Brightness.light
        : Brightness.dark;
    final pageBackground = pageBackgroundForPrimary(color, brightness);
    final menuBackground = menuBackgroundForPrimary(color, brightness);
    final menuText = defaultTextColor(menuBackground);

    setState(() {
      _primaryColor = color;
      _screenBackgroundColor = pageBackground;
      _menuBackgroundColor = menuBackground;
      _menuTextColor = menuText;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color.toARGB32());
    await prefs.setInt('screen_background_color', pageBackground.toARGB32());
    await prefs.setInt('menu_background_color', menuBackground.toARGB32());
    await prefs.setInt('menu_text_color', menuText.toARGB32());
  }

  Future<void> _setMenuTextColor(Color color) async {
    setState(() => _menuTextColor = color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('menu_text_color', color.toARGB32());
  }

  Future<void> _setMenuBackgroundColor(Color color) async {
    setState(() => _menuBackgroundColor = color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('menu_background_color', color.toARGB32());
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final brightness = mode == ThemeMode.light
        ? Brightness.light
        : mode == ThemeMode.dark
        ? Brightness.dark
        : WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final pageBackground = pageBackgroundForPrimary(_primaryColor, brightness);
    final menuBackground = menuBackgroundForPrimary(_primaryColor, brightness);
    final menuText = defaultTextColor(menuBackground);

    setState(() {
      _themeMode = mode;
      _screenBackgroundColor = pageBackground;
      _menuBackgroundColor = menuBackground;
      _menuTextColor = menuText;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
    await prefs.setInt('screen_background_color', pageBackground.toARGB32());
    await prefs.setInt('menu_background_color', menuBackground.toARGB32());
    await prefs.setInt('menu_text_color', menuText.toARGB32());
  }

  Future<void> _setScreenBackgroundColor(Color color) async {
    setState(() {
      _screenBackgroundColor = color;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('screen_background_color', color.toARGB32());
  }

  Future<void> _saveProfile({
    required String name,
    required String detail,
    required String imageUrl,
    required bool useImage,
    required Uint8List? imageBytes,
    required Color menuTextColor,
  }) async {
    setState(() {
      _profileName = name.trim().isEmpty ? 'Tu nombre' : name.trim();
      _profileDetail = detail.trim().isEmpty
          ? 'Organiza tu semana'
          : detail.trim();
      _headerImageUrl = imageUrl.trim();
      _headerImageBytes = imageBytes;
      _useHeaderImage =
          useImage && (imageBytes != null || _headerImageUrl.isNotEmpty);
      _menuTextColor = menuTextColor;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _profileName);
    await prefs.setString('profile_detail', _profileDetail);
    await prefs.setString('header_image_url', _headerImageUrl);
    await prefs.setBool('use_header_image', _useHeaderImage);

    if (_headerImageBytes != null) {
      await prefs.setString(
        'header_image_base64',
        base64Encode(_headerImageBytes!),
      );
    } else {
      await prefs.remove('header_image_base64');
    }

    await prefs.setInt('menu_text_color', _menuTextColor.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horario',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: _themeMode == ThemeMode.light
            ? Brightness.light
            : Brightness.dark,
        scaffoldBackgroundColor: _screenBackgroundColor,
        colorScheme:
            _primaryColor == Colors.black || _primaryColor == Colors.white
            ? ColorScheme(
                brightness: _themeMode == ThemeMode.light
                    ? Brightness.light
                    : Brightness.dark,
                primary: _primaryColor,
                onPrimary: _primaryColor == Colors.black
                    ? Colors.white
                    : Colors.black,
                secondary: _primaryColor,
                onSecondary: _primaryColor == Colors.black
                    ? Colors.white
                    : Colors.black,
                error: Colors.red,
                onError: Colors.white,
                surface: _themeMode == ThemeMode.light
                    ? Colors.white
                    : const Color(0xFF1E2630),
                onSurface:
                    _primaryColor == Colors.black &&
                        _themeMode == ThemeMode.light
                    ? Colors.black
                    : Colors.white,
              )
            : ColorScheme.fromSeed(
                seedColor: _primaryColor,
                brightness: _themeMode == ThemeMode.light
                    ? Brightness.light
                    : Brightness.dark,
              ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryColor;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryColor.withValues(alpha: 0.5);
            }
            return null;
          }),
        ),
        textTheme: TextTheme(
          titleSmall: TextStyle(
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w800,
            color: _primaryColor,
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _themeMode == ThemeMode.light
                ? Colors.black87
                : Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: IconThemeData(
            color: _themeMode == ThemeMode.light
                ? Colors.black87
                : Colors.white,
          ),
        ),
        dividerTheme: DividerThemeData(
          color: _themeMode == ThemeMode.light
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.08),
          space: 1,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _screenBackgroundColor,
        colorScheme:
            _primaryColor == Colors.black || _primaryColor == Colors.white
            ? ColorScheme(
                brightness: Brightness.dark,
                primary: _primaryColor,
                onPrimary: _primaryColor == Colors.black
                    ? Colors.white
                    : Colors.black,
                secondary: _primaryColor,
                onSecondary: _primaryColor == Colors.black
                    ? Colors.white
                    : Colors.black,
                error: Colors.red,
                onError: Colors.white,
                surface: const Color(0xFF1E2630),
                onSurface: Colors.white,
              )
            : ColorScheme.fromSeed(
                seedColor: _primaryColor,
                brightness: Brightness.dark,
              ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryColor;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _primaryColor.withValues(alpha: 0.5);
            }
            return null;
          }),
        ),
        textTheme: TextTheme(
          titleSmall: TextStyle(
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w800,
            color: _primaryColor,
          ),
        ),
        useMaterial3: true,
      ),
      home: !_isInitialized
          ? WelcomeSetupScreen(
              initialThemeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
              onPrimaryColorChanged: _setPrimaryColor,
              onFinishSetup: _completeSetup,
            )
          : HorarioScreen(
              colorOptions: allMateriaColors,
              primaryColor: _primaryColor,
              onPrimaryColorChanged: _setPrimaryColor,
              profileName: _profileName,
              profileDetail: _profileDetail,
              headerImageUrl: _headerImageUrl,
              useHeaderImage: _useHeaderImage,
              headerImageBytes: _headerImageBytes,
              menuTextColor: _menuTextColor,
              onMenuTextColorChanged: _setMenuTextColor,
              menuBackgroundColor: _menuBackgroundColor,
              onMenuBackgroundColorChanged: _setMenuBackgroundColor,
              themeMode: _themeMode,
              screenBackgroundColor: _screenBackgroundColor,
              backgroundOptions: allMateriaColors,
              onThemeModeChanged: _setThemeMode,
              onScreenBackgroundColorChanged: _setScreenBackgroundColor,
              onProfileChanged: _saveProfile,
            ),
    );
  }
}
