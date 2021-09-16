import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final DateTime _kDefaultFirstSelectableDate = DateTime(1900);
final DateTime _kDefaultLastSelectableDate = DateTime(2100);

const double _kCupertinoDatePickerHeight = 216;

/// A [FormField] that contains a [DateTimeField].
///
/// This is a convenience widget that wraps a [DateTimeField] widget in a
/// [FormField].
///
/// A [Form] ancestor is not required. The [Form] simply makes it easier to
/// save, reset, or validate multiple fields at once. To use without a [Form],
/// pass a [GlobalKey] to the constructor and use [GlobalKey.currentState] to
/// save or reset the form field.
class DateTimeFormField extends FormField<DateTime> {
  DateTimeFormField({
    Key? key,
    FormFieldSetter<DateTime>? onSaved,
    FormFieldValidator<DateTime>? validator,
    DateTime? initialValue,
    AutovalidateMode? autovalidateMode,
    bool enabled = true,
    Function? onResetPressed,
    bool showClearButton = false,
    TextStyle? dateTextStyle,
    DateFormat? dateFormat,
    DateTime? firstDate,
    DateTime? lastDate,
    ValueChanged<DateTime>? onDateSelected,
    InputDecoration? decoration,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
    DateTimeFieldPickerMode mode = DateTimeFieldPickerMode.dateAndTime,
  }) : super(
          key: key,          
          initialValue: initialValue,
          onSaved: onSaved,
          validator: validator,
          autovalidateMode: autovalidateMode,
          enabled: enabled,
          builder: (FormFieldState<DateTime> field) {
            // Theme defaults are applied inside the _InputDropdown widget
            final InputDecoration _decorationWithThemeDefaults =
                decoration ?? const InputDecoration();

            final InputDecoration effectiveDecoration =
                _decorationWithThemeDefaults.copyWith(
                    errorText: field.errorText);

            void onChangedHandler(DateTime value) {
              if (onDateSelected != null) {
                onDateSelected(value);
              }
              field.didChange(value);
            }

            return DateTimeField(
              firstDate: firstDate,
              lastDate: lastDate,
              onResetPressed: onResetPressed,
              showClearButton: showClearButton,
              decoration: effectiveDecoration,
              initialDatePickerMode: initialDatePickerMode,
              dateFormat: dateFormat,
              onDateSelected: onChangedHandler,
              selectedDate: field.value,
              enabled: enabled,
              mode: mode,
              initialEntryMode: initialEntryMode,
              dateTextStyle: dateTextStyle,
            );
          },
        );

  @override
  _DateFormFieldState createState() => _DateFormFieldState();
}

class _DateFormFieldState extends FormFieldState<DateTime> {}

/// [DateTimeField]
///
/// Shows an [_InputDropdown] that'll trigger [DateTimeField._selectDate] whenever the user
/// clicks on it ! The date picker is **platform responsive** (ios date picker style for ios, ...)
class DateTimeField extends StatefulWidget {
  DateTimeField({
    Key? key,
    required this.onDateSelected,
    required this.selectedDate,
    this.initialDatePickerMode = DatePickerMode.day,
    this.decoration,
    this.enabled = true,
    this.mode = DateTimeFieldPickerMode.dateAndTime,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    this.dateTextStyle,
    this.showClearButton = false,
    this.onResetPressed,
    DateTime? firstDate,
    DateTime? lastDate,
    DateFormat? dateFormat,
  })  : dateFormat = dateFormat ?? getDateFormatFromDateFieldPickerMode(mode),
        firstDate = firstDate ?? _kDefaultFirstSelectableDate,
        lastDate = lastDate ?? _kDefaultLastSelectableDate,
        super(key: key);

  DateTimeField.time({
    Key? key,
    this.onDateSelected,
    this.selectedDate,
    this.decoration,
    this.enabled,
    this.dateTextStyle,
    this.showClearButton = false,
    this.onResetPressed,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    DateTime? firstDate,
    DateTime? lastDate,
  })  : initialDatePickerMode = null,
        mode = DateTimeFieldPickerMode.time,
        dateFormat = DateFormat.jm(),
        firstDate = firstDate ?? DateTime(2000),
        lastDate = lastDate ?? DateTime(2001),
        super(key: key);

  /// Callback for whenever the user selects a [DateTime]
  final ValueChanged<DateTime>? onDateSelected;

  /// The current selected date to display inside the field
  final DateTime? selectedDate;

  /// The first date that the user can select (default is 1900)
  final DateTime firstDate;

  /// The last date that the user can select (default is 2100)
  final DateTime lastDate;

  /// Let you choose the [DatePickerMode] for the date picker! (default is [DatePickerMode.day]
  final DatePickerMode? initialDatePickerMode;

  /// Custom [InputDecoration] for the [InputDecorator] widget
  final InputDecoration? decoration;

  /// How to display the [DateTime] for the user (default is [DateFormat.yMMMD])
  final DateFormat dateFormat;

  /// Whether the field is usable. If false the user won't be able to select any date
  final bool? enabled;

  /// Whether to ask the user to pick only the date, the time or both.
  final DateTimeFieldPickerMode mode;

  /// [TextStyle] of the selected date inside the field.
  final TextStyle? dateTextStyle;

  /// The initial entry mode for the material date picker dialog
  final DatePickerEntryMode initialEntryMode;

  /// shows a clear button (x) icon that when pressed, it resets the field value
  /// either this or inputDecoration suffix icon can be used. if both used then the clear icon will stack over it
  final bool showClearButton;

  /// applicable only if [showClearButton] is set to true
  final Function? onResetPressed;

  @override
  State<DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<DateTimeField> {
  DateTime? selectedDate;
  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
  }

  /// Shows a dialog asking the user to pick a date !
  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDateTime = selectedDate ?? DateTime.now();

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext builder) {
          return Container(
            height: _kCupertinoDatePickerHeight,
            child: CupertinoDatePicker(
              mode: _cupertinoModeFromPickerMode(widget.mode),
              onDateTimeChanged: widget.onDateSelected!,
              initialDateTime: initialDateTime,
              minimumDate: widget.firstDate,
              maximumDate: widget.lastDate,
            ),
          );
        },
      );
    } else {
      DateTime _selectedDateTime = initialDateTime;

      if ([DateTimeFieldPickerMode.dateAndTime, DateTimeFieldPickerMode.date]
          .contains(widget.mode)) {
        final DateTime? _selectedDate = await showDatePicker(
          context: context,
          initialDatePickerMode: widget.initialDatePickerMode!,
          initialDate: initialDateTime,
          initialEntryMode: widget.initialEntryMode,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
        );

        if (_selectedDate != null) {
          _selectedDateTime = _selectedDate;
        } else {
          return;
        }
      }

      if ([DateTimeFieldPickerMode.dateAndTime, DateTimeFieldPickerMode.time]
          .contains(widget.mode)) {
        final TimeOfDay? _selectedTime = await showTimePicker(
          initialTime: TimeOfDay.fromDateTime(initialDateTime),
          context: context,
        );

        if (_selectedTime != null) {
          _selectedDateTime = DateTime(
            _selectedDateTime.year,
            _selectedDateTime.month,
            _selectedDateTime.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );
        }
      }

      widget.onDateSelected!(_selectedDateTime);
      selectedDate = _selectedDateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? text;

    if (selectedDate != null) text = widget.dateFormat.format(selectedDate!);

    TextStyle? textStyle;

    if (text == null) {
      textStyle = widget.decoration!.hintStyle ??
          Theme.of(context).inputDecorationTheme.hintStyle;
    } else {
      textStyle = widget.dateTextStyle ?? widget.dateTextStyle;
    }

    final bool shouldDisplayLabelText = (text ?? widget.decoration!.hintText) != null;

    InputDecoration? effectiveDecoration = widget.decoration;

    if (!shouldDisplayLabelText) {
      effectiveDecoration = effectiveDecoration!.copyWith(labelText: '');
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _InputDropdown(
          text: text ??
              widget.decoration!.hintText ??
              widget.decoration!.labelText ??
              'Select date',
          textStyle: textStyle,
          decoration: effectiveDecoration,
          onPressed: widget.enabled! ? () => _selectDate(context) : null,
        ),
        Visibility(
          visible: widget.showClearButton,
          child: PositionedDirectional(
             end: 0,
             top: 5,
             child: IconButton(
               icon: const Icon(Icons.clear),
               splashRadius: 15,
               onPressed: (){
                 if(widget.onResetPressed!=null)     
                    widget.onResetPressed!();          
                 setState(() {
                   selectedDate = null;
                 });
            },)),
        )
      ],
    );
  }
}

/// Those values are used by the [DateTimeField] widget to determine whether to ask
/// the user for the time, the date or both.
enum DateTimeFieldPickerMode { time, date, dateAndTime }

/// Returns the [CupertinoDatePickerMode] corresponding to the selected
/// [DateTimeFieldPickerMode]. This exists to prevent redundancy in the [DateTimeField]
/// widget parameters.
CupertinoDatePickerMode _cupertinoModeFromPickerMode(
    DateTimeFieldPickerMode mode) {
  switch (mode) {
    case DateTimeFieldPickerMode.time:
      return CupertinoDatePickerMode.time;
    case DateTimeFieldPickerMode.date:
      return CupertinoDatePickerMode.date;
    default:
      return CupertinoDatePickerMode.dateAndTime;
  }
}

/// Returns the corresponding default [DateFormat] for the selected [DateTimeFieldPickerMode]
DateFormat getDateFormatFromDateFieldPickerMode(DateTimeFieldPickerMode mode) {
  switch (mode) {
    case DateTimeFieldPickerMode.time:
      return DateFormat.jm();
    case DateTimeFieldPickerMode.date:
      return DateFormat.yMMMMd();
    default:
      return DateFormat.yMd().add_jm();
  }
}

///
/// [_InputDropdown]
///
/// Shows a field with a dropdown arrow !
/// It does not show any popup menu, it'll just trigger onPressed whenever the
/// user does click on it !
class _InputDropdown extends StatelessWidget {
  const _InputDropdown({
    Key? key,
    required this.text,
    this.decoration,
    this.textStyle,
    this.onPressed,
  }) : super(key: key);

  /// The text that should be displayed inside the field
  final String text;

  /// Custom [InputDecoration] for the [InputDecorator] widget
  final InputDecoration? decoration;

  /// TextStyle for the field
  final TextStyle? textStyle;

  /// Callbacks triggered whenever the user presses on the field!
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final InputDecoration effectiveDecoration = decoration ??
        const InputDecoration(
          suffixIcon: Icon(Icons.arrow_drop_down),
        ).applyDefaults(Theme.of(context).inputDecorationTheme);

    return GestureDetector(
      onTap: onPressed,
      child: InputDecorator(
        decoration: effectiveDecoration,
        child: Text(text, style: textStyle),
      ),
    );
  }
}
