import 'package:flutter/material.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:rhino_flutter/rhino.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';

void main() {
  runApp(const Home());
}

BluetoothConnection? connection; // Bluetooth connection instance

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late PicovoiceManager _picovoiceManager;
  bool _isWakeWordDetected = false; // Initial status

  @override
  void initState() {
    super.initState();
    _initPicovoice();
    _initBluetooth();
  }

  @override
  void dispose() {
    _picovoiceManager.stop();
    connection?.dispose(); // Close the Bluetooth connection when disposing
    super.dispose();
  }

  Future<void> _initPicovoice() async {
    try {
      _picovoiceManager = await PicovoiceManager.create(
          "vBlmHBaVQQvS4dciOScUGpsJAVTql593NisoYRMkSZTkgYceBy7KRw==",
          'assets/Hey-Wheel-Ease_en_android_v3_0_0.ppn',
          _wakeWordCallback,
          'assets/WheelEase_en_android_v3_0_0.rhn',
          _inferenceCallback);
      await _picovoiceManager.start();
    } on PicovoiceException catch (ex) {
      print('Error initializing Picovoice: $ex');
    }
  }

  void _wakeWordCallback() {
    print('Wake word detected!');
    setState(() {
      _isWakeWordDetected = true;
    });
  }

  void _inferenceCallback(RhinoInference inference) {
    if (inference.isUnderstood != null && inference.intent != null) {
      String intent = inference.intent!;
      //Map<String, String> slots = inference.slots ?? {};
      switch (intent) {
        case 'MOVE_FORWARD':
          _sendToArduino('^'); // Send signal to move forward
          print("ana ghadi");
          break;
        case 'MOVE_BACKWARD':
          _sendToArduino('-'); // Send signal to move backward
          print("ananraj3");
          break;
        case 'MOVE_LEFT':
          _sendToArduino('<'); // Send signal to move left
          print("ana dayr lisr ");
          break;
        case 'MOVE_RIGHT':
          _sendToArduino('>'); // Send signal to move right
          print("ana dayr limn ");
          break;
        case 'STOP':
          _sendToArduino('*'); // Send signal to stop
          print("ana waqf");
          break;
        default:
          print('Unknown intent: $intent');
          break;
      }
      setState(() {
        _isWakeWordDetected = false;
      });
    } else {
      print("Command not understood.");
    }
  }

  String _connectionStatus = 'Not Connected'; // Initial status
  Future<void> _initBluetooth() async {
    setState(() {
      _connectionStatus = 'Attempting to connect...';
    });

    try {
      // Ensure Bluetooth is enabled
      bool? isBluetoothEnabled =
          await FlutterBluetoothSerial.instance.isEnabled;
      if (!isBluetoothEnabled!) {
        setState(() {
          _connectionStatus = 'Bluetooth is disabled. Please enable it.';
        });
        return;
      }

      // Get the list of paired devices
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      if (devices.isEmpty) {
        setState(() {
          _connectionStatus = 'No paired devices found. Please pair a device.';
        });
        return;
      }

      // Attempt to connect to the first paired device
      BluetoothDevice device = devices.first;
      setState(() {
        _connectionStatus = 'Connecting to ${device.name}...';
      });

      connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connectionStatus = 'Connected to ${device.name}';
      });
    } catch (e) {
      print('Failed to connect: $e');
      setState(() {
        _connectionStatus = 'Failed to connect: $e';
      });
    }
  }

  void _sendToArduino(String command) {
    try {
      if (connection != null) {
        // Convert List<int> to Uint8List
        Uint8List bytes = Uint8List.fromList(command.codeUnits);

        // Write the command to the Bluetooth connection
        connection!.output.add(bytes);
        connection!.output.allSent.then((_) {
          print('Sent: $command');
        });
      } else {
        print('Bluetooth connection not available');
      }
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFECE9E9),
        appBar: AppBar(
          title: const Text(
            "WheelEase",
            style: TextStyle(
              color: Color(0xFF091321),
              fontWeight: FontWeight.bold,
              fontFamily: "dosis",
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF28B67E),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  _isWakeWordDetected
                      ? 'Wake Word Detected'
                      : 'Wake Word Not Detected',
                  style: TextStyle(
                    color: _isWakeWordDetected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  )),
              Text(
                _connectionStatus,
                style: TextStyle(fontSize: 18),
              ),
              ElevatedButton(
                onPressed: _initBluetooth, // Trigger the connection attempt
                child: const Text('Connect Bluetooth'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Color(0xFF28B67E),     // Text color
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          print("forward");
                          _sendToArduino("^"); // Send command to move forward
                        },
                        icon: const Icon(Icons.keyboard_arrow_up, size: 40),
                        tooltip: 'Move Up',
                      ),
                      const Text("Forward",
                          style: TextStyle(fontFamily: "dosis"))
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          print("left");
                          _sendToArduino("<"); // Send command to move left
                        },
                        icon: const Icon(Icons.keyboard_arrow_left, size: 40),
                        tooltip: 'Move Left',
                      ),
                      const Text("Left", style: TextStyle(fontFamily: "dosis"))
                    ],
                  ),
                  SizedBox(width: 72), // Spacing between left and right buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          print("right");
                          _sendToArduino(">"); // Send command to move right
                        },
                        icon: const Icon(Icons.keyboard_arrow_right, size: 40),
                        tooltip: 'Move Right',
                      ),
                      const Text("Right", style: TextStyle(fontFamily: "dosis"))
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          print("backward");
                          _sendToArduino("-"); // Send command to move backward
                        },
                        icon: const Icon(Icons.keyboard_arrow_down, size: 40),
                        tooltip: 'Move Down',
                      ),
                      const Text("Backward",
                          style: TextStyle(fontFamily: "dosis"))
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              print('stopped');
                              _sendToArduino("*"); // Send command to stop
                            },
                            child: const Icon(
                              Icons.stop,
                              size: 40,
                              color: Color(0xFF28B67E),
                            ),
                          ),
                          const Text(
                            'Stop',
                            style: TextStyle(
                              color: Color(0xFF28B67E),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Dosis',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton:Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _toggleListening();
                });
              },
              backgroundColor: _isListening ? Color(0xFF28B67E) : Colors.red ,
              child: _isListening ? const Icon(Icons.mic) : const Icon(Icons.mic_off),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40.0),
              ),
            ),
            SizedBox(height: 5),
            Text(
              _isListening ? 'Turn off' : 'Turn on',
              style: TextStyle(
                color: _isListening ? const Color(0xFF28B67E): Colors.red ,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

      ),
    );
  }

  bool _isListening = false;

  void _toggleListening() {
    if (!_isListening) {
      _picovoiceManager.start();
      _isListening = true;
      print("Listening for commands...");
    } else {
      _picovoiceManager.stop();
      _isListening = false;
      print("Stopped listening.");
    }
  }
}
