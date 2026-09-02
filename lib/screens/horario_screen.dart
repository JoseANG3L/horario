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
  int _selectedTab = 0; // 0 = Horario, 1 = Materias Guardadas, 2 = Maestros, 3 = Salones, 4 = Edificios
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
  final List<Maestro> _maestros = [];
  final List<Salon> _salones = [];
  final List<Edificio> _edificios = [];

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
    await _loadMaestros();
    if (_maestros.isEmpty) {
      await _addSampleMaestros();
    }
    await _loadSalones();
    if (_salones.isEmpty) {
      await _addSampleSalones();
    }
    await _loadEdificios();
    if (_edificios.isEmpty) {
      await _addSampleEdificios();
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

  Future<void> _addSampleMaestros() async {
    const sampleMaestros = [
      ('Dr. Juan Pérez', 'juan.perez@uv.mx', '228-123-4567'),
      ('Mtra. María García', 'maria.garcia@uv.mx', '228-234-5678'),
      ('Dr. Carlos López', 'carlos.lopez@uv.mx', '228-345-6789'),
      ('Lic. Ana Rodríguez', 'ana.rodriguez@uv.mx', '228-456-7890'),
    ];

    setState(() {
      _maestros.addAll(
        sampleMaestros.map(
          (maestro) => Maestro(
            nombre: maestro.$1,
            correo: maestro.$2,
            telefono: maestro.$3,
            imagenUrl: null,
          ),
        ),
      );
    });
    await _saveMaestros();
  }

  Future<void> _addSampleSalones() async {
    const sampleSalones = [
      ('A-101', 'Edificio A', 'Primer piso, ala norte', 'Cerca de la escalera principal', 40),
      ('A-102', 'Edificio A', 'Primer piso, ala sur', 'Junto al laboratorio de cómputo', 35),
      ('B-201', 'Edificio B', 'Segundo piso', 'Con proyector y pizarrón digital', 50),
      ('B-202', 'Edificio B', 'Segundo piso', 'Sala de conferencias', 60),
      ('C-301', 'Edificio C', 'Tercer piso', 'Laboratorio de física', 30),
    ];

    setState(() {
      _salones.addAll(
        sampleSalones.map(
          (salon) => Salon(
            nombre: salon.$1,
            edificio: salon.$2,
            ubicacion: salon.$3,
            referencias: salon.$4,
            capacidad: salon.$5,
            imagenUrl: null,
          ),
        ),
      );
    });
    await _saveSalones();
  }

  Future<void> _addSampleEdificios() async {
    const sampleEdificios = [
      ('Edificio A', 'Edificio principal de ingeniería', ['A-101', 'A-102', 'A-103', 'A-104']),
      ('Edificio B', 'Edificio de ciencias básicas', ['B-201', 'B-202', 'B-203']),
      ('Edificio C', 'Edificio de laboratorios', ['C-301', 'C-302', 'C-303']),
    ];

    setState(() {
      _edificios.addAll(
        sampleEdificios.map(
          (edificio) => Edificio(
            nombre: edificio.$1,
            descripcion: edificio.$2,
            salones: edificio.$3,
            imagenUrl: null,
          ),
        ),
      );
    });
    await _saveEdificios();
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
              ? 'Maestros'
              : _selectedTab == 3
              ? 'Salones'
              : _selectedTab == 4
              ? 'Edificios'
              : _selectedTab == 5
              ? 'Perfil'
              : _selectedTab == 6
              ? 'Personalizar'
              : _selectedTab == 7
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
                leading: Icon(LucideIcons.users, color: widget.menuTextColor),
                title: Text(
                  'Maestros',
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
                leading: Icon(LucideIcons.doorOpen, color: widget.menuTextColor),
                title: Text(
                  'Salones',
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
                leading: Icon(LucideIcons.building2, color: widget.menuTextColor),
                title: Text(
                  'Edificios',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 4,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 4);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.user, color: widget.menuTextColor),
                title: Text(
                  'Perfil',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 5,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 5);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.palette, color: widget.menuTextColor),
                title: Text(
                  'Personalizar',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 6,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 6);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.bell, color: widget.menuTextColor),
                title: Text(
                  'Notificaciones',
                  style: TextStyle(color: widget.menuTextColor),
                ),
                selected: _selectedTab == 7,
                selectedTileColor: widget.menuTextColor.withValues(alpha: 0.05),
                onTap: () {
                  setState(() => _selectedTab = 7);
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
                onTeacherTap: _showTeacherDetail,
                onAulaTap: _showSalonDetail,
                onEdificioTap: _showEdificioDetail,
                onMateriaTap: _showMateriaDetail,
                onNrcTap: _showNrcDetail,
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
            ? MaestrosTab(
                maestros: _maestros,
                onAddMaestro: _addMaestro,
                onDeleteMaestro: _deleteMaestro,
                primaryColor: widget.primaryColor,
              )
            : _selectedTab == 3
            ? SalonesTab(
                salones: _salones,
                onAddSalon: _addSalon,
                onDeleteSalon: _deleteSalon,
                primaryColor: widget.primaryColor,
              )
            : _selectedTab == 4
            ? EdificiosTab(
                edificios: _edificios,
                onAddEdificio: _addEdificio,
                onDeleteEdificio: _deleteEdificio,
                primaryColor: widget.primaryColor,
              )
            : _selectedTab == 5
            ? ProfileSection(
                profileName: widget.profileName,
                profileDetail: widget.profileDetail,
                useHeaderImage: widget.useHeaderImage,
                headerImageBytes: widget.headerImageBytes,
                primaryColor: widget.primaryColor,
                themeMode: widget.themeMode,
                onProfileChanged: widget.onProfileChanged,
              )
            : _selectedTab == 6
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
                onWeekSettingsChanged: ({showWeekend, weekStart, labelFormat}) async {
                  if (showWeekend != null) {
                    setState(() => _showWeekend = showWeekend);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('show_weekend', showWeekend);
                    _replaceTabController();
                  }
                  if (weekStart != null) {
                    setState(() => _weekStart = weekStart);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('week_start', weekStart);
                    _replaceTabController();
                  }
                  if (labelFormat != null) {
                    setState(() => _dayLabelFormat = labelFormat);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('day_label_format', labelFormat.name);
                  }
                },
                timeFormat: _timeFormat,
                onTimeFormatChanged: (format) async {
                  setState(() => _timeFormat = format);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('time_format', format.name);
                },
              )
            : _selectedTab == 7
            ? NotificationsSection(
                notificationsEnabled: _notificationsEnabled,
                primaryColor: widget.primaryColor,
                onNotificationsChanged: _toggleNotifications,
                onNotificationMinutesChanged: (minutes) async {
                  setState(() => _notificationMinutes = minutes);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('notification_minutes', minutes);
                  if (_notificationsEnabled) {
                    await _scheduleNextClassNotification();
                  }
                },
                initialNotificationMinutes: _notificationMinutes,
              )
            : const SizedBox.shrink(),
      ),
      floatingActionButton: (_selectedTab == 0 || _selectedTab == 1 || _selectedTab == 2 || _selectedTab == 3 || _selectedTab == 4)
          ? FloatingActionButton(
              onPressed: _selectedTab == 0
                  ? _openAddClassSheet
                  : _selectedTab == 1
                      ? _openSaveMateriaSheet
                      : _selectedTab == 2
                          ? _openAddMaestroSheet
                          : _selectedTab == 3
                              ? _openAddSalonSheet
                              : _openAddEdificioSheet,
              backgroundColor: widget.primaryColor,
              foregroundColor: defaultTextColor(widget.primaryColor),
              child: Icon(
                _selectedTab == 0
                    ? LucideIcons.plus
                    : _selectedTab == 1
                        ? LucideIcons.bookmarkPlus
                        : _selectedTab == 2
                            ? LucideIcons.userPlus
                            : _selectedTab == 3
                                ? LucideIcons.doorOpen
                                : LucideIcons.building2,
              ),
            )
          : null,
    );
  }

  void _addMaestro(Maestro maestro) {
    setState(() => _maestros.add(maestro));
    _saveMaestros();
  }

  void _deleteMaestro(int index) {
    setState(() => _maestros.removeAt(index));
    _saveMaestros();
  }

  Future<void> _saveMaestros() async {
    final prefs = await SharedPreferences.getInstance();
    final maestrosJson = _maestros.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('maestros', maestrosJson);
  }

  Future<void> _loadMaestros() async {
    final prefs = await SharedPreferences.getInstance();
    final maestrosJson = prefs.getStringList('maestros');
    if (maestrosJson != null) {
      setState(() {
        _maestros.clear();
        _maestros.addAll(
          maestrosJson.map((json) => Maestro.fromJson(jsonDecode(json))),
        );
      });
    }
  }

  void _addSalon(Salon salon) {
    setState(() => _salones.add(salon));
    _saveSalones();
  }

  void _deleteSalon(int index) {
    setState(() => _salones.removeAt(index));
    _saveSalones();
  }

  Future<void> _saveSalones() async {
    final prefs = await SharedPreferences.getInstance();
    final salonesJson = _salones.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('salones', salonesJson);
  }

  Future<void> _loadSalones() async {
    final prefs = await SharedPreferences.getInstance();
    final salonesJson = prefs.getStringList('salones');
    if (salonesJson != null) {
      setState(() {
        _salones.clear();
        _salones.addAll(
          salonesJson.map((json) => Salon.fromJson(jsonDecode(json))),
        );
      });
    }
  }

  void _addEdificio(Edificio edificio) {
    setState(() => _edificios.add(edificio));
    _saveEdificios();
  }

  void _deleteEdificio(int index) {
    setState(() => _edificios.removeAt(index));
    _saveEdificios();
  }

  Future<void> _saveEdificios() async {
    final prefs = await SharedPreferences.getInstance();
    final edificiosJson = _edificios.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('edificios', edificiosJson);
  }

  Future<void> _loadEdificios() async {
    final prefs = await SharedPreferences.getInstance();
    final edificiosJson = prefs.getStringList('edificios');
    if (edificiosJson != null) {
      setState(() {
        _edificios.clear();
        _edificios.addAll(
          edificiosJson.map((json) => Edificio.fromJson(jsonDecode(json))),
        );
      });
    }
  }

  Future<void> _openAddSalonSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => AddSalonSheet(
        primaryColor: widget.primaryColor,
        onSave: (salon) async {
          _addSalon(salon);
        },
      ),
    );
  }

  Future<void> _openAddEdificioSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => AddEdificioSheet(
        primaryColor: widget.primaryColor,
        onSave: (edificio) async {
          _addEdificio(edificio);
        },
      ),
    );
  }

  Future<void> _openAddMaestroSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => AddMaestroSheet(
        primaryColor: widget.primaryColor,
        onSave: (maestro) async {
          _addMaestro(maestro);
        },
      ),
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

  void _showTeacherDetail(String teacherName) {
    final maestro = _maestros.firstWhere(
      (m) => m.nombre.toLowerCase() == teacherName.toLowerCase(),
      orElse: () => Maestro(
        nombre: teacherName,
        correo: '',
        telefono: '',
        imagenUrl: null,
      ),
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => MaestroDetailSheet(
        maestro: maestro,
        primaryColor: widget.primaryColor,
      ),
    );
  }

  void _showSalonDetail(String salonName) {
    final salon = _salones.firstWhere(
      (s) => s.nombre.toLowerCase() == salonName.toLowerCase(),
      orElse: () => Salon(
        nombre: salonName,
        edificio: '',
        ubicacion: '',
        imagenUrl: null,
      ),
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: widget.screenBackgroundColor,
      builder: (context) => SalonDetailSheet(
        salon: salon,
        primaryColor: widget.primaryColor,
      ),
    );
  }

  void _showEdificioDetail(String edificioName) {
    final edificio = _edificios.firstWhere(
      (e) => e.nombre.toLowerCase() == edificioName.toLowerCase(),
      orElse: () => Edificio(
        nombre: edificioName,
        imagenUrl: null,
        descripcion: null,
        salones: [],
      ),
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.screenBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: EdificioDetailSheet(
          edificio: edificio,
          primaryColor: widget.primaryColor,
        ),
      ),
    );
  }

  void _showMateriaDetail(Clase clase) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(clase.materia, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('NRC: ${clase.nrc}'),
              ),
              ListTile(
                title: Text('Profesor: ${clase.profesor}'),
              ),
              ListTile(
                title: Text('Aula: ${clase.aula}'),
              ),
              ListTile(
                title: Text('Edificio: ${clase.edificio}'),
              ),
              ListTile(
                title: Text('Horario: ${clase.horaInicio} - ${clase.horaFin}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNrcDetail(String nrc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('NRC: $nrc')),
    );
  }
}
