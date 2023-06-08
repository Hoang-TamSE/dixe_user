import 'package:dixa_user/Assistants/map_key.dart';
import 'package:dixa_user/Assistants/request_assistant.dart';
import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/infoHandler/app_info.dart';
import 'package:dixa_user/models/directions.dart';
import 'package:dixa_user/models/predicted_places.dart';
import 'package:dixa_user/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlacePredictionTitleDesign extends StatefulWidget {
  final PredictedPlaces? predictedPlaces;

  PlacePredictionTitleDesign({this.predictedPlaces});

  @override
  State<PlacePredictionTitleDesign> createState() =>
      _PlacePredictionTitleDesignState();
}

class _PlacePredictionTitleDesignState
    extends State<PlacePredictionTitleDesign> {
  getPlaceDirectionDetails(String? placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Setting up Drop-off, Please wait ...",
            ));
    String placeDirectionDetailsUrl =
    "https://rsapi.goong.io/geocode?place_id=$placeId&api_key=OFZ9O8Z3VMBj7mYuwxWzmTGgR3QruDWLd4B3FiEq";
        // "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";
    var responseApi =
        await RequestAssistant.receiveRequest(placeDirectionDetailsUrl);
    Navigator.pop(context);

    if (responseApi == "Error Occured. Failde. No Response.") {
      return;
    }
    if (responseApi["status"] == "OK") {
      print(placeDirectionDetailsUrl +
          "          aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
      Directions directions = Directions();
      directions.locaitonName = responseApi["results"][0]["name"];
      directions.locationId = placeId;
      directions.locationLatitude =
          responseApi["results"][0]["geometry"]["location"]["lat"];
      directions.locationLongitude =
          responseApi["results"][0]["geometry"]["location"]["lng"];

      Provider.of<AppInfo>(context, listen: false)
          .updateDropOffLocationAddress(directions);
      setState(() {
        userDropOffAddress = directions.locaitonName!;
      });
      Navigator.pop(context, "obtainedDropoff");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return ElevatedButton(
        onPressed: () {
          getPlaceDirectionDetails(widget.predictedPlaces!.place_id, context);
        },
        style: ElevatedButton.styleFrom(
          primary: darkTheme ? Colors.black : Colors.white,
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(
                Icons.add_location,
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.predictedPlaces!.main_text!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                  ),
                  Text(
                    widget.predictedPlaces!.secondary_text!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                  ),
                ],
              ))
            ],
          ),
        ));
  }
}
