import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(const MyApp());

@immutable
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late MqttServerClient client;
  double temperature = 0;
  double humidity = 0;

  @override
  void initState() {
    super.initState();
    connect();
  }

  Future<void> connect() async {
    client = MqttServerClient('IP_ADRESS', '');
    client.port = 1883;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterClient')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('Exception: $e');
      disconnect();
    }

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      debugPrint('Received message: $payload from topic: ${c[0].topic}');
      setState(() {
        if (c[0].topic == 'home/temperature') {
          temperature = double.parse(payload);
        } else if (c[0].topic == 'home/humidity') {
          humidity = double.parse(payload);
        }
      });
    });

    client.subscribe('home/temperature', MqttQos.atLeastOnce);
    client.subscribe('home/humidity', MqttQos.atLeastOnce);
  }

  void onDisconnected() {
    debugPrint('Disconnected');
  }

  void onConnected() {
    debugPrint('Connected');
  }

  void onSubscribed(String topic) {
    debugPrint('Subscribed topic: $topic');
  }

  void disconnect() {
    client.disconnect();
  }

  String getStatusMessage() {
    if (temperature < 27 &&
        temperature > 15 &&
        humidity >= 30 &&
        humidity <= 40) {
      return "The air quality is ideal.";
    } else if (temperature < 27 &&
        temperature > 15 &&
        humidity >= 40 &&
        humidity <= 50) {
      return "The air quality is good.";
    } else if (temperature >= 27 && humidity >= 30 && humidity <= 60) {
      return "It's hot. Stay hydrated!";
    } else if (humidity < 35 || humidity > 50) {
      return "Humidity is not ideal. Consider ventilating.";
    }
    return "Air quality needs improvement.";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color.fromARGB(255, 248, 241, 111),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 36.0, 16.0, 16.0),
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/undraw_nature_on_screen_xkli.svg',
                    width: 150,
                    height: 150,
                  ),
                  SizedBox(height: 25),
                  Text(
                    getStatusMessage(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 10.0,
                    animation: true,
                    percent: temperature / 50,
                    center: Text(
                      "$temperature°C",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: temperature < 27 ? Colors.green : Colors.red,
                      ),
                    ),
                    footer: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Temperature",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: temperature < 27 ? Colors.green : Colors.red,
                    backgroundColor: Colors.blue.shade100,
                  ),
                  SizedBox(height: 25),
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 10.0,
                    animation: true,
                    percent: humidity / 100,
                    center: Text(
                      "$humidity%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: (humidity >= 30 && humidity <= 40)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    footer: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Humidity",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: (humidity >= 30 && humidity <= 40)
                        ? Colors.green
                        : Colors.red,
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
