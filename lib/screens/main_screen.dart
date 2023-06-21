import 'dart:async';

import 'package:dixa_user/Assistants/assistant_method.dart';
import 'package:dixa_user/Assistants/geofire_assistant.dart';
import 'package:dixa_user/Assistants/map_key.dart';
import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/infoHandler/app_info.dart';
import 'package:dixa_user/models/active_nearby_available_drivers.dart';
import 'package:dixa_user/models/directions.dart';
import 'package:dixa_user/screens/drawer_screen.dart';
import 'package:dixa_user/screens/precise_pickup_location.dart';
import 'package:dixa_user/screens/search_places_screen.dart';
import 'package:dixa_user/splashScreen/splash_screen.dart';
import 'package:dixa_user/widgets/pay_fare_amout.dart';
import 'package:dixa_user/widgets/progress_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _makePhoneCall(String url) async{
  if(await canLaunch(url)) {
    await launch(url);
  }else {
    throw "Could not lauch ${url}";
  }
}
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
  double suggesteddRidesContainerHeight = 0;
  double searchingForDriverContainerHeight = 0;

  Position? userCurrentPostion;
  var geoLcation = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  DatabaseReference? referenceRideRequest;

  List<LatLng> pLineCoordinatedList = [];
  Set<Polyline> polyLineSet = {};

  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};

  String userName = "";
  String userEmail = "";

  bool openNavigationDrawer = true;
  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  String selectedVehicleType = "";

  String driverRideStatus = "Driver is coming";
  StreamSubscription<DatabaseEvent>? tripRidesRequestInfoStreamSubscription;

  List<ActiveNearByAvailableDrivers> onlineNearByAvailablerDriversList = [];
  String userRideQuestStatus = "";

  bool requestPositionInfo = true;
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

    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

    initializeGeoFireListener();

    // AssitantMethods.readTripsKeysForOnlineUser(content)
  }

  initializeGeoFireListener() {
    Geofire.initialize("activeDrivers");

    Geofire.queryAtLocation(
            userCurrentPostion!.latitude, userCurrentPostion!.longitude, 10)!
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map["callBack"];

        switch (callBack) {
          case Geofire.onKeyEntered:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers =
                ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude = map["longitude"];
            activeNearByAvailableDrivers.driverId = map["key"];
            GeoFireAssistant.activeNearByAvailableDriversList
                .add(activeNearByAvailableDrivers);
            if (activeNearbyDriverKeysLoaded == true) {
              displayActiveDriverOnUsersMap();
            }
            break;
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOffLineDriverFromList(map["key"]);
            displayActiveDriverOnUsersMap();
            break;
          case Geofire.onKeyMoved:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers =
                ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude = map["longitude"];
            activeNearByAvailableDrivers.driverId = map["key"];
            GeoFireAssistant.updateActiveNearByAvailableDriverLocation(
                activeNearByAvailableDrivers);
            displayActiveDriverOnUsersMap();
            break;
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            displayActiveDriverOnUsersMap();
            break;
        }
      }
      setState(() {});
    });
  }

  displayActiveDriverOnUsersMap() {
    setState(() {
      markerSet.clear();
      circleSet.clear();

      Set<Marker> driversMarkerSet = Set<Marker>();

      for (ActiveNearByAvailableDrivers eachDriver
          in GeoFireAssistant.activeNearByAvailableDriversList) {
        LatLng eachDriverActivePosition =
            LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );
        driversMarkerSet.add(marker);
      }

      setState(() {
        markerSet = driversMarkerSet;
      });
    });
  }

  createActiveNearByDriverIconMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, "images/motorcycle-icon_1.png")
          .then((value) {
        activeNearbyIcon = value;
      });
    }
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

  void showSuggestedRidersContanier() {
    setState(() {
      suggesteddRidesContainerHeight = 400;
      bottomPaddingOfMap = 400;
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

  saveRideRequestInformation(String selectedVehicleType) {
    referenceRideRequest =
        FirebaseDatabase.instance.ref().child("ALl Ride Requests").push();

    var originLocation =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation!.locationLongitude.toString(),
    };
    Map destinationLocationMap = {
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation!.locationLongitude.toString(),
    };

    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locaitonName,
      "destinationAddress": destinationLocation.locaitonName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);

    tripRidesRequestInfoStreamSubscription =
        referenceRideRequest!.onValue.listen((eventSnap) async {
      if (eventSnap.snapshot.value == null) {
        return;
      }
      if ((eventSnap.snapshot.value as Map)["motobi_details"] != null) {
        setState(() {
          driverMotobikeDetails =
              (eventSnap.snapshot.value as Map)["motobi_details"].toString();
        });
      }
      if ((eventSnap.snapshot.value as Map)["driverPhone"] != null) {
        setState(() {
          driverPhone = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }
      if ((eventSnap.snapshot.value as Map)["driverName"] != null) {
        setState(() {
          driverName = (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }
      if ((eventSnap.snapshot.value as Map)["newRideStatus"] != null) {
        setState(() {
          userRideQuestStatus =
              (eventSnap.snapshot.value as Map)["newRideStatus"].toString();
        });
      }
      if ((eventSnap.snapshot.value as Map)["driverlocation"] != null) {
        double driverCurrentPositionLat = double.parse(
            (eventSnap.snapshot.value as Map)["driverLocation"]["latitude"]
                .toString());
        double driverCurrentPositionLng = double.parse(
            (eventSnap.snapshot.value as Map)["driverLocation"]["longitude"]
                .toString());

        LatLng driverCurrentPositionLatLng =
            LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        if (userRideQuestStatus == "accepted") {
          updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
        }
        if (userRideQuestStatus == "arrived") {
          setState(() {
            driverRideStatus = "Driver has arrived";
          });
        }

        if (userRideQuestStatus == "ontrip") {
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }
        if (userRideQuestStatus == "ended") {
          if ((eventSnap.snapshot.value as Map)["fareAmount"] != null) {
            double fareAmount = double.parse(
                (eventSnap.snapshot.value as Map)["fareAmount"].toString());
            var response = await showDialog(
                context: context,
                builder: (BuildContext context) => PayFareAmountDialog(
                      fareAmount: fareAmount,
                    ));
            if (response == "Cash Paid") {
              if ((eventSnap.snapshot.value as Map)["driverId"] != null) {
                String assignedDriverId =
                    (eventSnap.snapshot.value as Map)["driverId"].toString();
                // Navigator.push(context,
                //     MaterialPageRoute(builder: (c) => RateDriverScreen()));

                referenceRideRequest!.onDisconnect();
                tripRidesRequestInfoStreamSubscription!.cancel();
              }
            }
          }
        }
      }
    });
    onlineNearByAvailablerDriversList =
        GeoFireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);
  }

  searchNearestOnlineDrivers(String selectedVehicleType) async {
    if (onlineNearByAvailablerDriversList.length == 0) {
      referenceRideRequest!.remove();
      setState(() {
        polyLineSet.clear();
        markerSet.clear();
        circleSet.clear();
        pLineCoordinatedList.clear();
      });
      Fluttertoast.showToast(msg: "No online nearest Driver Available");
      Fluttertoast.showToast(msg: "Search Again. \n Restrating App");

      Future.delayed(Duration(milliseconds: 4000), () {
        referenceRideRequest!.remove();
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => SplashScreen()));
      });
      return;
    }
    await retrieveOnlineDriversInformation(onlineNearByAvailablerDriversList);

    print("Driver List: " + driversList.toString());

    for (var i = 0; i < driversList.length; i++) {
      if (driversList[i]["motobike_details"]["type"] == selectedVehicleType) {
        AssitantMethods.sendNotificationToDriverNow(
            driversList[i]["token"], referenceRideRequest!.key!, context);
      }
    }
    Fluttertoast.showToast(msg: "Notification sent Successfully");

    showSearchingForDriversContainer();

    await FirebaseDatabase.instance
        .ref()
        .child("ALl Ride Request")
        .child(referenceRideRequest!.key!)
        .child("driverId")
        .onValue
        .listen((eventRideRequestSnapshot) {
      print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
      if (eventRideRequestSnapshot.snapshot.value == null) {
        if (eventRideRequestSnapshot.snapshot.value != "waiting") {
          showUIForAssignedDriverInfo();
        }
      }
    });
  }

  void showSearchingForDriversContainer() {
    setState(() {
      searchingForDriverContainerHeight = 200;
    });
  }

  showUIForAssignedDriverInfo() {
    setState(() {
      waitingResponseFromDriverContainerHeight = 0;
      searchLocationContainerHeight = 0;
      asignedDriverInfoContainerHeight = 300;
      suggesteddRidesContainerHeight = 0;
      bottomPaddingOfMap = 200;
    });
  }

  updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng) async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;
      LatLng userPickUpPosition =
          LatLng(userCurrentPostion!.latitude, userCurrentPostion!.longitude);
      var directionDetailsInfo =
          await AssitantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        userPickUpPosition,
      );
      if (directionDetailsInfo == null) {
        return;
      }
      setState(() {
        driverRideStatus = "Driver is coming: " +
            directionDetailsInfo.distance_text.toString();
      });
      requestPositionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;
      var dropOffLocation =
          Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
          dropOffLocation!.locationLatitude!,
          dropOffLocation.locationLongitude!);
      var directionDetailsInfo =
          await AssitantMethods.obtainOriginToDestinationDirectionDetails(
              driverCurrentPositionLatLng, userDestinationPosition);
      if (directionDetailsInfo == null) {
        return;
      }
      setState(() {
        driverRideStatus = "Going Towards Destination: " +
            directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }
  }

  retrieveOnlineDriversInformation(
      List onlineNearByAvailablerDriversList) async {
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");

    for (int i = 0; i < onlineNearByAvailablerDriversList.length; i++) {
      await ref
          .child(onlineNearByAvailablerDriversList[i].driverId.toString())
          .once()
          .then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;
        driversList.add(driverKeyInfo);
        print("driver key information = " + driversList.toString());
      });
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
    createActiveNearByDriverIconMarker();
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
                padding: EdgeInsets.fromLTRB(10, 50, 10, 10),
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
                                      "From",
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
                                          : "Not Getting Address",
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
                                        "From",
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
                                            : "Where to?",
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
                              "Change Pick Up Address",
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
                            onPressed: () {
                              if (Provider.of<AppInfo>(context, listen: false)
                                      .userDropOffLocation !=
                                  null) {
                                showSuggestedRidersContanier();
                              } else {
                                Fluttertoast.showToast(
                                    msg: "Please select destination location");
                              }
                            },
                            child: Text(
                              "Show Fare",
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

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: suggesteddRidesContainerHeight,
                decoration: BoxDecoration(
                    color: darkTheme ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    )),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: darkTheme
                                        ? Colors.amber.shade400
                                        : Colors.blue,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
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
                                      : "Not Getting Address",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Text(
                                  Provider.of<AppInfo>(context)
                                              .userDropOffLocation !=
                                          null
                                      ? Provider.of<AppInfo>(context)
                                          .userDropOffLocation!
                                          .locaitonName!
                                      : "Where to?",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "SUGGESTED RIDES",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "motobike";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "motobike"
                                    ? (darkTheme
                                        ? Colors.amber.shade400
                                        : Colors.blue)
                                    : (darkTheme
                                        ? Colors.black54
                                        : Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(15.0),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      "images/motorcycle-icon_1.png",
                                      scale: 2,
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      "Motobike",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "motobike"
                                            ? (darkTheme
                                                ? Colors.black
                                                : Colors.white)
                                            : (darkTheme
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      tripDirectionDetailsInfo != null
                                          ? "VND ${AssitantMethods.caculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!)}"
                                          : "null",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          if (selectedVehicleType != "") {
                            saveRideRequestInformation(selectedVehicleType);
                          } else {
                            Fluttertoast.showToast(
                                msg:
                                    "Please selecte a vehicle from \n suggested rides.");
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: darkTheme
                                  ? Colors.amber.shade400
                                  : Colors.blue,
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Text(
                              "Request a Ride",
                              style: TextStyle(
                                  color:
                                      darkTheme ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                  height: searchingForDriverContainerHeight,
                  decoration: BoxDecoration(
                    color: darkTheme ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15)),
                  ),
                  child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LinearProgressIndicator(
                            color:
                                darkTheme ? Colors.amber.shade400 : Colors.blue,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Center(
                            child: Text(
                              "Searching for a driver",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                            onTap: () {
                              referenceRideRequest!.remove();
                              setState(() {
                                searchingForDriverContainerHeight = 0;
                                suggesteddRidesContainerHeight = 0;
                              });
                            },
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: darkTheme ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border:
                                    Border.all(width: 1, color: Colors.grey),
                              ),
                              child: Icon(Icons.close, size: 25),
                            ),
                          ),
                          SizedBox(height: 15),
                          Container(
                            width: double.infinity,
                            child: Text(
                              "Cancel",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                  ),
              ),
            ),

            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: asignedDriverInfoContainerHeight,
                  decoration: BoxDecoration(
                    color: darkTheme ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(driverRideStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        SizedBox(height: 5),
                        Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: darkTheme ? Colors.amber.shade400 : Colors.lightBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.person, color: darkTheme ? Colors.black : Colors.white),
                                ),

                                SizedBox(width: 10,),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(driverName, style: TextStyle(fontWeight: FontWeight.bold),),

                                    Row(children: [
                                      Icon(Icons.start, color: Colors.orange),
                                      SizedBox(width: 5,),
                                      Text("4.5",
                                      style: TextStyle(
                                        color: Colors.grey
                                      )
                                        ,)
                                    ],)
                                  ],
                                ),

                              ],

                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Image.asset("images/motorcycle-icon_1.png", scale: 3,),
                                Text(driverMotobikeDetails, style: TextStyle(
                                  fontSize: 12,
                                ),
                                ),
                              ],
                            )

                          ],

                        ),


                        SizedBox(height: 5,),
                        Divider(
                          thickness: 1,
                          color: darkTheme ? Colors.grey : Colors.grey[300],
                        ),
                        ElevatedButton.icon(
                            onPressed: (){
                              _makePhoneCall("tell: ${driverPhone}");
                            },
                            icon: Icon(Icons.phone),
                            style: ElevatedButton.styleFrom(
                              primary: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            ),
                            label: Text("Call Driver")
                        ),
                      ],
                    )
                  ),
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
