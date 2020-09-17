import 'package:attendence_reminder/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatefulWidget {
  static FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static String _email, _password;

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  SharedPreferences _sharedPreferences;
  bool showSpinner = false;

  void initSP() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initSP();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  SizedBox(height: 300),
                  TextField(
                    decoration: InputDecoration(hintText: 'Enter Email'),
                    onChanged: (value) {
                      SignInPage._email = value;
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    decoration: InputDecoration(hintText: 'Enter Password'),
                    obscureText: true,
                    onChanged: (value) {
                      SignInPage._password = value;
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    child: Container(
                      height: 54,
                      color: Colors.lightBlue,
                      child: Center(
                        child: Text(
                          'Log in',
                          style: TextStyle(color: Colors.white, fontSize: 30),
                        ),
                      ),
                    ),
                    onTap: () async {
                      if (SignInPage._email != null &&
                          SignInPage._password != null) {
                        setState(() {
                          showSpinner = true;
                        });
                        try {
                          final loginUser = await SignInPage._firebaseAuth
                              .signInWithEmailAndPassword(
                                  email: SignInPage._email,
                                  password: SignInPage._password);
                          if (loginUser != null) {
                            _sharedPreferences.setStringList('userInfo',
                                [SignInPage._email, SignInPage._password]);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MainScreen()));
                          }
                          setState(() {
                            showSpinner = false;
                          });
                        } catch (e) {
                          print(e);
                        }
                      } else {
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('There is an error'),
                        ));
                      }
                    },
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text('Don\'t have an account? Sign up here',
                            style: TextStyle(
                                color: Colors.lightBlue, fontSize: 17)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(
                        width: 5,
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
