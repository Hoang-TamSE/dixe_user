import 'dart:async';

import 'package:dixa_user/Assistants/assistant_method.dart';
import 'package:dixa_user/Assistants/map_key.dart';
import 'package:dixa_user/infoHandler/app_info.dart';
import 'package:dixa_user/models/directions.dart';
import 'package:flutter/material.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class PrecisePickUpScreen extends StatefulWidget {
  const PrecisePickUpScreen({Key? key}) : super(key: key);

  @override
  State<PrecisePickUpScreen> createState() => _PrecisePickUpScreenState();
}
class _PrecisePickUpScreenState extends State<PrecisePickUpScreen> {
  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  locateUserPosition() async {
    Position cPostion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPostion = cPostion;

    LatLng latLngPosition =
        LatLng(userCurrentPostion!.latitude, userCurrentPostion!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 15);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress =
        await AssitantMethods.searchAddressForGeographicCoOrdinates(
            userCurrentPostion!, context);
  }

  getAddressFromLatLng() async {
    try {
      String humanReadableAddress = await AssitantMethods.searchAddressForPickUpAddress(pickLocation!.latitude, pickLocation!.longitude, context);
      // GeoData data = await Geocoder2.getDataFromCoordinates(
      //     latitude: pickLocation!.latitude,
      //     longitude: pickLocation!.longitude,
      //     googleMapApiKey: mapKey);

      setState(() {
        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLongitude = pickLocation!.longitude;
        userPickUpAddress.locationLatitude = pickLocation!.latitude;
        userPickUpAddress.locaitonName = humanReadableAddress;

        Provider.of<AppInfo>(context, listen: false)
            .updatePickUpLocationAddress(userPickUpAddress);
      });
    } catch (exp) {
      print(exp);
    }
  }

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  Position? userCurrentPostion;
  double bottomPaddingOfMap = 0;

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;
            setState(() {
              bottomPaddingOfMap = 50;
            });
            locateUserPosition();
          },
          onCameraMove: (CameraPosition? position) {
            if (pickLocation != position!.target) {
              setState(() {
                pickLocation = position.target;
              });
            }
          },
          onCameraIdle: () {
            getAddressFromLatLng();
          },
        ),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.only(top: 60,bottom: bottomPaddingOfMap),
            child: Image.asset(
              "images/pick.png",
              height: 45,
              width: 45,
            ),
          ),
        ),

        Positioned(
          top: 40,
          right: 20,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
            ),
            padding: EdgeInsets.all(20),
            child: Text(
              Provider.of<AppInfo>(context).userPickUpLocation != null
                  ? (Provider.of<AppInfo>(context)
                              .userPickUpLocation!
                              .locaitonName!)
                          .substring(0, 24) +
                      "..."
                  : "Không nhận được địa chỉ",
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: (){
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                primary: darkTheme ? Colors.amber.shade400 : Colors.blue,
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              child: Text("Đặt vị trí hiện tại"),
            ),
          ),
        )
      ]),
    );
  }
}
