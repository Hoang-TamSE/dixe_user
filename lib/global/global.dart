// import 'package:dixa_app_users/models/user_model.dart';
import 'package:dixa_user/models/directions_details_info.dart';
import 'package:dixa_user/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

List driversList = [];

String userDropOffAddress = "";

DirectionDetailsInfo? tripDirectionDetailsInfo;

String driverMotobikeDetails = "";
String driverName = "";
String driverPhone = "";

double countRatingStars = 0.0;
String titleStarsRating = "";

String cloudMessagingServerToken =
    "key=AAAAOkG887s:APA91bHqjJXy4odrDqZJSxr7Hke-0tCxuHmwhEsiEdBC8PN6gmkmEDG7hDekKtwQSsbVTA_GsCRPMLWCPZP62B5hiDeF7F7vnwLFs0tt__vvii6SkJPphrr6X3Rh68PLvZCFDrPUoq1D";
