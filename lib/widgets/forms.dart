import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../utils/theme.dart';

class AddClassSheet extends StatefulWidget {
  final List<String> days;
  final int initialDay;
  final List<MateriaGuardada> materiasGuardadas;
  final MateriaGuardada? preselectedMateria;
  final Color primaryColor;
  final void Function(int day, Clase newClass) onSave;

  const AddClassSheet({
    super.key,
    required this.days,
    required this.initialDay,
    required this.materiasGuardadas,
    this.preselectedMateria,
    required this.primaryColor,
    required this.onSave,
  });

  @override
  State<AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends State<AddClassSheet> {
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final borderColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.02);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: primaryColor),
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
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPadding = MediaQuery.paddingOf(context).top;
    final primaryColor = widget.primaryColor;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 10 : 20,
        bottom: bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nueva clase',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          color: Theme.of(context).colorScheme.surface
                              .withValues(alpha: 0.2),
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
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Materias guardadas',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: widget.materiasGuardadas.map((materia) {
                                final isSelected = _selectedMateria == materia;
                                final brightness = Theme.of(context).brightness;
                                final accentColor = materiaColorForTheme(
                                  materia.color,
                                  brightness,
                                );
                                final itemColor = isSelected
                                    ? cardColorForTheme(
                                        materia.color,
                                        brightness,
                                      ).withValues(alpha: 0.8)
                                    : Theme.of(context).colorScheme.surface
                                          .withValues(alpha: 0.2);
                                final itemTextColor = defaultTextColor(
                                  itemColor,
                                );
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                  color: defaultTextColor(
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: itemTextColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    materia.profesor,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: itemTextColor
                                                          .withValues(
                                                            alpha: 0.68,
                                                          ),
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
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.bookOpen,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Información de la clase',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.mapPin,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ubicación',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.clock,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Horario',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TimeSelector(
                            label: 'Hora inicio',
                            icon: LucideIcons.clock3,
                            initialTime: _startController.text,
                            onTimeChanged: (time) => _startController.text = time,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 12),
                          TimeSelector(
                            label: 'Hora fin',
                            icon: LucideIcons.clock3,
                            initialTime: _endController.text,
                            onTimeChanged: (time) => _endController.text = time,
                            primaryColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(LucideIcons.plus, size: 20),
              label: const Text(
                'Agregar al horario',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 22),
                backgroundColor: primaryColor,
                foregroundColor: defaultTextColor(primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SaveMateriaSheet extends StatefulWidget {
  final void Function(MateriaGuardada materia) onSave;
  final Color primaryColor;

  const SaveMateriaSheet({
    super.key,
    required this.onSave,
    required this.primaryColor,
  });

  @override
  State<SaveMateriaSheet> createState() => _SaveMateriaSheetState();
}

class _SaveMateriaSheetState extends State<SaveMateriaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _roomController = TextEditingController();
  final _buildingController = TextEditingController(text: 'ECONEX');
  final _nrcController = TextEditingController();
  int _selectedColorIndex = 0;

  List<Color> get _materiaColors => allMateriaColors;

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
        iconColor: defaultIconColor(_materiaColors[_selectedColorIndex]),
        textColor: defaultTextColor(_materiaColors[_selectedColorIndex]),
        cardColor: cardColorForTheme(
          _materiaColors[_selectedColorIndex],
          Theme.of(context).brightness,
        ),
      ),
    );
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final borderColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.02);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: primaryColor),
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
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPadding = MediaQuery.paddingOf(context).top;
    final primaryColor = widget.primaryColor;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 10 : 20,
        bottom: bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Guardar materia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cerrar',
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guarda los datos de una materia para agregarla fácilmente.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.bookOpen,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Información de la clase',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.mapPin,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ubicación',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _materiaColors.length,
                        itemBuilder: (context, index) {
                          final color = _materiaColors[index];
                          final isSelected = _selectedColorIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
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
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.2),
                                    width: 3,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        LucideIcons.check,
                                        color: defaultTextColor(color),
                                        size: 28,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(LucideIcons.bookmarkPlus),
              label: const Text(
                'Guardar materia',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 22),
                backgroundColor: primaryColor,
                foregroundColor: defaultTextColor(primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditClassSheet extends StatefulWidget {
  final List<String> days;
  final int initialDay;
  final List<MateriaGuardada> materiasGuardadas;
  final Clase initialClass;
  final Color primaryColor;
  final void Function(int day, Clase updatedClass) onSave;

  const EditClassSheet({
    super.key,
    required this.days,
    required this.initialDay,
    required this.materiasGuardadas,
    required this.initialClass,
    required this.onSave,
    required this.primaryColor,
  });

  @override
  State<EditClassSheet> createState() => _EditClassSheetState();
}

class _EditClassSheetState extends State<EditClassSheet> {
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final borderColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.02);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: primaryColor),
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
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPadding = MediaQuery.paddingOf(context).top;
    final primaryColor = widget.primaryColor;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 10 : 20,
        bottom: bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar clase',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifica los datos de la clase.',
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
                          color: Theme.of(context).colorScheme.surface
                              .withValues(alpha: 0.2),
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
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Materias guardadas',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: widget.materiasGuardadas.map((materia) {
                                final isSelected = _selectedMateria == materia;
                                final brightness = Theme.of(context).brightness;
                                final accentColor = materiaColorForTheme(
                                  materia.color,
                                  brightness,
                                );
                                final itemColor = isSelected
                                    ? cardColorForTheme(
                                        materia.color,
                                        brightness,
                                      ).withValues(alpha: 0.8)
                                    : Theme.of(context).colorScheme.surface
                                          .withValues(alpha: 0.2);
                                final itemTextColor = defaultTextColor(
                                  itemColor,
                                );
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? accentColor
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.12),
                                            width: 1,
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
                                                  color: defaultTextColor(
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: itemTextColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    materia.profesor,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: itemTextColor
                                                          .withValues(
                                                            alpha: 0.68,
                                                          ),
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
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.bookOpen,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Información de la clase',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.mapPin,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ubicación',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.clock,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Horario',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TimeSelector(
                            label: 'Hora inicio',
                            icon: LucideIcons.clock3,
                            initialTime: _startController.text,
                            onTimeChanged: (time) => _startController.text = time,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 12),
                          TimeSelector(
                            label: 'Hora fin',
                            icon: LucideIcons.clock3,
                            initialTime: _endController.text,
                            onTimeChanged: (time) => _endController.text = time,
                            primaryColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(LucideIcons.save),
              label: const Text(
                'Guardar cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 22),
                backgroundColor: primaryColor,
                foregroundColor: defaultTextColor(primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditMateriaSheet extends StatefulWidget {
  final MateriaGuardada initialMateria;
  final Function(MateriaGuardada) onSave;
  final Color primaryColor;

  const EditMateriaSheet({
    super.key,
    required this.initialMateria,
    required this.onSave,
    required this.primaryColor,
  });

  @override
  State<EditMateriaSheet> createState() => _EditMateriaSheetState();
}

class _EditMateriaSheetState extends State<EditMateriaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _teacherController;
  late final TextEditingController _nrcController;
  late final TextEditingController _roomController;
  late final TextEditingController _buildingController;
  int _selectedColorIndex = 0;

  List<Color> get _materiaColors => allMateriaColors;

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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final borderColor = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.02);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: primaryColor),
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
        borderSide: BorderSide(color: primaryColor, width: 2),
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
        color: _materiaColors[_selectedColorIndex],
        iconColor: defaultIconColor(_materiaColors[_selectedColorIndex]),
        textColor: defaultTextColor(_materiaColors[_selectedColorIndex]),
        cardColor: cardColorForTheme(
          _materiaColors[_selectedColorIndex],
          Theme.of(context).brightness,
        ),
      );
      widget.onSave(updatedMateria);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPadding = MediaQuery.paddingOf(context).top;
    final primaryColor = widget.primaryColor;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 10 : 20,
        bottom: bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar materia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modifica los datos de la materia guardada.',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.bookOpen,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Información de la clase',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.2),
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
                                LucideIcons.mapPin,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ubicación',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _materiaColors.length,
                        itemBuilder: (context, index) {
                          final color = _materiaColors[index];
                          final isSelected = _selectedColorIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
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
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.2),
                                    width: 3,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        LucideIcons.check,
                                        color: defaultTextColor(color),
                                        size: 28,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                _save();
              },
              icon: const Icon(LucideIcons.save),
              label: const Text(
                'Guardar cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 22),
                backgroundColor: primaryColor,
                foregroundColor: defaultTextColor(primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeSelector extends StatefulWidget {
  final String label;
  final IconData icon;
  final String initialTime;
  final Function(String) onTimeChanged;
  final Color primaryColor;

  const TimeSelector({
    super.key,
    required this.label,
    required this.icon,
    required this.initialTime,
    required this.onTimeChanged,
    required this.primaryColor,
  });

  @override
  State<TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<TimeSelector> {
  late String _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  void _openTimePicker() async {
    final parts = _selectedTime.split(':');
    final initialHour = int.parse(parts[0]);
    final initialMinute = int.parse(parts[1]);

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimePickerModal(
        initialHour: initialHour,
        initialMinute: initialMinute,
        primaryColor: widget.primaryColor,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTime = result;
        widget.onTimeChanged(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final fill = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.02);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _openTimePicker,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(widget.icon, size: 20, color: widget.primaryColor),
                ),
                Expanded(
                  child: Text(
                    _selectedTime,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimePickerModal extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final Color primaryColor;

  const _TimePickerModal({
    required this.initialHour,
    required this.initialMinute,
    required this.primaryColor,
  });

  @override
  State<_TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<_TimePickerModal> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: widget.initialHour);
    _minuteController = FixedExtentScrollController(initialItem: widget.initialMinute ~/ 5);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                Text(
                  'Seleccionar hora',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final hour = _hourController.selectedItem;
                    final minute = _minuteController.selectedItem * 5;
                    final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                    Navigator.pop(context, timeString);
                  },
                  child: Text(
                    'Confirmar',
                    style: TextStyle(
                      color: widget.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _hourController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {});
                    },
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        border: Border(
                          top: BorderSide(color: widget.primaryColor.withValues(alpha: 0.3)),
                          bottom: BorderSide(color: widget.primaryColor.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    children: List.generate(24, (index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: _hourController.selectedItem == index
                                ? widget.primaryColor
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _minuteController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {});
                    },
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        border: Border(
                          top: BorderSide(color: widget.primaryColor.withValues(alpha: 0.3)),
                          bottom: BorderSide(color: widget.primaryColor.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    children: List.generate(12, (index) {
                      final minute = index * 5;
                      return Center(
                        child: Text(
                          minute.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: _minuteController.selectedItem == index
                                ? widget.primaryColor
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
