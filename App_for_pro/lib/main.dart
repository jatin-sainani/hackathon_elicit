import 'package:flutter/material.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() => runApp(new MaterialApp(
  home: new MainPage(),
  debugShowCheckedModeBanner: false,
));

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin{

  AnimationController controller;
  Animation<double> animation;
  double value = 0.0;
  bool accidentIsHappen = false;

  Map<String, double> _startLocation;
  Map<String, double> _currentLocation;
  var accidentLatitude = 26.8422965;
  var accidentLongitude = 75.5661535;

  StreamSubscription<Map<String, double>> _locationSubscription;

  Location _location = new Location();
  bool _permission = false;
  String error;

  @override
  void initState() {
    super.initState();
    controller = new AnimationController(vsync: this, duration: Duration(seconds: 1));
    animation = Tween(begin: 0.0, end: 15.0).animate(controller);
    controller.addListener(()=>setState((){
      value = animation.value;
    }));
    controller.addStatusListener((status){
      if(status == AnimationStatus.completed)
        controller.reverse();
      else if(status == AnimationStatus.dismissed)
        controller.forward();
    });//Animation
    controller.forward();
    initPlatformState();

    _locationSubscription =
        _location.onLocationChanged().listen((Map<String,double> result) {
          setState(() {
            accidentIsHappen = false;
            if(sqrt(pow(accidentLatitude - result["latitude"], 2) + pow(accidentLongitude - result["longitude"], 2)) <= 0.1){
              setState(() {
                accidentIsHappen = true;
              });
            }
          });
        });
  }

  initPlatformState() async {
    Map<String, double> location;
    // Platform messages may fail, so we use a try/catch PlatformException.

    try {
      _permission = await _location.hasPermission();
      getlocation().then((location){
        setState(() {
          accidentIsHappen = false;
          if(sqrt(pow(accidentLatitude - location["latitude"], 2) + pow(accidentLongitude - location["longitude"], 2)) <= 0.1){
            setState(() {
              accidentIsHappen = true;
            });
          }
        });
      });

      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error =
        'Permission denied - please ask the user to enable it from the app settings';
      }

      location = null;
    }
  }

  Future<Map<String, double>> getlocation() async {
    var location = await _location.getLocation();
    return location;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Hackathon Test(For professionals)'),
      ),
      body: Stack(
        children: <Widget>[
          AnimatedOpacity(
            opacity: (value > 3.0) ? 1.0: 0.0,
            duration: Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Colors.red[300],
                        Colors.red[400],
                        Colors.red[500],
                        Colors.red[800],
                      ]//Providing Gradient
                  )
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text((accidentIsHappen) ? 'Accident Occured at \nLatitude:${accidentLatitude.toString()} \nLongitude:${accidentLongitude.toString()}' : 'No Accidents in your area, Checking...',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 35.0,
                  color: Colors.black
                ),
              ),
            )
          )
        ],
      ),
    );
  }
}
