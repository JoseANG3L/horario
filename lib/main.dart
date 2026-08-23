import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'dart:convert';

enum DayLabelFormat { full, short, initial }

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar zona horaria
  tz_data.initializeTimeZones();

  // Inicializar notificaciones
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await _notificationsPlugin.initialize(initializationSettings);

  // Solicitar permisos de notificación (Android 13+)
  await _notificationsPlugin
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
  static const _defaultPrimaryColor = Color(0xFF53D1B6);
  Color _primaryColor = _defaultPrimaryColor;

  static const _lightPrimaryColorOptions = [
    Color(0xFF53D1B6),
    Color(0xFF60A5FA),
    Color(0xFFFCD34D),
    Color(0xFFFDA4AF),
    Color(0xFFC4B5FD),
    Color(0xFF5EEAD4),
    Color(0xFFA3E635),
    Color(0xFFFECACA),
  ];
  static const _darkPrimaryColorOptions = [
    Color(0xFF0F766E),
    Color(0xFF1D4ED8),
    Color(0xFFB45309),
    Color(0xFFBE123C),
    Color(0xFF6D28D9),
    Color(0xFF0E7490),
    Color(0xFF3F6212),
    Color(0xFF991B1B),
  ];
  static const _colorOptions = [
    ..._lightPrimaryColorOptions,
    ..._darkPrimaryColorOptions,
  ];
  String _profileName = 'Tu nombre';
  String _profileDetail = 'Organiza tu semana';
  String _headerImageUrl = '';
  bool _useHeaderImage = false;
  Uint8List? _headerImageBytes;
  Color _menuTextColor = Colors.white;
  Color _menuBackgroundColor = const Color(0xFF18232D);
  ThemeMode _themeMode = ThemeMode.dark;
  Color _screenBackgroundColor = const Color(0xFF0F1720);
  Color _lightScreenBackgroundColor = _lightBackgroundOptions.first;
  Color _darkScreenBackgroundColor = _darkBackgroundOptions.first;

  static const _darkBackgroundOptions = [
    Color(0xFF0F1720),
    Color(0xFF0B1220),
    Color(0xFF0E1622),
    Color(0xFF111827),
    Color(0xFF141A24),
    Color(0xFF17212B),
    Color(0xFF1B1B2F),
    Color(0xFF202A36),
    Color(0xFF27323B),
    Color(0xFF24313A),
    Color(0xFF102027),
    Color(0xFF082026),
  ];
  static const _lightBackgroundOptions = [
    Color(0xFFF4F7F6),
    Color(0xFFF5F7FB),
    Color(0xFFFFF8EE),
    Color(0xFFF8F3FA),
    Color(0xFFEFF8F7),
    Color(0xFFFFFFFF),
    Color(0xFFFCFCFD),
    Color(0xFFF7FAFC),
    Color(0xFFF3F6F5),
    Color(0xFFF9F7EE),
    Color(0xFFFEFBF3),
    Color(0xFFF2F5F8),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('primary_color');
    if (mounted) {
      setState(() {
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
        final legacyScreenBackgroundColor = prefs.getInt(
          'screen_background_color',
        );
        final lightScreenBackgroundColorValue = prefs.getInt(
          'light_screen_background_color',
        );
        final darkScreenBackgroundColorValue = prefs.getInt(
          'dark_screen_background_color',
        );
        _lightScreenBackgroundColor = lightScreenBackgroundColorValue != null
            ? Color(lightScreenBackgroundColorValue)
            : _lightBackgroundOptions.first;
        _darkScreenBackgroundColor = darkScreenBackgroundColorValue != null
            ? Color(darkScreenBackgroundColorValue)
            : legacyScreenBackgroundColor != null &&
                  _themeMode == ThemeMode.dark
            ? Color(legacyScreenBackgroundColor)
            : _darkBackgroundOptions.first;
        _screenBackgroundColor = _themeMode == ThemeMode.light
            ? _lightScreenBackgroundColor
            : _darkScreenBackgroundColor;
        final menuBrightness = _themeMode == ThemeMode.light
            ? Brightness.light
            : Brightness.dark;
        _menuBackgroundColor = _menuBackgroundForPrimary(
          _primaryColor,
          menuBrightness,
        );
        _menuTextColor = _defaultTextColor(_menuBackgroundColor);
      });
    }
  }

  Future<void> _setPrimaryColor(Color color) async {
    final brightness = _themeMode == ThemeMode.light
        ? Brightness.light
        : Brightness.dark;
    final pageBackground = _pageBackgroundForPrimary(color, brightness);
    final menuBackground = _menuBackgroundForPrimary(color, brightness);
    final menuText = _defaultTextColor(menuBackground);
    setState(() {
      _primaryColor = color;
      _screenBackgroundColor = pageBackground;
      _menuBackgroundColor = menuBackground;
      _menuTextColor = menuText;
      if (_themeMode == ThemeMode.light) {
        _lightScreenBackgroundColor = pageBackground;
      } else {
        _darkScreenBackgroundColor = pageBackground;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color.toARGB32());
    await prefs.setInt('screen_background_color', pageBackground.toARGB32());
    await prefs.setInt(
      _themeMode == ThemeMode.light
          ? 'light_screen_background_color'
          : 'dark_screen_background_color',
      pageBackground.toARGB32(),
    );
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
        : Brightness.dark;
    final pageBackground = _pageBackgroundForPrimary(_primaryColor, brightness);
    final menuBackground = _menuBackgroundForPrimary(_primaryColor, brightness);
    final menuText = _defaultTextColor(menuBackground);
    setState(() {
      _themeMode = mode;
      _screenBackgroundColor = pageBackground;
      _menuBackgroundColor = menuBackground;
      _menuTextColor = menuText;
      if (mode == ThemeMode.light) {
        _lightScreenBackgroundColor = pageBackground;
      } else {
        _darkScreenBackgroundColor = pageBackground;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      mode == ThemeMode.light ? 'light' : 'dark',
    );
    await prefs.setInt(
      'screen_background_color',
      _screenBackgroundColor.toARGB32(),
    );
    await prefs.setInt(
      mode == ThemeMode.light
          ? 'light_screen_background_color'
          : 'dark_screen_background_color',
      _screenBackgroundColor.toARGB32(),
    );
    await prefs.setInt('menu_background_color', menuBackground.toARGB32());
    await prefs.setInt('menu_text_color', menuText.toARGB32());
  }

  Future<void> _setScreenBackgroundColor(Color color) async {
    setState(() {
      _screenBackgroundColor = color;
      if (_themeMode == ThemeMode.light) {
        _lightScreenBackgroundColor = color;
      } else {
        _darkScreenBackgroundColor = color;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('screen_background_color', color.toARGB32());
    await prefs.setInt(
      _themeMode == ThemeMode.light
          ? 'light_screen_background_color'
          : 'dark_screen_background_color',
      color.toARGB32(),
    );
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: _themeMode == ThemeMode.light
              ? Brightness.light
              : Brightness.dark,
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
      home: HorarioScreen(
        colorOptions: _colorOptions,
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
        backgroundOptions: _themeMode == ThemeMode.light
            ? _lightBackgroundOptions
            : _darkBackgroundOptions,
        onThemeModeChanged: _setThemeMode,
        onScreenBackgroundColorChanged: _setScreenBackgroundColor,
        onProfileChanged: _saveProfile,
      ),
    );
  }
}

class Clase {
  final String materia;
  final String profesor;
  final String nrc;
  final String edificio;
  final String aula;
  final String horaInicio;
  final String horaFin;
  final String letraInicial;
  final Color color;
  final Color? cardColor;

  const Clase({
    required this.materia,
    required this.profesor,
    required this.nrc,
    required this.edificio,
    required this.aula,
    required this.horaInicio,
    required this.horaFin,
    required this.letraInicial,
    required this.color,
    this.cardColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'materia': materia,
      'profesor': profesor,
      'nrc': nrc,
      'edificio': edificio,
      'aula': aula,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'letraInicial': letraInicial,
      'color': color.toARGB32(),
      if (cardColor != null) 'cardColor': cardColor!.toARGB32(),
    };
  }

  factory Clase.fromJson(Map<String, dynamic> json) {
    return Clase(
      materia: json['materia'],
      profesor: json['profesor'],
      nrc: json['nrc'],
      edificio: json['edificio'],
      aula: json['aula'],
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
      letraInicial: json['letraInicial'],
      color: Color(json['color']),
      cardColor: json.containsKey('cardColor')
          ? Color(json['cardColor'])
          : null,
    );
  }
}

int _compareClassesByStartTime(Clase first, Clase second) {
  int minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  return minutes(first.horaInicio).compareTo(minutes(second.horaInicio));
}

class MateriaGuardada {
  final String materia;
  final String profesor;
  final String nrc;
  final String edificio;
  final String aula;
  final Color color;
  final Color iconColor;
  final Color textColor;
  final Color cardColor;

  const MateriaGuardada({
    required this.materia,
    required this.profesor,
    required this.nrc,
    required this.edificio,
    required this.aula,
    required this.color,
    required this.iconColor,
    required this.textColor,
    required this.cardColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'materia': materia,
      'profesor': profesor,
      'nrc': nrc,
      'edificio': edificio,
      'aula': aula,
      'color': color.toARGB32(),
      'iconColor': iconColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'cardColor': cardColor.toARGB32(),
    };
  }

  factory MateriaGuardada.fromJson(Map<String, dynamic> json) {
    return MateriaGuardada(
      materia: json['materia'],
      profesor: json['profesor'],
      nrc: json['nrc'],
      edificio: json['edificio'],
      aula: json['aula'],
      color: Color(json['color']),
      iconColor: json.containsKey('iconColor')
          ? Color(json['iconColor'])
          : _defaultIconColor(Color(json['color'])),
      textColor: json.containsKey('textColor')
          ? Color(json['textColor'])
          : _defaultTextColor(Color(json['color'])),
      cardColor: json.containsKey('cardColor')
          ? Color(json['cardColor'])
          : _defaultCardColor(Color(json['color'])),
    );
  }
}

Color _cardColorForTheme(Color color, Brightness brightness) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(brightness == Brightness.light ? 0.89 : 0.16)
      .withSaturation(brightness == Brightness.light ? 0.48 : 0.22)
      .toColor();
}

Color _materiaColorForTheme(Color color, Brightness brightness) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(brightness == Brightness.light ? 0.80 : 0.32)
      .withSaturation(brightness == Brightness.light ? 0.88 : 0.68)
      .toColor();
}

Color _defaultCardColor(Color background) => _cardColorForTheme(
  background,
  background.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
);

BoxDecoration _scheduleCardDecoration(
  BuildContext context, {
  required Color backgroundColor,
  required Color accentColor,
}) {
  return BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(18),
  );
}

Color _defaultIconColor(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
Color _defaultTextColor(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black : Colors.white;

Color _pageBackgroundForPrimary(Color color, Brightness brightness) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(brightness == Brightness.light ? 0.94 : 0.12)
      .withSaturation(brightness == Brightness.light ? 0.22 : 0.32)
      .toColor();
}

Color _menuBackgroundForPrimary(Color color, Brightness brightness) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(brightness == Brightness.light ? 0.88 : 0.08)
      .withSaturation(brightness == Brightness.light ? 0.16 : 0.28)
      .toColor();
}

class HorarioScreen extends StatefulWidget {
  final List<Color> colorOptions;
  final Color primaryColor;
  final Future<void> Function(Color color) onPrimaryColorChanged;
  final String profileName;
  final String profileDetail;
  final String headerImageUrl;
  final bool useHeaderImage;
  final Uint8List? headerImageBytes;
  final Color menuTextColor;
  final Future<void> Function(Color color) onMenuTextColorChanged;
  final Color menuBackgroundColor;
  final Future<void> Function(Color color) onMenuBackgroundColorChanged;
  final ThemeMode themeMode;
  final Color screenBackgroundColor;
  final List<Color> backgroundOptions;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;
  final Future<void> Function(Color color) onScreenBackgroundColorChanged;
  final Future<void> Function({
    required String name,
    required String detail,
    required String imageUrl,
    required bool useImage,
    required Uint8List? imageBytes,
    required Color menuTextColor,
  })
  onProfileChanged;

  const HorarioScreen({
    super.key,
    required this.colorOptions,
    required this.primaryColor,
    required this.onPrimaryColorChanged,
    required this.profileName,
    required this.profileDetail,
    required this.headerImageUrl,
    required this.useHeaderImage,
    required this.headerImageBytes,
    required this.menuTextColor,
    required this.onMenuTextColorChanged,
    required this.menuBackgroundColor,
    required this.onMenuBackgroundColorChanged,
    required this.themeMode,
    required this.screenBackgroundColor,
    required this.backgroundOptions,
    required this.onThemeModeChanged,
    required this.onScreenBackgroundColorChanged,
    required this.onProfileChanged,
  });

  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDay = 0;
  int _selectedTab = 0; // 0 = Horario, 1 = Materias Guardadas
  bool _notificationsEnabled = false;
  bool _showWeekend = true;
  int _weekStart = 1;
  DayLabelFormat _dayLabelFormat = DayLabelFormat.full;

  static const _allDays = [
    'Domingo',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];
  final List<List<Clase>> _classesByDay = [[], [], [], [], [], [], []];
  final List<MateriaGuardada> _materiasGuardadas = [];

  List<int> get _visibleDayIndices {
    final indices = List.generate(7, (offset) => (_weekStart + offset) % 7);
    return _showWeekend
        ? indices
        : indices.where((index) => index >= 1 && index <= 5).toList();
  }

  List<String> get _visibleDays =>
      _visibleDayIndices.map((index) => _allDays[index]).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    // Establecer el día actual
    final today = DateTime.now().weekday; // 1 = Lunes, 7 = Domingo
    if (today >= 1 && today <= 6) {
      _selectedDay = today;
      _tabController.index = _selectedDay;
    } else if (today == 7) {
      _selectedDay = 0;
      _tabController.index = 0;
    }

    _tabController.addListener(() {
      _handleDayTabChange();
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _showWeekend = prefs.getBool('show_weekend') ?? true;
    final savedWeekStart = prefs.getInt('week_start') ?? 1;
    _weekStart = savedWeekStart >= 0 && savedWeekStart <= 6
        ? savedWeekStart
        : 1;
    final savedLabelFormat = prefs.getString('day_label_format');
    _dayLabelFormat = DayLabelFormat.values.firstWhere(
      (format) => format.name == savedLabelFormat,
      orElse: () => DayLabelFormat.full,
    );
    _replaceTabController();

    // Cargar horario
    for (int i = 0; i < _allDays.length; i++) {
      final classesJson = prefs.getStringList('horario_dia_$i');
      if (classesJson != null) {
        setState(() {
          _classesByDay[i] = classesJson
              .map((json) => Clase.fromJson(jsonDecode(json)))
              .toList();
          _classesByDay[i].sort(_compareClassesByStartTime);
        });
      }
    }

    // Cargar materias guardadas
    final materiasJson = prefs.getStringList('materias_guardadas');
    if (materiasJson != null) {
      setState(() {
        _materiasGuardadas.clear();
        _materiasGuardadas.addAll(
          materiasJson.map(
            (json) => MateriaGuardada.fromJson(jsonDecode(json)),
          ),
        );
      });
    }

    if (_classesByDay.every((classes) => classes.isEmpty)) {
      await _addSampleSchedule();
    }
    if (_materiasGuardadas.isEmpty) {
      await _addSampleSavedSubjects();
    }
    if (mounted) setState(() {});

    // Cargar preferencia de notificaciones
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });

    // Programar notificación si está activado
    if (_notificationsEnabled) {
      await _scheduleNextClassNotification();
    }
  }

  void _replaceTabController() {
    final selectedIndex = _visibleDayIndices.indexOf(_selectedDay);
    _tabController.dispose();
    _tabController = TabController(
      length: _visibleDayIndices.length,
      vsync: this,
      initialIndex: selectedIndex >= 0 ? selectedIndex : 0,
    );
    _tabController.addListener(_handleDayTabChange);
    if (selectedIndex < 0) {
      _selectedDay = _visibleDayIndices.first;
    }
    if (mounted) setState(() {});
  }

  void _handleDayTabChange() {
    if (!_tabController.indexIsChanging &&
        _tabController.index < _visibleDayIndices.length) {
      final day = _visibleDayIndices[_tabController.index];
      if (_selectedDay != day) setState(() => _selectedDay = day);
    }
  }

  Future<void> _updateWeekSettings({
    bool? showWeekend,
    int? weekStart,
    DayLabelFormat? labelFormat,
  }) async {
    _showWeekend = showWeekend ?? _showWeekend;
    _weekStart = weekStart ?? _weekStart;
    _dayLabelFormat = labelFormat ?? _dayLabelFormat;
    _replaceTabController();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_weekend', _showWeekend);
    await prefs.setInt('week_start', _weekStart);
    await prefs.setString('day_label_format', _dayLabelFormat.name);
  }

  String _formatDay(String day) {
    if (_dayLabelFormat == DayLabelFormat.initial) {
      return day == 'Miércoles' ? 'X' : day.substring(0, 1);
    }
    if (_dayLabelFormat == DayLabelFormat.short) {
      return day.substring(0, 3);
    }
    return day;
  }

  Future<void> _addSampleSchedule() async {
    const sampleSubjects = [
      ('Matemáticas', '08:00', '09:00'),
      ('Programación', '09:15', '10:15'),
      ('Diseño', '10:30', '11:30'),
      ('Inglés', '11:45', '12:45'),
    ];
    const sampleColors = [
      Color(0xFF4DD0E1),
      Color(0xFFFFB74D),
      Color(0xFFE57373),
      Color(0xFFAED581),
    ];

    setState(() {
      for (var dayIndex = 0; dayIndex < _allDays.length; dayIndex++) {
        _classesByDay[dayIndex] = [
          for (
            var subjectIndex = 0;
            subjectIndex < sampleSubjects.length;
            subjectIndex++
          )
            Clase(
              materia: sampleSubjects[subjectIndex].$1,
              profesor: 'Profesor de prueba',
              nrc: 'PRUEBA-${dayIndex + 1}${subjectIndex + 1}',
              edificio: 'Edificio A',
              aula: 'A-${subjectIndex + 1}01',
              horaInicio: sampleSubjects[subjectIndex].$2,
              horaFin: sampleSubjects[subjectIndex].$3,
              letraInicial: sampleSubjects[subjectIndex].$1
                  .substring(0, 1)
                  .toUpperCase(),
              color: sampleColors[subjectIndex],
              cardColor: sampleColors[subjectIndex],
            ),
        ];
      }
    });
    await _saveSchedule();
  }

  Future<void> _addSampleSavedSubjects() async {
    const sampleSubjects = [
      ('Matemáticas', 'Profesor de prueba', Color(0xFF4DD0E1)),
      ('Programación', 'Profesor de prueba', Color(0xFFFFB74D)),
      ('Diseño', 'Profesor de prueba', Color(0xFFE57373)),
      ('Inglés', 'Profesor de prueba', Color(0xFFAED581)),
    ];

    setState(() {
      _materiasGuardadas.addAll(
        sampleSubjects.map(
          (subject) => MateriaGuardada(
            materia: subject.$1,
            profesor: subject.$2,
            nrc: 'MUESTRA',
            edificio: 'Edificio A',
            aula: 'Aula de prueba',
            color: subject.$3,
            iconColor: _defaultIconColor(subject.$3),
            textColor: _defaultTextColor(subject.$3),
            cardColor: subject.$3,
          ),
        ),
      );
    });
    await _saveMateriasGuardadas();
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _allDays.length; i++) {
      final classesJson = _classesByDay[i]
          .map((clase) => jsonEncode(clase.toJson()))
          .toList();
      await prefs.setStringList('horario_dia_$i', classesJson);
    }
  }

  Future<void> _saveMateriasGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final materiasJson = _materiasGuardadas
        .map((materia) => jsonEncode(materia.toJson()))
        .toList();
    await prefs.setStringList('materias_guardadas', materiasJson);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddClassSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _AddClassSheet(
        days: _visibleDays,
        initialDay: _visibleDayIndices.indexOf(_selectedDay),
        materiasGuardadas: _materiasGuardadas,
        onSave: (day, newClass) async {
          setState(() {
            final canonicalDay = _visibleDayIndices[day];
            _classesByDay[canonicalDay].add(newClass);
            _classesByDay[canonicalDay].sort(_compareClassesByStartTime);
          });
          await _saveSchedule();
          _tabController.animateTo(day);
        },
      ),
    );
  }

  Future<void> _openSaveMateriaSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _SaveMateriaSheet(
        onSave: (materia) async {
          setState(() => _materiasGuardadas.add(materia));
          await _saveMateriasGuardadas();
        },
      ),
    );
  }

  void _deleteMateriaGuardada(int index) async {
    setState(() => _materiasGuardadas.removeAt(index));
    await _saveMateriasGuardadas();
  }

  Future<void> _editMateriaGuardada(int index) async {
    final materia = _materiasGuardadas[index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _EditMateriaSheet(
        initialMateria: materia,
        onSave: (updatedMateria) async {
          final oldMateriaName = materia.materia;
          setState(() {
            _materiasGuardadas[index] = updatedMateria;
            // Actualizar el color en todas las clases del horario que tengan esta materia
            for (int day = 0; day < _allDays.length; day++) {
              for (int i = 0; i < _classesByDay[day].length; i++) {
                if (_classesByDay[day][i].materia == oldMateriaName) {
                  _classesByDay[day][i] = Clase(
                    materia: updatedMateria.materia,
                    profesor: updatedMateria.profesor,
                    nrc: updatedMateria.nrc,
                    edificio: updatedMateria.edificio,
                    aula: updatedMateria.aula,
                    horaInicio: _classesByDay[day][i].horaInicio,
                    horaFin: _classesByDay[day][i].horaFin,
                    color: updatedMateria.color,
                    cardColor: updatedMateria.cardColor,
                    letraInicial: updatedMateria.materia
                        .substring(0, 1)
                        .toUpperCase(),
                  );
                }
              }
            }
          });
          await _saveMateriasGuardadas();
          await _saveSchedule();
        },
      ),
    );
  }

  void _deleteClass(int dayIndex, int classIndex) async {
    setState(() => _classesByDay[dayIndex].removeAt(classIndex));
    await _saveSchedule();
  }

  Future<void> _editClass(int dayIndex, int classIndex) async {
    final clase = _classesByDay[dayIndex][classIndex];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _EditClassSheet(
        days: _visibleDays,
        initialDay: _visibleDayIndices.indexOf(dayIndex),
        materiasGuardadas: _materiasGuardadas,
        initialClass: clase,
        onSave: (day, updatedClass) async {
          setState(() {
            final canonicalDay = _visibleDayIndices[day];
            _classesByDay[canonicalDay][classIndex] = updatedClass;
            _classesByDay[canonicalDay].sort(_compareClassesByStartTime);
          });
          await _saveSchedule();
          _tabController.animateTo(day);
          if (_notificationsEnabled) {
            await _scheduleNextClassNotification();
          }
        },
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _notificationsEnabled = value);
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      await _scheduleNextClassNotification();
    } else {
      await _notificationsPlugin.cancelAll();
    }
  }

  Future<void> _scheduleNextClassNotification() async {
    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();
    Clase? nextClass;
    DateTime? nextClassTime;

    // Buscar la próxima clase
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final checkDate = now.add(Duration(days: dayOffset));
      final weekday = checkDate.weekday; // 1 = Lunes, 7 = Domingo

      if (weekday >= 1 && weekday <= 5) {
        final dayIndex = weekday - 1;
        final classes = _classesByDay[dayIndex];

        for (final clase in classes) {
          final classTime = _parseClassTime(checkDate, clase.horaInicio);

          if (classTime.isAfter(now)) {
            if (nextClassTime == null || classTime.isBefore(nextClassTime)) {
              nextClass = clase;
              nextClassTime = classTime;
            }
          }
        }
      }
    }

    if (nextClass != null && nextClassTime != null) {
      // Programar notificación 15 minutos antes
      final notificationTime = nextClassTime.subtract(
        const Duration(minutes: 15),
      );

      if (notificationTime.isAfter(now)) {
        final androidDetails = AndroidNotificationDetails(
          'class_notifications',
          'Notificaciones de Clases',
          channelDescription: 'Notificaciones para recordatorios de clases',
          importance: Importance.high,
          priority: Priority.high,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
        );

        await _notificationsPlugin.zonedSchedule(
          0,
          'Próxima clase: ${nextClass.materia}',
          'Tu clase comienza en 15 minutos en ${nextClass.aula}',
          tz.TZDateTime.from(notificationTime, tz.local),
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
      }
    }
  }

  DateTime _parseClassTime(DateTime date, String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedTab == 1
              ? 'Materias'
              : _selectedTab == 2
              ? 'Perfil'
              : _selectedTab == 3
              ? 'Personalizar'
              : _selectedTab == 4
              ? 'Notificaciones'
              : 'Horario',
        ),
        titleSpacing: 4,
        backgroundColor: widget.screenBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: widget.themeMode == ThemeMode.dark
                  ? 'Cambiar a modo claro'
                  : 'Cambiar a modo oscuro',
              icon: Icon(
                widget.themeMode == ThemeMode.dark
                    ? LucideIcons.sun
                    : LucideIcons.moon,
              ),
              onPressed: () {
                widget.onThemeModeChanged(
                  widget.themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: widget.menuBackgroundColor,
        child: Material(
          color: widget.menuBackgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: widget.screenBackgroundColor,
                  image:
                      widget.useHeaderImage &&
                          (widget.headerImageBytes != null ||
                              widget.headerImageUrl.isNotEmpty)
                      ? DecorationImage(
                          image: widget.headerImageBytes != null
                              ? MemoryImage(widget.headerImageBytes!)
                              : NetworkImage(widget.headerImageUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.42),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.profileName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: widget.menuTextColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.profileDetail,
                      style: TextStyle(
                        color: widget.menuTextColor.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(LucideIcons.user, color: widget.menuTextColor),
                title: Text(
                  'Perfil',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 2,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  LucideIcons.calendar,
                  color: widget.menuTextColor,
                ),
                title: Text(
                  'Horario',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 0,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  LucideIcons.bookmark,
                  color: widget.menuTextColor,
                ),
                title: Text(
                  'Materias',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 1,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.palette, color: widget.menuTextColor),
                title: Text(
                  'Personalizar',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 3,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 3);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.bell, color: widget.menuTextColor),
                title: Text(
                  'Notificaciones',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 4,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 4);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _selectedTab == 0
            ? _ScheduleTab(
                tabController: _tabController,
                days: _visibleDays.map(_formatDay).toList(),
                dayIndices: _visibleDayIndices,
                classesByDay: _classesByDay,
                selectedDay: _visibleDayIndices.indexOf(_selectedDay),
                onSelectedDayChanged: (day) {
                  setState(() => _selectedDay = _visibleDayIndices[day]);
                },
                onDeleteClass: _deleteClass,
                onEditClass: _editClass,
              )
            : _selectedTab == 1
            ? _MateriasGuardadasTab(
                materias: _materiasGuardadas,
                onDelete: _deleteMateriaGuardada,
                onAddToSchedule: (materia) async {
                  await _openAddClassSheetWithMateria(materia);
                },
                onEdit: _editMateriaGuardada,
              )
            : _selectedTab == 2
            ? _ProfileSection(
                profileName: widget.profileName,
                profileDetail: widget.profileDetail,
                useHeaderImage: widget.useHeaderImage,
                headerImageBytes: widget.headerImageBytes,
                primaryColor: widget.primaryColor,
                themeMode: widget.themeMode,
                onProfileChanged: widget.onProfileChanged,
              )
            : _selectedTab == 3
            ? _AppearanceSection(
                colorOptions: widget.colorOptions,
                primaryColor: widget.primaryColor,
                onColorChanged: widget.onPrimaryColorChanged,
                menuTextColor: widget.menuTextColor,
                onMenuTextColorChanged: widget.onMenuTextColorChanged,
                menuBackgroundColor: widget.menuBackgroundColor,
                onMenuBackgroundColorChanged:
                    widget.onMenuBackgroundColorChanged,
                themeMode: widget.themeMode,
                screenBackgroundColor: widget.screenBackgroundColor,
                backgroundOptions: widget.backgroundOptions,
                onThemeModeChanged: widget.onThemeModeChanged,
                onScreenBackgroundColorChanged:
                    widget.onScreenBackgroundColorChanged,
                showWeekend: _showWeekend,
                weekStart: _weekStart,
                dayLabelFormat: _dayLabelFormat,
                onWeekSettingsChanged: _updateWeekSettings,
              )
            : _NotificationsSection(
                notificationsEnabled: _notificationsEnabled,
                onNotificationsChanged: _toggleNotifications,
              ),
      ),
      floatingActionButton: _selectedTab == 2 || _selectedTab == 4
          ? null
          : FloatingActionButton(
              onPressed: _selectedTab == 0
                  ? _openAddClassSheet
                  : _openSaveMateriaSheet,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Icon(
                _selectedTab == 0 ? LucideIcons.plus : LucideIcons.bookmarkPlus,
              ),
            ),
    );
  }

  Future<void> _openAddClassSheetWithMateria(MateriaGuardada materia) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _AddClassSheet(
        days: _visibleDays,
        initialDay: _visibleDayIndices.indexOf(_selectedDay),
        materiasGuardadas: _materiasGuardadas,
        preselectedMateria: materia,
        onSave: (day, newClass) async {
          setState(() {
            final canonicalDay = _visibleDayIndices[day];
            _classesByDay[canonicalDay].add(newClass);
            _classesByDay[canonicalDay].sort(_compareClassesByStartTime);
          });
          await _saveSchedule();
          _tabController.animateTo(day);
        },
      ),
    );
  }
}

class _AppearanceSection extends StatefulWidget {
  final List<Color> colorOptions;
  final Color primaryColor;
  final Future<void> Function(Color color) onColorChanged;
  final Color menuTextColor;
  final Future<void> Function(Color color) onMenuTextColorChanged;
  final Color menuBackgroundColor;
  final Future<void> Function(Color color) onMenuBackgroundColorChanged;
  final ThemeMode themeMode;
  final Color screenBackgroundColor;
  final List<Color> backgroundOptions;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;
  final Future<void> Function(Color color) onScreenBackgroundColorChanged;
  final bool showWeekend;
  final int weekStart;
  final DayLabelFormat dayLabelFormat;
  final Future<void> Function({
    bool? showWeekend,
    int? weekStart,
    DayLabelFormat? labelFormat,
  })
  onWeekSettingsChanged;

  const _AppearanceSection({
    required this.colorOptions,
    required this.primaryColor,
    required this.onColorChanged,
    required this.menuTextColor,
    required this.onMenuTextColorChanged,
    required this.menuBackgroundColor,
    required this.onMenuBackgroundColorChanged,
    required this.themeMode,
    required this.screenBackgroundColor,
    required this.backgroundOptions,
    required this.onThemeModeChanged,
    required this.onScreenBackgroundColorChanged,
    required this.showWeekend,
    required this.weekStart,
    required this.dayLabelFormat,
    required this.onWeekSettingsChanged,
  });

  @override
  State<_AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<_AppearanceSection> {
  late bool _showWeekend;
  late int _weekStart;
  late DayLabelFormat _dayLabelFormat;

  List<String> get _previewDays {
    return const ['Lunes'];
  }

  String _previewLabel(String day) {
    if (_dayLabelFormat == DayLabelFormat.initial) return day.substring(0, 1);
    if (_dayLabelFormat == DayLabelFormat.short) return day.substring(0, 3);
    return day;
  }

  @override
  void initState() {
    super.initState();
    _showWeekend = widget.showWeekend;
    _weekStart = widget.weekStart;
    _dayLabelFormat = widget.dayLabelFormat;
  }

  @override
  void dispose() {
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final borderColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final selectedPrimaryColor = widget.primaryColor;
    final baseColorCount = widget.colorOptions.length ~/ 2;
    final lightColorOptions = widget.colorOptions.take(baseColorCount).toList();
    final darkColorOptions = widget.colorOptions.skip(baseColorCount).toList();
    if (!widget.colorOptions.any(
      (color) => color.toARGB32() == selectedPrimaryColor.toARGB32(),
    )) {
      final selectedGroup =
          HSLColor.fromColor(selectedPrimaryColor).lightness >= 0.58
          ? lightColorOptions
          : darkColorOptions;
      selectedGroup.add(selectedPrimaryColor);
    }

    List<Widget> colorSwatches(List<Color> colors) {
      return colors.map((color) {
        final isSelected = selectedPrimaryColor.toARGB32() == color.toARGB32();
        return Semantics(
          label: 'Seleccionar color principal',
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: () => widget.onColorChanged(color),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(LucideIcons.check, color: _defaultTextColor(color))
                  : null,
            ),
          ),
        );
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Color principal',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Se usa en botones, pestañas y nuevas materias.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        Text('Colores claros', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: colorSwatches(lightColorOptions),
        ),
        const SizedBox(height: 14),
        Text('Colores oscuros', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: colorSwatches(darkColorOptions),
        ),
        const SizedBox(height: 28),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opciones de semana',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajusta los días que quieres ver en tu horario.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar sábado y domingo'),
              value: _showWeekend,
              onChanged: (value) async {
                setState(() => _showWeekend = value);
                await widget.onWeekSettingsChanged(showWeekend: value);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _weekStart,
              decoration: _fieldDecoration(
                'Comenzar la semana en',
                LucideIcons.calendarRange,
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Lunes')),
                DropdownMenuItem(value: 2, child: Text('Martes')),
                DropdownMenuItem(value: 3, child: Text('Miércoles')),
                DropdownMenuItem(value: 4, child: Text('Jueves')),
                DropdownMenuItem(value: 5, child: Text('Viernes')),
                DropdownMenuItem(value: 6, child: Text('Sábado')),
                DropdownMenuItem(value: 0, child: Text('Domingo')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _weekStart = value);
                await widget.onWeekSettingsChanged(weekStart: value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Formato de los días',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DayLabelFormat>(
                segments: const [
                  ButtonSegment(
                    value: DayLabelFormat.full,
                    label: Text('Todo'),
                  ),
                  ButtonSegment(
                    value: DayLabelFormat.short,
                    label: Text('3 letras'),
                  ),
                  ButtonSegment(
                    value: DayLabelFormat.initial,
                    label: Text('Inicial'),
                  ),
                ],
                selected: {_dayLabelFormat},
                onSelectionChanged: (selection) async {
                  final format = selection.first;
                  setState(() => _dayLabelFormat = format);
                  await widget.onWeekSettingsChanged(labelFormat: format);
                },
              ),
            ),
            const SizedBox(height: 18),
            Text('Vista previa', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _previewDays.map((day) {
                final isWednesday = day == 'Miércoles';
                return Chip(
                  avatar: Icon(
                    isWednesday ? LucideIcons.badgeX : LucideIcons.calendar,
                    size: 16,
                  ),
                  label: Text(_previewLabel(day)),
                  side: BorderSide.none,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileSection extends StatefulWidget {
  final String profileName;
  final String profileDetail;
  final bool useHeaderImage;
  final Uint8List? headerImageBytes;
  final Color primaryColor;
  final ThemeMode themeMode;
  final Future<void> Function({
    required String name,
    required String detail,
    required String imageUrl,
    required bool useImage,
    required Uint8List? imageBytes,
    required Color menuTextColor,
  })
  onProfileChanged;

  const _ProfileSection({
    required this.profileName,
    required this.profileDetail,
    required this.useHeaderImage,
    required this.headerImageBytes,
    required this.primaryColor,
    required this.themeMode,
    required this.onProfileChanged,
  });

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _detailController;
  late bool _useImage;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileName);
    _detailController = TextEditingController(text: widget.profileDetail);
    _useImage = widget.useHeaderImage;
    _imageBytes = widget.headerImageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _pickHeaderImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _useImage = true;
    });
    await _autoSave();
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageBytes = null;
      _useImage = false;
    });
    await _autoSave();
  }

  Future<void> _autoSave() async {
    final brightness = widget.themeMode == ThemeMode.light
        ? Brightness.light
        : Brightness.dark;
    final menuBackground = _menuBackgroundForPrimary(
      widget.primaryColor,
      brightness,
    );
    await widget.onProfileChanged(
      name: _nameController.text,
      detail: _detailController.text,
      imageUrl: '',
      useImage: _useImage,
      imageBytes: _imageBytes,
      menuTextColor: _defaultTextColor(menuBackground),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final borderColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Datos del usuario',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Personaliza tu experiencia con tu información.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _nameController,
          decoration: _fieldDecoration('Nombre', LucideIcons.user),
          onChanged: (_) => _autoSave(),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _detailController,
          decoration: _fieldDecoration(
            'Carrera, grupo o descripción',
            LucideIcons.graduationCap,
          ),
          onChanged: (_) => _autoSave(),
        ),
        const SizedBox(height: 18),
        if (_imageBytes != null) ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: MemoryImage(_imageBytes!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _removeImage,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size.fromHeight(48),
              foregroundColor: Colors.red,
            ),
            icon: const Icon(LucideIcons.trash2),
            label: const Text('Eliminar imagen'),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: _pickHeaderImage,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size.fromHeight(58),
          ),
          icon: const Icon(LucideIcons.upload),
          label: const Text('Elegir imagen del dispositivo'),
        ),
      ],
    );
  }
}

class _NotificationsSection extends StatefulWidget {
  final bool notificationsEnabled;
  final Future<void> Function(bool enabled) onNotificationsChanged;

  const _NotificationsSection({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  late bool _notificationsEnabled;
  late int _notificationMinutes;

  final List<int> _notificationOptions = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.notificationsEnabled;
    _notificationMinutes = 15;
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await widget.onNotificationsChanged(value);
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final borderColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Notificaciones',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Configura recordatorios para tus clases.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 22),
        Material(
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Activar notificaciones'),
            subtitle: const Text('Recibe recordatorios antes de cada clase'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Tiempo de aviso',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          value: _notificationMinutes,
          decoration: _fieldDecoration(
            'Minutos antes de la clase',
            LucideIcons.clock,
          ),
          items: _notificationOptions.map((minutes) {
            return DropdownMenuItem<int>(
              value: minutes,
              child: Text('$minutes minutos'),
            );
          }).toList(),
          onChanged: _notificationsEnabled
              ? (value) {
                  if (value != null) {
                    setState(() => _notificationMinutes = value);
                  }
                }
              : null,
        ),
      ],
    );
  }
}

class _DayTabs extends StatelessWidget {
  final TabController controller;
  final List<String> days;
  final List<int> classCounts;

  const _DayTabs({
    required this.controller,
    required this.days,
    required this.classCounts,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return TabBar(
      controller: controller,
      isScrollable: false,
      padding: EdgeInsets.zero,
      labelPadding: EdgeInsets.zero,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 3),
        insets: const EdgeInsets.symmetric(horizontal: 20),
      ),
      labelColor: primaryColor,
      unselectedLabelColor: Theme.of(context).colorScheme.onSurface
          .withValues(alpha: 0.54),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      tabs: List.generate(
        days.length,
        (index) => Tab(child: Text(days[index])),
      ),
    );
  }
}

class _DaySchedule extends StatelessWidget {
  final String day;
  final List<Clase> classes;
  final int dayIndex;
  final Function(int, int) onDeleteClass;
  final Function(int, int) onEditClass;

  const _DaySchedule({
    required this.day,
    required this.classes,
    required this.dayIndex,
    required this.onDeleteClass,
    required this.onEditClass,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return _EmptyDay(day: day);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      itemCount: classes.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = classes[index];
        return ClaseCard(
          materia: item.materia,
          profesor: item.profesor,
          nrc: item.nrc,
          edificio: item.edificio,
          aula: item.aula,
          horaInicio: item.horaInicio,
          horaFin: item.horaFin,
          letraInicial: item.letraInicial,
          color: item.color,
          onDelete: () => onDeleteClass(dayIndex, index),
          onEdit: () => onEditClass(dayIndex, index),
        );
      },
    );
  }
}

class _ScheduleTab extends StatefulWidget {
  final TabController tabController;
  final List<String> days;
  final List<int> dayIndices;
  final List<List<Clase>> classesByDay;
  final int selectedDay;
  final Function(int) onSelectedDayChanged;
  final Function(int, int) onDeleteClass;
  final Function(int, int) onEditClass;

  const _ScheduleTab({
    required this.tabController,
    required this.days,
    required this.dayIndices,
    required this.classesByDay,
    required this.selectedDay,
    required this.onSelectedDayChanged,
    required this.onDeleteClass,
    required this.onEditClass,
  });

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(() {
      if (!widget.tabController.indexIsChanging &&
          widget.selectedDay != widget.tabController.index) {
        widget.onSelectedDayChanged(widget.tabController.index);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          _DayTabs(
            controller: widget.tabController,
            days: widget.days,
            classCounts: widget.classesByDay
                .map((classes) => classes.length)
                .toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: widget.tabController,
              children: List.generate(
                widget.days.length,
                (dayIndex) => _DaySchedule(
                  day: widget.days[dayIndex].toLowerCase(),
                  classes: widget.classesByDay[widget.dayIndices[dayIndex]],
                  dayIndex: widget.dayIndices[dayIndex],
                  onDeleteClass: widget.onDeleteClass,
                  onEditClass: widget.onEditClass,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MateriasGuardadasTab extends StatelessWidget {
  final List<MateriaGuardada> materias;
  final Function(int) onDelete;
  final Function(MateriaGuardada) onAddToSchedule;
  final Function(int) onEdit;

  const _MateriasGuardadasTab({
    required this.materias,
    required this.onDelete,
    required this.onAddToSchedule,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (materias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.bookmark, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'Sin materias guardadas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Guarda tus materias para agregarlas fácilmente',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: materias.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final materia = materias[index];
        return MateriaGuardadaCard(
          materia: materia,
          onDelete: () => onDelete(index),
          onAddToSchedule: () => onAddToSchedule(materia),
          onEdit: () => onEdit(index),
        );
      },
    );
  }
}

class _AddClassSheet extends StatefulWidget {
  final List<String> days;
  final int initialDay;
  final List<MateriaGuardada> materiasGuardadas;
  final MateriaGuardada? preselectedMateria;
  final void Function(int day, Clase newClass) onSave;

  const _AddClassSheet({
    required this.days,
    required this.initialDay,
    required this.materiasGuardadas,
    this.preselectedMateria,
    required this.onSave,
  });

  @override
  State<_AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends State<_AddClassSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _roomController = TextEditingController();
  final _buildingController = TextEditingController(text: 'ECONEX');
  final _nrcController = TextEditingController();
  final _startController = TextEditingController(text: '08:00');
  final _endController = TextEditingController(text: '09:00');
  MateriaGuardada? _selectedMateria;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedMateria != null) {
      _selectedMateria = widget.preselectedMateria;
      _fillFormFromMateria(widget.preselectedMateria!);
    }
  }

  void _fillFormFromMateria(MateriaGuardada materia) {
    _subjectController.text = materia.materia;
    _teacherController.text = materia.profesor;
    _roomController.text = materia.aula;
    _buildingController.text = materia.edificio;
    _nrcController.text = materia.nrc;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    _buildingController.dispose();
    _nrcController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _selectMateria(MateriaGuardada materia) {
    setState(() {
      _selectedMateria = materia;
      _fillFormFromMateria(materia);
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final subject = _subjectController.text.trim();
    final color =
        _selectedMateria?.color ?? Theme.of(context).colorScheme.primary;

    widget.onSave(
      widget.initialDay,
      Clase(
        materia: subject,
        profesor: _teacherController.text.trim(),
        nrc: _nrcController.text.trim().isEmpty
            ? 'Sin NRC'
            : _nrcController.text.trim(),
        edificio: _buildingController.text.trim().isEmpty
            ? 'Por definir'
            : _buildingController.text.trim(),
        aula: _roomController.text.trim(),
        horaInicio: _startController.text.trim(),
        horaFin: _endController.text.trim(),
        letraInicial: subject.substring(0, 1).toUpperCase(),
        color: color,
        cardColor:
            _selectedMateria?.cardColor ??
            Theme.of(context).colorScheme.surface,
      ),
    );
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final borderColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nueva clase',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Completa los datos para añadirla a tu horario.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.materiasGuardadas.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.bookmark,
                              size: 18,
                              color: const Color(0xFF53D1B6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Materias guardadas',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF53D1B6),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: widget.materiasGuardadas.map((materia) {
                            final isSelected = _selectedMateria == materia;
                            final brightness = Theme.of(context).brightness;
                            final accentColor = _materiaColorForTheme(
                              materia.color,
                              brightness,
                            );
                            final itemColor = isSelected
                                ? _cardColorForTheme(materia.color, brightness)
                                : Theme.of(context).colorScheme.surface;
                            final itemTextColor = _defaultTextColor(itemColor);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectMateria(materia),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: itemColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? accentColor
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.12),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 5,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            color: materia.color,
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                  left: Radius.circular(12),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        CircleAvatar(
                                          radius: 17,
                                          backgroundColor: accentColor,
                                          child: Text(
                                            materia.materia
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: _defaultTextColor(
                                                accentColor,
                                              ),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                materia.materia,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: itemTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                materia.profesor,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: itemTextColor
                                                      .withValues(alpha: 0.68),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Icon(
                                              LucideIcons.circleCheck,
                                              color: accentColor,
                                              size: 22,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.bookOpen,
                            size: 18,
                            color: const Color(0xFF53D1B6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Información de la clase',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF53D1B6),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _subjectController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          'Materia',
                          LucideIcons.bookOpen,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe el nombre de la materia'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _teacherController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          'Profesor',
                          LucideIcons.user,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe el nombre del profesor'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 18,
                            color: const Color(0xFF53D1B6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ubicación',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF53D1B6),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _roomController,
                              textInputAction: TextInputAction.next,
                              decoration: _fieldDecoration(
                                'Aula',
                                LucideIcons.doorOpen,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Requerida'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nrcController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _fieldDecoration(
                                'NRC',
                                LucideIcons.tag,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _buildingController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          'Edificio',
                          LucideIcons.building2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 18,
                            color: const Color(0xFF53D1B6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Horario',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF53D1B6),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_TimeInputFormatter()],
                              decoration: _fieldDecoration(
                                'Hora inicio',
                                LucideIcons.clock3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _endController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_TimeInputFormatter()],
                              decoration: _fieldDecoration(
                                'Hora fin',
                                LucideIcons.clock3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(LucideIcons.plus, size: 20),
                    label: const Text(
                      'Agregar al horario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF53D1B6),
                      foregroundColor: const Color(0xFF09201D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final String day;

  const _EmptyDay({required this.day});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendarOff,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.24),
            ),
            const SizedBox(height: 16),
            Text('Día libre', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'No tienes clases el $day',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget universal reutilizable para clases programadas y materias guardadas
class ClaseCard extends StatelessWidget {
  final String materia;
  final String profesor;
  final String nrc;
  final String edificio;
  final String aula;
  final String? horaInicio; // Opcional
  final String? horaFin; // Opcional
  final String letraInicial;
  final Color color;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onAddToSchedule; // Opcional para las materias guardadas

  const ClaseCard({
    super.key,
    required this.materia,
    required this.profesor,
    required this.nrc,
    required this.edificio,
    required this.aula,
    this.horaInicio,
    this.horaFin,
    required this.letraInicial,
    required this.color,
    required this.onDelete,
    required this.onEdit,
    this.onAddToSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accentColor = _materiaColorForTheme(color, brightness);
    final surfaceColor = _cardColorForTheme(color, brightness);
    final cardTextColor = _defaultTextColor(surfaceColor);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).colorScheme.surface,
          builder: (context) => SafeArea(
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      LucideIcons.pencil,
                      color: Color(0xFF53D1B6),
                    ),
                    title: const Text('Editar'),
                    onTap: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                  ),
                  // Solo se muestra si la tarjeta actúa como MateriaGuardada
                  if (onAddToSchedule != null)
                    ListTile(
                      leading: const Icon(
                        LucideIcons.circlePlus,
                        color: Color(0xFF53D1B6),
                      ),
                      title: const Text('Agregar al horario'),
                      onTap: () {
                        Navigator.pop(context);
                        onAddToSchedule!();
                      },
                    ),
                  ListTile(
                    leading: const Icon(LucideIcons.trash2, color: Colors.red),
                    title: const Text('Eliminar'),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: _scheduleCardDecoration(
          context,
          backgroundColor: surfaceColor,
          accentColor: accentColor,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: accentColor,
                  child: Text(
                    letraInicial,
                    style: TextStyle(
                      color: Brightness.light == brightness
                          ? Colors.black
                          : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Renderizado condicional para los horarios
                if (horaInicio != null && horaFin != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    horaInicio!,
                    style: TextStyle(
                      color: cardTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    horaFin!,
                    style: TextStyle(
                      color: cardTextColor.withValues(alpha: 0.62),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cardTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    profesor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cardTextColor.withValues(alpha: 0.72),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: LucideIcons.mapPin,
                        label: aula,
                        color: cardTextColor,
                      ),
                      _InfoChip(
                        icon: LucideIcons.badge,
                        label: 'NRC $nrc',
                        color: cardTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    edificio,
                    style: TextStyle(
                      color: cardTextColor.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.onSurface).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color:
                  color?.withValues(alpha: 0.78) ??
                  Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveMateriaSheet extends StatefulWidget {
  final void Function(MateriaGuardada materia) onSave;

  const _SaveMateriaSheet({required this.onSave});

  @override
  State<_SaveMateriaSheet> createState() => _SaveMateriaSheetState();
}

class _SaveMateriaSheetState extends State<_SaveMateriaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _roomController = TextEditingController();
  final _buildingController = TextEditingController(text: 'ECONEX');
  final _nrcController = TextEditingController();
  int _selectedColorIndex = 0;

  List<Color> get _materiaColors => [
    Theme.of(context).colorScheme.primary,
    const Color(0xFFFFC857),
    const Color(0xFFFF8A65),
    const Color(0xFF8AB4F8),
    const Color(0xFFD7A8FF),
    const Color(0xFFF48FB1),
    const Color(0xFF80CBC4),
    const Color(0xFF64B5F6),
    const Color(0xFFFFB74D),
    const Color(0xFFE57373),
    const Color(0xFFBA68C8),
    const Color(0xFFAED581),
    const Color(0xFF4DD0E1),
    const Color(0xFF90A4AE),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    _buildingController.dispose();
    _nrcController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSave(
      MateriaGuardada(
        materia: _subjectController.text.trim(),
        profesor: _teacherController.text.trim(),
        nrc: _nrcController.text.trim().isEmpty
            ? 'Sin NRC'
            : _nrcController.text.trim(),
        edificio: _buildingController.text.trim().isEmpty
            ? 'Por definir'
            : _buildingController.text.trim(),
        aula: _roomController.text.trim(),
        color: _materiaColors[_selectedColorIndex],
        iconColor: _defaultIconColor(_materiaColors[_selectedColorIndex]),
        textColor: _defaultTextColor(_materiaColors[_selectedColorIndex]),
        cardColor: _cardColorForTheme(
          _materiaColors[_selectedColorIndex],
          Theme.of(context).brightness,
        ),
      ),
    );
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final borderColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Guardar materia',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Guarda los datos de una materia para agregarla fácilmente.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjectController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration('Materia', LucideIcons.bookOpen),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre de la materia'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teacherController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration('Profesor', LucideIcons.user),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre del profesor'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _roomController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          'Aula',
                          LucideIcons.doorOpen,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Requerida'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nrcController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration('NRC', LucideIcons.tag),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _buildingController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Edificio',
                    LucideIcons.building2,
                  ),
                ),
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _materiaColors.length,
                    itemBuilder: (context, index) {
                      final color = _materiaColors[index];
                      final isSelected = _selectedColorIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColorIndex = index),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.2),
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    LucideIcons.check,
                                    color: Color(0xFF09201D),
                                    size: 28,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(LucideIcons.bookmarkPlus),
                    label: const Text('Guardar materia'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFF53D1B6),
                      foregroundColor: const Color(0xFF09201D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditClassSheet extends StatefulWidget {
  final List<String> days;
  final int initialDay;
  final List<MateriaGuardada> materiasGuardadas;
  final Clase initialClass;
  final void Function(int day, Clase updatedClass) onSave;

  const _EditClassSheet({
    required this.days,
    required this.initialDay,
    required this.materiasGuardadas,
    required this.initialClass,
    required this.onSave,
  });

  @override
  State<_EditClassSheet> createState() => _EditClassSheetState();
}

class _EditClassSheetState extends State<_EditClassSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _teacherController;
  late final TextEditingController _roomController;
  late final TextEditingController _buildingController;
  late final TextEditingController _nrcController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  MateriaGuardada? _selectedMateria;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: widget.initialClass.materia,
    );
    _teacherController = TextEditingController(
      text: widget.initialClass.profesor,
    );
    _roomController = TextEditingController(text: widget.initialClass.aula);
    _buildingController = TextEditingController(
      text: widget.initialClass.edificio,
    );
    _nrcController = TextEditingController(text: widget.initialClass.nrc);
    _startController = TextEditingController(
      text: widget.initialClass.horaInicio,
    );
    _endController = TextEditingController(text: widget.initialClass.horaFin);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    _buildingController.dispose();
    _nrcController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _selectMateria(MateriaGuardada materia) {
    setState(() {
      _selectedMateria = materia;
      _subjectController.text = materia.materia;
      _teacherController.text = materia.profesor;
      _roomController.text = materia.aula;
      _buildingController.text = materia.edificio;
      _nrcController.text = materia.nrc;
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final subject = _subjectController.text.trim();
    final color = _selectedMateria?.color ?? widget.initialClass.color;

    widget.onSave(
      widget.initialDay,
      Clase(
        materia: subject,
        profesor: _teacherController.text.trim(),
        nrc: _nrcController.text.trim().isEmpty
            ? 'Sin NRC'
            : _nrcController.text.trim(),
        edificio: _buildingController.text.trim().isEmpty
            ? 'Por definir'
            : _buildingController.text.trim(),
        aula: _roomController.text.trim(),
        horaInicio: _startController.text.trim(),
        horaFin: _endController.text.trim(),
        letraInicial: subject.substring(0, 1).toUpperCase(),
        color: color,
      ),
    );
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final borderColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Editar clase',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Modifica los datos de la clase.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 14),
                if (widget.materiasGuardadas.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.bookmark,
                              size: 18,
                              color: const Color(0xFF53D1B6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Materias guardadas',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF53D1B6),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: widget.materiasGuardadas.map((materia) {
                            final isSelected = _selectedMateria == materia;
                            final brightness = Theme.of(context).brightness;
                            final accentColor = _materiaColorForTheme(
                              materia.color,
                              brightness,
                            );
                            final itemColor = isSelected
                                ? _cardColorForTheme(materia.color, brightness)
                                : Theme.of(context).colorScheme.surface;
                            final itemTextColor = _defaultTextColor(itemColor);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectMateria(materia),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: itemColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? accentColor
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.12),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 5,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            color: materia.color,
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                  left: Radius.circular(12),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        CircleAvatar(
                                          radius: 17,
                                          backgroundColor: accentColor,
                                          child: Text(
                                            materia.materia
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: _defaultTextColor(
                                                accentColor,
                                              ),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                materia.materia,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: itemTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                materia.profesor,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: itemTextColor
                                                      .withValues(alpha: 0.68),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Icon(
                                              LucideIcons.check,
                                              size: 20,
                                              color: accentColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.bookOpen,
                            size: 18,
                            color: const Color(0xFF53D1B6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Información de la clase',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF53D1B6),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _subjectController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          'Materia',
                          LucideIcons.bookOpen,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe el nombre de la materia'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _teacherController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          'Profesor',
                          LucideIcons.user,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe el nombre del profesor'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 18,
                            color: const Color(0xFF53D1B6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ubicación',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF53D1B6),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _roomController,
                              textInputAction: TextInputAction.next,
                              decoration: _fieldDecoration(
                                'Aula',
                                LucideIcons.doorOpen,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Requerida'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nrcController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _fieldDecoration(
                                'NRC',
                                LucideIcons.tag,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _buildingController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          'Edificio',
                          LucideIcons.building2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 18,
                            color: const Color(0xFF53D1B6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Horario',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF53D1B6),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_TimeInputFormatter()],
                              decoration: _fieldDecoration(
                                'Hora inicio',
                                LucideIcons.clock3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _endController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_TimeInputFormatter()],
                              decoration: _fieldDecoration(
                                'Hora fin',
                                LucideIcons.clock3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(LucideIcons.save),
                    label: const Text(
                      'Guardar cambios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF53D1B6),
                      foregroundColor: const Color(0xFF09201D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MateriaGuardadaCard extends StatelessWidget {
  final MateriaGuardada materia;
  final VoidCallback onDelete;
  final VoidCallback onAddToSchedule;
  final VoidCallback onEdit;

  const MateriaGuardadaCard({
    super.key,
    required this.materia,
    required this.onDelete,
    required this.onAddToSchedule,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Reutilizamos ClaseCard, pasando null a los campos que no aplican
    return ClaseCard(
      materia: materia.materia,
      profesor: materia.profesor,
      nrc: materia.nrc,
      edificio: materia.edificio,
      aula: materia.aula,
      horaInicio: null, // No aplica para materias guardadas
      horaFin: null, // No aplica para materias guardadas
      letraInicial: materia.materia.substring(0, 1).toUpperCase(),
      color: materia.color,
      onDelete: onDelete,
      onEdit: onEdit,
      onAddToSchedule: onAddToSchedule, // Activa la opción en el BottomSheet
    );
  }
}

class _EditMateriaSheet extends StatefulWidget {
  final MateriaGuardada initialMateria;
  final Function(MateriaGuardada) onSave;

  const _EditMateriaSheet({required this.initialMateria, required this.onSave});

  @override
  State<_EditMateriaSheet> createState() => _EditMateriaSheetState();
}

class _EditMateriaSheetState extends State<_EditMateriaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _teacherController;
  late final TextEditingController _nrcController;
  late final TextEditingController _roomController;
  late final TextEditingController _buildingController;
  Color _selectedColor = const Color(0xFF53D1B6);

  static const _classColors = [
    Color(0xFF53D1B6),
    Color(0xFFFFC857),
    Color(0xFFFF8A65),
    Color(0xFF8AB4F8),
    Color(0xFFD7A8FF),
  ];

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: widget.initialMateria.materia,
    );
    _teacherController = TextEditingController(
      text: widget.initialMateria.profesor,
    );
    _nrcController = TextEditingController(text: widget.initialMateria.nrc);
    _roomController = TextEditingController(text: widget.initialMateria.aula);
    _buildingController = TextEditingController(
      text: widget.initialMateria.edificio,
    );
    _selectedColor = widget.initialMateria.color;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _nrcController.dispose();
    _roomController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final borderColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedMateria = MateriaGuardada(
        materia: _subjectController.text.trim(),
        profesor: _teacherController.text.trim(),
        nrc: _nrcController.text.trim(),
        edificio: _buildingController.text.trim(),
        aula: _roomController.text.trim(),
        color: _selectedColor,
        iconColor: _defaultIconColor(_selectedColor),
        textColor: _defaultTextColor(_selectedColor),
        cardColor: _cardColorForTheme(
          _selectedColor,
          Theme.of(context).brightness,
        ),
      );
      widget.onSave(updatedMateria);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Editar materia',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Modifica los datos de la materia guardada.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjectController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration('Materia', LucideIcons.bookOpen),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre de la materia'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teacherController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration('Profesor', LucideIcons.user),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre del profesor'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _roomController,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          'Aula',
                          LucideIcons.doorOpen,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Requerida'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nrcController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _fieldDecoration('NRC', LucideIcons.tag),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _buildingController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Edificio',
                    LucideIcons.building2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF53D1B6),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _classColors.length,
                    itemBuilder: (context, index) {
                      final color = _classColors[index];
                      final isSelected = _selectedColor == color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedColor = color),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    LucideIcons.check,
                                    color: Color(0xFF09201D),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(LucideIcons.save),
                    label: const Text('Guardar cambios'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFF53D1B6),
                      foregroundColor: const Color(0xFF09201D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) {
        formatted += ':';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
