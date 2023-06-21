import 'dart:convert';

import 'package:http/http.dart' as http;

class RequestAssistant {
  static Future<dynamic> receiveRequest(String url) async {
    http.Response httpResponse = await http.get(Uri.parse(url));

    try {
      if (httpResponse.statusCode == 200) {
        String reponseData = httpResponse.body;
        var decodeResponseData = jsonDecode(reponseData);

        return decodeResponseData;
      } else {
        return "Error Occured. Failde. No Response.";
      }
    } catch (exp) {
      return "Error Occured. Failde. No Response.";
    }
  }
}
