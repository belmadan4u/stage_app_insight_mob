
import 'package:flutter/material.dart';
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import '../login.dart';
import '../provider/provider_user.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../types/types.historiqueAnomalies.dart';
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
      home: const HistoriqueAnomalieAdminPage(),
    );
  }
}

class HistoriqueAnomalieAdminPage extends StatefulWidget {
  final User? user;
  const HistoriqueAnomalieAdminPage({super.key, this.user});
  
  @override
  State<HistoriqueAnomalieAdminPage> createState() => HistoriqueAnomalieAdminPageState();
}

class HistoriqueAnomalieAdminPageState extends State<HistoriqueAnomalieAdminPage> {
  String? datePeriodique;

late List<HistoriqueAnomalie> historiqueAnomalie = [];

  Future<void> fetchHistoriqueAnomalies() async {
    if(Provider.of<UserProvider>(context).user == null) {
      return;
    }
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/historiqueAnomalie/getAll"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final anomaliesList = parsed.findAllElements('anomalie');
      historiqueAnomalie = anomaliesList.map((xml.XmlElement anomalie) {
        return HistoriqueAnomalie.fromXml(anomalie);
      }).toList();
    } else if(response.statusCode == 404){
      historiqueAnomalie = [];
    }else {
      throw Exception('Failed to load anomalies\'s historique');
    }
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
              title: const Text('Historique des anomalies'),
              leading: IconButton(
                onPressed: () {
                    Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                iconSize: 40,
              ),
            ),
            body: FutureBuilder(
                future: fetchHistoriqueAnomalies(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator()
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if(historiqueAnomalie.isEmpty){
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
                      itemCount: historiqueAnomalie.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: ListTile(
                            title: Text('ID cable : ${historiqueAnomalie[index].cablInt!.idCablInt}'),
                            subtitle: Text('Date de réception des données : ${historiqueAnomalie[index].dateReceptionDonnee}\nUser : ${historiqueAnomalie[index].cablInt!.user!.nomUser} ${historiqueAnomalie[index].cablInt!.user!.prenomUser} \nEntreprise : ${historiqueAnomalie[index].cablInt!.entreprise!.nomEntreprise}'),
                            trailing: Text('Code erreur : ${historiqueAnomalie[index].codeErreur}'),
                          ),
                        );
                      }
                    );
                  }
                }
            )
          );
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
