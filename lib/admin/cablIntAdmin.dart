import 'package:flutter/material.dart';
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import '../login.dart';
import '../provider/provider_user.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../types/types.cablInt.dart';
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
      home: const CablIntAdminPage(),
    );
  }
}

class CablIntAdminPage extends StatefulWidget {
  final User? user;
  const CablIntAdminPage({super.key, this.user});
  
  @override
  State<CablIntAdminPage> createState() => CablIntAdminPageState();
}

class CablIntAdminPageState extends State<CablIntAdminPage> {
  late List<CablInt> cablIntAll = [];

  Future<void> fetchCablInts() async {
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/cable/getAllCables"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final cablIntList = parsed.findAllElements('cablint');
      cablIntAll = cablIntList.map((cablInt) => CablInt.fromXml(cablInt)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  /*Future<String?> isCablIntAssociatedWithACar(cablInt) async {
    if(cablInt == null) {
      return null;
    }
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/vehicule/getVehiculeByIdCable/$cablInt"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final vehiculeAssocieCablInt = parsed.findAllElements('vehicules').first;
      return "${Vehicule.fromXml(vehiculeAssocieCablInt).marque} ${Vehicule.fromXml(vehiculeAssocieCablInt).modele}";
    } else if(response.statusCode == 404){
      return "Pas de véhicule associé";
    } else {
      throw Exception('Failed to load users');
    }
  }*/

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
              title: const Text('Câbles'),
              leading: IconButton(
                onPressed: () {
                    Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                iconSize: 40,
              ),
            ),
           body: FutureBuilder(
                future: fetchCablInts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator()
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return ListView.builder(
                      itemCount: cablIntAll.length,
                      itemBuilder: (BuildContext context, int index) {
                        String? nomPrenomUser = "${cablIntAll[index].user?.nomUser} ${cablIntAll[index].user?.prenomUser}";
                        String? nomEntreprise = cablIntAll[index].entreprise?.nomEntreprise;
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${cablIntAll[index].idCablInt} ',
                            ),
                            subtitle: Text(
                              'Utilisateur : $nomPrenomUser \n'
                              'Entreprise : $nomEntreprise.'
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                            onTap: () {
                              
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              )
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
