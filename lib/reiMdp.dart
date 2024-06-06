import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/provider/provider_user.dart';

void main() {
   runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: const Color(0xFF008EFE)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: ReinitialiserMdpPage(),
    );
  }
}


class ReinitialiserMdpPage extends StatefulWidget {
  final String? token;
  ReinitialiserMdpPage({super.key, this.token});


  @override
  ReinitialiserMdpPageState createState() => ReinitialiserMdpPageState();
}

class ReinitialiserMdpPageState extends State<ReinitialiserMdpPage> {
  late String? token;

  @override
  void initState() {
    super.initState();
    token = widget.token;
  }

  Future<bool> checkIfTokenInDB(token) async {
    if(token == null) {
      return false;
    }
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/token/ifTokenInDb/$token'));
    if(response.statusCode == 200) {
      if(response.body == 'true') {
        print('token dans la bdd');
        return true;
      } else {
        print('token pas trouvé dans la bdd');
        return false;
      }
    } else {
      throw Exception('Erreur de chargement');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Page de réinitialisation du mot de passe'),
          Text('Token: $token'),
        ],
      ),
    );
    
  }
}