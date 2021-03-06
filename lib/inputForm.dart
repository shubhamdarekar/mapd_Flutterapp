import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapd_demo/arguments.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:http/http.dart' as http;

import 'locationCalibrate.dart';


class WizardFormBloc extends FormBloc<String, String> {
  final latitude = TextFieldBloc(
    validators: [FieldBlocValidators.required],
  );

  final longitude = TextFieldBloc(
    validators: [FieldBlocValidators.required],
  );

  final nameOfPlace = TextFieldBloc(
    validators: [FieldBlocValidators.required],
  );

  final photoList = TextFieldBloc(
    validators: [FieldBlocValidators.required],
    initialValue: "Shubham"
  );

  final mapPhoto = TextFieldBloc(
    validators: [FieldBlocValidators.required],
      initialValue: "Shubham"

  );

  List<Asset> images = [];
  List<Asset> map = [];
  String placeId = '';

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  WizardFormBloc() {
    addFieldBlocs(
      step: 0,
      fieldBlocs: [latitude, longitude,nameOfPlace],
    );
    addFieldBlocs(
      step: 1,
      fieldBlocs: [photoList],
    );
    addFieldBlocs(
      step: 2,
      fieldBlocs: [mapPhoto],
    );
  }

  _callStitching(id) async{
    var host = "192.168.0.10:8000";
    var path = 'apis/stitchImage/';
    var queryParameters = {
      'id':id
    };
    var response = await http.get(Uri.http(host, path, queryParameters));
    var x = json.decode(response.body);
    print(x);
  }

  @override
  void onSubmitting() async {
    if (state.currentStep == 0) {
      await Future.delayed(Duration(milliseconds: 500));
      emitSuccess();
    } else if (state.currentStep == 1) {

      if (images.length<3) {
        photoList.addFieldError('Atleast 3 photos');
        emitFailure();
      } else {
        emitSuccess();
      }
    } else if (state.currentStep == 2) {
      if (map.length!=1) {
        mapPhoto.addFieldError('Add a photo');
        emitFailure();
      } else {



      firestore.collection('listLatLong').add({
        'latitude': latitude.value,
        'longitude': longitude.value,
        'name': nameOfPlace.value,
        'imageListLength':images.length,
        'map':map.length
      }).then((value)  async{
        // print(value.id);
        placeId = value.id;
        for(var i =0;i<images.length;i++){
          ByteData byteData = await images[i].getByteData();
          List<int> imageData = byteData.buffer.asUint8List();
          await storage.ref('rawFiles/'+value.id+"/"+i.toString())
              .putData(imageData);
        }
        ByteData byteData = await map[0].getByteData();
        List<int> imageData = byteData.buffer.asUint8List();
        await storage.ref('maps/'+value.id)
            .putData(imageData);
        _callStitching(value.id);
        emitSuccess();
      }).catchError((){
        emitFailure();
      });

      }
    }

  }
}

class WizardForm extends StatefulWidget {
  @override
  _WizardFormState createState() => _WizardFormState();
}

class _WizardFormState extends State<WizardForm> {
  var _type = StepperType.horizontal;
  List<Asset> images = [];
  List<Asset> map = [];


  void _toggleType() {
    setState(() {
      if (_type == StepperType.horizontal) {
        _type = StepperType.vertical;
      } else {
        _type = StepperType.horizontal;
      }
    });
  }

  Future<void> pickImages(WizardFormBloc wizardFormBloc) async {
    List<Asset> resultList = [];

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
        enableCamera: true,
        selectedAssets: wizardFormBloc.images,
        materialOptions: MaterialOptions(
          actionBarTitle: "Pick 3 to 10 images",
        ),
      );
    } on Exception catch (e) {
      print(e);
    }

    setState(() {
      wizardFormBloc.images = resultList;
      images = resultList;
    });
  }

  Future<void> pickMapImage(WizardFormBloc wizardFormBloc) async {
    List<Asset> resultList = [];

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 1,
        enableCamera: true,
        selectedAssets: wizardFormBloc.map,
        materialOptions: MaterialOptions(
          actionBarTitle: "Pick 1 map image",
        ),
      );
    } on Exception catch (e) {
      print(e);
    }
    setState(() {
      wizardFormBloc.map = resultList;
      map = resultList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AddNewPlaceArguments args = ModalRoute.of(context).settings.arguments as AddNewPlaceArguments;

    return BlocProvider(
      create: (context) => WizardFormBloc(),
      child: Builder(
        builder: (context) {
          return Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar:
              AppBar(
                title: Hero(
                    child: Text("Add new place"),
                    tag:"addPlace"
                ),
                actions: <Widget>[
                  IconButton(
                      icon: Icon(_type == StepperType.horizontal
                          ? Icons.swap_vert
                          : Icons.swap_horiz),
                      onPressed: _toggleType)
                ],
              ),
              body: SafeArea(
                child: FormBlocListener<WizardFormBloc, String, String>(
                  onSubmitting: (context, state) => LoadingDialog.show(context),
                  onSuccess: (context, state) {
                    LoadingDialog.hide(context);

                    if (state.stepCompleted == state.lastStep) {
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => SuccessScreen(id:context.read<WizardFormBloc>().placeId )));
                    }
                  },
                  onFailure: (context, state) {
                    LoadingDialog.hide(context);
                  },
                  child: StepperFormBlocBuilder<WizardFormBloc>(
                    formBloc: context.read<WizardFormBloc>(),
                    type: _type,
                    physics: ClampingScrollPhysics(),
                    stepsBuilder: (formBloc) {
                      return [
                        _locationStep(formBloc,args.latLng),
                        _photosStep(formBloc),
                        _mapStep(formBloc),
                      ];
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  FormBlocStep _locationStep(WizardFormBloc wizardFormBloc, LatLng latLng) {
    wizardFormBloc.latitude.updateValue(latLng.latitude.toString());
    wizardFormBloc.longitude.updateValue(latLng.longitude.toString());

    return FormBlocStep(
      title: Text('Confirm Location'),
      content: Column(
        children: <Widget>[
          TextFieldBlocBuilder(
            textFieldBloc: wizardFormBloc.latitude,
            keyboardType: TextInputType.numberWithOptions(decimal: true,signed: true),
            enableOnlyWhenFormBlocCanSubmit: true,
            decoration: InputDecoration(
              labelText: 'Latitude',
              prefixIcon: Icon(Icons.edit_location_outlined),
            ),
          ),
          TextFieldBlocBuilder(
            textFieldBloc: wizardFormBloc.longitude,
            keyboardType: TextInputType.numberWithOptions(decimal: true,signed: true),
            decoration: InputDecoration(
              labelText: 'Longitude',
              prefixIcon: Icon(Icons.edit_location_sharp),
            ),
          ),
          TextFieldBlocBuilder(
            textFieldBloc: wizardFormBloc.nameOfPlace,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              labelText: 'Name of Place',
              prefixIcon: Icon(Icons.edit_attributes),
            ),
          ),
        ],
      ),
    );
  }

  FormBlocStep _photosStep(WizardFormBloc wizardFormBloc) {
    return FormBlocStep(
      title: Text('Add location Photos'),
      content: Column(
        children: <Widget>[
          ElevatedButton.icon(
            icon: Icon(Icons.photo),
            label: Text("Pick images"),
            onPressed: ()=>pickImages(wizardFormBloc),
          ),
          SizedBox(
            height: 250,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              children: List.generate(images.length, (index) {
                Asset asset = images[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onLongPress: (){
                      setState(() {
                        images.removeAt(index);
                      });
                    },
                    child: AssetThumb(
                      asset: asset,
                      width: 500,
                      height: 500,
                    ),
                  ),
                );
              }),
            ),
          ),
          Text("Long press the Thumbnail to remove selection..."),
          TextFieldBlocBuilder(
            textFieldBloc: wizardFormBloc.photoList,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              labelText: 'Enter Uploader\'s name',
              prefixIcon: Icon(Icons.edit_location_outlined),
            ),
          ),
        ],
      ),
    );
  }

  FormBlocStep _mapStep(WizardFormBloc wizardFormBloc) {
    return FormBlocStep(
      title: Text('Add map photos'),
      content: Column(
        children: <Widget>[
          ElevatedButton.icon(
            icon: Icon(Icons.photo),
            label: Text("Pick map image"),
            onPressed: (){
              pickMapImage(wizardFormBloc);
              },
          ),
          SizedBox(
            height: 500,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 1,
              children: List.generate(map.length, (index) {
                Asset asset = map[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onLongPress: (){
                      setState(() {
                        map.removeAt(index);
                      });
                    },
                    child: AssetThumb(
                      asset: asset,
                      width: 500,
                      height: 500,
                    ),
                  ),
                );
              }),
            ),
          ),
          Text("Long press the Thumbnail to remove selection..."),
          TextFieldBlocBuilder(
            textFieldBloc: wizardFormBloc.mapPhoto,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              labelText: 'Enter Uploader\'s name',
              prefixIcon: Icon(Icons.edit_location_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  static void show(BuildContext context, {Key key}) => showDialog<void>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: false,
    builder: (_) => LoadingDialog(key: key),
  ).then((_) => FocusScope.of(context).requestFocus(FocusNode()));

  static void hide(BuildContext context) => Navigator.pop(context);

  LoadingDialog({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: Card(
          child: Container(
            width: 80,
            height: 80,
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  String id;
  SuccessScreen({Key key, this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.tag_faces, size: 100),
            SizedBox(height: 10),
            Text(
              'Success',
              style: TextStyle(fontSize: 54, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            RaisedButton.icon(
              onPressed: () =>Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationCalibration(id: id)),
              ),
              icon: Icon(Icons.replay),
              label: Text('Start Caliberating'),
            ),
          ],
        ),
      ),
    );
  }
}

