import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/wrapper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'models/file_model.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
        // StreamProvider<List<ImageModel?>>.value(
        //   value: db.getImageList(),
        //   initialData: [],
        //   catchError: (_, error) {
        //     print('Error fetching image stream: $error');
        //     return [];
        //   },
        // )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rill Live Streaming',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MySplashScreen(),
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => Wrapper(),
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
  AuthService as = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(resizeToAvoidBottomInset: true, body: _buildSplashScreen());
  }

  @override
  void initState() {
    super.initState();
    //_checkSignedIn = checkSignedInUser();
    //_getDeviceInfo();
    Timer(
      Duration(seconds: 4),
      () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (builder) => Wrapper()),
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
