class AppError implements Exception {
  AppError(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() {
    if (code == null || code!.isEmpty) {
      return message;
    }
    return '$code: $message';
  }
}
