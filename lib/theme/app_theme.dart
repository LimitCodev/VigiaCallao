import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ════════════════════════════════════════════════════════════════
/// VIGÍA CALLAO — SISTEMA DE DISEÑO
/// ════════════════════════════════════════════════════════════════
/// Filosofía: Centro de Control / NOC (Network Operations Center).
/// El fondo es grafito neutro -no azul- para que las alertas
/// (rojo/ámbar/verde) tengan máximo contraste y la app pueda
/// monitorearse por turnos largos sin fatiga visual.
/// El azul institucional original (#1B3A6B) se conserva como
/// ACENTO de marca, no como fondo.
class AppColors {
  AppColors._();

  // ---- Superficies (antes "azul marino" como fondo, ahora grafito) ----
  static const Color background = Color(0xFF0F1117); // fondo raíz de la app
  static const Color surface = Color(0xFF1A1E27); // cards, sidebar, paneles
  static const Color surfaceElevated = Color(0xFF232934); // hover, modales, inputs
  static const Color border = Color(0xFF2D333F);
  static const Color borderSubtle = Color(0xFF21262F);

  // ---- Acento institucional (heredado de la paleta original) ----
  static const Color navyInstitutional = Color(0xFF1B3A6B); // identidad de marca
  static const Color accent = Color(0xFF3D7DFF); // CTA, focus, links, gráficos
  static const Color accentMuted = Color(0xFF2A5BC7);

  // ---- Estados semánticos (ajustados para fondo oscuro) ----
  static const Color danger = Color(0xFFFF5C5C); // alerta activa / infracción
  static const Color dangerBg = Color(0x1FFF5C5C);
  static const Color warning = Color(0xFFFFB74D); // en revisión
  static const Color warningBg = Color(0x1FFFB74D);
  static const Color success = Color(0xFF4ADE80); // atendida / online
  static const Color successBg = Color(0x1F4ADE80);
  static const Color neutralStatus = Color(0xFF7C8699); // cámara offline / sin datos
  static const Color neutralStatusBg = Color(0x1F7C8699);

  // ---- Texto ----
  static const Color textPrimary = Color(0xFFF4F6F9);
  static const Color textSecondary = Color(0xFF9AA3B2);
  static const Color textDisabled = Color(0xFF5C6472);

  // ---- Gradientes de marca (para hero del login / headers de KPI) ----
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B3A6B), Color(0xFF0F1117)],
  );

  static const LinearGradient accentGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D7DFF), Color(0xFF1B3A6B)],
  );
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppTextStyles {
  AppTextStyles._();

  // Títulos → Poppins SemiBold (jerarquía / branding)
  static TextStyle get displayLg => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMd => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get titleLg => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMd => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Cuerpo → Inter Regular (legibilidad en data)
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      );

  // Logs / IDs / placas → JetBrains Mono (monoespaciado)
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get monoSm => GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // Número grande de KPI (hero numérico del dashboard)
  static TextStyle get kpiNumber => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.0,
        letterSpacing: -0.5,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.navyInstitutional,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      dividerColor: AppColors.border,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMd,
        labelStyle: AppTextStyles.bodyMd,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
