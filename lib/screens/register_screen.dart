import 'dart:io';

import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/screens/login_screen.dart';
import 'package:dixa_user/screens/main_screen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameTextEditingController = TextEditingController();
  final emailTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();
  final confirmTextEditingController = TextEditingController();
  bool _passwordVisible = false;
  File? _imageAvatar;
  final imagePicker = ImagePicker();
  String? downloadURL;
  //declare a globalKey
  final _formKey = GlobalKey<FormState>();
  Future imagePickerMethod() async {
    final pick = await imagePicker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pick != null) {
        _imageAvatar = File(pick.path);
      } else {
        Fluttertoast.showToast(msg: "Không có tập tin được chọn");
      }
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await firebaseAuth
          .createUserWithEmailAndPassword(
              email: emailTextEditingController.text.trim(),
              password: passwordTextEditingController.text.trim())
          .then((auth) async {
        currentUser = auth.user;
        Reference ref =
            FirebaseStorage.instance.ref().child('${currentUser!.uid}/avatar');
        await ref.putFile(_imageAvatar!);
        downloadURL = await ref.getDownloadURL();

        if (currentUser != null) {
          Map userMap = {
            "id": currentUser!.uid,
            "name": nameTextEditingController.text.trim(),
            "email": emailTextEditingController.text.trim(),
            "address": addressTextEditingController.text.trim(),
            "phone": phoneTextEditingController.text.trim(),
            "avatar": downloadURL,
          };
          DatabaseReference userRef =
              FirebaseDatabase.instance.ref().child('users');
          userRef.child(currentUser!.uid).set(userMap);
        }
        await Fluttertoast.showToast(msg: "Đăng ký thành công");
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => MainScreen()));
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
        child: SafeArea(
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                Column(
                  children: [
                    Container(
                      child: _imageAvatar == null
                          ? Image.asset(
                              darkTheme
                                  ? 'images/city_dark.jpg'
                                  : 'images/city.jpg',
                              height: 350,
                              fit: BoxFit.cover,
                            )
                          : Image.file(_imageAvatar!),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Đăng ký",
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
                                  TextFormField(
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(50)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Tên đầy đủ",
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        filled: true,
                                        fillColor: darkTheme
                                            ? Colors.black45
                                            : Colors.grey.shade200,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            borderSide: const BorderSide(
                                              width: 0,
                                              style: BorderStyle.none,
                                            )),
                                        prefixIcon: Icon(
                                          Icons.person,
                                          color: darkTheme
                                              ? Colors.amber.shade400
                                              : Colors.grey,
                                        )),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (text) {
                                      if (text == null || text.isEmpty) {
                                        return 'Tên không được để trống';
                                      }
                                      if (text.length < 2) {
                                        return "Xin vui lòng nhập vào một tên hợp lệ";
                                      }
                                      if (text.length > 50) {
                                        return "Tên không được nhiều hơn 50";
                                      }
                                    },
                                    onChanged: (text) => setState(() {
                                      nameTextEditingController.text = text;
                                    }),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextFormField(
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(50)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Email",
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        filled: true,
                                        fillColor: darkTheme
                                            ? Colors.black45
                                            : Colors.grey.shade200,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            borderSide: const BorderSide(
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
                                      if (EmailValidator.validate(text) !=
                                          true) {
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
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  IntlPhoneField(
                                    showCountryFlag: false,
                                    dropdownIcon: Icon(
                                      Icons.arrow_drop_down,
                                      color: darkTheme
                                          ? Colors.amber.shade400
                                          : Colors.grey,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Số điện thoại",
                                      hintStyle: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: darkTheme
                                          ? Colors.black45
                                          : Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                          borderSide: const BorderSide(
                                            width: 0,
                                            style: BorderStyle.none,
                                          )),
                                    ),
                                    initialCountryCode: 'VN',
                                    disableLengthCheck: true,
                                    onChanged: (text) => setState(() {
                                      phoneTextEditingController.text =
                                          text.completeNumber;
                                    }),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextFormField(
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(50)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Địa chỉ",
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        filled: true,
                                        fillColor: darkTheme
                                            ? Colors.black45
                                            : Colors.grey.shade200,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            borderSide: const BorderSide(
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
                                        return 'Địa chỉ không được để trống';
                                      }
                                      if (text.length < 2) {
                                        return "Vui lòng nhập email hợp lệ";
                                      }
                                      if (text.length > 50) {
                                        return "Địa chỉ không được nhiều hơn 50";
                                      }
                                    },
                                    onChanged: (text) => setState(() {
                                      addressTextEditingController.text = text;
                                    }),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextFormField(
                                    obscureText: !_passwordVisible,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(50)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Mật khẩu",
                                        hintStyle: const TextStyle(
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
                                  TextFormField(
                                    obscureText: !_passwordVisible,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(50)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Xác nhận mật khẩu",
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
                                        return 'Xác nhận Mật khẩu không được để trống';
                                      }
                                      if (text !=
                                          passwordTextEditingController.text) {
                                        return "Mật khẩu không khớp";
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
                                      confirmTextEditingController.text = text;
                                    }),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      imagePickerMethod();
                                    },
                                    icon: Icon(Icons.camera_alt),
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
                                          minimumSize:
                                              Size(double.infinity, 50)),
                                      onPressed: () {
                                        _submit();
                                      },
                                      child: Text(
                                        'Đăng ký',
                                        style: TextStyle(
                                          fontSize: 20,
                                        ),
                                      )),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  GestureDetector(
                                    onTap: () {},
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
                                        "Có một tài khoản?",
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
                                                      LoginScreen()));
                                        },
                                        child: Text(
                                          "Đăng nhập",
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
          ),
        ));
  }
}
