import 'dart:math';

import 'package:flutter/material.dart';

class ProgressBarController {
  int currentBar = 0;

  Duration Function(int)? _nextListener;

  Duration next() {
    var duration = _nextListener!(currentBar);

    currentBar++;
    return duration;
  }

  void addNextListener(Duration Function(int) listener) {
    _nextListener = listener;
  }
}

class ProgressBar extends StatefulWidget {
  final ProgressBarController controller;

  const ProgressBar({Key? key, required this.controller}) : super(key: key);

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with TickerProviderStateMixin {
  final int divisions = 16;
  final List<int> dividers = [1, 2, 4, 8];
  final List<int> durations = [1, 1, 2, 4, 8];

  late AnimationController controller;

  double _progress = 0.0;

  @override
  void initState() {
    controller = AnimationController(vsync: this);

    widget.controller.addNextListener(next);

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  Duration next(int bar) {
    if (bar > dividers.length) return Duration.zero;

    controller.reset();

    var duration = Duration(seconds: durations[bar]);
    controller.duration = duration;
    var animation = Tween<double>(
            begin: (widget.controller.currentBar == 0 ? 0 : dividers[bar - 1])
                    .toDouble() /
                divisions,
            end: (widget.controller.currentBar == dividers.length
                        ? divisions
                        : dividers[bar])
                    .toDouble() /
                divisions)
        .animate(controller);

    animation.addListener(() {
      setState(() {
        _progress = animation.value;
      });
    });

    controller.forward();

    return duration;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            width: constraints.maxWidth,
            height: 35,
            child: CustomPaint(
              painter: ProgressBarPainter(_progress, divisions, dividers),
            ),
          ),
        ));
  }
}

class ProgressBarPainter extends CustomPainter {
  int divisions;
  List<int> dividers;

  double percentage = 0.0;

  ProgressBarPainter(this.percentage, this.divisions, this.dividers);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF9A879D);

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * percentage, size.height), paint);

    drawDash(canvas, const Offset(0, 0), Offset(size.width, 0));
    drawDash(canvas, Offset(0, size.height), const Offset(0, 0));
    drawDash(canvas, Offset(size.width, size.height), Offset(0, size.height));
    drawDash(canvas, Offset(size.width, 0), Offset(size.width, size.height));

    var x = 0.0;
    var previous = 0.0;

    for (var i = 0.0; i <= divisions; i++) {
      if (dividers.contains(i)) {
        drawDash(canvas, Offset(x, 0), Offset(x, size.height));
        previous = x;
      }

      x += size.width / divisions;
    }
  }

  void drawDash(Canvas canvas, Offset point1, Offset point2) {
    var paint = Paint()
      ..color = const Color(0xFF4E6E58)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    var maxDistance = (point1 - point2).distance;
    var distance = 0.0;

    while (distance < maxDistance) {
      var position = Offset.lerp(point1, point2, distance / maxDistance)!;
      distance += 10;
      if (distance > maxDistance) {
        distance = maxDistance;
      }

      var nextPosition = Offset.lerp(point1, point2, distance / maxDistance)!;
      distance += 3;

      canvas.drawLine(position, nextPosition, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
