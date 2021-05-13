import 'package:flutter/material.dart';
import 'package:mapd_demo/VrPage.dart';
import 'package:mapd_demo/addNewPlace.dart';

import 'home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapD',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.yellow,
        primaryColor: Colors.yellow,
        accentColor: Colors.cyanAccent,
      ),
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => MyHomePage(title: 'Main Activity'),
        '/VRpage':(context) =>  VrPage(),
        '/addNew':(context) => AddNewPlace(),

      },

    );
  }
}


