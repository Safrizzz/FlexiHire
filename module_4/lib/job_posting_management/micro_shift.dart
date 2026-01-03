class MicroShift {
  final DateTime start;
  final DateTime end;

  final int capacity; // default 1 staff per shift
  int filled;         // how many already hired

  MicroShift({
    required this.start,
    required this.end,
    this.capacity = 1,
    this.filled = 0,
  });

  bool get isFull => filled >= capacity;

  String toDisplay() {
    final date =
        '${start.day.toString().padLeft(2, '0')} ${_m(start.month)} ${start.year}';
    final s =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$date • $s–$e';
  }

  static String _m(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
