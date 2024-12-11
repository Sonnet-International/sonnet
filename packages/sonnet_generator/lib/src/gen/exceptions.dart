class SonnetException implements Exception {
  SonnetException(this.message);

  final String? message;

  @override
  String toString() {
    return '$SonnetException: $message';
  }
}
