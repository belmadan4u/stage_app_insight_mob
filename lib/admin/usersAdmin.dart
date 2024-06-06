import 'package:flutter/material.dart';
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'package:insight_mobility_app/types/types.vehicule.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import '../login.dart';
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
      home: const UsersOfAdminPage(),
    );
  }
}

class UsersOfAdminPage extends StatefulWidget {
  final User? user;
  const UsersOfAdminPage({super.key, this.user});
  
  @override
  State<UsersOfAdminPage> createState() => UsersOfAdminPageState();
}

class UsersOfAdminPageState extends State<UsersOfAdminPage> {
  String? datePeriodique;
  final List<String> vehicules = ['Véhicule 1', 'Véhicule 2', 'Véhicule 3'];
  late List<User> usersOfEntreprise = [];


  Future<void> fetchUsers() async {
    if(Provider.of<UserProvider>(context).user == null) {
      return;
    }
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/user/getAll"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final userList = parsed.findAllElements('user');
      usersOfEntreprise = userList.map((user) => User.fromXml(user, 10)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<Vehicule?> carAssociatedByIdUser(idUser) async {
    if(Provider.of<UserProvider>(context).user == null) {
      throw Exception('Error: user that is supposed to be connected is null');
    }
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/vehicule/getVehiculeByIdUser/$idUser"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
          
      final vehicule = parsed.findElements('vehicule').first;
      return Vehicule.fromXml(vehicule);
    } else if(response.statusCode == 404){
      return null;
    } else {
      throw Exception('Failed to load the vehicule of the user $idUser');
    }
  }
// fetch vehicule by user pour l'ecrire avec un user
// update vehicule by user pour l'associer à un user
// fetch add vehicule for user pour ajouter un vehicule à un user
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if(user != null) {
      if(user.roleUser == "ROLE_SUPERADMIN") {
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 70,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: const Text('Tout les Utilisateurs'),
              leading: IconButton(
                onPressed: () {
                    Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                iconSize: 40,
              ),
            ),
           body: 
            FutureBuilder(
              future: fetchUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator()
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return ListView.builder(
                    itemCount: usersOfEntreprise.length,
                    itemBuilder: (BuildContext context, int index) {
                      String entrepriseUser = '';
                      if(usersOfEntreprise[index].idEntrepriseUser == null) {
                        entrepriseUser = "employé chez aucune entreprise";
                      } else {
                        entrepriseUser = "employé chez ${usersOfEntreprise[index].idEntrepriseUser!.nomEntreprise}";
                      }
                      
                      return FutureBuilder<Vehicule?>(
                        future: carAssociatedByIdUser(usersOfEntreprise[index].idUser),
                        builder: (context, snapshotVehicule) {
                          if (snapshotVehicule.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshotVehicule.hasError) {
                            return Text("Erreur: ${snapshotVehicule.error}");
                          } else {
                            String vehiculeName = '';
                            if(snapshotVehicule.data != null) {
                              vehiculeName = "Conduit le véhicule ${snapshotVehicule.data!.marque} ${snapshotVehicule.data!.modele}.";
                            } else {
                              vehiculeName = 'Aucun véhicule associé.';
                            }


                            return Card(
                              child: ListTile(
                                title: Text(
                                  '${usersOfEntreprise[index].nomUser} ${usersOfEntreprise[index].prenomUser}',
                                ),
                                subtitle: Text(
                                  'ID: ${usersOfEntreprise[index].idUser}, $entrepriseUser.\n$vehiculeName',
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                onTap: () {
                                  // Action lorsque l'utilisateur est tapé
                                },
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddUserPage()));
                },
                label: const Text('Ajouter un utilisateur'),
                icon: const Icon(Icons.add),
              ),
          );
        } else if (user.roleUser == "ROLE_USER") {
          return const Text("Vous n'êtes pas autorisé à accéder à cette page");
        } else {
          return const Text("Erreur ? : ni admin ni user");
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {  // permet d'attendre que la page s'affiche en entier avant de faire tourner ce qu'il y'a à l'intérieur
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MyLoginPage(),
            ),
            (route) => false,
          );
        });
        return const SizedBox.shrink(); 
      }
  }
}
