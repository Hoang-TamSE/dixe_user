import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/screens/profile_screen.dart';
import 'package:dixa_user/splashScreen/splash_screen.dart';
import 'package:flutter/material.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      child: Drawer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, 50, 0, 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: userModelCurrentInfo?.avatar ==null
                          ?Icon(
                      Icons.person,
                      color: Colors.white,
                    ):CircleAvatar(
                      backgroundImage: NetworkImage("${userModelCurrentInfo?.avatar}"),
                      radius: 50,
                    ),
                  ),

                  SizedBox(height: 20,),

                  Text(
                    '${userModelCurrentInfo?.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  SizedBox(height: 10,),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileScreen()));

                    },
                    child: Text(
                      "Sửa thông tin",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30,),
                  
                  Text("chuyến đi của bạn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 30,),

                  Text("Thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 30,),

                  Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 30,),

                  Text("khuyến mãi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 30,),

                  Text("Hỗ trợ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 30,),

                  Text("Miễn phí chuyến đi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

                  SizedBox(height: 15,)


                ],
              ),

              GestureDetector(
                onTap: (){
                  firebaseAuth.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c) => SplashScreen()));
                },
                child: Text(
                  "Đăng xuất",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
