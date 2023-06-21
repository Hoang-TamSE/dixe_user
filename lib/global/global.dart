// import 'package:dixa_app_users/models/user_model.dart';
import 'package:dixa_user/models/directions_details_info.dart';
import 'package:dixa_user/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

String userDropOffAddress = "";

DirectionDetailsInfo? tripDirectionDetailsInfo;
