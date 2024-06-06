
import 'package:flutter/material.dart';
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import '../login.dart';
import '../provider/provider_user.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../types/types.remboursement.dart';
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
      home: const RemboursementsAdminPage(),
    );
  }
}

class RemboursementsAdminPage extends StatefulWidget {
  final User? user;
  const RemboursementsAdminPage({super.key, this.user});
  
  @override
  State<RemboursementsAdminPage> createState() => RemboursementsAdminPageState();
}

class RemboursementsAdminPageState extends State<RemboursementsAdminPage> {
  String? datePeriodique;

late List<Remboursement> remboursements = [];

  Future<void> fetchRemboursement() async {
    if(Provider.of<UserProvider>(context).user == null) {
      return;
    }
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/remboursement/getAll"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final remboursementList = parsed.findAllElements('remboursement');
      remboursements = remboursementList.map((nodeRemboursement) => Remboursement.fromXml(nodeRemboursement)).toList();
    } else if(response.statusCode == 404){
      remboursements = [];
    }else {
      throw Exception('Failed to load remboursements');
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
              title: const Text('Remboursements'),
              leading: IconButton(
                onPressed: () {
                    Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                iconSize: 40,
              ),
            ),
            body: FutureBuilder(
                future: fetchRemboursement(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator()
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if(remboursements.isEmpty){
                    return const Center(
                      child: Text(
                        "Aucun remboursement n'a été fait pour le moment",
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
                      itemCount: remboursements.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: ListTile(
                            title: Text(remboursements[index].user!.nomUser!,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold
                                        ),
                                    ),
                            subtitle: Text("Montant : ${remboursements[index].montant!}\n Période de remboursement : ${remboursements[index].periodeDebut!} - ${remboursements[index].periodeFin!}"),
                            trailing: Text("Date de transmission : \n${remboursements[index].dateTransmission!}"),
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
