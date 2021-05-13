
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VrPageArguments {

  final String name;
  final String id;
  final LatLng latLng;

  VrPageArguments(this.name, this.id, this.latLng);

}

class AddNewPlaceArguments {

  final LatLng latLng;
  AddNewPlaceArguments(this.latLng);

}