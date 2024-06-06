import 'package:flutter/material.dart';
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import '../provider/provider_user.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'ajouterUserAdmin.dart';
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: const Color(0xFF008EFE)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AddVehiculeAdminPage(),
    );
  }
}

class AddVehiculeAdminPage extends StatefulWidget {
  final User? user;
  const AddVehiculeAdminPage({super.key, this.user});
  
  @override
  State<AddVehiculeAdminPage> createState() => AddVehiculeAdminPageState();
}

class AddVehiculeAdminPageState extends State<AddVehiculeAdminPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _numVinController = TextEditingController();
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _immatController = TextEditingController();


  Future<List<User>> fetchUsersByIdEntreprise() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/user/getAll'));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final userList = parsed.findAllElements('user');
      return userList.map((user) => User.fromXml(user, 9)).toList();
    } else if(response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load users');
    }
  }

  User? _selectedUser;

  final RegExp _marqueRegExp = RegExp(r'^[a-zA-Z ]+$');
  final RegExp _numVinRegExp = RegExp(r'^[A-Za-z0-9 ]+$');
  final RegExp _immatRegExp = RegExp(r'^[A-Za-z]{2}-[0-9]{3}-[A-Za-z ]{2}$');



  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    User? user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un véhicule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<User>>(
          future: fetchUsersByIdEntreprise(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(), 
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Erreur: ${snapshot.error}'), 
              );
            } else {
              List<User> users = snapshot.data ?? [];
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _numVinController,
                      decoration: const InputDecoration(labelText: 'Numéro VIN'),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un numéro VIN.';
                        } else if (!_numVinRegExp.hasMatch(value.trim())) {
                          return 'Le numéro VIN doit contenir uniquement des lettres et des chiffres.';
                        } else if(value.length != 17){
                          return 'Le numéro VIN doit faire 17 caractères de long.';
                        } else {
                          _numVinController.text = value.toUpperCase().trim();
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _marqueController,
                      decoration: const InputDecoration(labelText: 'Marque'),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom de marque.';
                        } else if (!_marqueRegExp.hasMatch(value.trim())) {
                          return 'La marque doit contenir uniquement des lettres';
                        }
                        _marqueController.text = value[0].toUpperCase().trim() + value.substring(1).toLowerCase().trim();
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _modeleController,
                      decoration:const InputDecoration(labelText: 'Modèle'),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom de modèle.';
                        } else if (value.length < 2 || value.length > 50) {
                          return 'Le modèle doit au moins 2 caractères et 50 au plus.';
                        }
                        _modeleController.text = value[0].toUpperCase().trim() + value.substring(1).toLowerCase().trim();
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<User?>(
                            onChanged: (User? userChoisi) {
                                _selectedUser = userChoisi;
                            },
                            items: [
                              const DropdownMenuItem<User?>(
                                value: null,
                                child: Text('Aucun utilisateur'),
                              ),
                              ...users.map<DropdownMenuItem<User?>>((User user) {
                                return DropdownMenuItem<User?>(
                                  value: user,
                                  child: Text('${user.nomUser} ${user.prenomUser}'),
                                );
                              }),
                            ],
                            decoration: const InputDecoration(labelText: 'Utilisateur'),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Ajouter un utilisateur ?'),
                                  content: Text('Souhaitez-vous ajouter un nouvel utilisateur ?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('Non'),
                                      onPressed: () {
                                        Navigator.of(context).pop(); 
                                      },
                                    ),
                                    TextButton(
                                      child: Text('Oui'),
                                      onPressed: () {
                                        Navigator.of(context).pop(); 
                                        Navigator.push( 
                                          context,
                                          MaterialPageRoute(builder: (context) => const AddUserPage()),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: Icon(Icons.add),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _immatController,
                      decoration: const InputDecoration(labelText: 'Immatriculation'),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une immatriculation.';
                        } else if (!_immatRegExp.hasMatch(value.trim())) {
                          return 'Format d\'immatriculation invalide.\nUtilisez le format AA-001-AA';
                        } else {
                          _immatController.text = value.toUpperCase().trim();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final userId = _selectedUser != null ? _selectedUser!.idUser : "null";
                          final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/vehicule/add/${_numVinController.text}/${_marqueController.text}/${_modeleController.text}/${user!.idEntrepriseUser!.idEntreprise}/$userId/${_immatController.text}'));
                          if(response.body.toString() == 'Voiture ajoutée avec succès !'){
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Succès'),
                                  content: const Text('Véhicule ajouté avec succès !'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Erreur'),
                                  content: Text(response.body.toString()),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop(); 
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          
                          }
                        }
                      },
                      child: const Text('Ajouter un véhicule'),
                    ),
                  ],
                ),
              );
            }
          }
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numVinController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _immatController.dispose();
    super.dispose();
  }
}
