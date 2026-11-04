import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// SETTINGS: the only things you need to edit to personalize the app
// ---------------------------------------------------------------------------

/// The moment your relationship started (year, month, day, hour, minute).
final DateTime kStartDate = DateTime(2026, 10, 24, 18, 0);

/// Small title shown above the counter.
const String kTitle = 'Ensemble depuis';

/// Message shown at the bottom of the screen.
const String kFinalMessage = 'Je t\'aime';

// ---------------------------------------------------------------------------
// ANNIVERSARY HELPERS
// ---------------------------------------------------------------------------

/// Strips the time of day and uses UTC.
/// Using UTC avoids daylight-saving bugs: in local time, a day can last 23h
/// or 25h, which makes `difference().inDays` off by one around DST changes.
DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Builds a date but never overflows into the next month.
/// Example: if you started on the 31st, February has no 31st, so we use
/// the last day of February instead (28 or 29).
DateTime _safeDate(int year, int month, int day) {
  // Day 0 of the *next* month = last day of this month.
  final lastDayOfMonth = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, min(day, lastDayOfMonth));
}

/// Next monthly anniversary (same day of the month as the start date).
/// If today is the anniversary, it returns today (0 days left).
DateTime nextMonthlyAnniversary(DateTime now) {
  final today = _dateOnly(now);

  // Try this month first.
  var candidate = _safeDate(today.year, today.month, kStartDate.day);

  // Already passed this month? Use next month (Dec -> Jan rolls the year).
  if (candidate.isBefore(today)) {
    final year = today.month == 12 ? today.year + 1 : today.year;
    final month = today.month == 12 ? 1 : today.month + 1;
    candidate = _safeDate(year, month, kStartDate.day);
  }
  return candidate;
}

/// Next yearly anniversary (same month and day as the start date).
DateTime nextYearlyAnniversary(DateTime now) {
  final today = _dateOnly(now);

  // Try this year first.
  var candidate = _safeDate(today.year, kStartDate.month, kStartDate.day);

  // Already passed this year? Use next year.
  if (candidate.isBefore(today)) {
    candidate = _safeDate(today.year + 1, kStartDate.month, kStartDate.day);
  }
  return candidate;
}

/// Number of full days between today and a future date.
int daysUntil(DateTime now, DateTime target) =>
    target.difference(_dateOnly(now)).inDays;

/// Turns a day count into a friendly sentence.
String _countdownText(String label, int days) {
  if (days == 0) return '$label: today! 🎉';
  if (days == 1) return '$label: tomorrow!';
  return '$label in $days days';
}

// ---------------------------------------------------------------------------
// APP ENTRY POINT
// ---------------------------------------------------------------------------

void main() => runApp(const LoveCounterApp());

/// Root widget: sets up the theme and shows the counter screen.
class LoveCounterApp extends StatelessWidget {
  const LoveCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // hides the red "DEBUG" banner
      title: 'Love Counter',
      theme: ThemeData(
        colorSchemeSeed: Colors.pink, // generates a pink color palette
        useMaterial3: true,
      ),
      home: const CounterScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// MAIN SCREEN
// ---------------------------------------------------------------------------

/// A StatefulWidget because the screen changes over time (the seconds tick).
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late Timer _timer; // fires every second
  DateTime _now = DateTime.now(); // the "current time" used by the UI

  @override
  void initState() {
    super.initState();
    // Every second, update _now. setState() tells Flutter to rebuild the UI.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    // Always stop the timer when the screen is removed, or it keeps running.
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Time elapsed since the start date, split into days/hours/minutes/seconds.
    // The "% 24" and "% 60" keep only the remainder (e.g. 25h -> 1h).
    final diff = _now.difference(kStartDate);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    // Countdowns to the next anniversaries.
    final monthlyDays = daysUntil(_now, nextMonthlyAnniversary(_now));
    final yearlyDays = daysUntil(_now, nextYearlyAnniversary(_now));

    return Scaffold(
      body: Container(
        // background, top to bottom.
        color: const Color.fromARGB(255, 188, 183, 183),
        // Stack = layers on top of each other: hearts behind, content in front.
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingHearts()), // back layer
            SafeArea(
              // keeps content away from the notch / status bar
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // column only as tall as needed
                  children: [
                    const Text(
                      kTitle,
                      style: TextStyle(
                        fontSize: 22,
                        color: Color(0xFF8A1C4A),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // The four counter boxes.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TimeBox(value: days, label: 'days'),
                        _TimeBox(value: hours, label: 'hours'),
                        _TimeBox(value: minutes, label: 'min'),
                        _TimeBox(value: seconds, label: 'sec'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Next monthly and yearly anniversaries.
                    Text(
                      _countdownText('Prochain monthsary', monthlyDays),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8A1C4A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _countdownText('Prochain anniversary', yearlyDays),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8A1C4A),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      kFinalMessage,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COUNTER BOX
// ---------------------------------------------------------------------------

/// One white rounded box showing a number and its label (e.g. "08 days").
/// StatelessWidget because it never changes by itself: the parent gives it
/// a new value on every rebuild.
class _TimeBox extends StatelessWidget {
  final int value;
  final String label;
  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75), // slightly transparent white
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            // padLeft adds a leading zero: 5 -> "05"
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD81B60),
            ),
          ),
          Text(label, style: const TextStyle(color: Color(0xFF8A1C4A))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FLOATING HEARTS BACKGROUND
// ---------------------------------------------------------------------------

/// Hearts that slowly float from the bottom to the top of the screen.
class FloatingHearts extends StatefulWidget {
  const FloatingHearts({super.key});

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

/// The random "personality" of a single heart. Created once, so each heart
/// keeps the same position, size and speed for the whole session.
class _Heart {
  final double x = Random().nextDouble(); // horizontal position (0 to 1)
  final double size = 14 + Random().nextDouble() * 22; // 14 to 36 px
  final double speed = 0.4 + Random().nextDouble() * 0.8; // rise speed
  final double phase = Random().nextDouble(); // starting height offset
  final double opacity = 0.25 + Random().nextDouble() * 0.45; // transparency
}

// SingleTickerProviderStateMixin is required to drive an AnimationController.
class _FloatingHeartsState extends State<FloatingHearts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Heart> _hearts = List.generate(18, (_) => _Heart());

  @override
  void initState() {
    super.initState();
    // A value going 0 -> 1 every 12 seconds, looping forever.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose(); // free the animation resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // hearts never block taps on the content
      child: AnimatedBuilder(
        animation: _controller, // rebuild on every animation frame
        builder: (context, _) {
          return LayoutBuilder(
            // gives us the available width/height (box.maxWidth/maxHeight)
            builder: (context, box) {
              return Stack(
                children: _hearts.map((h) {
                  // progress goes 0 -> 1 (bottom -> top). "% 1.0" wraps it
                  // back to 0 so the heart restarts at the bottom.
                  final progress =
                      (_controller.value * h.speed + h.phase) % 1.0;
                  return Positioned(
                    left: h.x * (box.maxWidth - h.size),
                    top: box.maxHeight * (1 - progress) - h.size,
                    child: Opacity(
                      opacity: h.opacity,
                      child: Icon(
                        Icons.favorite,
                        size: h.size,
                        color: Colors.pink,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}