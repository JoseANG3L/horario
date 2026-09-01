import 'package:flutter/material.dart';
import 'package:horario/utils/theme.dart';

enum DayLabelFormat { full, short, initial }

enum TimeFormat { twelveHour, twentyFourHour }

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
          : defaultIconColor(Color(json['color'])),
      textColor: json.containsKey('textColor')
          ? Color(json['textColor'])
          : defaultTextColor(Color(json['color'])),
      cardColor: json.containsKey('cardColor')
          ? Color(json['cardColor'])
          : defaultCardColor(Color(json['color'])),
    );
  }
}

int compareClassesByStartTime(Clase first, Clase second) {
  int minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  return minutes(first.horaInicio).compareTo(minutes(second.horaInicio));
}

class Maestro {
  final String nombre;
  final String correo;
  final String telefono;
  final String? imagenUrl;

  const Maestro({
    required this.nombre,
    required this.correo,
    required this.telefono,
    this.imagenUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
    };
  }

  factory Maestro.fromJson(Map<String, dynamic> json) {
    return Maestro(
      nombre: json['nombre'],
      correo: json['correo'],
      telefono: json['telefono'],
      imagenUrl: json['imagenUrl'],
    );
  }
}

class Salon {
  final String nombre;
  final String edificio;
  final String ubicacion;
  final String? imagenUrl;
  final String? referencias;
  final int capacidad;

  const Salon({
    required this.nombre,
    required this.edificio,
    required this.ubicacion,
    this.imagenUrl,
    this.referencias,
    this.capacidad = 40,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'edificio': edificio,
      'ubicacion': ubicacion,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
      if (referencias != null) 'referencias': referencias,
      'capacidad': capacidad,
    };
  }

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      nombre: json['nombre'],
      edificio: json['edificio'],
      ubicacion: json['ubicacion'],
      imagenUrl: json['imagenUrl'],
      referencias: json['referencias'],
      capacidad: json['capacidad'] ?? 40,
    );
  }
}

class Edificio {
  final String nombre;
  final String? imagenUrl;
  final String? descripcion;
  final List<String> salones;

  const Edificio({
    required this.nombre,
    this.imagenUrl,
    this.descripcion,
    this.salones = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
      if (descripcion != null) 'descripcion': descripcion,
      'salones': salones,
    };
  }

  factory Edificio.fromJson(Map<String, dynamic> json) {
    return Edificio(
      nombre: json['nombre'],
      imagenUrl: json['imagenUrl'],
      descripcion: json['descripcion'],
      salones: List<String>.from(json['salones'] ?? []),
    );
  }
}
