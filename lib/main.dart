import 'dart:io';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:camera/camera.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/amplifyconfiguration.dart';
import 'package:rillliveapp/push/push_notification.dart';
import 'package:rillliveapp/screens/notification_screen.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/purchase_logic.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/error_screen.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/wrapper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'models/user_model.dart';
//Amplify configuration
import 'package:amplify_flutter/amplify.dart';
import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

//A top level named handler to handle background/terminated messages will call
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //make sure firebase is initialized bofore using this service
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

List<CameraDescription> cameras = [];
//Create an android notification channel for head up notification
AndroidNotificationChannel? channel;
//Initialize flutter notification channel
FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
String errorMessage = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
  }
  // await Firebase.initializeApp().catchError((error, stackTrace) async {
  //   errorMessage = error.toString();
  //   await Sentry.captureException(error, stackTrace: stackTrace);
  // });
  cameras = await availableCameras();
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://59a95067f678454ab288e638cd9d9774@o994278.ingest.sentry.io/5952729';
    },
    appRunner: () {
      runApp(MyApp());
    },
  );
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  final FirebaseAnalytics firebaseAnalytics = FirebaseAnalytics();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          print('the snapshot: ${snapshot.data}');
          if (snapshot.hasError) {
            Sentry.captureException(snapshot.error);
            return errorInitializing(snapshot.error.toString());
          }
          if (snapshot.connectionState == ConnectionState.done) {
            print('the snapshot 1: ${snapshot.data}');
            //initiate messaging
            _initiateMessaging();
            return MultiProvider(
              providers: [
                StreamProvider<UserModel?>.value(
                  value: AuthService().user,
                  initialData: null,
                  catchError: (_, error) {
                    Sentry.captureException(error);
                    return null;
                  },
                ),
                ChangeNotifierProvider<PurchaseLogic>(
                  create: (context) => PurchaseLogic(),
                  lazy: false,
                )
              ],
              child: MaterialApp(
                navigatorObservers: [
                  FirebaseAnalyticsObserver(
                    analytics: FirebaseAnalytics(),
                  ),
                ],
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
                home: errorMessage.isEmpty
                    ? const MySplashScreen()
                    : const ErrorScreen(),
                routes: <String, WidgetBuilder>{
                  '/home': (BuildContext context) => const Wrapper(
                        guestUser: false,
                      ),
                  '/notifications': (BuildContext context) =>
                      const NotificationScreen(),
                },
              ),
            );
          }

          return MaterialApp(
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
            home: const Center(
              child: LoadingAmination(
                animationType: 'ThreeInOut',
              ),
            ),
          );
        }
        // ),
        );
  }

  //Initiate the messaging process
  Future _initiateMessaging() async {
    //Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (Platform.isAndroid || Platform.isIOS) {
      channel = const AndroidNotificationChannel(
          'High_Importance', 'High importance notifications',
          importance: Importance.high);
    }
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('message opened main: $message');
    });

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    //Create an android notification channel to overrid the default FCM channel
    await flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);

    //Update ios foreground notification presentation options
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
  }

  errorInitializing(String error) {
    return MaterialApp(
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
        home: Center(
          child: Text('Error loading cloud firebase: $error'),
        ));
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
    //_configureAmplify();
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

  // void _configureAmplify() async {
  //   // Add Pinpoint and Cognito Plugins, or any other plugins you want to use
  //   AmplifyAnalyticsPinpoint analyticsPlugin = AmplifyAnalyticsPinpoint();
  //   AmplifyAuthCognito authPlugin = AmplifyAuthCognito();
  //   AmplifyStorageS3 storageS3Plugin = AmplifyStorageS3();
  //   await Amplify.addPlugins([analyticsPlugin, authPlugin, storageS3Plugin]);

  //   // Once Plugins are added, configure Amplify
  //   // Note: Amplify can only be configured once.
  //   try {
  //     await Amplify.configure(amplifyconfig);
  //   } on AmplifyAlreadyConfiguredException {
  //     print(
  //         "Tried to reconfigure Amplify; this can occur when your app restarts on Android.");
  //   } catch (e) {
  //     print('could not configure amplify: $e');
  //   }
  // }

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
