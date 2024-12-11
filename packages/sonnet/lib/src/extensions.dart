extension SonnetStringExtension on String? {
  String? get presence {
    if (this == null) return null;

    if (this!.trim().isEmpty) return null;

    return this;
  }
}
