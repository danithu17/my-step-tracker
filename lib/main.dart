import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final int _goal = 5000;

  // Dummy data for History Chart (Sathiye dawas 7)
  final List<double> _weeklySteps = [3500, 4200, 2000, 5100, 4800, 3000, 0];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
      if (_steps >= _goal) _showBadge(); // Goal eka reach unama badge eka pennanna
    });
  }

  void onStepCountError(Object error) => setState(() => _steps = 0);

  void initPlatformState() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
    }
  }

  void _showBadge() {
    // Goal reach unama yana badge popup eka
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("🎉 Goal Reached! You earned a 'Walker' Badge!"),
        backgroundColor: Colors.purpleAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = min(_steps / _goal, 1.0);

    return Scaffold(
      body: Container(
        // Messenger style gradient theme
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('FITNESS TRACKER', 
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                
                const SizedBox(height: 30),
                
                // Circular Progress
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Column(
                        children: [
                          Text('$_steps', style: GoogleFonts.poppins(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Steps Today', style: GoogleFonts.poppins(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // History Chart Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BarChart(
                      BarChartData(
                        barGroups: _weeklySteps.asMap().entries.map((e) => 
                          BarChartGroupData(x: e.key, barRods: [
                            BarChartRodData(toY: e.value, color: Colors.white, width: 12, borderRadius: BorderRadius.circular(4))
                          ])).toList(),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                    ),
                  ),
                ),

                // Badges Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBadgeIcon(Icons.stars, "Starter", _steps > 100),
                      _buildBadgeIcon(Icons.bolt, "Active", _steps > 2500),
                      _buildBadgeIcon(Icons.emoji_events, "Pro", _steps >= _goal),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon, String label, bool unlocked) {
    return Column(
      children: [
        Icon(icon, size: 40, color: unlocked ? Colors.amber : Colors.white24),
        Text(label, style: GoogleFonts.poppins(color: unlocked ? Colors.white : Colors.white24, fontSize: 12)),
      ],
    );
  }
}