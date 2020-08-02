import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shake/shake.dart';
import 'package:sms_maintained/sms.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'ShakeyShake'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  Position _currentPosition;
  String _currentAddress;
  SmsSender sender = SmsSender();
  String address = "9677051645";
  // String address = "9003162666";

  void counter() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("SOS Action Triggered"),
          content: CircularCountDownTimer(
            // Countdown duration in Seconds
            duration: 10,

            // Width of the Countdown Widget
            width: MediaQuery.of(context).size.width / 3,

            // Height of the Countdown Widget
            height: MediaQuery.of(context).size.height / 3,

            // Default Color for Countdown Timer
            color: Colors.white,

            // Filling Color for Countdown Timer
            fillColor: Colors.green,

            // Border Thickness of the Countdown Circle
            strokeWidth: 5.0,

            textStyle: TextStyle(
                fontSize: 22.0,
                color: Colors.black87,
                fontWeight: FontWeight.bold),

            // true for reverse countdown (max to 0), false for forward countdown (0 to max)
            isReverse: true,

            // Function which will execute when the Countdown Ends
            onComplete: () {
              SmsMessage message = new SmsMessage(address,
                  "The address is $_currentAddress and the exact co-ordinates are LAT:${_currentPosition.latitude} and LNG : ${_currentPosition.longitude}");
              message.onStateChanged.listen((state) {
                if (state == SmsMessageState.Sent) {
                  Fluttertoast.showToast(
                      msg: 'Message sent to the number',
                      textColor: Colors.black);
                } else if (state == SmsMessageState.Delivered) {
                  print("SMS is delivered!");
                }
              });
              sender.sendSms(message);
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[
            RaisedButton(
              color: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    _getCurrentLocation();

    ShakeDetector detector = ShakeDetector.autoStart(onPhoneShake: () {
      print('phone shaked bro...');
      counter();
    });
    super.initState();
  }

  GoogleMapController mapController;

  double la;
  double lo;

  final LatLng _center = const LatLng(13.0827, 80.2707);
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 15.0,
        ),
        myLocationEnabled: true,
      ),
    );
  }

  /// getting the location in _getCurrentLocation which is initiated in init state
  _getCurrentLocation() async {
    if (await geolocator.isLocationServiceEnabled()) {
    } else {}
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  /// getting address from [LAT] and [LON] obtained from _getCurrentLocation method
  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);
      la = _currentPosition.latitude;
      lo = _currentPosition.longitude;

      Placemark place = p[0];
      print(place.toJson()); // Detailed address can be found here. See Logcat
      setState(() {
        _currentAddress =
            "${place.name},${place.subLocality},${place.thoroughfare},${place.locality},${place.subAdministrativeArea},${place.postalCode}";
      });
    } catch (e) {
      print(e);
    }
  }
}
