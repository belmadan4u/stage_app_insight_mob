import 'package:flutter/material.dart';
import 'package:insight_mobility_app/login.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/provider/provider_user.dart';
import 'api_config/api_config.dart';
import 'package:http/http.dart' as http;
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        fontFamily: 'Roboto',
      ),
      home: const ChangerMdpUser(),
    );
  }
}

class ChangerMdpUser extends StatefulWidget {
  const ChangerMdpUser({super.key});

  @override
  State<ChangerMdpUser> createState() => _ChangerMdpUserState();
}

class _ChangerMdpUserState extends State<ChangerMdpUser> {
  String? _ancienMdp = '';
  String? _nouveauMdp = '';
  String? _nvMdpConfirmation = '';
bool _isVerifyingPassword = false;
  String? _tempAncienMdp = '';
  String? _tempNouveauMdp = '';

  Future<bool> verifMdpUser(userId, passwordInput) async {
    setState(() {
      _isVerifyingPassword = true;
    });

    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/user/verifyPsdForUser/$userId/$passwordInput'));

    setState(() {
      _isVerifyingPassword = false;
    });

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Changer mon mot de passe'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  readOnly: _ancienMdp != '' ? true : false,
                  decoration: const InputDecoration(
                    hintText: 'Ancien mot de passe',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _tempAncienMdp = value;
                    });
                  },
                ),

                const SizedBox(height: 20),
                if (_tempAncienMdp != '')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Couleur de fond du bouton
                    foregroundColor: Colors.white, // Couleur du texte du bouton
                    textStyle: const TextStyle( // Style du texte
                      fontSize: 20, // Taille du texte
                      fontWeight: FontWeight.bold, // Gras
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15), // Espacement interne du bouton
                    shape: RoundedRectangleBorder( // Forme du bouton
                      borderRadius: BorderRadius.circular(3), // Bordure arrondie
                    ),
                    elevation: 4, // Élévation du bouton
                  ),
                  onPressed: () async {
                    if (await verifMdpUser(user.idUser, _tempAncienMdp)) {
                      setState(() {
                        _ancienMdp = _tempAncienMdp;
                        _tempAncienMdp = '';
                      });
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Erreur'),
                            content: const Text('Le mot de passe saisi est incorrect'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: _isVerifyingPassword ? const CircularProgressIndicator() : const Text('Valider'),
                ),
                  
                




               
                const SizedBox(height: 20),





                if (_ancienMdp != '')
                  Column(
                    children: [
                      TextFormField(
                        readOnly: _nouveauMdp != '' ? true : false,
                        decoration: const InputDecoration(
                          hintText: 'Nouveau mot de passe',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _tempNouveauMdp = value;
                          });
                        },
                      ),
                      if (_tempNouveauMdp != '' && _getCriteresNonAtteintMdp(_tempNouveauMdp!).isEmpty)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _nouveauMdp = _tempNouveauMdp;
                              _tempNouveauMdp = '';
                            });
                          },
                          child: const Text('Valider'),
                        ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _getCriteresNonAtteintMdp(_tempNouveauMdp!).length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.error_outline, color: Colors.red),
                            title: Text(_getCriteresNonAtteintMdp(_tempNouveauMdp!)[index]),
                          );
                        },
                      ),

                      if (_nouveauMdp != '')
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Confirmez le nouveau mot de passe',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _nvMdpConfirmation = value;
                            });
                          },
                        ),
                      if (_nvMdpConfirmation == _nouveauMdp && _nvMdpConfirmation != '' && _nouveauMdp != '')
                        ElevatedButton(
                          onPressed: () async {
                            await userProvider.user!.updatePsw(_nouveauMdp!);
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Succès'),
                                  content: const Text('Votre mot de passe a été modifié avec succès'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        if(Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }
                                        if(Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text('Valider'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyLoginPage()),
      );
      return Container();
    }
  }

  List<String> _getCriteresNonAtteintMdp(String? password) {
    List<String> mdpCriteres = [];

    if (password == null || password == '') {
      return mdpCriteres;
    }
    // Vérifier la longueur minimale
    if (password.length < 9) {
      mdpCriteres.add('Le mot de passe doit contenir au moins 9 caractères');
    } else if (password.length >= 9) {
      mdpCriteres.remove('Le mot de passe ne doit pas dépasser 12 caractères');
    }

    // Vérifier la présence d'au moins un caractère spécial
    RegExp specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    if (!specialCharRegex.hasMatch(password)) {
      mdpCriteres.add('Le mot de passe doit contenir au moins un caractère spécial');
    } else if (specialCharRegex.hasMatch(password)) {
      mdpCriteres.remove('Le mot de passe doit contenir au moins un caractère spécial');
    }

    // Vérifier la présence d'au moins une majuscule
    RegExp upperCaseRegex = RegExp(r'[A-Z]');
    if (!upperCaseRegex.hasMatch(password)) {
      mdpCriteres.add('Le mot de passe doit contenir au moins une majuscule');
    } else if (upperCaseRegex.hasMatch(password)) {
      mdpCriteres.remove('Le mot de passe doit contenir au moins une majuscule');
    }

    // Vérifier la présence d'au moins une minuscule
    RegExp lowerCaseRegex = RegExp(r'[a-z]');
    if (!lowerCaseRegex.hasMatch(password)) {
      mdpCriteres.add('Le mot de passe doit contenir au moins une minuscule');
    } else if (lowerCaseRegex.hasMatch(password)) {
      mdpCriteres.remove('Le mot de passe doit contenir au moins une minuscule');
    }

    // Vérifier la présence d'au moins un chiffre
    RegExp digitRegex = RegExp(r'\d');
    if (!digitRegex.hasMatch(password)) {
      mdpCriteres.add('Le mot de passe doit contenir au moins un chiffre');
    } else if (digitRegex.hasMatch(password)) {
      mdpCriteres.remove('Le mot de passe doit contenir au moins un chiffre');
    }

    return mdpCriteres;
  }
}
