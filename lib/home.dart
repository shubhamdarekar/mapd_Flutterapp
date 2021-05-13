import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mapd_demo/arguments.dart';
import 'package:http/http.dart' as http;


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  LocationData currentLocation;
  LatLng _center = new LatLng(19.053033, 72.890933);

  bool _popUpVisibility;
  String _placeName;
  String _placeId;


  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  _getNearbyPlaces(var lat, var lon) async{
    var host = "192.168.0.10:8000";
    var path = 'apis/getNearest/';
    var queryParameters = {
      'latitude': lat.toString(),
      'longitude': lon.toString()
    };
    var response = await http.get(Uri.http(host, path, queryParameters ));
    var x = json.decode(response.body);

    if(x['res'] == 'true'){
      setState(() {
        _placeId = x['id'];
        _placeName = x['name'];
        _popUpVisibility = true;
      });
    }else{
      setState(() {
        _placeId = '-1';
        _placeName = '';
        _popUpVisibility = false;
      });
    }
  }

  _getLocation() async {
    var location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    try {
      mapController = await _controller.future;
      location.onLocationChanged.listen((l) {
        if(markers.isEmpty){
          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(l.latitude, l.longitude), zoom: 18),
            ),
          );

          //TODO api call
          _getNearbyPlaces(l.latitude, l.longitude);
        }
      });

      currentLocation = await location.getLocation();

      // print("locationLatitude: ${currentLocation.latitude}");
      // print("locationLongitude: ${currentLocation.longitude}");
      setState(() {
        _center = LatLng(currentLocation.latitude, currentLocation.longitude);
      }); //rebuild the widget after getting the current location of the user
    } on Exception {
      currentLocation = null;
    }
  }

  Future _addMarkerLongPressed(LatLng latlang) async {
    setState(() {
      final MarkerId markerId = MarkerId("RANDOM_ID");
      Marker marker = Marker(
        markerId: markerId,
        draggable: true,
        position: latlang, //With this parameter you automatically obtain latitude and longitude
        infoWindow: InfoWindow(
          title: "Marker here",
          snippet: 'This looks good',
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      markers[markerId] = marker;
      _popUpVisibility=false;
    });
    mapController = await _controller.future;

    //This is optional, it will zoom when the marker has been created
    mapController.animateCamera(CameraUpdate.newLatLngZoom(latlang, 20.0));
  }

  @override
  void initState() {
    // TODO: implement initState
    _getLocation();
    _popUpVisibility=false;
    _placeId="-1";
    _placeName="";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      floatingActionButton: Padding(
        padding: _popUpVisibility? EdgeInsets.fromLTRB(0, 0, 0, 180):EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/addNew', arguments: AddNewPlaceArguments(_center));
          },
          icon: Icon(Icons.add),
          // foregroundColor: Theme.of(context).accentColor,
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
          heroTag: "addPlace",
          label: markers.isEmpty?Text("Add new place at your current location"):Text("Add new place at Marker"),
        ),
      ),
      body: Container(
        color: Theme.of(context).primaryColor,
        padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                compassEnabled: true,
                zoomControlsEnabled: false,
                markers: Set<Marker>.of(markers.values),
                onTap: (latlong){
                  setState(() {
                    markers = <MarkerId, Marker>{};
                  });
                },
                onLongPress: (latlong){
                  _addMarkerLongPressed(latlong);
                  _getNearbyPlaces(latlong.latitude, latlong.longitude);
                },
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 15.0,
                ),
              ),
            ),
          ),
          Visibility(
            visible: _popUpVisibility,
            child: new Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 450,
                // color: Colors.red,
                // padding: EdgeInsets.all(8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Colors.white,
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 15, 8, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(width:32),
                            Text('Nearby Structures'),
                            IconButton(icon: Icon(Icons.cancel_outlined), onPressed: (){
                              setState(() {
                                _popUpVisibility = false;
                              });
                            }, iconSize: 32,)
                          ],
                        ),
                        SizedBox(height: 10,),
                        Hero(
                          tag:'place',
                          child: Material(
                            color: Colors.grey,
                            child: InkWell(
                              splashColor: Theme.of(context).accentColor,
                              onTap: () {
                                Navigator.pushNamed(context, '/VRpage', arguments: VrPageArguments(_placeName, _placeId, _center));
                              },
                              child: ListTile(
                                leading: Icon(Icons.looks_one, size: 60),
                                title: Text(_placeName,
                                    style: TextStyle(color: Colors.white)),
                                subtitle: Text(_placeId,
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
