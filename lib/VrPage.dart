import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mapd_demo/arguments.dart';
import 'package:panorama/panorama.dart';

class VrPage extends StatefulWidget {
  VrPage({Key key}) : super(key: key);

  @override
  _VrPageState createState() {
    return _VrPageState();
  }
}

class _VrPageState extends State<VrPage> {
  bool _showGoogleMaps = false;

  @override
  void initState() {
    _getLocation();
    super.initState();

    Future.delayed(const Duration(milliseconds: 2000), () {
      print("loading");
      setState(() {
        _showGoogleMaps = true;
      });
    });
  }

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  LocationData currentLocation;
  LatLng _center ;

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
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

        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(l.latitude, l.longitude), zoom: 18),
          ),
        );
      });

      currentLocation = await location.getLocation();

      print("locationLatitude: ${currentLocation.latitude}");
      print("locationLongitude: ${currentLocation.longitude}");
      setState(() {
        _center = LatLng(currentLocation.latitude, currentLocation.longitude);
      }); //rebuild the widget after getting the current location of the user
    } on Exception {
      currentLocation = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final VrPageArguments args = ModalRoute.of(context).settings.arguments as VrPageArguments;
    setState(() {
      _center = args.latLng;
    });

    return Scaffold(
      appBar: AppBar(
        title: Hero(child: Text(args.name),tag:'place'),
        centerTitle: true,
      ),
      body: Container(
        child: Stack(
          children: [
            Panorama(
              zoom: 1,
              sensitivity: 3,
              child: Image.asset('assets/images/2.jpg'),
            ),
            Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0,20,20,10),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(
                        color: Colors.grey,
                        blurRadius: 5.0,
                      ),],
                        border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                    ),
                    width:150,
                    height: 150,
                    child: _showGoogleMaps? GoogleMap(
                      onMapCreated: _onMapCreated,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 10.0,
                      ),
                    ):Center(child: Text("loading...")),
                  ),
                )
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.1,
              minChildSize: 0.08,
              maxChildSize: 0.8,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                    decoration: new BoxDecoration(
                      borderRadius: new BorderRadius.circular(15.0),
                      color: Colors.brown,
                    ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      SizedBox(height: 10,width: 10,),
                      new Container(
                        width:10,
                        height: 5,
                        margin: EdgeInsets.symmetric(vertical: 0,horizontal: 70),
                        decoration: new BoxDecoration(
                          borderRadius: new BorderRadius.circular(10.0),
                          color: Colors.grey,
                          boxShadow: [
                            new BoxShadow(
                                color: Colors.grey,
                                blurRadius: 3.0,
                                offset: new Offset(1.0, 1.0))
                          ],
                        ),
                      ),
                      SizedBox(height: 50,),
                      Image.asset('assets/images/materialized-view.png'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}