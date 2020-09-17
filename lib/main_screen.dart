import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  String branch = '';
  String userDocId = '';
  String name = '';
  SharedPreferences _sharedPreferences;

  void initSP() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    initSP();
    var currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      String email = currentUser.email;
      var userSnapshot = await _fireStore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      var data = userSnapshot.docs[0].data();
      userDocId = userSnapshot.docs[0].id;
      branch = data['branch'];
      name = data['name'];
      setState(() {});
    }
  }

  void createEvent() async {
    var snapshot = await _fireStore
        .collection('users')
        .doc(userDocId)
        .collection('classmates')
        .where('status', isEqualTo: true)
        .get();
    var devices = snapshot.docs;
    var deviceList = [];
    var nameList = [];
    if (devices.length != 0) {
      for (var device in devices) {
        var data = device.data();
        var id = data['deviceToken'];
        var target = data['name'];
        deviceList.add(id);
        nameList.add(target);
      }
    }
    _fireStore.collection('event').add({
      'targets': nameList,
      'devices': deviceList,
      'name': name,
      'timestamp': DateTime.now()
    });
  }

  Future<Widget> alert(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Send notification ?'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('No')),
              TextButton(
                  onPressed: () {
                    createEvent();
                    Navigator.pop(context);
                  },
                  child: Text('Yes'))
            ],
          );
        });
  }

  Future<Widget> alert1(BuildContext context) {
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

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(branch),
            actions: [
              IconButton(
                  tooltip: 'Send reminder',
                  icon: Icon(
                    Icons.notifications,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    alert(context);
                  })
            ],
          ),
          drawer: Drawer(
            child: Stack(children: [
              Container(
                height: MediaQuery.of(context).size.height,
                color: Colors.blue,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    color: Colors.white,
                    height: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    color: Colors.blue,
                    child: GestureDetector(
                      child: ListTile(
                        title: Text(
                          'Sign out',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        leading: Icon(
                          Icons.logout,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        _sharedPreferences.remove('userInfo');
                        _firebaseAuth.signOut();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Card(
                    color: Colors.blue,
                    child: GestureDetector(
                      child: ListTile(
                        title: Text(
                          '',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        leading: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        alert1(context);
                      },
                    ),
                  )
                ],
              )
            ]),
          ),
          body: branch == ''
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    StreamBuilder(
                      stream: _fireStore
                          .collection('users')
                          .doc(userDocId)
                          .collection('classmates')
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final users = snapshot.data.documents;
                        List<Widget> items = [];
                        for (var user in users) {
                          String name = user.data()['name'];
                          String email = user.data()['email'];
                          bool value = user.data()['status'];
                          final widget = MainTile(
                            name: name,
                            email: email,
                            value: value,
                            onChanged: (value) {
                              _fireStore
                                  .collection('users')
                                  .doc(userDocId)
                                  .collection('classmates')
                                  .doc(user.documentID)
                                  .update({'status': value});
                            },
                          );
                          items.add(widget);
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return Container(
                          height: MediaQuery.of(context).size.height - 150,
                          child: ListView(
                            children: items,
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Made with frustration 😡',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey),
                    ),
                    Text(
                      'Due to attendance',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey),
                    )
                  ],
                )),
    );
  }
}

class MainTile extends StatelessWidget {
  MainTile({this.value, this.onChanged, this.name, this.email});

  final bool value;
  final Function onChanged;
  final String name, email;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(name),
      subtitle: Text(email),
      secondary: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(
          Icons.person,
          size: 25,
        ),
      ),
    );
  }
}
