import 'dart:io';

import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/screens/main_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  String? imageEdit;
  File? _showImageAvatar;
  final imagePicker = ImagePicker();

  DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users');

  @override
  void dispose() {
    // todo: implement dispose
    super.dispose();
  }

  Future<void> showUserNameDialogAlert(BuildContext context, String name) {
    nameTextEditingController.text = name;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Cập nhật"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: nameTextEditingController,
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Hủy",
                    style: TextStyle(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () {
                    userRef.child(firebaseAuth.currentUser!.uid).update({
                      "name": nameTextEditingController.text.trim(),
                    }).then((value) {
                      nameTextEditingController.clear();
                      Fluttertoast.showToast(
                          msg:
                              "Đã cập nhật thành công và Tải lại ứng dụng để xem các thay đổi");
                    }).catchError((errorMessage) {
                      Fluttertoast.showToast(
                          msg: "Error Occcured. \n $errorMessage");
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Sửa",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }

  Future<void> showUserPhoneDialogAlert(BuildContext context, String name) {
    phoneTextEditingController.text = name;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Cập nhật"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: phoneTextEditingController,
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Hủy",
                    style: TextStyle(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () {
                    userRef.child(firebaseAuth.currentUser!.uid).update({
                      "phone": phoneTextEditingController.text.trim(),
                    }).then((value) {
                      phoneTextEditingController.clear();
                      Fluttertoast.showToast(
                          msg:
                              "Cập nhật thành công. Tải lại ứng dụng để xem các thay đổi");
                    }).catchError((errorMessage) {
                      Fluttertoast.showToast(
                          msg: "Error Occcured. \n $errorMessage");
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Sửa",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }

  Future<void> showUserAddressDialogAlert(BuildContext context, String name) {
    addressTextEditingController.text = name;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Cập nhật"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: addressTextEditingController,
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Hủy",
                    style: TextStyle(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () {
                    userRef.child(firebaseAuth.currentUser!.uid).update({
                      "address": addressTextEditingController.text.trim(),
                    }).then((value) {
                      addressTextEditingController.clear();
                      Fluttertoast.showToast(
                          msg:
                              "Cập nhật thành công. Tải lại ứng dụng để xem các thay đổi");
                    }).catchError((errorMessage) {
                      Fluttertoast.showToast(
                          msg: "Error Occcured. \n $errorMessage");
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Sửa",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }

  Future<void> showImageDialogAlert(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Cập nhật"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    child: _showImageAvatar == null
                        ? Text("Không có hình ảnh")
                        : Image.file(_showImageAvatar!),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Hủy",
                    style: TextStyle(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () {
                    _submit();
                  },
                  child: Text(
                    "Sửa",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }

  Future imagePickerMethod() async {
    final pick = await imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pick != null) {
        _showImageAvatar = File(pick.path);
      } else {
        Fluttertoast.showToast(msg: "Không có tập tin được chọn");
      }
    }
    );
  }

  void _submit() async {
    Reference referenceImageToUpload = FirebaseStorage.instance.refFromURL(
        'gs://dixa-app-47a21.appspot.com/${userModelCurrentInfo!.id!}/avatar');
    try {
      await referenceImageToUpload.putFile(_showImageAvatar!);
      imageEdit = await referenceImageToUpload.getDownloadURL();
    } catch (error) {}

    userRef.child(firebaseAuth.currentUser!.uid).update({
      "avatar": imageEdit,
    }).then((value) {
      Fluttertoast.showToast(msg: "Updated Successfully.");
    }).catchError((errorMessage) {
      Fluttertoast.showToast(msg: "Error Occcured. \n $errorMessage");
    });
    userModelCurrentInfo?.avatar = imageEdit;
    _showImageAvatar = null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
          title: Text(
            "Thông tin cá nhân",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: userModelCurrentInfo == null
                      ? Icon(
                          Icons.person,
                          color: Colors.white,
                        )
                      : CircleAvatar(
                          backgroundImage:
                              NetworkImage('${userModelCurrentInfo?.avatar}'),
                          radius: 100,
                        ),
                ),
                IconButton(
                    onPressed: () {
                      showImageDialogAlert(context);
                    },
                    icon: Icon(Icons.camera_alt)),
                SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.name!}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showUserNameDialogAlert(
                            context, userModelCurrentInfo!.name!);
                      },
                      icon: Icon(
                        Icons.edit,
                      ),
                    ),
                  ],
                ),
                Divider(
                  thickness: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.phone!}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showUserPhoneDialogAlert(
                            context, userModelCurrentInfo!.phone!);
                      },
                      icon: Icon(
                        Icons.edit,
                      ),
                    ),
                  ],
                ),
                Divider(
                  thickness: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.address!}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showUserAddressDialogAlert(
                            context, userModelCurrentInfo!.address!);
                      },
                      icon: Icon(
                        Icons.edit,
                      ),
                    ),
                  ],
                ),
                Divider(
                  thickness: 1,
                ),
                Text(
                  "${userModelCurrentInfo!.email!}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
