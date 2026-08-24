import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Importaciones de tus módulos
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/cards.dart';

// ==========================================
// 1. PESTAÑA: HORARIO
// ==========================================

class DayTabs extends StatelessWidget {
  final TabController controller;
  final List<String> days;
  final List<int> classCounts;

  const DayTabs({
    super.key,
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

class DaySchedule extends StatelessWidget {
  final String day;
  final List<Clase> classes;
  final int dayIndex;
  final Function(int, int) onDeleteClass;
  final Function(int, int) onEditClass;

  const DaySchedule({
    super.key,
    required this.day,
    required this.classes,
    required this.dayIndex,
    required this.onDeleteClass,
    required this.onEditClass,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) return EmptyDay(day: day);

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

class ScheduleTab extends StatefulWidget {
  final TabController tabController;
  final List<String> days;
  final List<int> dayIndices;
  final List<List<Clase>> classesByDay;
  final int selectedDay;
  final Function(int) onSelectedDayChanged;
  final Function(int, int) onDeleteClass;
  final Function(int, int) onEditClass;

  const ScheduleTab({
    super.key,
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
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
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
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          DayTabs(
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
                (dayIndex) => DaySchedule(
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

// ==========================================
// 2. PESTAÑA: MATERIAS GUARDADAS
// ==========================================

class MateriasGuardadasTab extends StatelessWidget {
  final List<MateriaGuardada> materias;
  final Function(int) onDelete;
  final Function(MateriaGuardada) onAddToSchedule;
  final Function(int) onEdit;

  const MateriasGuardadasTab({
    super.key,
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
              const Icon(LucideIcons.bookmark, size: 48, color: Colors.white24),
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

// ==========================================
// 3. PESTAÑA: PERFIL
// ==========================================

class ProfileSection extends StatefulWidget {
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

  const ProfileSection({
    super.key,
    required this.profileName,
    required this.profileDetail,
    required this.useHeaderImage,
    required this.headerImageBytes,
    required this.primaryColor,
    required this.themeMode,
    required this.onProfileChanged,
  });

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
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
    final menuBackground = menuBackgroundForPrimary(
      widget.primaryColor,
      brightness,
    );
    await widget.onProfileChanged(
      name: _nameController.text,
      detail: _detailController.text,
      imageUrl: '',
      useImage: _useImage,
      imageBytes: _imageBytes,
      menuTextColor: defaultTextColor(menuBackground),
    );
  }

  InputDecoration _fieldDecoration(
    String label,
    IconData icon,
    Color primaryColor,
  ) {
    final borderColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
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
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Datos del usuario',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: primaryColor),
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
          decoration: _fieldDecoration(
            'Nombre',
            LucideIcons.user,
            primaryColor,
          ),
          onChanged: (_) => _autoSave(),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _detailController,
          decoration: _fieldDecoration(
            'Carrera, grupo o descripción',
            LucideIcons.graduationCap,
            primaryColor,
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
            foregroundColor: primaryColor,
          ),
          icon: const Icon(LucideIcons.upload),
          label: const Text('Elegir imagen del dispositivo'),
        ),
      ],
    );
  }
}

// ==========================================
// 4. PESTAÑA: APARIENCIA
// ==========================================

class AppearanceSection extends StatefulWidget {
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

  const AppearanceSection({
    super.key,
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
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
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

  InputDecoration _fieldDecoration(
    String label,
    IconData icon,
    Color primaryColor,
  ) {
    final borderColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
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
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor;
    final selectedPrimaryColor = widget.primaryColor;
    final colorsList = allMateriaColors;

    List<Widget> colorSwatches() {
      return colorsList.map((color) {
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
                  ? Icon(LucideIcons.check, color: defaultTextColor(color))
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
              ?.copyWith(fontWeight: FontWeight.w800, color: primaryColor),
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
        Wrap(spacing: 14, runSpacing: 14, children: colorSwatches()),
        const SizedBox(height: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opciones de semana',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800, color: primaryColor),
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
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _weekStart,
              decoration: _fieldDecoration(
                'Comenzar la semana en',
                LucideIcons.calendarRange,
                primaryColor,
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
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: primaryColor),
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
            Text(
              'Vista previa',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: primaryColor),
            ),
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
                    color: primaryColor,
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

// ==========================================
// 5. PESTAÑA: NOTIFICACIONES
// ==========================================

class NotificationsSection extends StatefulWidget {
  final bool notificationsEnabled;
  final Color primaryColor;
  final Future<void> Function(bool enabled) onNotificationsChanged;

  const NotificationsSection({
    super.key,
    required this.notificationsEnabled,
    required this.primaryColor,
    required this.onNotificationsChanged,
  });

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
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

  InputDecoration _fieldDecoration(
    String label,
    IconData icon,
    Color primaryColor,
  ) {
    final borderColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.02);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
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
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Notificaciones',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: primaryColor),
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
              ?.copyWith(fontWeight: FontWeight.w800, color: primaryColor),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: _notificationMinutes,
          decoration: _fieldDecoration(
            'Minutos antes de la clase',
            LucideIcons.clock,
            primaryColor,
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
