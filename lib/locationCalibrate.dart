
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocationCalibration extends StatefulWidget {
  final String id;
  LocationCalibration({Key key, this.id}) : super(key: key);

  @override
  _LocationCalibrationState createState() => _LocationCalibrationState();
}

class _LocationCalibrationState extends State<LocationCalibration> {
  String _platformVersion = "";
  List _allWifi;
  final TextEditingController _aText = TextEditingController();
  final TextEditingController _bText = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _allWifi = [];
  }

  static const platform = const MethodChannel('wificustom');

  Future<LinkedHashMap> _getAllWifi() async {
    List allWifi;
    try {
      var x = await platform.invokeMethod('getAllWifi');
      return x;
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
    }

    setState(() {
      _allWifi = allWifi;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Positioning Entry Calibration'),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("A:"),
                    ),
                    Container(
                        width: 150,
                        child: TextField(
                          decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                          controller: _aText,
                        )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("B:"),
                    ),
                    Container(
                        width: 150,
                        child: TextField(
                          decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                          controller: _bText,
                        )),
                  ],
                ),
              ),
              Text("Results :"),
              Expanded(
                child: ListView.builder(
                    itemCount: _allWifi.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_allWifi[index].toString()),
                      );
                    }),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(35.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: Text("Add To Database"),
                        onPressed: () async {
                          var list = await _getAllWifi();

                          list.putIfAbsent("a", () => _aText.text);
                          list.putIfAbsent("b", () => _bText.text);
                          await _addToFirebase(list);
                          setState(() {
                            _allWifi.add(list);
                          });
                        },
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        child: Text("Clear Page"),
                        onPressed: () {
                          setState(() {
                            _allWifi.clear();
                          });
                        },
                      ),
                      ElevatedButton(
                        child: Text("Done"),
                        onPressed: () {
                          setState(() {
                            Navigator.popUntil(context, ModalRoute.withName('/'));
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          )),
    );
  }

  _addToFirebase(LinkedHashMap list) async{
    CollectionReference data = firestore.collection('locData').doc(widget.id).collection("locData");
    var batch = firestore.batch();
    data.add({
      "a": list['a'],
      "b": list['b'],
      "location": list['Location']
    }).then((value) {
      for(var wifi in list['Wifi']){
        var docRef = firestore.doc(value.path).collection("wifi").doc();
        batch.set(docRef, {"wifi":wifi});
      }

    }).catchError((error) => print("Failed to add data: $error"));
  }
}