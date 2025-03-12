import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CpuMonitorCard extends StatefulWidget {
  final String deviceId;

  const CpuMonitorCard({Key? key, required this.deviceId}) : super(key: key);

  @override
  _CpuMonitorCardState createState() => _CpuMonitorCardState();
}

class _CpuMonitorCardState extends State<CpuMonitorCard>with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _cpuData = [];
  Timer? _timer;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _startMonitoring();
    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  Future<Map<String, dynamic>> _getCurrentUsage() async {
    try {
      // Get CPU usage
      final cpuResult = await Process.run('adb', [
        '-s',
        widget.deviceId,
        'shell',
        'top -n 1 | grep "CPU"'
      ]);
      
      // Get Memory usage
      final memResult = await Process.run('adb', [
        '-s',
        widget.deviceId,
        'shell',
        'free -m'
      ]);

      // Parse CPU usage
      String cpuLine = cpuResult.stdout.toString();
      double cpuUsage = 0.0;
      if (cpuLine.contains('%')) {
        cpuUsage = double.parse(
          cpuLine.split('%')[0].replaceAll(RegExp(r'[^0-9.]'), '')
        );
      }

      // Parse Memory usage
      List<String> memLines = memResult.stdout.toString().split('\n');
      int totalMem = 0;
      int usedMem = 0;
      
      if (memLines.length > 1) {
        List<String> memValues = memLines[1].split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        if (memValues.length >= 3) {
          totalMem = int.tryParse(memValues[1]) ?? 0;
          usedMem = int.tryParse(memValues[2]) ?? 0;
        }
      }

      double memUsage = totalMem > 0 ? (usedMem / totalMem) * 100 : 0;

      return {
        'time': DateTime.now(),
        'cpu': cpuUsage,
        'memory': memUsage,
        'totalMem': totalMem,
        'usedMem': usedMem,
      };
    } catch (e) {
      print('Error getting usage: $e');
      return {
        'time': DateTime.now(),
        'cpu': 0,
        'memory': 0,
        'totalMem': 0,
        'usedMem': 0,
      };
    }
  }

  void _startMonitoring() {
    _fetchData();  // Initial fetch
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _fetchData());
  }

  Future<void> _fetchData() async {
    final usage = await _getCurrentUsage();
    setState(() {
      _cpuData.add(usage);
      if (_cpuData.length > 30) {  // Keep last 30 data points
        _cpuData.removeAt(0);
      }
      _isLoading = false;
    });
  }

 Widget _buildGlassCard({
    required Widget child,
    Color? accentColor,
    double blur = 10,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (accentColor ?? Colors.white).withOpacity(0.1),
            (accentColor ?? Colors.white).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (accentColor ?? Colors.white).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: child,
        ),
      ),
    );
  }

  Widget _buildUsageGraph() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _cpuData.length || value.toInt() < 0) {
                    return const SizedBox();
                  }
                  return Text(
                    _cpuData[value.toInt()]['time'].toString().substring(11, 16),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          minX: 0,
          maxX: (_cpuData.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            // CPU Line
            LineChartBarData(
              spots: _cpuData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value['cpu']);
              }).toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2196F3),
                  Color(0xFF00BCD4),
                ],
              ),
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.3),
                    const Color(0xFF00BCD4).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Memory Line
            LineChartBarData(
              spots: _cpuData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value['memory']);
              }).toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFF8BC34A),
                ],
              ),
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4CAF50).withOpacity(0.3),
                    const Color(0xFF8BC34A).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              //tooltipBgColor: Colors.black.withOpacity(0.8),
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final isMemory = spot.barIndex == 1;
                  return LineTooltipItem(
                    '${isMemory ? "Memory" : "CPU"}: ${spot.y.toStringAsFixed(1)}%',
                    TextStyle(
                      color: isMemory
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF2196F3),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return _buildGlassCard(
      accentColor: color,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 140,
        child: Column(
          children: [
            Icon(icon, color: color.withOpacity(0.9), size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: double.tryParse(
                        value.replaceAll('%', '').replaceAll(',', '')) ??
                    0,
              ),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Text(
                  '${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color.withOpacity(0.9),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildGlassCard(
        blur: 20,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Colors.white.withOpacity(0.9),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'System Monitor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.9),
                  ),
                )
              else
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'CPU Usage',
                          '${_cpuData.lastOrNull?['cpu']?.toStringAsFixed(1) ?? '0'}%',
                          Icons.memory,
                          const Color(0xFF2196F3),
                        ),
                        _buildStatCard(
                          'RAM Usage',
                          '${_cpuData.lastOrNull?['memory']?.toStringAsFixed(1) ?? '0'}%',
                          Icons.storage,
                          const Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildGlassCard(
                      blur: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildUsageGraph(),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this to the HardwareDetailsPage build method, just before the existing cards:
// CpuMonitorCard(deviceId: widget.deviceId),