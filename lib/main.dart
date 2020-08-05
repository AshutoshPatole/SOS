import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shake/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      home: MyHomePage(title: 'SOS'),
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

  void counter() async {
    final SharedPreferences prefs = await _prefs;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("SOS Action Triggered"),
          content: CircularCountDownTimer(
            duration: 4,
            width: MediaQuery.of(context).size.width / 3,
            height: MediaQuery.of(context).size.height / 3,
            color: Colors.white,
            fillColor: Colors.green,
            strokeWidth: 5.0,
            textStyle: TextStyle(
                fontSize: 22.0,
                color: Colors.black87,
                fontWeight: FontWeight.bold),
            isReverse: true,
            onComplete: () {
              SmsMessage message = new SmsMessage(prefs.getString('number'),
                  "The address is $_currentAddress and the exact co-ordinates are LAT:${_currentPosition.latitude} and LNG : ${_currentPosition.longitude}");
              message.onStateChanged.listen((state) {
                if (state == SmsMessageState.Sent) {
                  Fluttertoast.showToast(
                    msg: 'Message sent to the number',
                    textColor: Colors.black,
                    backgroundColor: Colors.green,
                  );
                } else if (state == SmsMessageState.Delivered) {
                  print("SMS is delivered!");
                }
              });
              prefs.getString("number") != null
                  ? sender.sendSms(message)
                  : Fluttertoast.showToast(
                      msg: "Please add atleast one number to send SOS",
                      textColor: Colors.black,
                      fontSize: 16,
                      backgroundColor: Colors.red);
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

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  TextEditingController _number = TextEditingController();
  void addNumber() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add number"),
          content: TextFormField(
            controller: _number,
            decoration: InputDecoration(hintText: "Ex 90031XXXXX"),
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
            ),
            RaisedButton(
              color: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              onPressed: () async {
                print(_number.text);
                final SharedPreferences prefs = await _prefs;
                await prefs.setString('number', _number.text);
                Navigator.pop(context);
              },
              child: Text("Add"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Image.asset('assets/sos.png'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addNumber();
        },
        child: Icon(Icons.add),
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
      print("fetched location");
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
