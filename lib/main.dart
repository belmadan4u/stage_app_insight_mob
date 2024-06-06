import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/reiMdp.dart';
import 'package:insight_mobility_app/home.dart';
import 'package:insight_mobility_app/login.dart';
import 'provider/provider_user.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _token;
  StreamSubscription<String?>? _linkSubscription;
  @override
  initState(){
    super.initState();
     _linkSubscription = linkStream.listen((String? linkStr) {
            if (linkStr != null) {
              Uri linkUri = Uri.parse(linkStr);
              print('Received uri host: ${linkUri.host}');
              if (linkUri.host == 'reinitialiser_mdp') {
                final tokenUri = linkUri.queryParameters['token'];
                if (tokenUri != null) {
                  print('token : $tokenUri');
                    _token = tokenUri;
                } else {
                  _token = null;
                }
              }
            }
          });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _token = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   print('token : $_token');
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: const Color(0xFF008EFE)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: _buildHomePage(),
    );
  }

  Widget _buildHomePage() {
    final userProvider = Provider.of<UserProvider>(context);
    if(_token != null) {
      return ReinitialiserMdpPage(token: _token);
    } 

    if (userProvider.user == null) {
      return const MyLoginPage();
    } else {
      
      return const MyHomePage();
    }
  }
}
