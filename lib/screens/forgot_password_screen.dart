import 'package:dixa_user/global/global.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailTextEditingController = TextEditingController();

  void _submit() async {
    firebaseAuth
        .sendPasswordResetEmail(email: emailTextEditingController.text.trim())
        .then((value) {
      Fluttertoast.showToast(
          msg: "We have sent an email to recover password, please check email");
    }).onError((error, stackTrace) {
      Fluttertoast.showToast(msg: "Error Occured: \n ${error.toString()}");
    });
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
                    "Forgot Password Screen",
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
                                      return 'Email can\'t be empty';
                                    }
                                    if (EmailValidator.validate(text) != true) {
                                      return "Please enter a valid email";
                                    }
                                    if (text.length > 50) {
                                      return "Email can\'t be more than 50";
                                    }
                                  },
                                  onChanged: (text) => setState(() {
                                    emailTextEditingController.text = text;
                                  }),
                                ),
                                SizedBox(
                                  height: 20,
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
                                      'Reset Password',
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    )),
                                SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Doesn't have an account?",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        "Register",
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
