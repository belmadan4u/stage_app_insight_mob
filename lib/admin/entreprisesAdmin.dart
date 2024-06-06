import 'package:flutter/material.dart';
import 'package:insight_mobility_app/types/types.entreprise.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import '../login.dart';
import '../provider/provider_user.dart';
import '../api_config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:insight_mobility_app/admin/entrepriseAdmin.dart';


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
      home: const AllEntreprisePage(),
    );
  }
}

class AllEntreprisePage extends StatefulWidget {
  final User? user;
  const AllEntreprisePage({super.key, this.user});
  
  @override
  State<AllEntreprisePage> createState() => AllEntreprisePageState();
}

class AllEntreprisePageState extends State<AllEntreprisePage> {
  String strRecherche = "";
  String? datePeriodique;
  late List<Entreprise> entreprisesAll = [];
  List<Entreprise> entrepriseFiltre = [];

  @override
  void initState() {
    super.initState();
    fetchEntreprises(); 
  }

  Future<void> fetchEntreprises() async {
    if (Provider.of<UserProvider>(context).user == null) {
      return;
    }
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/entreprises/getAll"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final entrepriseList = parsed.findAllElements('entreprise');
        entreprisesAll = entrepriseList.map((entreprise) => Entreprise.fromXml(entreprise)).toList();
        _filtrerEntreprises();
    } else if (response.statusCode == 404) {
        entreprisesAll = []; 
      
    } else {
      throw Exception('Failed to load entreprises');
    }
  }

  void _filtrerEntreprises() {
    entrepriseFiltre = entreprisesAll.where((entreprise) =>
      entreprise.nomEntreprise!.toLowerCase().contains(strRecherche.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if(user != null) {
      if(user.roleUser == "ROLE_SUPERADMIN"){
        return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              toolbarHeight: 70,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      "Toutes les Entreprises",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Recherche par nom d'entreprise",
                      hintText: "Recherchez",
                      icon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                        setState(() {
                          strRecherche = value;
                          _filtrerEntreprises();
                        });
                      
                    },
                  ),
                ),
                FutureBuilder(
                  future: fetchEntreprises(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator()
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      if(entrepriseFiltre.isEmpty){
                         return const Expanded(
                          child: Center(
                            child: Text(
                              'Aucune entreprise n\'a le nom que vous recherchez.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      } else {
                      return Expanded(
                        child:ListView.builder(
                          itemCount: entrepriseFiltre.length,
                          itemBuilder: (BuildContext context, int index) {
                              return Card(
                                child: ListTile(
                                  title: Text('${entrepriseFiltre[index].nomEntreprise }'),
                                  subtitle: Text("Ville: ${entrepriseFiltre[index].villeEntreprise}, Pays: ${entrepriseFiltre[index].paysEntreprise} \n ID : ${entrepriseFiltre[index].idEntreprise}",),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EntreprisePage(entreprise: entrepriseFiltre[index]),
                                      ),
                                    );
                                  },
                                ),
                              );
                          },
                        )
                      );
                      }
                      
                    }
                  },
                ),
              ],
            ),
          );
            
          
        }else {
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
