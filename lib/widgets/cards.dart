import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Importamos los modelos y el tema que creaste en los otros módulos
import '../models/models.dart';
import '../utils/theme.dart';

class ClaseCard extends StatelessWidget {
  final String materia;
  final String profesor;
  final String nrc;
  final String edificio;
  final String aula;
  final String? horaInicio;
  final String? horaFin;
  final String letraInicial;
  final Color color;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onAddToSchedule;
  final VoidCallback? onTeacherTap;
  final VoidCallback? onMateriaTap;
  final VoidCallback? onAulaTap;
  final VoidCallback? onNrcTap;
  final VoidCallback? onEdificioTap;
  final TimeFormat timeFormat;

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
    this.onTeacherTap,
    this.onMateriaTap,
    this.onAulaTap,
    this.onNrcTap,
    this.onEdificioTap,
    this.timeFormat = TimeFormat.twentyFourHour,
  });

  String _formatTime(String time24) {
    if (timeFormat == TimeFormat.twentyFourHour) {
      return time24;
    }
    
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Utilizamos las funciones globales de theme.dart (sin guion bajo)
    final accentColor = materiaColorForTheme(color, brightness);
    final surfaceColor = cardColorForTheme(color, brightness);
    final cardTextColor = defaultTextColor(surfaceColor);

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18),
          // Borde visible en modo claro, invisible (transparente) en modo oscuro
          border: Border.all(
            color: brightness == Brightness.light
                ? accentColor
                : Colors.transparent, // Invisible en modo dark
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accentColor,
                  child: Text(
                    letraInicial,
                    style: TextStyle(
                      color: Brightness.light == brightness
                          ? Colors.black
                          : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (horaInicio != null && horaFin != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(horaInicio!),
                    style: TextStyle(
                      color: cardTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(horaFin!),
                    style: TextStyle(
                      color: cardTextColor.withValues(alpha: 0.62),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onMateriaTap,
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          materia,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cardTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (onMateriaTap != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: accentColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      InkWell(
                        onTap: onAulaTap,
                        borderRadius: BorderRadius.circular(12),
                        child: InfoChip(
                          icon: LucideIcons.mapPin,
                          label: aula,
                          color: cardTextColor,
                        ),
                      ),
                      InkWell(
                        onTap: onTeacherTap,
                        borderRadius: BorderRadius.circular(12),
                        child: InfoChip(
                          icon: LucideIcons.user,
                          label: profesor,
                          color: cardTextColor,
                        ),
                      ),
                      InkWell(
                        onTap: onEdificioTap,
                        borderRadius: BorderRadius.circular(12),
                        child: InfoChip(
                          icon: LucideIcons.building2,
                          label: edificio,
                          color: cardTextColor,
                        ),
                      ),
                    ],
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

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

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
    return ClaseCard(
      materia: materia.materia,
      profesor: materia.profesor,
      nrc: materia.nrc,
      edificio: materia.edificio,
      aula: materia.aula,
      horaInicio: null,
      horaFin: null,
      letraInicial: materia.materia.substring(0, 1).toUpperCase(),
      color: materia.color,
      onDelete: onDelete,
      onEdit: onEdit,
      onAddToSchedule: onAddToSchedule,
    );
  }
}

class EmptyDay extends StatelessWidget {
  final String day;

  const EmptyDay({super.key, required this.day});

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
