// lib/logic/Theme/NodeColorsExtension.dart
import 'package:flutter/material.dart';

class NodeColorsExtension extends ThemeExtension<NodeColorsExtension> {
  final Color defaultConceptColor;
  final Color defaultDomainColor;

  NodeColorsExtension({
    required this.defaultConceptColor,
    required this.defaultDomainColor,
  });

  @override
  ThemeExtension<NodeColorsExtension> copyWith(
      {Color? concept, Color? domain}) {
    return NodeColorsExtension(
      defaultConceptColor: concept ?? defaultConceptColor,
      defaultDomainColor: domain ?? defaultDomainColor,
    );
  }

  @override
  ThemeExtension<NodeColorsExtension> lerp(
      ThemeExtension<NodeColorsExtension>? other, double t) {
    if (other is! NodeColorsExtension) return this;
    return NodeColorsExtension(
      defaultConceptColor: Color.lerp(
          defaultConceptColor, other.defaultConceptColor, t)!,
      defaultDomainColor: Color.lerp(
          defaultDomainColor, other.defaultDomainColor, t)!,
    );
  }
}