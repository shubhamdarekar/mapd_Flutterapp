import 'package:flutter/material.dart';
import 'package:mapd_demo/arguments.dart';

class AddNewPlace extends StatefulWidget {
  const AddNewPlace({Key key}) : super(key: key);

  @override
  _AddNewPlaceState createState() => _AddNewPlaceState();
}

class _AddNewPlaceState extends State<AddNewPlace> {
  @override
  Widget build(BuildContext context) {
    final AddNewPlaceArguments args = ModalRoute.of(context).settings.arguments as AddNewPlaceArguments;
    
    return Scaffold(
      appBar: AppBar(
        title: Hero(
            child: Text("Add new place"),
        tag:"addPlace"
        ),
      ),
      body: Container(
        child: Center(child: Text("Hii")),

        
      ),
    );
  }
}
