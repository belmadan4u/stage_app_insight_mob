import 'package:flutter/material.dart';
import 'types/types.user.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/provider/provider_user.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'api_config/api_config.dart';
import 'home.dart';
import 'mdpOublieEntrerMail.dart';
import 'package:flutter/services.dart'; // Importez cette ligne pour utiliser SystemChrome



void main() {
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp])
      .then((_) => runApp(ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyLoginPage(),
    );
  }
} 

class MyLoginPage extends StatefulWidget {
  const MyLoginPage({super.key});

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _emailOuTel = "email@example.com"; //  contact@aestria.fr email@example.com
  String? _password = "Motdepasse1@"; // aestria Motdepasse1@
  double imageSize = 0.7;
  bool _loading = false;
  bool _obscureText = true;
  Future<User> fetchUserByEmailOrTelAndPwd(emailOrTel, password) async {
    if(emailOrTel == null || password == null) {
      throw Exception('Veuillez remplir tous les champs');
    }
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/user/getUserByEmailOrTelAndPsd/$emailOrTel/$password'));
    
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final user = parsed.findElements('user').first;
      print(user);
      return User.fromXml(user, _password!.length);
    } else if(response.statusCode == 404) {
      throw Exception('Utilisateur non trouvé ou mot de passe incorrect');
    } 
    else if(response.statusCode == 500){
      throw Exception('Erreur coté serveur');
    } else {
      throw Exception('Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold( 
      body: Center(
        child:
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
         return SingleChildScrollView(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: constraints.maxWidth < 600 ? 0.8 : constraints.maxWidth > 1200 ? 0.3 : 0.5,
                    child: Image.asset('images/logo_ins_mob2.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 14.0),
                  const Center(
                    child:  Text(
                    'Connectez vous',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'e-mail ou n° de téléphone',
                      filled: true,
                      fillColor: Colors.grey[200], // Couleur de fond pour les champs d'entrée
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0), // Espacement interne
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez votre e-mail ou numéro de téléphone';
                      }

                      final mailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      final telRegex = RegExp(r'^\+?[0-9]{7,15}$');

                      if (mailRegex.hasMatch(value) || telRegex.hasMatch(value)) {
                        _emailOuTel = value;
                        return null;
                      } else {
                        return 'Entrez une adresse e-mail ou un numéro de téléphone valide';
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    obscureText : _obscureText,
                    decoration: InputDecoration(
                      suffixIcon : IconButton(
                        icon: _obscureText ? const Icon(Icons.remove_red_eye) : const Icon(Icons.visibility_off),
                        onPressed: (){
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      hintText: 'Mot de passe',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Saisissez votre mot de passe';
                      }
                      _password = value;
                      return null;
                    },
                  ),
                  const SizedBox(height: 5.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmailInputPage()),
                      );
                    },
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        height: 1.3,
                        decoration: TextDecoration.underline, 
                        decorationColor: Colors.grey, 
                        decorationThickness: 2.0, 
                        decorationStyle: TextDecorationStyle.solid, 
                        color: Colors.grey[850], 
                        fontSize: 15.0,
                      ),
                    )
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loading
                      ? null 
                      : () async {
                      //if (_formKey.currentState!.validate()) {
                        setState(() {
                          _loading = true; 
                        });
                        try {
                          final user = await fetchUserByEmailOrTelAndPwd(_emailOuTel, _password);
                          userProvider.setUser(user);
                          if(mounted){
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const MyHomePage()), 
                              (Route<dynamic> route) => false
                            );
                          }
                          
                          
                        } catch (e) {
                          if (e.toString().contains('Utilisateur non trouvé ou mot de passe incorrect')) {
                            if(mounted){
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Utilisateur non trouvé ou mot de passe incorrect'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            setState(() {
                              _loading = false;
                            });
                            
                          } else {
                            if(mounted){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                          setState(() {
                            _loading = false;
                          });
                        }
                      //}
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _loading
                      ? const CircularProgressIndicator() 
                      : const Text('Se connecter', style: TextStyle(fontSize: 16.0)),
                  ),
                ],
              ),
            ),
          )
        );
      
  }
    )
    )
    );
  }
}