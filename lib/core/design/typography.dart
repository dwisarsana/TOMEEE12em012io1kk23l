import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class TomeTypography {
  // Headings (Serif)
  static final display1 = GoogleFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: TomeColors.inkBlack,
    letterSpacing: -0.5,
  );

  static final heading2 = GoogleFonts.fraunces(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: TomeColors.inkBlack,
    letterSpacing: -0.3,
  );

  // UI & Body (Sans)
  static final heading3 = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: TomeColors.inkBlack,
    letterSpacing: -0.2,
  );

  static final bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    color: TomeColors.inkBlack,
  );

  static final bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: TomeColors.inkBlack,
  );

  static final caption = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: TomeColors.slateGrey,
  );
}
