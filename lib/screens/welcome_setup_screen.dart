import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../utils/theme.dart';

class WelcomeSetupScreen extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onPrimaryColorChanged;
  final Function({
    required Color primaryColor,
    required String profileName,
    required String profileDetail,
    required DayLabelFormat dayFormat,
    required bool notificationsEnabled,
    required int notificationMinutes,
    required ThemeMode themeMode,
  })
  onFinishSetup;

  const WelcomeSetupScreen({
    super.key,
    required this.initialThemeMode,
    required this.onThemeModeChanged,
    required this.onPrimaryColorChanged,
    required this.onFinishSetup,
  });

  @override
  State<WelcomeSetupScreen> createState() => _WelcomeSetupScreenState();
}

class _WelcomeSetupScreenState extends State<WelcomeSetupScreen> {
  int _currentStep = 0;

  late ThemeMode _selectedThemeMode;
  Color? _userSelectedColor;
  final _nameController = TextEditingController(text: 'Mi Nombre');
  final _detailController = TextEditingController(
    text: 'Ingeniería de Software',
  );
  DayLabelFormat _selectedFormat = DayLabelFormat.short;
  bool _notifications = true;
  int _notificationMinutes = 15;
  final List<int> _notificationOptions = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.initialThemeMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Color get _activeColor {
    if (_userSelectedColor != null) return _userSelectedColor!;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  InputDecoration _fieldDecoration(
    String label,
    IconData icon,
    Color activeColor,
  ) {
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
        borderSide: BorderSide(color: activeColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentActiveColor = _activeColor;
    const totalSteps = 5;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración inicial',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: currentActiveColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personaliza tu aplicación antes de comenzar.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    _buildThemeStep(),
                    _buildColorStep(),
                    _buildProfileStep(),
                    _buildDayFormatStep(),
                    _buildNotificationsStep(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Anterior'),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 22,
                      ),
                      backgroundColor: currentActiveColor,
                      foregroundColor: defaultTextColor(currentActiveColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_currentStep < totalSteps - 1) {
                        setState(() => _currentStep++);
                      } else {
                        widget.onFinishSetup(
                          primaryColor: currentActiveColor,
                          profileName: _nameController.text,
                          profileDetail: _detailController.text,
                          dayFormat: _selectedFormat,
                          notificationsEnabled: _notifications,
                          notificationMinutes: _notificationMinutes,
                          themeMode: _selectedThemeMode,
                        );
                      }
                    },
                    child: Text(
                      _currentStep == totalSteps - 1 ? 'Comenzar' : 'Siguiente',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona el tema visual:',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: _activeColor),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              _cardOption(
                title: 'Predeterminado del sistema',
                subtitle: 'Sigue la configuración de tu dispositivo',
                icon: LucideIcons.smartphone,
                isSelected: _selectedThemeMode == ThemeMode.system,
                onTap: () {
                  setState(() => _selectedThemeMode = ThemeMode.system);
                  widget.onThemeModeChanged(ThemeMode.system);
                },
              ),
              const SizedBox(height: 12),
              _cardOption(
                title: 'Modo Claro',
                subtitle: 'Apariencia luminosa y limpia',
                icon: LucideIcons.sun,
                isSelected: _selectedThemeMode == ThemeMode.light,
                onTap: () {
                  setState(() => _selectedThemeMode = ThemeMode.light);
                  widget.onThemeModeChanged(ThemeMode.light);
                },
              ),
              const SizedBox(height: 12),
              _cardOption(
                title: 'Modo Oscuro',
                subtitle: 'Apariencia profunda ideal para la noche',
                icon: LucideIcons.moon,
                isSelected: _selectedThemeMode == ThemeMode.dark,
                onTap: () {
                  setState(() => _selectedThemeMode = ThemeMode.dark);
                  widget.onThemeModeChanged(ThemeMode.dark);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorStep() {
    final baseColors = allMateriaColors
        .where((c) => c != Colors.white && c != Colors.black)
        .toList();
    final half = baseColors.length ~/ 2;
    final lightColors = baseColors.take(half).toList();
    final darkColors = baseColors.skip(half).toList();
    final neutralColors = [Colors.white, Colors.black];

    Widget buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.8),
          ),
        ),
      );
    }

    Widget buildColorGrid(List<Color> colors) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = _userSelectedColor == color;
          return GestureDetector(
            onTap: () {
              setState(() => _userSelectedColor = color);
              widget.onPrimaryColorChanged(color);
            },
            child: Container(
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
                  ? Icon(
                      LucideIcons.check,
                      color: defaultTextColor(color),
                      size: 24,
                    )
                  : null,
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elige tu color principal:',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: _activeColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Se usará en botones, pestañas y elementos destacados.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              buildSectionTitle('Colores claros'),
              buildColorGrid(lightColors),
              const SizedBox(height: 12),
              buildSectionTitle('Colores oscuros'),
              buildColorGrid(darkColors),
              const SizedBox(height: 12),
              buildSectionTitle('Neutros'),
              buildColorGrid(neutralColors),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus datos de usuario:',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: _activeColor),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(
            'Nombre',
            LucideIcons.user,
            _activeColor,
          ),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _detailController,
          textInputAction: TextInputAction.done,
          decoration: _fieldDecoration(
            'Carrera o Descripción',
            LucideIcons.graduationCap,
            _activeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDayFormatStep() {
    String previewText(DayLabelFormat format) {
      if (format == DayLabelFormat.initial) return 'L (o M, X, J, V...)';
      if (format == DayLabelFormat.short) return 'Lun, Mar, Mié, Jue...';
      return 'Lunes, Martes, Miércoles...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formato de los días:',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: _activeColor),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              _cardOption(
                title: 'Nombre completo',
                subtitle: 'Ejemplo: ${previewText(DayLabelFormat.full)}',
                icon: LucideIcons.calendarDays,
                isSelected: _selectedFormat == DayLabelFormat.full,
                onTap: () =>
                    setState(() => _selectedFormat = DayLabelFormat.full),
              ),
              const SizedBox(height: 12),
              _cardOption(
                title: 'Abreviado (3 letras)',
                subtitle: 'Ejemplo: ${previewText(DayLabelFormat.short)}',
                icon: LucideIcons.calendar,
                isSelected: _selectedFormat == DayLabelFormat.short,
                onTap: () =>
                    setState(() => _selectedFormat = DayLabelFormat.short),
              ),
              const SizedBox(height: 12),
              _cardOption(
                title: 'Inicial',
                subtitle: 'Ejemplo: ${previewText(DayLabelFormat.initial)}',
                icon: LucideIcons.calendarRange,
                isSelected: _selectedFormat == DayLabelFormat.initial,
                onTap: () =>
                    setState(() => _selectedFormat = DayLabelFormat.initial),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notificaciones y alertas:',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: _activeColor),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text('Activar notificaciones'),
              subtitle: const Text('Recibe recordatorios antes de cada clase'),
              value: _notifications,
              onChanged: (val) => setState(() => _notifications = val),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tiempo de aviso',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _notificationMinutes,
            decoration: _fieldDecoration(
              'Minutos antes de la clase',
              LucideIcons.clock,
              _activeColor,
            ),
            items: _notificationOptions.map((minutes) {
              return DropdownMenuItem<int>(
                value: minutes,
                child: Text('$minutes minutos'),
              );
            }).toList(),
            onChanged: _notifications
                ? (value) {
                    if (value != null) {
                      setState(() => _notificationMinutes = value);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _cardOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = _activeColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? primary
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
                    ? primary
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
                Icon(LucideIcons.circleCheck, color: primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
