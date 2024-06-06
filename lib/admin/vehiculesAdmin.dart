
import 'package:flutter/material.dart';
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import 'package:insight_mobility_app/types/types.vehicule.dart';
import '../login.dart';
import '../provider/provider_user.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'addVehiculeAdmin.dart';
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
      home: const VehiculeOfAdminPage(),
    );
  }
}

class VehiculeOfAdminPage extends StatefulWidget {
  final User? user;
  const VehiculeOfAdminPage({super.key, this.user});
  
  @override
  State<VehiculeOfAdminPage> createState() => VehiculeOfAdminPageState();
}

class VehiculeOfAdminPageState extends State<VehiculeOfAdminPage> {
  String? datePeriodique;

  late List<Vehicule> vehiculesOfEntreprise = [];

  Future<void> fetchVehicules() async {
    if(Provider.of<UserProvider>(context).user == null) {
      return;
    }
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/vehicule/getAll"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final vehiculeList = parsed.findAllElements('vehicule');
      vehiculesOfEntreprise = vehiculeList.map((vehicule) => Vehicule.fromXml(vehicule)).toList();
    } else if(response.statusCode == 404){
      vehiculesOfEntreprise = [];
    }else {
      throw Exception('Failed to load vehicules');
    }
  }

  Future<void> refreshnewVehicule() async {
    print("refreshnewVehicule"); 
    setState(() {fetchVehicules();});
  }

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
              title: const Text('Vehicules d\'entreprise'),
              leading: IconButton(
                onPressed: () {
                    Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                iconSize: 40,
              ),
            ),
           body:  FutureBuilder(
                future: fetchVehicules(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator()
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if(vehiculesOfEntreprise.isEmpty){
                    return const Center(
                      child: Text(
                        "Aucun véhicule n'est associé à votre entreprise",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic, 
                          letterSpacing: 1.2, 
                          shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))],
                        ),
                      ),
                    );
                  }else {
                    return ListView.builder(
                      itemCount: vehiculesOfEntreprise.length,
                      itemBuilder: (BuildContext context, int index) {
                        String marqueAndModele = '';
                        String userVehicule = '';
                        String entrepriseVehicule = '';

                        if (vehiculesOfEntreprise[index].marque != null || vehiculesOfEntreprise[index].marque != '' && vehiculesOfEntreprise[index].modele != null || vehiculesOfEntreprise[index].modele != '') {
                          marqueAndModele = '${vehiculesOfEntreprise[index].marque} ${vehiculesOfEntreprise[index].modele}';
                        } else {
                          marqueAndModele = 'Marque et modèle non renseignés';
                        }

                        if (vehiculesOfEntreprise[index].user != null) {
                          userVehicule = '${vehiculesOfEntreprise[index].user!.nomUser} ${vehiculesOfEntreprise[index].user!.prenomUser}';
                        } else {
                          userVehicule = 'Non attribué';
                        }

                        if (vehiculesOfEntreprise[index].entreprise != null) {
                          entrepriseVehicule = '${vehiculesOfEntreprise[index].entreprise!.nomEntreprise}';
                        } else {
                          entrepriseVehicule = 'n\'appartient à aucune entreprise';
                        }

                        return Card(
                          child: ListTile(
                            title: Text(
                              marqueAndModele, 
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16.0,
                                ),
                                children: [
                                  const TextSpan(text: 'N°V.I.N. : '),
                                  TextSpan(text: '${vehiculesOfEntreprise[index].numVin}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: '\n'),
                                  userVehicule == 'Non attribué.' ? 
                                    TextSpan( text: userVehicule,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                              )
                                    ) : 
                                    const TextSpan( text: 'Attribué à ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                              )
                                    ),
                                    TextSpan( text: userVehicule,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              )
                                    ),
                                  const TextSpan(text: '\n'),
                                  entrepriseVehicule == 'n\'appartient à aucune entreprise.' ? 
                                    TextSpan( text: entrepriseVehicule,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                              )
                                    ) : 
                                    const TextSpan( text: 'Appartient à l\'entreprise ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                              )
                                    ),
                                    TextSpan( text: '$entrepriseVehicule.',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              )
                                    ),
                                ],
                              ),
                            ),
                            onTap: () {
                            },
                          ),
                        );
                      },
                    );

                  }
                },
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async{
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVehiculeAdminPage(),
                    ),
                  );
                  await refreshnewVehicule();
                },
                label: const Text('Ajouter un véhicule'),
                icon: const Icon(Icons.add),
              ));
        } else if (user.roleUser == "ROLE_USER") {
          return const Text("Vous n'êtes pas autorisé à accéder à cette page");
        } else {
          return const Text("Erreur ? : ni admin ni user");
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
