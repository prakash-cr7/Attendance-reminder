import 'package:attendence_reminder/main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signin_page.dart';

SharedPreferences _sharedPreferences;

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  var _fireStore = FirebaseFirestore.instance;
  String hintText = 'select your branch';
  String name, branch, _email, _password, deviceToken;
  bool shuwSpinner = false;

  void intSP() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    getLocalData();
  }

  void getLocalData() async {
    var data = _sharedPreferences.getStringList('userInfo');
    var currentUser = _firebaseAuth.currentUser;
    if (data[0] != null &&
        data[1] != null &&
        currentUser != null &&
        currentUser.email == data[0]) {
      var email = data[0];
      var password = data[1];
      try {
        _firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MainScreen()));
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> addUserToDatabase(
    String branch,
    email,
    name,
    deviceToken,
  ) async {
    await _fireStore.collection('users').add({
      'name': name,
      'email': email,
      'status': false,
      'deviceToken': deviceToken,
      'branch': branch
    });
  }

  void addYourselfInClass() async {
    var snapshot = await _fireStore
        .collection('users')
        .where('branch', isEqualTo: branch)
        .get();
    var classmates = snapshot.docs;
    for (var classmate in classmates) {
      var id = classmate.id;
      _fireStore.collection('users').doc(id).collection('classmates').add({
        'name': name,
        'email': _email,
        'status': false,
        'deviceToken': deviceToken,
        'branch': branch
      });
    }
    addClassmates();
  }

  void addClassmates() async {
    var userSnapshot = await _fireStore
        .collection('users')
        .where('email', isEqualTo: _email)
        .get();

    var userDocId = userSnapshot.docs[0].id;

    var snapshot = await _fireStore
        .collection('users')
        .where('branch', isEqualTo: branch)
        .get();

    var classmates = snapshot.docs;

    for (var classmate in classmates) {
      if (classmate.data()['email'] != _email) {
        _fireStore
            .collection('users')
            .doc(userDocId)
            .collection('classmates')
            .add(classmate.data());
      }
    }
  }

  Future<Widget> alert(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
                'To use this app effectively go to your app setting and enable notification sound for this app and Choose a unique'
                ' ringtone.'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('I Understand')),
            ],
          );
        });
  }

  void getToken() async {
    deviceToken = await _firebaseMessaging.getToken();
    intSP();
  }

  @override
  void initState() {
    super.initState();
    getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: shuwSpinner,
        child: Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 220,
                  ),
                  Container(
                      height: 60,
                      child: DropdownButton<String>(
                          hint: Text(
                            hintText,
                          ),
                          items: [
                            DropdownMenuItem<String>(
                                child: Text('IIIT 2nd CSE'),
                                value: 'IIIT 2nd CSE'),
                            DropdownMenuItem<String>(
                                child: Text('IIIT 2nd ECE'),
                                value: 'IIIT 2nd ECE')
                          ],
                          onChanged: (value) {
                            setState(() {
                              hintText = value;
                              branch = value;
                            });
                          })),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    decoration: InputDecoration(hintText: 'Enter Name'),
                    onChanged: (value) {
                      name = value;
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    decoration: InputDecoration(hintText: 'Enter Email'),
                    onChanged: (value) {
                      _email = value;
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    decoration: InputDecoration(hintText: 'Enter Password'),
                    onChanged: (value) {
                      _password = value;
                    },
                    obscureText: true,
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
                          'Sign up',
                          style: TextStyle(color: Colors.white, fontSize: 30),
                        ),
                      ),
                    ),
                    onTap: () async {
                      if (name != null &&
                          _password != null &&
                          branch != null &&
                          _email != null) {
                        setState(() {
                          shuwSpinner = true;
                        });
                        try {
                          _sharedPreferences
                              .setStringList('userInfo', [_email, _password]);
                          final newUser = await _firebaseAuth
                              .createUserWithEmailAndPassword(
                                  email: _email, password: _password);
                          if (newUser != null) {
                            await addUserToDatabase(
                                branch, _email, name, deviceToken);
                            addYourselfInClass();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MainScreen()));
                          }
                        } catch (e) {
                          print(e);
                        }
                        setState(() {
                          shuwSpinner = false;
                        });
                      } else {
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Please enter all fields'),
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
                        child: Text('Already signed up? login here',
                            style: TextStyle(
                                color: Colors.lightBlue, fontSize: 17)),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignInPage()));
                        },
                      ),
                      SizedBox(
                        width: 5,
                      ),
                    ],
                  ),
                  IconButton(
                      alignment: Alignment.bottomRight,
                      icon: Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 30,
                      ),
                      onPressed: () {
                        alert(context);
                      })
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
