import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:path_provider/path_provider.dart';

import 'chart_data.dart';

class DataCollectionService {
  static List<ChartData> chartData = [];

  static Future<List<ChartData>> collectData(
      BluetoothDevice device, String fileName, int duration) async {
    List<BluetoothService> services = await device.discoverServices();
    List<int> collectedData = [];
    StreamSubscription<List<int>>? subscription;

    for (BluetoothService service in services) {
      if (service.uuid.toString() == "4fafc201-1fb5-459e-8fcc-c5c9c331914b") {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() ==
              "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
            characteristic.setNotifyValue(true);

            subscription = characteristic.value.listen((value) {
              ByteData byteData =
                  ByteData.view(Uint8List.fromList(value).buffer);
              var receivedValue = byteData.getUint32(0, Endian.little);
              collectedData.add(receivedValue);
            });
          }
        }
      }
    }

    await Future.delayed(Duration(seconds: duration));
    subscription?.cancel();

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/$fileName.csv');
    await file.writeAsString(collectedData.map((e) => e.toString()).join('\n'));
    await loadCSVData(file.path);
    return chartData;
  }

  static Future<List<int>> readData(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/$fileName.csv');

    if (await file.exists()) {
      final lines = await file.readAsLines();
      return lines.map((line) => int.parse(line)).toList();
    } else {
      throw Exception('File not found');
    }
  }

  static Future<void> loadCSVData(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('File not found');
    }
    final lines = await file.readAsLines();
    List<ChartData> tempChartData = [];
    for (int i = 0; i < lines.length; i++) {
      try {
        double yValue = double.parse(lines[i]);
        tempChartData.add(ChartData(i.toDouble(), yValue));
      } catch (e) {
        print('Error: $e');
      }
    }
    chartData = tempChartData;
  }
}
