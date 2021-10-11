import 'dart:io';
import 'package:camera/camera.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/push/push_notification.dart';
import 'package:rillliveapp/screens/message_screen.dart';
import 'package:rillliveapp/screens/notification_screen.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/wrapper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'models/user_model.dart';

//A top level named handler to handle background/terminated messages will call
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //make sure firebase is initialized bofore using this service
  print('Id: ${message.messageId}');
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

List<CameraDescription> cameras = [];
//Create an android notification channel for head up notification
AndroidNotificationChannel? channel;
//Initialize flutter notification channel
FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  cameras = await availableCameras();
  //Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (Platform.isAndroid || Platform.isIOS) {
    channel = const AndroidNotificationChannel(
        'High_Importance', 'High importance notifications',
        importance: Importance.high);
  }

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  //Create an android notification channel to overrid the default FCM channel
  await flutterLocalNotificationsPlugin!
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel!);

  //Update ios foreground notification presentation options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true);

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://59a95067f678454ab288e638cd9d9774@o994278.ingest.sentry.io/5952729';
    },
    appRunner: () => runApp(MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    bool _userSignedIn = false;
    DatabaseService db = DatabaseService();
    return MultiProvider(
      providers: [
        StreamProvider<UserModel?>.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, error) {
            print('Error streaming user: $error');
            return null;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rill Live Streaming',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
          textTheme: const TextTheme(
            headline1: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xffdf1266)),
            headline6: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Color(0xffdf1266)),
          ),
        ),
        home: MySplashScreen(),
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => const Wrapper(
                guestUser: false,
              ),
          '/notifications': (BuildContext context) => const NotificationScreen()
        },
      ),
    );
  }
}

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key, this.userSignedIn}) : super(key: key);
  final bool? userSignedIn;
  @override
  _MySplashScreenState createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  late String identifier;
  late Future _checkSignedIn;
  late UserModel currentUser;
  late bool userSignedIn = false;

  //Controllers
  PushNotificationsManager pNotif = PushNotificationsManager();
  AuthService as = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(resizeToAvoidBottomInset: true, body: _buildSplashScreen());
  }

  @override
  void initState() {
    super.initState();
    pNotif.init();
    //_checkSignedIn = checkSignedInUser();
    //_getDeviceInfo();
    Timer(
      Duration(seconds: 4),
      () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (builder) => const Wrapper(guestUser: false),
        ),
        ModalRoute.withName('/home'),
      ),
    );
  }

  Future _getDeviceInfo() async {
    try {
      if (io.Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        identifier = build.id.toString();
      } else if (io.Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        identifier = data.identifierForVendor;
      }
    } on PlatformException {
      print('Failed to get platform version');
    }
  }

  //The splash screen will be the first screen of the app, clicking on it will lead to the sign in page or the home page
  Widget _buildSplashScreen() {
    var _screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          //Background screen
          Container(
            decoration: BoxDecoration(
                image: const DecorationImage(
                    image: AssetImage('assets/images/splash_screen.png'),
                    fit: BoxFit.cover),
                color: Colors.lightBlue[200],
                backgroundBlendMode: BlendMode.dstIn),
          ),
          //Logo screen
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  height: _screenSize.height / 4,
                  width: _screenSize.width / 2,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/logo_type.png'),
                        fit: BoxFit.contain),
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  height: _screenSize.height / 4,
                  child: Text('Live Streaming App', style: heading_1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
