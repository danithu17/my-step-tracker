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

  // Dummy data for History Chart (Last 7 days)
  final List<double> _weeklySteps = [3500, 4200, 2000, 5100, 4800, 3000, 0];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
      if (_steps >= _goal) {
        // Goal reach unama badge notification ekak danna puluwan
      }
    });
  }

  void onStepCountError(Object error) {
    setState(() => _steps = 0);
  }

  void initPlatformState() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
    }
  }

  double get calories => _steps * 0.04; 
  double get distance => _steps * 0.0008; 

  @override
  Widget build(BuildContext context) {
    double progress = min(_steps / _goal, 1.0);

    return Scaffold(
      body: Container(
        // Messenger style smooth gradient
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
                const SizedBox(height: 30),
                Text('MY FITNESS TRACKER', 
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                
                const SizedBox(height: 40),
                
                // Main Circular Progress
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 15,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Column(
                        children: [
                          const Icon(Icons.directions_run, color: Colors.white70, size: 40),
                          Text('$_steps', style: GoogleFonts.poppins(fontSize: 55, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Steps Today', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Distance & Calories Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildInfoCard("Calories", "${calories.toStringAsFixed(1)} kcal", Icons.local_fire_department, Colors.orangeAccent),
                      const SizedBox(width: 15),
                      _buildInfoCard("Distance", "${distance.toStringAsFixed(2)} km", Icons.location_on, Colors.greenAccent),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // History Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 180,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: BarChart(
                      BarChartData(
                        barGroups: _weeklySteps.asMap().entries.map((e) => 
                          BarChartGroupData(x: e.key, barRods: [
                            BarChartRodData(toY: e.value, color: Colors.white, width: 10, borderRadius: BorderRadius.circular(5))
                          ])).toList(),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Badges Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(Icons.workspace_premium, "Starter", _steps > 500),
                      _buildBadge(Icons.bolt, "Active", _steps > 2500),
                      _buildBadge(Icons.emoji_events, "Pro", _steps >= _goal),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, bool isUnlocked) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isUnlocked ? Colors.amber : Colors.white10,
          radius: 25,
          child: Icon(icon, color: isUnlocked ? Colors.white : Colors.white24, size: 30),
        ),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.poppins(color: isUnlocked ? Colors.white : Colors.white24, fontSize: 12)),
      ],
    );
  }
}