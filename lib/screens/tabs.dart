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

class DaySchedule extends StatefulWidget {
  final String day;
  final List<Clase> classes;
  final int dayIndex;
  final Function(int, int) onDeleteClass;
  final Function(int, int) onEditClass;
  final Function(String) onTeacherTap;
  final Function(String) onAulaTap;
  final Function(String) onEdificioTap;
  final Function(Clase) onMateriaTap;
  final Function(String) onNrcTap;
  final TimeFormat timeFormat;

  const DaySchedule({
    super.key,
    required this.day,
    required this.classes,
    required this.dayIndex,
    required this.onDeleteClass,
    required this.onEditClass,
    required this.onTeacherTap,
    required this.onAulaTap,
    required this.onEdificioTap,
    required this.onMateriaTap,
    required this.onNrcTap,
    required this.timeFormat,
  });

  @override
  State<DaySchedule> createState() => _DayScheduleState();
}

class _DayScheduleState extends State<DaySchedule> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Clase> _classes;

  @override
  void initState() {
    super.initState();
    _classes = List.from(widget.classes);
  }

  @override
  void didUpdateWidget(DaySchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classes.length != widget.classes.length) {
      if (widget.classes.length > oldWidget.classes.length) {
        // Item added
        final newIndex = widget.classes.length - 1;
        _classes.add(widget.classes[newIndex]);
        _listKey.currentState?.insertItem(newIndex);
      } else {
        // Item removed
        for (int i = 0; i < _classes.length; i++) {
          if (!widget.classes.contains(_classes[i])) {
            final removedItem = _classes[i];
            _listKey.currentState?.removeItem(
              i,
              (context, animation) => _buildItem(removedItem, i, animation),
              duration: const Duration(milliseconds: 300),
            );
            _classes.removeAt(i);
            break;
          }
        }
      }
    } else {
      _classes = List.from(widget.classes);
    }
  }

  Widget _buildItem(Clase item, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(animation),
          child: ClaseCard(
            materia: item.materia,
            profesor: item.profesor,
            nrc: item.nrc,
            edificio: item.edificio,
            aula: item.aula,
            horaInicio: item.horaInicio,
            horaFin: item.horaFin,
            letraInicial: item.letraInicial,
            color: item.color,
            onDelete: () => widget.onDeleteClass(widget.dayIndex, index),
            onEdit: () => widget.onEditClass(widget.dayIndex, index),
            onTeacherTap: () => widget.onTeacherTap(item.profesor),
            onAulaTap: () => widget.onAulaTap(item.aula),
            onEdificioTap: () => widget.onEdificioTap(item.edificio),
            onMateriaTap: () => widget.onMateriaTap(item),
            onNrcTap: () => widget.onNrcTap(item.nrc),
            timeFormat: widget.timeFormat,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_classes.isEmpty) return EmptyDay(day: widget.day);

    return AnimatedList(
      key: _listKey,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      initialItemCount: _classes.length,
      itemBuilder: (context, index, animation) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildItem(_classes[index], index, animation),
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
  final Function(String) onTeacherTap;
  final Function(String) onAulaTap;
  final Function(String) onEdificioTap;
  final Function(Clase) onMateriaTap;
  final Function(String) onNrcTap;
  final TimeFormat timeFormat;

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
    required this.onTeacherTap,
    required this.onAulaTap,
    required this.onEdificioTap,
    required this.onMateriaTap,
    required this.onNrcTap,
    required this.timeFormat,
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
                  onTeacherTap: widget.onTeacherTap,
                  onAulaTap: widget.onAulaTap,
                  onEdificioTap: widget.onEdificioTap,
                  onMateriaTap: widget.onMateriaTap,
                  onNrcTap: widget.onNrcTap,
                  timeFormat: widget.timeFormat,
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
  final TimeFormat timeFormat;
  final Future<void> Function(TimeFormat format) onTimeFormatChanged;

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
    required this.timeFormat,
    required this.onTimeFormatChanged,
  });

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  late bool _showWeekend;
  late int _weekStart;
  late DayLabelFormat _dayLabelFormat;
  late TimeFormat _timeFormat;



  @override
  void initState() {
    super.initState();
    _showWeekend = widget.showWeekend;
    _weekStart = widget.weekStart;
    _dayLabelFormat = widget.dayLabelFormat;
    _timeFormat = widget.timeFormat;
  }

  Widget _cardOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.12),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? primaryColor
                    : Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.circleCheck, color: primaryColor, size: 22),
            ],
          ),
        ),
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
            const SizedBox(height: 16),
            Text(
              'Formato de los días',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: primaryColor),
            ),
            const SizedBox(height: 12),
            _cardOption(
              title: 'Nombre completo',
              subtitle: 'Ejemplo: Lunes, Martes, Miércoles...',
              icon: LucideIcons.calendarDays,
              isSelected: _dayLabelFormat == DayLabelFormat.full,
              onTap: () async {
                setState(() => _dayLabelFormat = DayLabelFormat.full);
                await widget.onWeekSettingsChanged(
                  labelFormat: DayLabelFormat.full,
                );
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            _cardOption(
              title: 'Abreviado (3 letras)',
              subtitle: 'Ejemplo: Lun, Mar, Mié, Jue...',
              icon: LucideIcons.calendar,
              isSelected: _dayLabelFormat == DayLabelFormat.short,
              onTap: () async {
                setState(() => _dayLabelFormat = DayLabelFormat.short);
                await widget.onWeekSettingsChanged(
                  labelFormat: DayLabelFormat.short,
                );
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            _cardOption(
              title: 'Inicial',
              subtitle: 'Ejemplo: L, M, X, J, V...',
              icon: LucideIcons.calendarRange,
              isSelected: _dayLabelFormat == DayLabelFormat.initial,
              onTap: () async {
                setState(() => _dayLabelFormat = DayLabelFormat.initial);
                await widget.onWeekSettingsChanged(
                  labelFormat: DayLabelFormat.initial,
                );
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Comenzar la semana en',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: primaryColor),
            ),
            const SizedBox(height: 12),
            _cardOption(
              title: 'Lunes',
              subtitle: 'La semana inicia en Lunes',
              icon: LucideIcons.calendar,
              isSelected: _weekStart == 1,
              onTap: () async {
                setState(() => _weekStart = 1);
                await widget.onWeekSettingsChanged(weekStart: 1);
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            _cardOption(
              title: 'Domingo',
              subtitle: 'La semana inicia en Domingo',
              icon: LucideIcons.calendarRange,
              isSelected: _weekStart == 0,
              onTap: () async {
                setState(() => _weekStart = 0);
                await widget.onWeekSettingsChanged(weekStart: 0);
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Formato de hora',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: primaryColor),
            ),
            const SizedBox(height: 12),
            _cardOption(
              title: '24 horas',
              subtitle: 'Ejemplo: 08:00, 14:30, 20:00',
              icon: LucideIcons.clock,
              isSelected: _timeFormat == TimeFormat.twentyFourHour,
              onTap: () async {
                setState(() => _timeFormat = TimeFormat.twentyFourHour);
                await widget.onTimeFormatChanged(TimeFormat.twentyFourHour);
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
            _cardOption(
              title: '12 horas (AM/PM)',
              subtitle: 'Ejemplo: 8:00 AM, 2:30 PM, 8:00 PM',
              icon: LucideIcons.clock,
              isSelected: _timeFormat == TimeFormat.twelveHour,
              onTap: () async {
                setState(() => _timeFormat = TimeFormat.twelveHour);
                await widget.onTimeFormatChanged(TimeFormat.twelveHour);
              },
              primaryColor: primaryColor,
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
  final Future<void> Function(int minutes) onNotificationMinutesChanged;
  final int initialNotificationMinutes;

  const NotificationsSection({
    super.key,
    required this.notificationsEnabled,
    required this.primaryColor,
    required this.onNotificationsChanged,
    required this.onNotificationMinutesChanged,
    required this.initialNotificationMinutes,
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
    _notificationMinutes = widget.initialNotificationMinutes;
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await widget.onNotificationsChanged(value);
  }

  Widget _cardOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.12),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? primaryColor
                    : Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.circleCheck, color: primaryColor, size: 22),
            ],
          ),
        ),
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
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: primaryColor),
        ),
        const SizedBox(height: 12),
        ..._notificationOptions.map((minutes) {
          final isSelected = _notificationMinutes == minutes;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _cardOption(
              title: '$minutes minutos antes',
              subtitle: 'Aviso previo para prepararte',
              icon: LucideIcons.clock,
              isSelected: isSelected,
              onTap: _notificationsEnabled
                  ? () async {
                      setState(() => _notificationMinutes = minutes);
                      await widget.onNotificationMinutesChanged(minutes);
                    }
                  : () {},
              primaryColor: primaryColor,
            ),
          );
        }),
      ],
    );
  }
}

// ==========================================
// 6. PESTAÑA: MAESTROS
// ==========================================

class MaestrosTab extends StatefulWidget {
  final List<Maestro> maestros;
  final Function(Maestro) onAddMaestro;
  final Function(int) onDeleteMaestro;
  final Function(int) onEditMaestro;
  final Color primaryColor;

  const MaestrosTab({
    super.key,
    required this.maestros,
    required this.onAddMaestro,
    required this.onDeleteMaestro,
    required this.onEditMaestro,
    required this.primaryColor,
  });

  @override
  State<MaestrosTab> createState() => _MaestrosTabState();
}

class _MaestrosTabState extends State<MaestrosTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.maestros.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.users,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin maestros',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tus maestros para verlos aquí',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.maestros.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final maestro = widget.maestros[index];
        return MaestroCard(
          maestro: maestro,
          onEdit: () => widget.onEditMaestro(index),
          onDelete: () => widget.onDeleteMaestro(index),
          primaryColor: widget.primaryColor,
        );
      },
    );
  }
}

class MaestroCard extends StatelessWidget {
  final Maestro maestro;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color primaryColor;

  const MaestroCard({
    super.key,
    required this.maestro,
    required this.onEdit,
    required this.onDelete,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              child: maestro.imagenUrl != null
                  ? ClipOval(
                      child: Image.network(
                        maestro.imagenUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            maestro.nombre.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      maestro.nombre.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maestro.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    maestro.correo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

class MaestroDetailSheet extends StatelessWidget {
  final Maestro maestro;
  final Color primaryColor;

  const MaestroDetailSheet({
    super.key,
    required this.maestro,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 48,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            child: maestro.imagenUrl != null
                ? ClipOval(
                    child: Image.network(
                      maestro.imagenUrl!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          maestro.nombre.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    maestro.nombre.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            maestro.nombre,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _DetailRow(
                  icon: LucideIcons.mail,
                  label: 'Correo',
                  value: maestro.correo,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: LucideIcons.phone,
                  label: 'Teléfono',
                  value: maestro.telefono,
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primaryColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 6. PESTAÑA: SALONES
// ==========================================

class SalonesTab extends StatefulWidget {
  final List<Salon> salones;
  final Function(Salon) onAddSalon;
  final Function(int) onDeleteSalon;
  final Function(int) onEditSalon;
  final Color primaryColor;

  const SalonesTab({
    super.key,
    required this.salones,
    required this.onAddSalon,
    required this.onDeleteSalon,
    required this.onEditSalon,
    required this.primaryColor,
  });

  @override
  State<SalonesTab> createState() => _SalonesTabState();
}

class _SalonesTabState extends State<SalonesTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.salones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.doorOpen,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay salones',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega salones para ver su información',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.salones.length,
      itemBuilder: (context, index) {
        final salon = widget.salones[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SalonCard(
            salon: salon,
            primaryColor: widget.primaryColor,
            onEdit: () => widget.onEditSalon(index),
            onDelete: () => widget.onDeleteSalon(index),
          ),
        );
      },
    );
  }
}

class SalonCard extends StatelessWidget {
  final Salon salon;
  final Color primaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SalonCard({
    super.key,
    required this.salon,
    required this.primaryColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cardColor = brightness == Brightness.light
        ? Colors.white
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.3);
    final textColor = brightness == Brightness.light
        ? Colors.black87
        : Colors.white;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.doorOpen,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.nombre,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      salon.edificio,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalonDetailSheet extends StatelessWidget {
  final Salon salon;
  final Color primaryColor;

  const SalonDetailSheet({
    super.key,
    required this.salon,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (salon.imagenUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                salon.imagenUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    LucideIcons.image,
                    size: 48,
                    color: primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.nombre,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  salon.edificio,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                _DetailRow(
                  icon: LucideIcons.mapPin,
                  label: 'Ubicación',
                  value: salon.ubicacion,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: LucideIcons.users,
                  label: 'Capacidad',
                  value: '${salon.capacidad} personas',
                  primaryColor: primaryColor,
                ),
                if (salon.referencias != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: LucideIcons.info,
                    label: 'Referencias',
                    value: salon.referencias!,
                    primaryColor: primaryColor,
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ==========================================
// 7. PESTAÑA: EDIFICIOS
// ==========================================

class EdificiosTab extends StatefulWidget {
  final List<Edificio> edificios;
  final Function(Edificio) onAddEdificio;
  final Function(int) onDeleteEdificio;
  final Function(int) onEditEdificio;
  final Color primaryColor;

  const EdificiosTab({
    super.key,
    required this.edificios,
    required this.onAddEdificio,
    required this.onDeleteEdificio,
    required this.onEditEdificio,
    required this.primaryColor,
  });

  @override
  State<EdificiosTab> createState() => _EdificiosTabState();
}

class _EdificiosTabState extends State<EdificiosTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.edificios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.building2,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay edificios',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega edificios para ver sus salones',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.edificios.length,
      itemBuilder: (context, index) {
        final edificio = widget.edificios[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EdificioCard(
            edificio: edificio,
            primaryColor: widget.primaryColor,
            onEdit: () => widget.onEditEdificio(index),
            onDelete: () => widget.onDeleteEdificio(index),
          ),
        );
      },
    );
  }
}

class EdificioCard extends StatelessWidget {
  final Edificio edificio;
  final Color primaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EdificioCard({
    super.key,
    required this.edificio,
    required this.primaryColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cardColor = brightness == Brightness.light
        ? Colors.white
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.3);
    final textColor = brightness == Brightness.light
        ? Colors.black87
        : Colors.white;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.building2,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edificio.nombre,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${edificio.salones.length} salones',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EdificioDetailSheet extends StatelessWidget {
  final Edificio edificio;
  final Color primaryColor;

  const EdificioDetailSheet({
    super.key,
    required this.edificio,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 20),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        if (edificio.imagenUrl != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                edificio.imagenUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    LucideIcons.image,
                    size: 48,
                    color: primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  edificio.nombre,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ),
              if (edificio.descripcion != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    edificio.descripcion!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Salones (${edificio.salones.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: edificio.salones.map((salon) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        salon,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
