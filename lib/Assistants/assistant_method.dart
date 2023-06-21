import 'dart:convert';
import 'dart:ffi';

import 'package:dixa_user/Assistants/map_key.dart';
import 'package:dixa_user/Assistants/request_assistant.dart';
import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/infoHandler/app_info.dart';
import 'package:dixa_user/models/directions.dart';
import 'package:dixa_user/models/directions_details_info.dart';
import 'package:dixa_user/models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class AssitantMethods {
  static void readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref().child("users").child(currentUser!.uid);

    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  static Future<String> searchAddressForGeographicCoOrdinates(
      Position position, context) async {
    String apiUrl =
        "https://rsapi.goong.io/Geocode?latlng=${position.latitude},${position.longitude}&api_key=$mapgoongkey";
    // "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";
    print(apiUrl);
    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);
    if (requestResponse != "Error Occured. Failde. No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];
      print(humanReadableAddress + " ssssssssssssss");
      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locaitonName = humanReadableAddress;

      Provider.of<AppInfo>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }
    return humanReadableAddress;
  }

  static Future<String> searchAddressForPickUpAddress(
      latitude, longtitude, context) async {
    String apiUrl =
        "https://rsapi.goong.io/Geocode?latlng=${latitude},${longtitude}&api_key=$mapgoongkey";
    // "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";
    print(apiUrl);
    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);
    if (requestResponse != "Error Occured. Failde. No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];
    }
    return humanReadableAddress;
  }

  static Future<DirectionDetailsInfo> obtainOriginToDestinationDirectionDetails(
      LatLng originPosition, LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails =
        "https://rsapi.goong.io/Direction?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&vehicle=hd&api_key=$mapgoongkey";
    // "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    var responseDirectionApi = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionDetails);
    if (responseDirectionApi == "Error Occured. Failde. No Response.") {
      return DirectionDetailsInfo();
    }

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.e_points =
        responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    directionDetailsInfo.distance_text =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];

    directionDetailsInfo.distance_value =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];

    directionDetailsInfo.duration_text =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.duration_value =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];
    return directionDetailsInfo;
  }

  static double caculateFareAmountFromOriginToDestination(
      DirectionDetailsInfo directionDetailsInfo) {
    double timeTravelledFareAmountPerMinute =
        (directionDetailsInfo.duration_value! / 60) * 0.1;

    double distanceTraveledFareAmountPerKilometer =
        (directionDetailsInfo.distance_value! / 1000) * 0.1;

    double totalFareAmount = (timeTravelledFareAmountPerMinute +
            distanceTraveledFareAmountPerKilometer) *
        22000;
    return double.parse(totalFareAmount.toStringAsFixed(1));
  }

  static sendNotificationToDriverNow(
      String deviveRegistrationToken, String userRideRequestId, context) async {
    String destinationAddress = userDropOffAddress;
    Map<String, String> headerNotificaiton = {
      'Content-type': 'application/json',
      'Authorization': cloudMessagingServerToken,
    };

    Map bodyNotification = {
      "body": "Destination Address: \n$destinationAddress.",
      "title": "New Trip Request"
    };

    Map dataMap = {
      "click_action": "Flutter_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "rideRequestId": userRideRequestId
    };
    Map officialNotificationFormat = {
      "notification": bodyNotification,
      "data": dataMap,
      "priority": "high",
      "to": deviveRegistrationToken,
    };
    var responseNotification = http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headerNotificaiton,
      body: jsonEncode(officialNotificationFormat),
    );
    print(responseNotification.toString());
  }
}
