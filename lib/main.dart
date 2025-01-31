import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutes/core/services/events.dart';
//import 'package:nutes/ui/screens/profile_screen.dart';
import 'package:nutes/core/services/local_cache.dart';
import 'package:nutes/ui/screens/chat_screen.dart';
import 'package:nutes/ui/screens/post_detail_screen.dart';
import 'package:nutes/ui/screens/profile_screen.dart';
import 'package:nutes/ui/shared/avatar_image.dart';
import 'package:nutes/ui/shared/loading_indicator.dart';
import 'package:nutes/ui/widgets/app_page_view.dart';
import 'package:nutes/ui/screens/login_screen.dart';
import 'package:nutes/core/services/repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/models/user.dart';
import 'core/services/firestore_service.dart';

//final auth = Auth.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

//  await initCurrentUser();

  runApp(MyApp());
}

Future initCurrentUser() async {
  UserProfile user;

  ///check FIRAuth if user is signed in

  final authUser = await FirebaseAuth.instance.currentUser();

  if (authUser != null) {
    user = await Repo.getUserProfile(authUser.uid);

    Repo.auth = user;
    FirestoreService.auth = user;

    Repo.myStory = null;

    if (user == null) FirebaseAuth.instance.signOut();

    LocalCache.instance = LocalCache();

    return;
  }
}

Future<void> _handleNotification(
    BuildContext context, Map<dynamic, dynamic> message, bool dialog,
    {bool chatIsActive = false}) async {
  var data = message['data'] ?? message;

  final id = data['id'] ?? '';

  switch (data['screen']) {
    case "dm":
      print('go to chat $id');

      if (!dialog) {
        Navigator.popUntil(context, (r) => r.isFirst);
        Navigator.push(context, ChatScreen.FCMroute(id));
      } else {
        ///Show in app notification if not on home tab 0
        if (!chatIsActive)
          BotToast.showNotification(
              duration: Duration(seconds: 5),
              leading: (_) => AvatarImage(
                    url: data['extradata'] ?? '',
                    padding: 4,
                  ),
              title: (_) => Text(data['body'] ?? ''),
              onTap: () {
                Navigator.popUntil(context, (r) => r.isFirst);
                Navigator.push(context, ChatScreen.FCMroute(id));
              });
      }

      break;
    case "post":
      if (!dialog) {
        Navigator.popUntil(context, (r) => r.isFirst);
        Navigator.push(
            context,
            PostDetailScreen.route(null,
                postId: id, ownerId: data['extradata'] ?? ''));
      } else {
        BotToast.showNotification(
            duration: Duration(seconds: 5),
            leading: (_) => AvatarImage(
                  url: data['extradata'] ?? '',
                  padding: 4,
                ),
            title: (_) => Text(data['body'] ?? ''),
            onTap: () {
              Navigator.popUntil(context, (r) => r.isFirst);
              Navigator.push(
                  context,
                  PostDetailScreen.route(null,
                      postId: id, ownerId: data['extradata'] ?? ''));
            });
      }

      break;
    case "user":
      if (!dialog) {
        Navigator.popUntil(context, (r) => r.isFirst);
        Navigator.push(context, ProfileScreen.route(id));
      } else {
        BotToast.showNotification(
            duration: Duration(seconds: 5),
            leading: (_) => AvatarImage(
                  url: data['extradata'] ?? '',
                  padding: 4,
                ),
            title: (_) => Text(data['body'] ?? ''),
            onTap: () {
              Navigator.popUntil(context, (r) => r.isFirst);
              Navigator.push(context, ProfileScreen.route(id));
            });
      }
      break;
    case "comment":
      if (!dialog) {
        Navigator.popUntil(context, (r) => r.isFirst);
        Navigator.push(
            context,
            PostDetailScreen.route(null,
                postId: id, ownerId: data['post_owner_id'] ?? ''));
      } else {
        BotToast.showNotification(
            duration: Duration(seconds: 5),
            leading: (_) => AvatarImage(
                  url: data['extradata'] ?? '',
                  padding: 4,
                ),
            title: (_) => Text(data['body'] ?? ''),
            onTap: () {
              Navigator.popUntil(context, (r) => r.isFirst);
              Navigator.push(
                  context,
                  PostDetailScreen.route(null,
                      postId: id, ownerId: data['post_owner_id'] ?? ''));
            });
      }
      break;
    default:
      break;
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return BotToastInit(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainBuilder(),
        navigatorObservers: [BotToastNavigatorObserver()],
      ),
    );
  }
}

class MainBuilder extends StatefulWidget {
  @override
  _MainBuilderState createState() => _MainBuilderState();
}

class _MainBuilderState extends State<MainBuilder> {
  final auth = Repo.auth;
  final _fcm = FirebaseMessaging();
  IosNotificationSettings iosSettings;
  String fcmToken;

  UserProfile profile;

  int currentPageIndex = 1;
  int currentHomeTab = 0;

  bool chatScreenActive = false;

  _subscribeToTopic() async {
    final user = await FirebaseAuth.instance.currentUser();

    if (user != null) {
      await _fcm.subscribeToTopic(user.uid);
      print('subcribed to topic ${user.uid}');
    }
  }

  _incrementOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    final counter = (prefs.getInt('open_count') ?? 0) + 1;
    print('Opened app $counter times.');

    if (counter < 2) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
              "By using NUTES you agree to the terms of service(EULA) and privacy policy. NUTES has no tolerance for objectionable content and abusive users. Any inappropriate usage will be banned."),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('I Agree'),
              isDefaultAction: true,
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            )
          ],
        ),
      );
    }
    await prefs.setInt('open_count', counter);
  }

  @override
  void initState() {
    super.initState();
    _incrementOpenCount();

    if (Platform.isIOS) _fcm.requestNotificationPermissions();

    _fcm.getToken().then((String token) {
      fcmToken = token;
      FirestoreService.FCMToken = fcmToken;
    });

    _fcm.onIosSettingsRegistered.listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
      iosSettings = settings;

      if (iosSettings != null && fcmToken != null) _subscribeToTopic();
    });

    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        _handleNotification(context, message, true,
            chatIsActive: chatScreenActive);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        _handleNotification(context, message, false);
      },
    );

    ///listen to if chat screen in visible
    eventBus.on<ChatScreenActiveEvent>().listen((event) {
      setState(() {
        chatScreenActive = event.isActive;
      });

      print('chat is active: $chatScreenActive');
    });
  }

  @override
  void dispose() {
    print('Main builder disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirebaseUser>(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LoginScreen();

//        if (snapshot.data != null) _getProfile(snapshot.data.uid);

        return StreamBuilder<DocumentSnapshot>(
            stream: Repo.userProfileStream(snapshot.data.uid),
            builder: (context, snap) {
              if (!snap.hasData)
                return Scaffold(
                    body: Container(
                  color: Colors.white,
                  child: Center(
                    child: LoadingIndicator(),
                  ),
                ));
              final profile = UserProfile.fromDoc(snap.data);

              if (profile == null) Repo.logout();

              Repo.auth = profile;
              FirestoreService.auth = profile;

              print('@@@@@@ #### stream profile: ${profile.uid}');
              return profile == null
                  ? Scaffold(
                      body: Container(
                        color: Colors.white,
                        child: Center(
                          child: LoadingIndicator(),
                        ),
                      ),
                    )
                  : Provider<UserProfile>(
                      create: (BuildContext context) => profile,
                      child: AppPageView(
                        uid: snapshot.data.uid,
                        onPage: (index) {
                          if (mounted)
                            setState(() {
                              currentPageIndex = index;
                            });
                        },
                        onTab: (index) {
                          if (mounted)
                            setState(() {
                              currentHomeTab = index;
                            });
                        },
                      ),
                    );
            });
      },
    );
  }

//  Future<void> _getProfile(String uid) async {
//    print('#### Get Profile for $uid');
//    final result = await Repo.getUserProfile(uid);
//
//    if (result == null)
//      await Repo.logout();
//    else {
//      Auth.instance.profile = result;
//
//      profile = result;
//
//      ///TODO: get rid of auth == null error
//
//      setState(() {});
//    }
//
//    return;
//  }
}
