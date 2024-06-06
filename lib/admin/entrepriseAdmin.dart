import 'package:flutter/material.dart';
import 'package:insight_mobility_app/types/types.entreprise.dart';
import 'package:provider/provider.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import '../login.dart';
import '../provider/provider_user.dart';
import '../api_config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: const Color(0xFF008EFE)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const EntreprisePage(),
    );
  }
}

class EntreprisePage extends StatefulWidget {
  final User? user;
final Entreprise? entreprise;

  const EntreprisePage({super.key, this.user, this.entreprise});
  
  @override
  State<EntreprisePage> createState() => EntreprisePageState();
}

class EntreprisePageState extends State<EntreprisePage> {
  Entreprise? entreprise;

  @override
  void initState() {
    super.initState();
    entreprise = widget.entreprise;
  }

  late List<User> usersOfEntreprise = [];
  late List<User> adminOfEntreprise = [];

  Future<void> fetchUsersAndAdmins() async {
    try {
      final usersResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/user/getUsersByIdEntreprise/${entreprise?.idEntreprise}'));
      final adminResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/user/getAdminbyIdEntreprise/${entreprise?.idEntreprise}'));
      
      if(usersResponse.statusCode == 200 ) {
        final parsedUsers = xml.XmlDocument.parse(usersResponse.body);
        final users = parsedUsers.findAllElements('user');

        usersOfEntreprise = users.map((e) => User.fromXml(e, 9)).toList();
        print(usersOfEntreprise);
      } else {
        usersOfEntreprise = [];
      }

      if( adminResponse.statusCode == 200) {
        final parsedAdmins = xml.XmlDocument.parse(adminResponse.body);
        final admins = parsedAdmins.findAllElements('user');

        adminOfEntreprise = admins.map((e) => User.fromXml(e, 9)).toList();
        print(adminOfEntreprise);
      } else {
        adminOfEntreprise = [];
      }
    } catch (e) {
      usersOfEntreprise = [];
      adminOfEntreprise = [];
    }
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
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      entreprise?.nomEntreprise ?? 'erreur',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text('Employés de l\'entreprise', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  FutureBuilder(
                    future: fetchUsersAndAdmins(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        if (snapshot.hasError) {
                          return const Center(child: Text('Erreur de chargement'));
                        }
                        return ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            if (adminOfEntreprise.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text('Administrateurs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              for (var admin in adminOfEntreprise)
                                ListTile(
                                  title: Text(admin.nomUser!),
                                  subtitle: Text(admin.prenomUser!),
                                  trailing: const Text('Admin', style: TextStyle(color: Colors.red)),
                                ),
                              const Divider(),
                            if(adminOfEntreprise.isEmpty) const Center(child: Text('Aucun administrateur trouvé')),

                            if (usersOfEntreprise.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text('Employés', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              for (var employee in usersOfEntreprise)
                                ListTile(
                                  title: Text(employee.nomUser!),
                                  subtitle: Text(employee.prenomUser!),
                                ),
                              const Divider(),
                            if(usersOfEntreprise.isEmpty) const Center(child: Text('Aucun employé trouvé')),
                          ],
                        );
                      }
                    },
                  ),
                ] ,
              ),
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
