import 'package:flutter/material.dart';
import 'login_page.dart';
import 'back4app_db.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Back4App.connectToDB();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}
