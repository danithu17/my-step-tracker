import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MaterialApp(home: StepTracker()));

class StepTracker extends StatefulWidget {
  const StepTracker({super.key});
  @override
    State<StepTracker> createState() => _StepTrackerState();
}

class _StepTrackerState extends State<StepTracker> {
  late Stream<StepCount> _stepCountStream;
  String _steps = '0';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onStepCountError(Object error) {
    setState(() {
      _steps = 'Sensor not found';
    });
  }

  void initPlatformState() async {
    // Permission illana thuna
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Step Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, size: 100, color: Colors.blue),
            const Text('Today Steps:', style: TextStyle(fontSize: 30)),
            Text(_steps, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}