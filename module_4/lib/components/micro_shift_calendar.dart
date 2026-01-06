import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A beautiful modern calendar widget for micro-shift selection
/// Used by employers to select dates and by students to view/select available dates
class MicroShiftCalendar extends StatefulWidget {
  /// Dates that are available for selection (employer's selected dates)
  final Set<DateTime> availableDates;

  /// Currently selected dates
  final Set<DateTime> selectedDates;

  /// Callback when selection changes
  final ValueChanged<Set<DateTime>>? onSelectionChanged;

  /// Whether multiple dates can be selected
  final bool multiSelect;

  /// Whether the calendar is in view-only mode
  final bool viewOnly;

  /// Whether to show only available dates as selectable (for student mode)
  final bool restrictToAvailable;

  /// The color for available dates border (student view)
  final Color availableBorderColor;

  /// The color for selected dates
  final Color selectedColor;

  const MicroShiftCalendar({
    super.key,
    this.availableDates = const {},
    this.selectedDates = const {},
    this.onSelectionChanged,
    this.multiSelect = true,
    this.viewOnly = false,
    this.restrictToAvailable = false,
    this.availableBorderColor = const Color(0xFF6366F1),
    this.selectedColor = const Color(0xFF0F1E3C),
  });

  @override
  State<MicroShiftCalendar> createState() => _MicroShiftCalendarState();
}

class _MicroShiftCalendarState extends State<MicroShiftCalendar>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth;
  late Set<DateTime> _selectedDates;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDates = Set.from(widget.selectedDates.map(_normalizeDate));

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isDateAvailable(DateTime date) {
    final normalized = _normalizeDate(date);
    return widget.availableDates.any((d) => _normalizeDate(d) == normalized);
  }

  bool _isDateSelected(DateTime date) {
    final normalized = _normalizeDate(date);
    return _selectedDates.any((d) => _normalizeDate(d) == normalized);
  }

  void _toggleDate(DateTime date) {
    if (widget.viewOnly) return;

    final normalized = _normalizeDate(date);

    // If restricted to available dates, check if date is available
    if (widget.restrictToAvailable && !_isDateAvailable(date)) {
      return;
    }

    // Don't allow past dates
    if (normalized.isBefore(_normalizeDate(DateTime.now()))) {
      return;
    }

    setState(() {
      if (widget.multiSelect) {
        if (_selectedDates.any((d) => _normalizeDate(d) == normalized)) {
          _selectedDates.removeWhere((d) => _normalizeDate(d) == normalized);
        } else {
          _selectedDates.add(normalized);
        }
      } else {
        _selectedDates.clear();
        _selectedDates.add(normalized);
      }
    });

    widget.onSelectionChanged?.call(Set.from(_selectedDates));
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _animController.reset();
    _animController.forward();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildWeekDays(),
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCalendarGrid(),
            ),
            if (_selectedDates.isNotEmpty) _buildSelectionSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.selectedColor,
            widget.selectedColor.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(Icons.chevron_left, _previousMonth),
          Column(
            children: [
              Text(
                DateFormat('MMMM').format(_currentMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('yyyy').format(_currentMonth),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _buildNavButton(Icons.chevron_right, _nextMonth),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildWeekDays() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final isWeekend = day == 'Sun' || day == 'Sat';
          return SizedBox(
            width: 40,
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isWeekend ? Colors.red.shade400 : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final startWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final cells = <Widget>[];

    // Empty cells for days before the first day of month
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox(width: 40, height: 40));
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      cells.add(_buildDayCell(date));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(spacing: 8, runSpacing: 8, children: cells),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isToday = _normalizeDate(date) == _normalizeDate(DateTime.now());
    final isSelected = _isDateSelected(date);
    final isAvailable = _isDateAvailable(date);
    final isPast = date.isBefore(_normalizeDate(DateTime.now()));
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    // Determine if cell is selectable
    bool isSelectable = !isPast && !widget.viewOnly;
    if (widget.restrictToAvailable) {
      isSelectable = isSelectable && isAvailable;
    }

    return GestureDetector(
      onTap: isSelectable ? () => _toggleDate(date) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.selectedColor,
                    widget.selectedColor.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected
              ? null
              : isToday
              ? widget.selectedColor.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: isAvailable && !isSelected
              ? Border.all(color: widget.availableBorderColor, width: 2.5)
              : isToday && !isSelected
              ? Border.all(
                  color: widget.selectedColor.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.selectedColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : isAvailable
              ? [
                  BoxShadow(
                    color: widget.availableBorderColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: isPast
                  ? Colors.grey.shade300
                  : isSelected
                  ? Colors.white
                  : isWeekend
                  ? Colors.red.shade400
                  : Colors.grey.shade800,
              fontSize: 14,
              fontWeight: isSelected || isToday || isAvailable
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSummary() {
    final sortedDates = _selectedDates.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.selectedColor.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.event_available,
                  color: widget.selectedColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_selectedDates.length} ${_selectedDates.length == 1 ? 'date' : 'dates'} selected',
                style: TextStyle(
                  color: widget.selectedColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                sortedDates.take(6).map((date) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.selectedColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      DateFormat('d MMM').format(date),
                      style: TextStyle(
                        color: widget.selectedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList()..addAll(
                  sortedDates.length > 6
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.selectedColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${sortedDates.length - 6} more',
                              style: TextStyle(
                                color: widget.selectedColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ]
                      : [],
                ),
          ),
        ],
      ),
    );
  }
}

/// A widget showing time selection for micro-shifts
class MicroShiftTimeSelector extends StatelessWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final ValueChanged<TimeOfDay>? onStartTimeChanged;
  final ValueChanged<TimeOfDay>? onEndTimeChanged;
  final bool enabled;

  const MicroShiftTimeSelector({
    super.key,
    this.startTime,
    this.endTime,
    this.onStartTimeChanged,
    this.onEndTimeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Working Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set the same time for all selected dates',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TimePickerButton(
                  label: 'Start Time',
                  time: startTime,
                  onTap: enabled
                      ? () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime:
                                startTime ??
                                const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (picked != null) {
                            onStartTimeChanged?.call(picked);
                          }
                        }
                      : null,
                  icon: Icons.login,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimePickerButton(
                  label: 'End Time',
                  time: endTime,
                  onTap: enabled
                      ? () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime:
                                endTime ?? const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (picked != null) {
                            onEndTimeChanged?.call(picked);
                          }
                        }
                      : null,
                  icon: Icons.logout,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback? onTap;
  final IconData icon;
  final Color color;

  const _TimePickerButton({
    required this.label,
    this.time,
    this.onTap,
    required this.icon,
    required this.color,
  });

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
