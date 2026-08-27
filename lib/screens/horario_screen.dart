import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

// MÓDULOS INTERNOS
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/forms.dart';
import 'tabs.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
  State<HorarioScreen> createState() => HorarioScreenState();
}

class HorarioScreenState extends State<HorarioScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDay = 0;
  int _selectedTab = 0; // 0 = Horario, 1 = Materias Guardadas
  bool _notificationsEnabled = false;
  bool _showWeekend = true;
  int _weekStart = 1;
  DayLabelFormat _dayLabelFormat = DayLabelFormat.short;
  int _notificationMinutes = 15;
  TimeFormat _timeFormat = TimeFormat.twentyFourHour;

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

    final today = DateTime.now().weekday;
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
      orElse: () => DayLabelFormat.short,
    );
    _replaceTabController();

    for (int i = 0; i < _allDays.length; i++) {
      final classesJson = prefs.getStringList('horario_dia_$i');
      if (classesJson != null) {
        setState(() {
          _classesByDay[i] = classesJson
              .map((json) => Clase.fromJson(jsonDecode(json)))
              .toList();
          _classesByDay[i].sort(compareClassesByStartTime);
        });
      }
    }

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

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _notificationMinutes = prefs.getInt('notification_minutes') ?? 15;
      final savedTimeFormat = prefs.getString('time_format');
      _timeFormat = TimeFormat.values.firstWhere(
        (format) => format.name == savedTimeFormat,
        orElse: () => TimeFormat.twentyFourHour,
      );
    });

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
            iconColor: defaultIconColor(subject.$3),
            textColor: defaultTextColor(subject.$3),
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
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => AddClassSheet(
        primaryColor: widget.primaryColor,
        days: _visibleDays,
        initialDay: _visibleDayIndices.indexOf(_selectedDay),
        materiasGuardadas: _materiasGuardadas,
        onSave: (day, newClass) async {
          setState(() {
            final canonicalDay = _visibleDayIndices[day];
            _classesByDay[canonicalDay].add(newClass);
            _classesByDay[canonicalDay].sort(compareClassesByStartTime);
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
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => SaveMateriaSheet(
        primaryColor: widget.primaryColor,
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
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => EditMateriaSheet(
        primaryColor: widget.primaryColor,
        initialMateria: materia,
        onSave: (updatedMateria) async {
          final oldMateriaName = materia.materia;
          setState(() {
            _materiasGuardadas[index] = updatedMateria;
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
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => EditClassSheet(
        primaryColor: widget.primaryColor,
        days: _visibleDays,
        initialDay: _visibleDayIndices.indexOf(dayIndex),
        materiasGuardadas: _materiasGuardadas,
        initialClass: clase,
        onSave: (day, updatedClass) async {
          setState(() {
            final canonicalDay = _visibleDayIndices[day];
            _classesByDay[canonicalDay][classIndex] = updatedClass;
            _classesByDay[canonicalDay].sort(compareClassesByStartTime);
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
      await notificationsPlugin.cancelAll();
    }
  }

  Future<void> _setNotificationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _notificationMinutes = minutes);
    await prefs.setInt('notification_minutes', minutes);

    if (_notificationsEnabled) {
      await _scheduleNextClassNotification();
    }
  }

  Future<void> _setTimeFormat(TimeFormat format) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _timeFormat = format);
    await prefs.setString('time_format', format.name);
  }

  String _formatTimeForNotification(String time24) {
    if (_timeFormat == TimeFormat.twentyFourHour) {
      return time24;
    }
    
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _scheduleNextClassNotification() async {
    await notificationsPlugin.cancelAll();

    final now = DateTime.now();
    Clase? nextClass;
    DateTime? nextClassTime;

    // Determine which days to check based on _showWeekend setting
    final validWeekdays = _showWeekend
        ? [0, 1, 2, 3, 4, 5, 6] // All days (Sunday=0 to Saturday=6)
        : [1, 2, 3, 4, 5]; // Monday to Friday

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final checkDate = now.add(Duration(days: dayOffset));
      final weekday = checkDate.weekday == 7 ? 0 : checkDate.weekday; // Convert Sunday from 7 to 0

      if (validWeekdays.contains(weekday)) {
        final dayIndex = weekday;
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
      final notificationTime = nextClassTime.subtract(
        Duration(minutes: _notificationMinutes),
      );

      if (notificationTime.isAfter(now)) {
        final androidDetails = const AndroidNotificationDetails(
          'class_notifications',
          'Notificaciones de Clases',
          channelDescription: 'Notificaciones para recordatorios de clases',
          importance: Importance.high,
          priority: Priority.high,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
        );

        await notificationsPlugin.zonedSchedule(
          0,
          'Próxima clase: ${nextClass.materia}',
          'Tu clase de ${_formatTimeForNotification(nextClass.horaInicio)} comienza en $_notificationMinutes minutos en ${nextClass.aula}',
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
            ? ScheduleTab(
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
                timeFormat: _timeFormat,
              )
            : _selectedTab == 1
            ? MateriasGuardadasTab(
                materias: _materiasGuardadas,
                onDelete: _deleteMateriaGuardada,
                onAddToSchedule: (materia) async {
                  await _openAddClassSheetWithMateria(materia);
                },
                onEdit: _editMateriaGuardada,
              )
            : _selectedTab == 2
            ? ProfileSection(
                profileName: widget.profileName,
                profileDetail: widget.profileDetail,
                useHeaderImage: widget.useHeaderImage,
                headerImageBytes: widget.headerImageBytes,
                primaryColor: widget.primaryColor,
                themeMode: widget.themeMode,
                onProfileChanged: widget.onProfileChanged,
              )
            : _selectedTab == 3
            ? AppearanceSection(
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
                timeFormat: _timeFormat,
                onTimeFormatChanged: _setTimeFormat,
              )
            : NotificationsSection(
                notificationsEnabled: _notificationsEnabled,
                onNotificationsChanged: _toggleNotifications,
                onNotificationMinutesChanged: _setNotificationMinutes,
                initialNotificationMinutes: _notificationMinutes,
                primaryColor: widget.primaryColor,
              ),
      ),
      floatingActionButton: (_selectedTab == 0 || _selectedTab == 1)
          ? FloatingActionButton(
              onPressed: _selectedTab == 0
                  ? _openAddClassSheet
                  : _openSaveMateriaSheet,
              backgroundColor: widget.primaryColor,
              foregroundColor: defaultTextColor(widget.primaryColor),
              child: Icon(
                _selectedTab == 0 ? LucideIcons.plus : LucideIcons.bookmarkPlus,
              ),
            )
          : null,
    );
  }

  Future<void> _openAddClassSheetWithMateria(MateriaGuardada materia) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => AddClassSheet(
        primaryColor: widget.primaryColor,
        days: _visibleDays,
        initialDay: _visibleDayIndices.indexOf(_selectedDay),
        materiasGuardadas: _materiasGuardadas,
        preselectedMateria: materia,
        onSave: (day, newClass) async {
          setState(() {
            final canonicalDay = _visibleDayIndices[day];
            _classesByDay[canonicalDay].add(newClass);
            _classesByDay[canonicalDay].sort(compareClassesByStartTime);
          });
          await _saveSchedule();
          _tabController.animateTo(day);
        },
      ),
    );
  }
}
