library material_clock;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import './global_ticker.dart' as ticker;

class Clock extends StatefulWidget {
  /// Size of your widget. By default it is `double.infinty`.
  final double size;

  /// Aligment of widget. Could be useful if parameter `size` is setted.
  final AlignmentGeometry alignment;

  /// Theme of clocks. By default it is set to `Brightness.light`
  /// for supporting dark and light modes of iOS and Android.
  ///
  /// Supports only `Brightness.light` and `Brightness.dark` constants.
  final Brightness theme;

  /// Background style of widget. It can be only `PaintingStyle.fill` or `PanintingStyle.stroke`
  final PaintingStyle backgroundStyle;

  /// Color of your second hand. By default it is `Colors.redAccent`
  final Color secondHandColor;

  /// If true, than clocks will update every second. If false, than hands position will be fixed.
  final bool live;

  /// Which time you want to render. By default it is current time.
  ///
  /// Note, that date is ignored, so you can set only specific time.
  final DateTime time;
  
  /// Optional callback upon each tick, to align external actions with
  /// when the second hand moves
  void Function()? onTick;

  // Timezone offset of this clock. For example, Duration(hour:-3, minute:30) is equal to "-3:30" zone
  final Duration timezoneOffset;

  /// Widget `Clock` implements simple and awesome material clock for your app!
  Clock({
    required this.time,
    this.size = double.infinity,
    this.secondHandColor = Colors.redAccent,
    this.live = false,
    this.theme = Brightness.light,
    this.backgroundStyle = PaintingStyle.fill,
    this.alignment = Alignment.center,
    this.timezoneOffset = Duration.zero,
  });

  @override
  _ClockState createState() => _ClockState(
        time: this.timezoneOffset != Duration.zero
            ? this.time.toUtc().add(this.timezoneOffset)
            : this.time,
      );
}

class _ClockState extends State<Clock> {
  DateTime time;

  _ClockState({
    required this.time
  });

  @override
  void initState() {
    ticker.setupUpdating(update);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: Container(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _ClockPainter(
            time: time,
            theme: widget.theme,
            backgroundStyle: widget.backgroundStyle,
            secondLineColor: widget.secondHandColor,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    ticker.cancelUpdating(update);
  }

  update(Timer timer) {
    widget.onTick!();
    setState(() {
      time = (widget.timezoneOffset != Duration.zero)
          ? DateTime.now().toUtc()
          : DateTime.now();
      time = time.add(widget.timezoneOffset);
    });
  }
}

class _ClockPainter extends CustomPainter {
  static const hourRadius = 40.0;
  static const minuteRadius = 70.0;
  static const secondRadius = 80.0;
  static const hourStrokeWidth = 5.0;
  static const secondStrokeWidth = 3.0;
  static const backgroundStrokeWidth = 7.0;

  final DateTime time;
  final PaintingStyle backgroundStyle;
  final Brightness theme;
  final Color secondLineColor;

  const _ClockPainter({
    required this.time,
    this.theme = Brightness.light,
    this.backgroundStyle = PaintingStyle.fill,
    this.secondLineColor = Colors.redAccent,
  }) : super();

  @override
  void paint(Canvas canvas, Size size) {
    ClockColors clockColors = ClockColors(this.theme, this.backgroundStyle);
    final radius = size.shortestSide / 2;
    final offset = Offset(
      size.width / 2,
      size.height / 2,
    );
    final scalefactor = radius / 100;
    final hourRadian = remap(
            time.hour + normalize(time.minute, 0, 60), 0, 24, 0, math.pi * 4) -
        (math.pi / 2);
    final minuteRaidan = remap(time.minute + normalize(time.second, 0, 60), 0,
            60, 0, math.pi * 2) -
        (math.pi / 2);
    final secondRaidan =
        remap(time.second, 0, 60, 0, math.pi * 2) - (math.pi / 2);

    // background
    Paint background = Paint()
      ..color = clockColors.background
      ..strokeWidth = backgroundStrokeWidth * scalefactor
      ..style = this.backgroundStyle;
    var circleRadius = radius;
    if (this.backgroundStyle == PaintingStyle.stroke) {
      circleRadius = radius - backgroundStrokeWidth / 2 * scalefactor;
    }
    canvas.drawCircle(offset, circleRadius, background);

    Paint bigLines = Paint()
      ..color = clockColors.line
      ..strokeCap = StrokeCap.round
      ..strokeWidth = hourStrokeWidth * scalefactor
      ..style = PaintingStyle.stroke;

    // hour
    Path hourPath = Path()
      ..moveTo(
        offset.dx - math.cos(hourRadian) * hourRadius * scalefactor * 0.2,
        offset.dy - math.sin(hourRadian) * hourRadius * scalefactor * 0.2,
      )
      ..lineTo(
        offset.dx + math.cos(hourRadian) * hourRadius * scalefactor,
        offset.dy + math.sin(hourRadian) * hourRadius * scalefactor,
      );
    canvas.drawPath(
      hourPath,
      bigLines,
    );

    //minute
    Path minutePath = Path()
      ..moveTo(
        offset.dx - math.cos(minuteRaidan) * minuteRadius * scalefactor * 0.2,
        offset.dy - math.sin(minuteRaidan) * minuteRadius * scalefactor * 0.2,
      )
      ..lineTo(
        offset.dx + math.cos(minuteRaidan) * minuteRadius * scalefactor,
        offset.dy + math.sin(minuteRaidan) * minuteRadius * scalefactor,
      );
    canvas.drawPath(
      minutePath,
      bigLines,
    );

    //second
    Paint secondPaint = Paint()
      ..color = secondLineColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = secondStrokeWidth * scalefactor
      ..style = PaintingStyle.stroke;

    Path secondPath = Path()
      ..moveTo(
        offset.dx - math.cos(secondRaidan) * secondRadius * scalefactor * 0.2,
        offset.dy - math.sin(secondRaidan) * secondRadius * scalefactor * 0.2,
      )
      ..lineTo(
        offset.dx + math.cos(secondRaidan) * secondRadius * scalefactor,
        offset.dy + math.sin(secondRaidan) * secondRadius * scalefactor,
      );
    canvas.drawPath(
      secondPath,
      secondPaint,
    );
  }

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) {
    return oldDelegate.time.isBefore(this.time);
  }
}

double remap(n, start1, stop1, start2, stop2) {
  return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2;
}

double normalize(n, start, stop) {
  return remap(n, start, stop, 0, 1);
}

class ClockColors {
  late Brightness _brightness;
  late PaintingStyle _paintingStyle;

  ClockColors(this._brightness, this._paintingStyle);

  Color get line {
    return (this._brightness == Brightness.light) ? Colors.black : Colors.white;
  }

  Color get background {
    if (this._brightness == Brightness.light)
      return (this._paintingStyle == PaintingStyle.fill)
          ? Colors.white
          : Colors.black;
    else
      return (this._paintingStyle == PaintingStyle.fill)
          ? Colors.black
          : Colors.white;
  }
}
