import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'dart:convert';

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

  static const _colorOptions = [
    Color(0xFF53D1B6),
    Color(0xFF8AB4F8),
    Color(0xFFFFC857),
    Color(0xFFFF8A65),
    Color(0xFFD7A8FF),
    Color(0xFFF48FB1),
    Color(0xFF80CBC4),
    Color(0xFF64B5F6),
    Color(0xFFFFB74D),
    Color(0xFFE57373),
    Color(0xFFBA68C8),
    Color(0xFFAED581),
    Color(0xFF4DD0E1),
    Color(0xFFFF8A65),
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

  static const _darkBackgroundOptions = [
    Color(0xFF0F1720),
    Color(0xFF111827),
    Color(0xFF17212B),
    Color(0xFF1B1B2F),
    Color(0xFF202A36),
  ];
  static const _lightBackgroundOptions = [
    Color(0xFFF4F7F6),
    Color(0xFFF5F7FB),
    Color(0xFFFFF8EE),
    Color(0xFFF8F3FA),
    Color(0xFFEFF8F7),
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
        final screenBackgroundColorValue = prefs.getInt(
          'screen_background_color',
        );
        _screenBackgroundColor = screenBackgroundColorValue != null
            ? Color(screenBackgroundColorValue)
            : _defaultBackgroundForMode(_themeMode);
      });
    }
  }

  Future<void> _setPrimaryColor(Color color) async {
    setState(() => _primaryColor = color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color.toARGB32());
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

  Color _defaultBackgroundForMode(ThemeMode mode) => mode == ThemeMode.light
      ? _lightBackgroundOptions.first
      : _darkBackgroundOptions.first;

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
      _screenBackgroundColor = _defaultBackgroundForMode(mode);
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
  }

  Future<void> _setScreenBackgroundColor(Color color) async {
    setState(() => _screenBackgroundColor = color);
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: _themeMode == ThemeMode.light
              ? Brightness.light
              : Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HorarioScreen(
        colorOptions: _colorOptions,
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

  const MateriaGuardada({
    required this.materia,
    required this.profesor,
    required this.nrc,
    required this.edificio,
    required this.aula,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'materia': materia,
      'profesor': profesor,
      'nrc': nrc,
      'edificio': edificio,
      'aula': aula,
      'color': color.toARGB32(),
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
    );
  }
}

class HorarioScreen extends StatefulWidget {
  final List<Color> colorOptions;
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
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedDay = 0;
  int _selectedTab = 0; // 0 = Horario, 1 = Materias Guardadas
  bool _notificationsEnabled = false;

  static const _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<List<Clase>> _classesByDay = [[], [], [], [], []];
  final List<MateriaGuardada> _materiasGuardadas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);

    // Establecer el día actual
    final today = DateTime.now().weekday; // 1 = Lunes, 7 = Domingo
    if (today >= 1 && today <= 5) {
      _selectedDay = today - 1;
      _tabController.index = _selectedDay;
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _selectedDay != _tabController.index) {
        setState(() => _selectedDay = _tabController.index);
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar horario
    for (int i = 0; i < _days.length; i++) {
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

    // Cargar preferencia de notificaciones
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });

    // Programar notificación si está activado
    if (_notificationsEnabled) {
      await _scheduleNextClassNotification();
    }
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _days.length; i++) {
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
        days: _days,
        initialDay: _selectedDay,
        materiasGuardadas: _materiasGuardadas,
        onSave: (day, newClass) async {
          setState(() {
            _classesByDay[day].add(newClass);
            _classesByDay[day].sort(_compareClassesByStartTime);
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
            for (int day = 0; day < _days.length; day++) {
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
        days: _days,
        initialDay: dayIndex,
        materiasGuardadas: _materiasGuardadas,
        initialClass: clase,
        onSave: (day, updatedClass) async {
          setState(() {
            _classesByDay[day][classIndex] = updatedClass;
            _classesByDay[day].sort(_compareClassesByStartTime);
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
        title: const Text('Horario'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: widget.menuBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
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
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 32,
                    color: widget.menuTextColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.profileName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: widget.menuTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.profileDetail,
                    style: TextStyle(
                      color: widget.menuTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Horario'),
              selected: _selectedTab == 0,
              selectedTileColor: Colors.white.withValues(alpha: 0.05),
              onTap: () {
                setState(() => _selectedTab = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_rounded),
              title: const Text('Materias Guardadas'),
              selected: _selectedTab == 1,
              selectedTileColor: Colors.white.withValues(alpha: 0.05),
              onTap: () {
                setState(() => _selectedTab = 1);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Apariencia'),
              subtitle: const Text('Personalizar color principal'),
              selected: _selectedTab == 2,
              selectedTileColor: Colors.white.withValues(alpha: 0.05),
              onTap: () {
                setState(() => _selectedTab = 2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_rounded),
              title: const Text('Notificaciones'),
              subtitle: const Text('Recordatorio de próxima clase'),
              value: _notificationsEnabled,
              onChanged: (value) {
                _toggleNotifications(value);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _selectedTab == 0
            ? _ScheduleTab(
                tabController: _tabController,
                days: _days,
                classesByDay: _classesByDay,
                selectedDay: _selectedDay,
                onSelectedDayChanged: (day) {
                  setState(() => _selectedDay = day);
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
            : _AppearanceSection(
                colorOptions: widget.colorOptions,
                onColorChanged: widget.onPrimaryColorChanged,
                profileName: widget.profileName,
                profileDetail: widget.profileDetail,
                headerImageUrl: widget.headerImageUrl,
                useHeaderImage: widget.useHeaderImage,
                headerImageBytes: widget.headerImageBytes,
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
                onProfileChanged: widget.onProfileChanged,
              ),
      ),
      floatingActionButton: _selectedTab == 2
          ? null
          : FloatingActionButton(
              onPressed: _selectedTab == 0
                  ? _openAddClassSheet
                  : _openSaveMateriaSheet,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Icon(
                _selectedTab == 0
                    ? Icons.add_rounded
                    : Icons.bookmark_add_rounded,
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
        days: _days,
        initialDay: _selectedDay,
        materiasGuardadas: _materiasGuardadas,
        preselectedMateria: materia,
        onSave: (day, newClass) async {
          setState(() {
            _classesByDay[day].add(newClass);
            _classesByDay[day].sort(_compareClassesByStartTime);
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
  final Future<void> Function(Color color) onColorChanged;
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

  const _AppearanceSection({
    required this.colorOptions,
    required this.onColorChanged,
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
  State<_AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<_AppearanceSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _detailController;
  late final TextEditingController _imageController;
  late bool _useImage;
  Uint8List? _imageBytes;
  late Color _menuTextColor;
  late Color _menuBackgroundColor;
  late ThemeMode _themeMode;
  late Color _screenBackgroundColor;
  static const _menuTextColors = [
    Colors.white,
    Color(0xFFF5F5F5),
    Color(0xFF121820),
    Color(0xFFFFF3CD),
    Color(0xFFE0F7FA),
    Color(0xFFFFE4EC),
  ];
  static const _menuBackgroundColors = [
    Color(0xFF18232D),
    Color(0xFF202A36),
    Color(0xFF263238),
    Color(0xFF26324A),
    Color(0xFF30243D),
    Color(0xFF3A2924),
    Color(0xFF20352F),
    Color(0xFF111827),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileName);
    _detailController = TextEditingController(text: widget.profileDetail);
    _imageController = TextEditingController(text: widget.headerImageUrl);
    _useImage = widget.useHeaderImage;
    _imageBytes = widget.headerImageBytes;
    _menuTextColor = widget.menuTextColor;
    _menuBackgroundColor = widget.menuBackgroundColor;
    _themeMode = widget.themeMode;
    _screenBackgroundColor = widget.screenBackgroundColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await widget.onProfileChanged(
      name: _nameController.text,
      detail: _detailController.text,
      imageUrl: _imageController.text,
      useImage: _useImage,
      imageBytes: _imageBytes,
      menuTextColor: _menuTextColor,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Personalización guardada')));
    }
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
      _imageController.clear();
      _useImage = true;
    });
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Apariencia',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Personaliza el color que identifica las acciones principales de tu horario.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modo de pantalla',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Oscuro'),
                    ),
                  ],
                  selected: {_themeMode},
                  onSelectionChanged: (selection) async {
                    final mode = selection.first;
                    setState(() {
                      _themeMode = mode;
                      _screenBackgroundColor = mode == ThemeMode.light
                          ? const Color(0xFFF4F7F6)
                          : const Color(0xFF0F1720);
                    });
                    await widget.onThemeModeChanged(mode);
                  },
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Color de fondo de las pantallas',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: widget.backgroundOptions.map((color) {
                  final isSelected =
                      _screenBackgroundColor.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () async {
                      setState(() => _screenBackgroundColor = color);
                      await widget.onScreenBackgroundColorChanged(color);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white24,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datos del usuario',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                decoration: _fieldDecoration(
                  'Nombre',
                  Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detailController,
                decoration: _fieldDecoration(
                  'Carrera, grupo o descripción',
                  Icons.school_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageController,
                keyboardType: TextInputType.url,
                onChanged: (_) {
                  if (_imageBytes != null) {
                    setState(() => _imageBytes = null);
                  }
                },
                decoration: _fieldDecoration(
                  'URL de imagen para el menú',
                  Icons.image_outlined,
                ).copyWith(hintText: 'https://ejemplo.com/imagen.jpg'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickHeaderImage,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Elegir imagen del dispositivo'),
              ),
              Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usar imagen en el menú'),
                  subtitle: const Text(
                    'Si está apagado, se usará el color principal',
                  ),
                  value: _useImage,
                  onChanged: (value) => setState(() => _useImage = value),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar datos'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, color: primaryColor),
                  const SizedBox(width: 10),
                  const Text(
                    'Color principal',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Se usa en el día activo, botones, pestañas y nuevas materias.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.54),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: widget.colorOptions.map((color) {
                  final isSelected =
                      primaryColor.toARGB32() == color.toARGB32();
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
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.45),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF09201D),
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Color del menú lateral',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: _menuBackgroundColors.map((color) {
                  final isSelected =
                      _menuBackgroundColor.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () async {
                      setState(() => _menuBackgroundColor = color);
                      await widget.onMenuBackgroundColorChanged(color);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.white24,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check_rounded, color: primaryColor)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Color de letras del menú',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: _menuTextColors.map((color) {
                  final isSelected =
                      _menuTextColor.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () async {
                      setState(() => _menuTextColor = color);
                      await widget.onMenuTextColorChanged(color);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.white24,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check_rounded, color: primaryColor)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: primaryColor),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Vista previa del color activo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: primaryColor),
                  ],
                ),
              ),
            ],
          ),
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
  final List<List<Clase>> classesByDay;
  final int selectedDay;
  final Function(int) onSelectedDayChanged;
  final Function(int, int) onDeleteClass;
  final Function(int, int) onEditClass;

  const _ScheduleTab({
    required this.tabController,
    required this.days,
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
    return Column(
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
                classes: widget.classesByDay[dayIndex],
                dayIndex: dayIndex,
                onDeleteClass: widget.onDeleteClass,
                onEditClass: widget.onEditClass,
              ),
            ),
          ),
        ),
      ],
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
              Icon(
                Icons.bookmark_outline_rounded,
                size: 48,
                color: Colors.white24,
              ),
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
  late int _selectedDay = widget.initialDay;
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
    if (!_formKey.currentState!.validate()) return;

    final subject = _subjectController.text.trim();
    final color =
        _selectedMateria?.color ?? Theme.of(context).colorScheme.primary;

    widget.onSave(
      _selectedDay,
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
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF53D1B6), width: 2),
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
                      icon: const Icon(Icons.close_rounded),
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
                              Icons.bookmark_rounded,
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
                                      color: isSelected
                                          ? materia.color.withValues(
                                              alpha: 0.16,
                                            )
                                          : Colors.white.withValues(
                                              alpha: 0.04,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? materia.color
                                            : Colors.white.withValues(
                                                alpha: 0.07,
                                              ),
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
                                          backgroundColor: materia.color,
                                          child: Text(
                                            materia.materia
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF09201D),
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
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.white.withValues(
                                                          alpha: 0.88,
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                materia.profesor,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.54),
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
                                              Icons.check_circle_rounded,
                                              color: materia.color,
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
                  const SizedBox(height: 20),
                ],
                DropdownButtonFormField<int>(
                  initialValue: _selectedDay,
                  decoration: _fieldDecoration('Día', Icons.today_rounded),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items: List.generate(
                    widget.days.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(widget.days[index]),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedDay = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Materia',
                    Icons.menu_book_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre de la materia'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _teacherController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Profesor',
                    Icons.person_outline_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre del profesor'
                      : null,
                ),
                const SizedBox(height: 20),
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
                            Icons.location_on_outlined,
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
                                Icons.room_outlined,
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
                                Icons.tag_rounded,
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
                          Icons.business_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                            Icons.access_time_rounded,
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
                                Icons.schedule_rounded,
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
                                Icons.schedule_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.add_rounded, size: 20),
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
              Icons.weekend_outlined,
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

// Widget reutilizable para cada tarjeta de clase
class ClaseCard extends StatelessWidget {
  final String materia;
  final String profesor;
  final String nrc;
  final String edificio;
  final String aula;
  final String horaInicio;
  final String horaFin;
  final String letraInicial;
  final Color color;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ClaseCard({
    super.key,
    required this.materia,
    required this.profesor,
    required this.nrc,
    required this.edificio,
    required this.aula,
    required this.horaInicio,
    required this.horaFin,
    required this.letraInicial,
    required this.color,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).colorScheme.surface,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF53D1B6),
                  ),
                  title: const Text('Editar'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text('Eliminar'),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: color,
                  child: Text(
                    letraInicial,
                    style: const TextStyle(
                      color: Color(0xFF09201D),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  horaInicio,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  horaFin,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.54),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _InfoChip(icon: Icons.location_on_outlined, label: aula),
                      _InfoChip(
                        icon: Icons.confirmation_number_outlined,
                        label: 'NRC $nrc',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    edificio,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.38),
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

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface
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
    if (!_formKey.currentState!.validate()) return;

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
      ),
    );
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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
                      icon: const Icon(Icons.close_rounded),
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _subjectController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Materia',
                    Icons.menu_book_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre de la materia'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teacherController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Profesor',
                    Icons.person_outline_rounded,
                  ),
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
                          Icons.room_outlined,
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
                        decoration: _fieldDecoration('NRC', Icons.tag_rounded),
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
                    Icons.business_outlined,
                  ),
                ),
                const SizedBox(height: 16),
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
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.bookmark_add_rounded),
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
  late int _selectedDay = widget.initialDay;
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
    if (!_formKey.currentState!.validate()) return;

    final subject = _subjectController.text.trim();
    final color = _selectedMateria?.color ?? widget.initialClass.color;

    widget.onSave(
      _selectedDay,
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
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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
                      'Editar clase',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close_rounded),
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
                const SizedBox(height: 20),
                if (widget.materiasGuardadas.isNotEmpty) ...[
                  Text(
                    'Materias guardadas',
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
                      itemCount: widget.materiasGuardadas.length,
                      itemBuilder: (context, index) {
                        final materia = widget.materiasGuardadas[index];
                        final isSelected = _selectedMateria == materia;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(materia.materia),
                            selected: isSelected,
                            onSelected: (_) => _selectMateria(materia),
                            selectedColor: materia.color,
                            checkmarkColor: const Color(0xFF09201D),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF09201D)
                                  : Colors.white70,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<int>(
                  initialValue: _selectedDay,
                  decoration: _fieldDecoration('Día', Icons.today_rounded),
                  items: List.generate(
                    widget.days.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(widget.days[index]),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedDay = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subjectController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Materia',
                    Icons.menu_book_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre de la materia'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teacherController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Profesor',
                    Icons.person_outline_rounded,
                  ),
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
                          Icons.room_outlined,
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
                        decoration: _fieldDecoration('NRC', Icons.tag_rounded),
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
                    Icons.business_outlined,
                  ),
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
                          Icons.schedule_rounded,
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
                          Icons.schedule_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
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
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).colorScheme.surface,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF53D1B6),
                  ),
                  title: const Text('Editar'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF53D1B6),
                  ),
                  title: const Text('Agregar al horario'),
                  onTap: () {
                    Navigator.pop(context);
                    onAddToSchedule();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text('Eliminar'),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: materia.color,
              child: Text(
                materia.materia.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF09201D),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia.materia,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    materia.profesor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: materia.aula,
                      ),
                      _InfoChip(
                        icon: Icons.confirmation_number_outlined,
                        label: 'NRC ${materia.nrc}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    materia.edificio,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
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
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF53D1B6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final updatedMateria = MateriaGuardada(
        materia: _subjectController.text.trim(),
        profesor: _teacherController.text.trim(),
        nrc: _nrcController.text.trim(),
        edificio: _buildingController.text.trim(),
        aula: _roomController.text.trim(),
        color: _selectedColor,
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
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Modifica los datos de la materia guardada.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _subjectController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Materia',
                    Icons.menu_book_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe el nombre de la materia'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teacherController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    'Profesor',
                    Icons.person_outline_rounded,
                  ),
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
                          Icons.room_outlined,
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
                        decoration: _fieldDecoration('NRC', Icons.tag_rounded),
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
                    Icons.business_outlined,
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
                                    Icons.check,
                                    color: Color(0xFF09201D),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
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
