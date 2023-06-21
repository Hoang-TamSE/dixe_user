import 'dart:async';

import 'package:dixa_user/Assistants/assistant_method.dart';
import 'package:dixa_user/Assistants/map_key.dart';
import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/infoHandler/app_info.dart';
import 'package:dixa_user/models/directions.dart';
import 'package:dixa_user/screens/drawer_screen.dart';
import 'package:dixa_user/screens/precise_pickup_location.dart';
import 'package:dixa_user/screens/search_places_screen.dart';
import 'package:dixa_user/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight = 220;
  double waitingResponseFromDriverContainerHeight = 0;
  double asignedDriverInfoContainerHeight = 0;

  Position? userCurrentPostion;
  var geoLcation = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoordinatedList = [];
  Set<Polyline> polyLineSet = {};

  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};

  String userName = "";
  String userEmail = "";

  bool openNavigationDrawer = true;
  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

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
    print("This our address = " + humanReadableAddress);

    userName = '${userModelCurrentInfo?.name}';
    userEmail = '${userModelCurrentInfo?.email}';

    // initializeGeoFireListener();

    // AssitantMethods.readTripsKeysForOnlineUser(content)
  }

  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async {
    var originPosition =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var origninLatLng = LatLng(
        originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,
        destinationPosition.locationLongitude!);
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: "Please wait...",
      ),
    );
    var directionDetailsInfo =
        await AssitantMethods.obtainOriginToDestinationDirectionDetails(
            origninLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResultsList =
        pPoints.decodePolyline(directionDetailsInfo.e_points!);

    if (decodePolyLinePointsResultsList.isNotEmpty) {
      decodePolyLinePointsResultsList.forEach((PointLatLng pointLatLng) {
        pLineCoordinatedList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme ? Colors.amberAccent : Colors.blue,
        polylineId: PolylineId("PolylineId"),
        jointType: JointType.round,
        points: pLineCoordinatedList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );
      polyLineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if (origninLatLng.latitude > destinationLatLng.latitude &&
        origninLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: origninLatLng);
    } else if (origninLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(origninLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, origninLatLng.longitude),
      );
    } else if (origninLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, origninLatLng.longitude),
        northeast: LatLng(origninLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng =
          LatLngBounds(southwest: origninLatLng, northeast: destinationLatLng);
    }

    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: MarkerId("originId"),
      infoWindow:
          InfoWindow(title: originPosition.locaitonName, snippet: "Origin"),
      position: origninLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker = Marker(
      markerId: MarkerId("destinationId"),
      infoWindow: InfoWindow(
          title: destinationPosition.locaitonName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      markerSet.add(originMarker);
      markerSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: CircleId("originId"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: origninLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: CircleId("destinationId"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circleSet.add(originCircle);
      circleSet.add(destinationCircle);
    });
  }

  // getAddressFromLatLng() async {
  //   try {
  //     GeoData data = await Geocoder2.getDataFromCoordinates(
  //         latitude: pickLocation!.latitude,
  //         longitude: pickLocation!.longitude,
  //         googleMapApiKey: mapKey);
  //
  //     setState(() {
  //       Directions userPickUpAddress = Directions();
  //       userPickUpAddress.locationLongitude = pickLocation!.longitude;
  //       userPickUpAddress.locationLatitude = pickLocation!.latitude;
  //       userPickUpAddress.locaitonName = data.address;
  //
  //       Provider.of<AppInfo>(context, listen: false)
  //           .updatePickUpLocationAddress(userPickUpAddress);
  //     });
  //   } catch (exp) {
  //     print(exp);
  //   }
  // }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: _scaffoldState,
        drawer: DrawerScreen(),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _kGooglePlex,
              polylines: polyLineSet,
              markers: markerSet,
              circles: circleSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;
                setState(() {});
                locateUserPosition();
              },
              // onCameraMove: (CameraPosition? position) {
              //   if (pickLocation != position!.target) {
              //     setState(() {
              //       pickLocation = position.target;
              //     });
              //   }
              // },
              // onCameraIdle: () {
              //   getAddressFromLatLng();
              // },
            ),
            // Align(
            //   alignment: Alignment.center,
            //   child: Padding(
            //     padding: const EdgeInsets.only(bottom: 35.0),
            //     child: Image.asset(
            //       "images/pick.png",
            //       height: 45,
            //       width: 45,
            //     ),
            //   ),
            // ),
            Positioned(
                top: 50,
                left: 20,
                child: Container(
                  child: GestureDetector(
                    onTap: () {
                      _scaffoldState.currentState!.openDrawer();
                    },
                    child: CircleAvatar(
                      backgroundColor:
                          darkTheme ? Colors.amber.shade400 : Colors.white,
                      child: Icon(
                        Icons.menu,
                        color: darkTheme ? Colors.black : Colors.lightBlue,
                      ),
                    ),
                  ),
                )),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
                child: Column(children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: darkTheme ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      Container(
                        decoration: BoxDecoration(
                          color: darkTheme
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(children: [
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: darkTheme
                                      ? Colors.amber.shade400
                                      : Colors.blue,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Vị trí bắt đầu",
                                      style: TextStyle(
                                          color: darkTheme
                                              ? Colors.amber.shade400
                                              : Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      Provider.of<AppInfo>(context)
                                                  .userPickUpLocation !=
                                              null
                                          ? (Provider.of<AppInfo>(context)
                                                      .userPickUpLocation!
                                                      .locaitonName!)
                                                  .substring(0, 24) +
                                              "..."
                                          : "Không nhận được địa chỉ",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Divider(
                            height: 1,
                            thickness: 2,
                            color:
                                darkTheme ? Colors.amber.shade400 : Colors.blue,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: GestureDetector(
                              onTap: () async {
                                var responseFromSearchScreen =
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (c) =>
                                                SearchPlacesScreen()));
                                if (responseFromSearchScreen ==
                                    "obtainedDropoff") {
                                  setState(() {
                                    openNavigationDrawer = false;
                                  });
                                }
                                await drawPolyLineFromOriginToDestination(
                                    darkTheme);
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: darkTheme
                                        ? Colors.amber.shade400
                                        : Colors.blue,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Điểm kiếm thúc",
                                        style: TextStyle(
                                            color: darkTheme
                                                ? Colors.amber.shade400
                                                : Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        Provider.of<AppInfo>(context)
                                                    .userDropOffLocation !=
                                                null
                                            ? Provider.of<AppInfo>(context)
                                                .userDropOffLocation!
                                                .locaitonName!
                                            : "đến đâu?",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ]),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => PrecisePickUpScreen()));
                            },
                            child: Text(
                              "Đặt xe",
                              style: TextStyle(
                                color: darkTheme ? Colors.black : Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                                primary: darkTheme
                                    ? Colors.amber.shade400
                                    : Colors.blue,
                                textStyle: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text(
                              "Yêu cầu một chuyến đi",
                              style: TextStyle(
                                color: darkTheme ? Colors.black : Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                                primary: darkTheme
                                    ? Colors.amber.shade400
                                    : Colors.blue,
                                textStyle: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      )
                    ]),
                  )
                ]),
              ),
            ),
            // Positioned(
            //   top: 40,
            //   right: 20,
            //   left: 20,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Colors.black),
            //       color: Colors.white,
            //     ),
            //     padding: EdgeInsets.all(20),
            //     child: Text(
            //       Provider.of<AppInfo>(context).userPickUpLocation != null
            //           ? (Provider.of<AppInfo>(context)
            //                       .userPickUpLocation!
            //                       .locaitonName!)
            //                   .substring(0, 24) +
            //               "..."
            //           : "Not Getting Address",
            //       overflow: TextOverflow.visible,
            //       softWrap: true,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
