import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/screens/forgot_password_screen.dart';
import 'package:dixa_user/screens/main_screen.dart';
import 'package:dixa_user/screens/register_screen.dart';
import 'package:dixa_user/splashScreen/splash_screen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await firebaseAuth
          .signInWithEmailAndPassword(
              email: emailTextEditingController.text.trim(),
              password: passwordTextEditingController.text.trim())
          .then((auth) async {
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref().child('users');
        userRef.child(firebaseAuth.currentUser!.uid).once().then((value) async {
          final snap = value.snapshot;
          if (snap.value != null) {
            currentUser = auth.user;
            await Fluttertoast.showToast(msg: "Successfully Logged in");
            Navigator.push(
                context, MaterialPageRoute(builder: (c) => MainScreen()));
          } else {
            await Fluttertoast.showToast(
                msg: "No record exist with this email");
            firebaseAuth.signOut();
            Navigator.push(
                context, MaterialPageRoute(builder: (c) => SplashScreen()));
          }
        });
      }).catchError((errorMessage) {
        Fluttertoast.showToast(msg: "Error occured: \n $errorMessage");
      });
    } else {
      Fluttertoast.showToast(msg: "Not all field are valid");
    }
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
          body: ListView(
            padding: EdgeInsets.all(0),
            children: [
              Column(
                children: [
                  Image.asset(
                      darkTheme ? "images/city_dark.jpg" : "images/city.jpg"),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Đăng nhập",
                    style: TextStyle(
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 20, 15, 50),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                ),
                                TextFormField(
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(50)
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Email",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: darkTheme
                                          ? Colors.black45
                                          : Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                            width: 0,
                                            style: BorderStyle.none,
                                          )),
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: darkTheme
                                            ? Colors.amber.shade400
                                            : Colors.grey,
                                      )),
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (text) {
                                    if (text == null || text.isEmpty) {
                                      return 'Email không được để trống';
                                    }
                                    if (EmailValidator.validate(text) != true) {
                                      return "Vui lòng nhập email hợp lệ";
                                    }
                                    if (text.length > 50) {
                                      return "Email không được nhiều hơn 50";
                                    }
                                  },
                                  onChanged: (text) => setState(() {
                                    emailTextEditingController.text = text;
                                  }),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                TextFormField(
                                  obscureText: !_passwordVisible,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(50)
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Mật khẩu",
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: darkTheme
                                          ? Colors.black45
                                          : Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                            width: 0,
                                            style: BorderStyle.none,
                                          )),
                                      prefixIcon: Icon(
                                        Icons.password,
                                        color: darkTheme
                                            ? Colors.amber.shade400
                                            : Colors.grey,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _passwordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: darkTheme
                                              ? Colors.amber.shade400
                                              : Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _passwordVisible =
                                                !_passwordVisible;
                                          });
                                        },
                                      )),
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (text) {
                                    if (text == null || text.isEmpty) {
                                      return 'Mật khẩu không được để trống';
                                    }
                                    if (text.length < 6) {
                                      return "Vui lòng nhập mật khẩu hợp lệ";
                                    }
                                    if (text.length > 50) {
                                      return "Mật khẩu không được nhiều hơn 50";
                                    }
                                    return null;
                                  },
                                  onChanged: (text) => setState(() {
                                    passwordTextEditingController.text = text;
                                  }),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        primary: darkTheme
                                            ? Colors.amber.shade400
                                            : Colors.blue,
                                        onPrimary: darkTheme
                                            ? Colors.black
                                            : Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32),
                                        ),
                                        minimumSize: Size(double.infinity, 50)),
                                    onPressed: () {
                                      _submit();
                                    },
                                    child: Text(
                                      'Đăng nhập',
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    )),
                                SizedBox(
                                  height: 20,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (c) =>
                                                ForgotPasswordScreen()));
                                  },
                                  child: Text(
                                    'Quên mật khẩu',
                                    style: TextStyle(
                                      color: darkTheme
                                          ? Colors.amber.shade400
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Không có tài khoản?",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (c) =>
                                                    RegisterScreen()));
                                      },
                                      child: Text(
                                        "Đăng ký",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: darkTheme
                                              ? Colors.amber.shade400
                                              : Colors.blue,
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ]),
                  )
                ],
              )
            ],
          ),
        ));
  }
}
