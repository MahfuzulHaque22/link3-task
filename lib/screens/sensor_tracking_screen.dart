import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorTrackingScreen extends StatefulWidget {
  @override
  _SensorTrackingScreenState createState() => _SensorTrackingScreenState();
}

class _SensorTrackingScreenState extends State<SensorTrackingScreen> {
  List<double> gyroXData = [];
  List<double> gyroYData = [];
  List<double> gyroZData = [];

  List<double> accelXData = [];
  List<double> accelYData = [];
  List<double> accelZData = [];

  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  bool _isAlertShown = false; // Flag to track alert state

  @override
  void initState() {
    super.initState();
    _initializeSensors();
  }

  void _initializeSensors() {
    // Listen to gyroscope events
    _gyroSubscription = SensorsPlatform.instance.gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        gyroXData.add(event.x);
        gyroYData.add(event.y);
        gyroZData.add(event.z);
        print("Gyro - X: ${event.x}, Y: ${event.y}, Z: ${event.z}");
        _checkMovement(event.x, event.y, event.z);
      });
    });

    // Listen to accelerometer events
    _accelSubscription = SensorsPlatform.instance.accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        accelXData.add(event.x);
        accelYData.add(event.y);
        accelZData.add(event.z);
        print("Accel - X: ${event.x}, Y: ${event.y}, Z: ${event.z}");
        _checkMovement(
          gyroXData.isNotEmpty ? gyroXData.last : 0,
          gyroYData.isNotEmpty ? gyroYData.last : 0,
          gyroZData.isNotEmpty ? gyroZData.last : 0,
        );
      });
    });
  }

  void _checkMovement(double gyroX, double gyroY, double gyroZ) {
    // Check if there is high movement
    if ((gyroX.abs() > 5 || gyroY.abs() > 5 || gyroZ.abs() > 5) &&
        (accelXData.isNotEmpty && (accelXData.last.abs() > 5 || accelYData.last.abs() > 5 || accelZData.last.abs() > 5))) {
      if (!_isAlertShown) {
        _showAlert();
      }
    } else {
      _isAlertShown = false;
    }
  }

  void _showAlert() {
    _isAlertShown = true; // Set the flag to true
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("ALERT"),
          content: const Text("High movement detected on multiple axes!"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _isAlertShown = false; // Reset the flag when the alert is dismissed
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _accelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sensor Tracking"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Gyroscope Data Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Gyroscope Sensor Data",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                          minX: 0,
                          maxX: gyroXData.length.toDouble(),
                          minY: -4,
                          maxY: 4,
                          lineBarsData: [
                            // Line for X-axis
                            LineChartBarData(
                              spots: List.generate(
                                gyroXData.length,
                                    (index) => FlSpot(index.toDouble(), gyroXData[index]),
                              ),
                              isCurved: true,
                              color: Colors.blue,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                            // Line for Y-axis
                            LineChartBarData(
                              spots: List.generate(
                                gyroYData.length,
                                    (index) => FlSpot(index.toDouble(), gyroYData[index]),
                              ),
                              isCurved: true,
                              color: Colors.green,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                            // Line for Z-axis
                            LineChartBarData(
                              spots: List.generate(
                                gyroZData.length,
                                    (index) => FlSpot(index.toDouble(), gyroZData[index]),
                              ),
                              isCurved: true,
                              color: Colors.red,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Accelerometer Data Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text(
                      "Accelerometer Sensor Data",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                titlesData: const FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                ),
                                gridData: const FlGridData(show: true),
                                borderData: FlBorderData(show: true),
                                minX: 0,
                                maxX: accelXData.length.toDouble(),
                                minY: -20,
                                maxY: 20,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(
                                      accelXData.length,
                                          (index) => FlSpot(index.toDouble(), accelXData[index]),
                                    ),
                                    isCurved: true,
                                    color: Colors.red,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                titlesData: const FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                ),
                                gridData: const FlGridData(show: true),
                                borderData: FlBorderData(show: true),
                                minX: 0,
                                maxX: accelYData.length.toDouble(),
                                minY: -20,
                                maxY: 20,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(
                                      accelYData.length,
                                          (index) => FlSpot(index.toDouble(), accelYData[index]),
                                    ),
                                    isCurved: true,
                                    color: Colors.green,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                titlesData: const FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                ),
                                gridData: const FlGridData(show: true),
                                borderData: FlBorderData(show: true),
                                minX: 0,
                                maxX: accelZData.length.toDouble(),
                                minY: -20,
                                maxY: 20,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(
                                      accelZData.length,
                                          (index) => FlSpot(index.toDouble(), accelZData[index]),
                                    ),
                                    isCurved: true,
                                    color: Colors.blue,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
