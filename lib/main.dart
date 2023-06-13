import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'chart_data.dart';
import 'data_collection_service.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primaryColor: const Color(0xFF6200EE),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6200EE),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: const Color(0xFF6200EE),
      ),
    ),
    home: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devices = [];
  late BluetoothDevice selectedDevice;
  String filePath = "";
  String fileName = "";
  late double duration;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ChartData> chartData = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  startScan() async {
    devices = [];
    await flutterBlue.startScan(timeout: const Duration(seconds: 4));
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devices.contains(r.device)) {
          setState(() {
            if (r.device.name != "") {
              devices.add(r.device);
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Sensor EMG'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 70),
        child: chartData.isNotEmpty
            ? SfCartesianChart(
                series: <LineSeries<ChartData, num>>[
                  LineSeries<ChartData, num>(
                    animationDuration: 2500,
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                  ),
                ],
              )
            : Center(
                child: Text(
                  "Nenhum dado coletado",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
      ),
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white10.withOpacity(0.8),
        ),
        child: Drawer(
          child: ListView(
            children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF6200EE),
                ),
                accountName: const Text('Sensor EMG'),
                accountEmail: const Text(''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Image.asset('assets/logo.png'),
                ),
              ),
              ...devices
                  .map((device) => ListTile(
                        title: Text(device.name),
                        onTap: () async {
                          await device.connect();
                          selectedDevice = device;
                          Navigator.of(context).pop();
                        },
                      ))
                  .toList(),
              ListTile(
                title: const Text('Coletar dados'),
                onTap: () async {
                  String fileName = 'resultados_coleta';
                  int duration = 5;
                  List<ChartData> newChartData =
                      await DataCollectionService.collectData(
                          selectedDevice, fileName, duration);
                  setState(() {
                    chartData = newChartData;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        child: const Icon(Icons.menu),
      ),
    );
  }
}
