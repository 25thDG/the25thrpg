import 'package:flutter/material.dart';

/// Dark RPG color palette — shared across the entire app.
abstract final class RpgColors {
  // ── Surfaces ──────────────────────────────────────────────────────────────

  /// Page scaffold background — near-black with a very slight cool cast.
  static const pageBg = Color(0xFF0C0C0F);

  /// Panel surface — one step lighter than the page background.
  static const panelBg = Color(0xFF131318);

  /// Alternate panel surface for subtle nested depth.
  static const panelBgAlt = Color(0xFF18181F);

  // ── Borders ───────────────────────────────────────────────────────────────

  /// Visible panel border — used for outer frame edges.
  static const border = Color(0xFF28282F);

  /// Subtle inner divider — used between rows.
  static const divider = Color(0xFF1E1E26);

  // ── Typography ────────────────────────────────────────────────────────────

  /// Primary text — warm off-white.
  static const textPrimary = Color(0xFFDEDAD2);

  /// Secondary text — medium grey for labels and descriptors.
  static const textSecondary = Color(0xFF8A8A92);

  /// Muted text — very dark, used for headers and faint labels.
  static const textMuted = Color(0xFF55555E);

  // ── Accent ────────────────────────────────────────────────────────────────

  /// Neutral warm accent — section header tints, "Lv." prefix.
  static const accent = Color(0xFFA09A88);

  // ── Progress bar ──────────────────────────────────────────────────────────

  /// Empty track behind progress bar.
  static const progressTrack = Color(0xFF1E1E2A);

  /// Filled segment for an active skill.
  static const progressFillActive = Color(0xFF86806E);

  /// Filled segment for a dormant skill — desaturated.
  static const progressFillDormant = Color(0xFF3E3E48);

  // ── Status labels ─────────────────────────────────────────────────────────

  /// "ACTIVE" label color — muted sage green.
  static const statusActive = Color(0xFF9BB49A);

  /// "DORMANT" label color — dark grey.
  static const statusDormant = Color(0xFF4A4A54);
}
