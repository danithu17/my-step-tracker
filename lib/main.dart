import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StepTracker(),
    ));

class StepTracker extends StatefulWidget {
  const StepTracker({super.key});

  @override
  State<StepTracker> createState() => _StepTrackerState();
}

class _StepTrackerState extends State<StepTracker> {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
  int _goal = 5000;
  late ConfettiController _confettiController;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _initNotifications();
    initPlatformState();
  }

  void _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    
    await _notifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  void _sendNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'goal_channel', 
      'Goals', 
      importance: Importance.max, 
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails, 
      iOS: DarwinNotificationDetails()
    );
    
    await _notifications.show(
      id: 0, 
      title: 'Goal Reached! 🎉', 
      body: 'Congratulations! You hit your $_goal steps goal!', 
      notificationDetails: notificationDetails
    );
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
      if (_steps >= _goal && !_confettiController.state.toString().contains('playing')) {
        _confettiController.play();
        _sendNotification();
      }
    });
  }

  void onStepCountError(Object error) => setState(() => _steps = 0);

  void initPlatformState() async {
    if (await Permission.activityRecognition.request().isGranted && 
        await Permission.notification.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = min(_steps / _goal, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildProgressCircle(progress),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          _buildInteractiveCard("Calories", (_steps * 0.04).toStringAsFixed(1), Icons.fireplace, Colors.orange),
                          const SizedBox(width: 15),
                          _buildInteractiveCard("Distance", (_steps * 0.0008).toStringAsFixed(2), Icons.location_on, Colors.greenAccent),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildHistoryChart(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController, 
              blastDirectionality: BlastDirectionality.explosive
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Activity Status', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
          Text('March 2026', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
        const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
      ],
    );
  }

  Widget _buildProgressCircle(double progress) {
    return GestureDetector(
      onTap: () => _showGoalDialog(),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 15,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$_steps', style: GoogleFonts.poppins(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Steps of $_goal', style: GoogleFonts.poppins(color: Colors.white60)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(val, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildHistoryChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(24)
      ),
      child: BarChart(BarChartData(
        barGroups: [1, 2, 3, 4, 5, 6, 7].map((i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: Random().nextInt(5000).toDouble(), color: Colors.cyanAccent, width: 12, borderRadius: BorderRadius.circular(6))])).toList(),
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: _goal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: Text("Set Daily Goal", style: GoogleFonts.poppins(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            hintText: "Enter steps",
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _goal = int.tryParse(controller.text) ?? _goal);
              Navigator.pop(context);
            }, 
            child: const Text("SAVE", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
}

