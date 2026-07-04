import 'package:bosque_flutter/data/models/feriado_model.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

Future<List<DateTime?>?> showCustomRangePickerDialog({
  required BuildContext context,
  required DateTime initialStartDate,
  required DateTime initialEndDate,
  required List<FeriadoModel> feriados,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Convertimos la lista de feriados a un Set de fechas (sin horas) para búsqueda rápida
  final Set<String> feriadosFechas =
      feriados
          .map((f) => "${f.fecha.year}-${f.fecha.month}-${f.fecha.day}")
          .toSet();

  String? getMotivoFeriado(DateTime date) {
    try {
      return feriados
          .firstWhere(
            (f) =>
                f.fecha.year == date.year &&
                f.fecha.month == date.month &&
                f.fecha.day == date.day,
          )
          .motivo;
    } catch (e) {
      return null;
    }
  }

  final config = CalendarDatePicker2WithActionButtonsConfig(
    calendarType: CalendarDatePicker2Type.range,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    currentDate: DateTime.now(),
    selectedDayHighlightColor: Theme.of(context).colorScheme.primary,
    selectedRangeHighlightColor: Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.2),
    selectedRangeDayTextStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    ),
    okButtonTextStyle: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
    cancelButtonTextStyle: TextStyle(
      color: isDark ? Colors.white70 : Colors.black54,
    ),
    controlsTextStyle: TextStyle(
      color: isDark ? Colors.white : Colors.black87,
      fontWeight: FontWeight.bold,
    ),
    weekdayLabelTextStyle: TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
      fontWeight: FontWeight.bold,
    ),
    dayTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
    dayBuilder: ({
      required date,
      textStyle,
      decoration,
      isSelected,
      isDisabled,
      isToday,
    }) {
      final isSunday = date.weekday == DateTime.sunday;
      final isSaturday = date.weekday == DateTime.saturday;
      final dateKey = "${date.year}-${date.month}-${date.day}";
      final isFeriado = feriadosFechas.contains(dateKey);

      Widget? dayWidget;

      // Determine text style with overrides for weekends and holidays
      TextStyle? finalTextStyle = textStyle;
      if (isSelected != true) {
        if (isFeriado || isSunday) {
          finalTextStyle = (textStyle ?? const TextStyle()).copyWith(
            color: Colors.red,
            fontWeight: isFeriado ? FontWeight.bold : null,
          );
        } else if (isSaturday) {
          finalTextStyle = (textStyle ?? const TextStyle()).copyWith(
            color: Colors.orange,
          );
        }
      }

      if (isFeriado) {
        dayWidget = Tooltip(
          message: getMotivoFeriado(date) ?? 'Feriado',
          child: Container(
            decoration:
                isSelected == true
                    ? decoration
                    : BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.2),
                      shape: BoxShape.circle,
                    ),
            child: Center(
              child: Text(date.day.toString(), style: finalTextStyle),
            ),
          ),
        );
      } else {
        // Default rendering for days, applying package decoration (including range highlights)
        dayWidget = Container(
          decoration: decoration,
          child: Center(
            child: Text(date.day.toString(), style: finalTextStyle),
          ),
        );
      }
      return dayWidget;
    },
  );

  final dialogWidth = ResponsiveUtilsBosque.getResponsiveValue<double>(
    context: context,
    defaultValue: 325,
    mobile: 310,
    desktop: 380,
  );
  final dialogHeight = ResponsiveUtilsBosque.getResponsiveValue<double>(
    context: context,
    defaultValue: 400,
    mobile: 380,
    desktop: 440,
  );

  return showCalendarDatePicker2Dialog(
    context: context,
    config: config,
    dialogSize: Size(dialogWidth, dialogHeight),
    value: [initialStartDate, initialEndDate],
    borderRadius: BorderRadius.circular(15),
  );
}
