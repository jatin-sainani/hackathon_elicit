import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(new MaterialApp(
  home: new MainPage(),
  debugShowCheckedModeBanner: false,
));

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin{
  Map<String, double> _startLocation;
  Map<String, dynamic> data;
  DocumentReference documentReference;
  int accidents;
  int hospitals;

  StreamSubscription<Map<String, double>> _locationSubscription;
  Location _location = new Location();
  bool _permission = false;
  String error;
  Coordinates coordinates;
  var first;

  AnimationController controller;
  Animation<int> animation;
  int value = 0;

  @override
  void initState() {
    super.initState();
    documentReference = null;
    first = null;
    data = null;
    accidents = 0;
    hospitals = 0;
    controller = new AnimationController(vsync: this, duration: Duration(seconds: 1));
    animation = Tween(begin: 0, end: 8).animate(controller);
    controller.addListener(()=> setState((){
      value = animation.value;
    }));
    controller.addStatusListener((status){
      if(status == AnimationStatus.completed)
        controller.reverse();
      else if(status == AnimationStatus.dismissed)
        controller.forward();
    });
    controller.forward();
    initPlatformState();

    _locationSubscription =
        _location.onLocationChanged().listen((Map<String,double> result) {
          coordinates = new Coordinates(result["latitude"], result["longitude"]);
          getAddress(coordinates).then((addressList){
            first = addressList.first;
          });
          setState(() {
            accidents = 0;
            hospitals = 0;
            for(double i = double.parse((result["latitude"] - 0.0005).toStringAsFixed(7)); i <= double.parse((result["latitude"] + 0.0005).toStringAsFixed(7)); i = double.parse((i + 0.0001).toStringAsFixed(7))){
              for(double j = double.parse((result["longitude"] - 0.0005).toStringAsFixed(7)); j <= double.parse((result["longitude"] + 0.0005).toStringAsFixed(7)); j = double.parse((j + 0.0001).toStringAsFixed(7))){
                print("${i.toString()}${j.toString()}");
                documentReference = Firestore.instance.document("locations/${i.toString()}${j.toString()}");
                documentReference.get().then((snapshot){
                  if(snapshot.exists){
                    setState(() {
                      accidents += snapshot["accidents"];
                      hospitals += snapshot["hospitals"];
                    });
                  } else {
                    data = {
                      "accidents" : 5,
                      "hospitals" : 6
                    };
                    documentReference.setData(data);
                  }
                });
              }
            }
            print(accidents);
            print(hospitals);
          });
        });
  }

  Future<List<Address>> getAddress(Coordinates coordinates) async {
    var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    return addresses;
  }

  Future<Map<String, double>> getlocation() async {
    var location = _location.getLocation();
    return location;
  }

  initPlatformState() async {
    Map<String, double> location;
    try {
      _permission = await _location.hasPermission();
      getlocation().then((location){
        setState(() {
          coordinates = new Coordinates(location["latitude"], location["longitude"]);
          getAddress(coordinates).then((addressList){
            first = addressList.first;
          });
        });
        setState(() {
          accidents = 0;
          hospitals = 0;
          for(double i = double.parse((location["latitude"] - 0.0005).toStringAsFixed(7)); i <= double.parse((location["latitude"] + 0.0005).toStringAsFixed(7)); i = double.parse((i + 0.0001).toStringAsFixed(7))){
            for(double j = double.parse((location["longitude"] - 0.0005).toStringAsFixed(7)); j <= double.parse((location["longitude"] + 0.0005).toStringAsFixed(7));  j = double.parse((j + 0.0001).toStringAsFixed(7))){
              print("${i.toString()}${j.toString()}");
              documentReference = Firestore.instance.document("locations/${i.toString()}${j.toString()}");
              documentReference.get().then((snapshot){
                if(snapshot.exists){
                  setState(() {
                    accidents += snapshot["accidents"];
                    hospitals += snapshot["hospitals"];
                  });
                } else {
                  data = {
                    "accidents" : 5,
                    "hospitals" : 6
                  };
                  documentReference.setData(data);
                }
              });
            }
          }
          print(accidents);
          print(hospitals);
        });
      });

      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error = 'Permission denied - please ask the user to enable it from the app settings';
      }

      location = null;
    }

    setState(() {
      _startLocation = location;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Hackathon-Test'),
      ),
      body: Stack(
        children: <Widget>[
          AnimatedOpacity(
            opacity: (value > 3 && accidents != 0 && hospitals != 0) ? 1.0 : 0.0,
            duration: Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.red[300],
                    Colors.red[400],
                    Colors.red[500],
                    Colors.red[800],
                  ]
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              height: 500.0,
              width: 350.0,
              child: Card(
                color: Colors.white,
                elevation: 20.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: [
                          Text('HIGH',
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              color: Colors.black,
                              fontSize: 60.0,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: Text('Accidents-per-month',
                              style: TextStyle(
                                fontSize: 30.0,
                                fontWeight: FontWeight.w100,
                                fontFamily: 'Oswald',
                                color: Colors.black,
                              ),
                            )
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: Text((accidents != 0 && hospitals != 0) ? accidents.toString() : "Location Changed. Fetching Data...",
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                fontWeight: FontWeight.w700,
                                fontSize: 20.0
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: Text('No. of hospitals in the area',
                              style: TextStyle(
                                fontSize: 30.0,
                                fontWeight: FontWeight.w100,
                                fontFamily: 'Oswald',
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: Text((accidents != 0 && hospitals != 0) ? hospitals.toString() : "Location Changed. Fetching Data...",
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Oswald',
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 10.0),
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  child: Text((first != null) ? 'Current Location: ${first.addressLine}' : 'Error: $error',
                                    style: TextStyle(
                                      fontFamily: 'Oswald',
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w700
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ]
                      ),
                      AnimatedOpacity(
                        opacity: (value > 3 && accidents != 0 && hospitals != 0) ? 1.0 : 0.0,
                        duration: Duration(milliseconds: 200),
                        child: Column(
                            children: [
                              Text('HIGH',
                                style: TextStyle(
                                  fontFamily: 'Oswald',
                                  color: Colors.red[500],
                                  fontSize: 60.0,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 84.0),
                                child: Text(accidents.toString(),
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20.0,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 84.0),
                                child: Text(hospitals.toString(),
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Oswald',
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            ]
                          ),
                      )
                    ],
                  )
                ),
              ),
            ),
          ),
        ]
      ),
    );
  }
}