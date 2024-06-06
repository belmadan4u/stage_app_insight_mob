import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login.dart';
import 'provider/provider_user.dart';
import 'tableau_de_bord_user.dart';
import 'admin/usersAdmin.dart';
import 'admin/vehiculesAdmin.dart';
import 'admin/cablIntAdmin.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'admin/entreprisesAdmin.dart';
import 'admin/historiqueAnomalieAdmin.dart';
import 'admin/remboursementAdmin.dart';

import 'types/types.remboursement.dart';
import 'types/types.user.dart';
import 'types/types.recharge.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'notification_user.dart';
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
      home : const MyHomePage()
    );
    
  }
}

class MyHomePage extends StatefulWidget {
  final User? user;
  const MyHomePage({super.key, this.user});
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  int _currentIndex = 0;
  bool _fetchedInfluxDB = false;
  bool _pushedInDB = false;
  bool _error = false;
  String _message = "";
  String _statusMessage = '';
  Color _colorButtonEnvoiDonnee = Colors.blue;
  late PageController _pageController = PageController();
  

  @override
  initState() {
    super.initState();
    _currentIndex = 1;
    _pageController = PageController(initialPage: 1);
    _initializeData();
  }

  void _initializeData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.fetchMontantARembourser();
      await userProvider.fetchRemboursement();
      await userProvider.fetchRecharges();
    } catch (e) {
      print('Failed to initialize data: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      Future.delayed(Duration.zero, () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const MyLoginPage(), 
          ),
          (Route<dynamic> route) => false,
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
    if(user != null) {
      if(user.roleUser == "ROLE_USER") {

        Future<List<dynamic>> fetchAutomateCumulEnergie() async {
          setState(() {
            _statusMessage = 'Récupération des données de l\'automate(Cumul)...';
          });

          final uriCumulEnergie = Uri.parse('http://192.168.1.144:8086/query?db=homedb&q=SELECT%20date_debut,date_fin,heure_debut,heure_fin,total_consommation%20FROM%20Cumul');
          final response = await http.get(uriCumulEnergie);
          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = json.decode(response.body);

            setState(() {
              _error = false;
              _pushedInDB = false;
              _fetchedInfluxDB = true;
              _statusMessage = 'Récupération des données de l\'automate(Cumul) terminée avec succès.';
            });

            return responseData['results'][0]['series'][0]['values'];
          } else {
            setState(() {
              _error = true;
              _pushedInDB = false;
              _fetchedInfluxDB = false;
              _message = 'Failed to load data(Cumul): ${response.statusCode}';
              _statusMessage = 'Échec de la récupération des données de l\'automate(Cumul).';
            });
            throw Exception('Failed to load data(Cumul): ${response.statusCode}');
          }
        }

        Future<List<dynamic>> fetchAutomateRechargeTotal() async {  
          setState(() {
            _statusMessage = 'Récupération des données de l\'automate(Recharge)...';
          });

          final uriRechargeTotal = Uri.parse('http://192.168.1.144:8086/query?db=homedb&q=SELECT%20date_debut,date_fin,heure_debut,heure_fin,total_consommation%20FROM%20RechargeTotal');
          final response = await http.get(uriRechargeTotal);
          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = json.decode(response.body);

            setState(() {
              _error = false;
              _pushedInDB = false;
              _fetchedInfluxDB = true;
              _statusMessage = 'Récupération des données de l\'automate(Recharge) terminée avec succès.';
            });

            return responseData['results'][0]['series'][0]['values'];
          } else {
            setState(() {
              _error = true;
              _pushedInDB = false;
              _fetchedInfluxDB = false;
              _message = 'Failed to load data: ${response.statusCode}';
              _statusMessage = 'Échec de la récupération des données(Recharge) de l\'automate.';
            });
            throw Exception('Failed to load data(Recharge): ${response.statusCode}');
          }
        }

        Future<void> envoyerDonneesCumulEnergie() async {
          setState(() {
            _statusMessage = 'Envoi des données vers la BDD principale...';
          });

          const String apiUrl = '${ApiConfig.baseUrl}/pushCumul';
          List<dynamic> automateDataCumul = await fetchAutomateCumulEnergie();
          List<dynamic> automateDataRecharge = await fetchAutomateRechargeTotal();
          if (!_fetchedInfluxDB) {
            return;
          }
          print("automateDataCumul : $automateDataCumul");
          print("automateDataRecharge : $automateDataRecharge");
          try {
            final response = await http.post(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'id_user': user.idUser,
                'data': automateDataCumul,
                'recharge': automateDataRecharge,
              }),
            );

            if (response.statusCode == 200) {
              setState(() {
                _pushedInDB = true;
                _error = false;
                _fetchedInfluxDB = false;
                _message = response.body;
                _statusMessage = 'Envoi des données vers la BDD principale terminé.';
              });
              print(response.body);
            } else {
              setState(() {
                _error = true;
                _pushedInDB = false;
                _fetchedInfluxDB = false;
                _message = response.body;
                _statusMessage = 'Échec de l\'envoi des données vers la BDD principale.';
              });
              print(response.body);
            }
          } catch (e) {
            setState(() {
              _error = true;
              _pushedInDB = false;
              _fetchedInfluxDB = false;
              _message = e.toString();
              _statusMessage = 'Erreur lors de l\'envoi des données vers la BDD principale.';
            });
            print(e.toString());
          }
        }
        
       String periodeRemboursement(String dateAnniversaire) {
        DateTime now = DateTime.now();
        int dayAnniversaire = int.parse(dateAnniversaire);
        int currentDay = now.day;
        int currentMonth = now.month;
        int currentYear = now.year;

        if (currentMonth < 12) {
            if (currentDay < dayAnniversaire) {
              DateTime startDate = DateTime(currentYear, currentMonth -1, dayAnniversaire);
              DateTime endDate = DateTime(currentYear, currentMonth, dayAnniversaire);
              return '${startDate.day}/${startDate.month}/${startDate.year} au ${endDate.day}/${endDate.month}/${endDate.year}';
            } else {
              DateTime startDate = DateTime(currentYear, currentMonth, dayAnniversaire);
              DateTime endDate = DateTime(currentYear, currentMonth + 1, dayAnniversaire);
              return '${startDate.day}/${startDate.month}/${startDate.year} au ${endDate.day}/${endDate.month}/${endDate.year}';
            }
        } else {
          DateTime startDate = DateTime(currentYear, currentMonth, dayAnniversaire);
          DateTime endDate = DateTime(currentYear + 1, 1, dayAnniversaire);
          return '${startDate.day}/${startDate.month}/${startDate.year} au ${endDate.day}/${endDate.month}/${endDate.year}';
        }
        
      }

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 70,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              leading: IconButton(
                onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationsPage()),
                    );
                },
                icon: const Icon(Icons.notifications),
                iconSize: 40,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  iconSize: 40 ,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TabDeBordUserPage()),
                    );
                  },
                ),
              ],
            ),
            body: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [ 
                  RefreshIndicator(
                    onRefresh: () async{
                      _initializeData();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Text(
                                    'Historique des remboursements',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16), 
                                userProvider.remboursements.isEmpty ? 
                                        const Center(
                                          child: Text(
                                            'Aucun remboursement',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ) :
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: userProvider.remboursements.length,
                                          itemBuilder: (context, index) {
                                            final remboursement = userProvider.remboursements[index];
                                            return Card(
                                              child: ListTile(
                                                title: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      "${remboursement.montant!} €",
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          remboursement.dateTransmission!,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.normal,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Text(
                                                  "Période : \n${remboursement.periodeDebut!} au ${remboursement.periodeFin!}",
                                                ),
                                              ),
                                            );
                                          },
                                        )
                              
                            ],
                          ),
                      ),
                    )
                  ),
                  RefreshIndicator(
                    onRefresh: () async{
                      _initializeData();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Column(
                          children: <Widget>[
                            Container(
                              height: MediaQuery.of(context).size.height * 0.8,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width, 
                                  child: const Text(
                                    'Votre entreprise vous doit',
                                    textAlign: TextAlign.center, 
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                ),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: Size(MediaQuery.of(context).size.width * 0.75, MediaQuery.of(context).size.width * 0.75),
                                      painter: CirclePainter(),
                                    ), Text(
                                            NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(userProvider.montantARembourser),
                                            style: const TextStyle(
                                              fontSize: 50,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                  ],
                                ),
                                Text(
                                  user.idEntrepriseUser == null || user.idEntrepriseUser!.dateAnniversaire == null ? 'Erreur dans la récupération de la date de remboursement' : 'pour la période du ${periodeRemboursement(user.idEntrepriseUser!.dateAnniversaire!)}' ,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _pushedInDB = false;
                                        _error = false;
                                        _fetchedInfluxDB = false;
                                        _message = "";
                                        _statusMessage = '';
                                        _colorButtonEnvoiDonnee = Colors.blue[400]!;
                                      });
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Veuillez patienter'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const CircularProgressIndicator(),
                                                const SizedBox(height: 20),
                                                Text(_statusMessage),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                      await envoyerDonneesCumulEnergie();
                                      Navigator.of(context).pop();
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          String? titre;
                                          if (_fetchedInfluxDB) {
                                            titre = 'Envoi des données...';
                                          } else if (_pushedInDB) {
                                            titre = 'Données envoyées';
                                          } else if (_error) {
                                            titre = 'Erreur';
                                          } else {
                                            titre = 'Erreur inconnue';
                                          }
                                          return AlertDialog(
                                            title: Text(titre),
                                            content: jsonDecode(_message)['message'] != null
                                                ? Text(jsonDecode(_message)['message'])
                                                : const Text('Erreur inconnue'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  _initializeData();
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      _colorButtonEnvoiDonnee = Colors.blue;
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _colorButtonEnvoiDonnee,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    ),
                                    child: const Text(
                                      'Envoyer les données...',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                
                              ]
                            )
                          ),
                        ],
                      ),
                    )
                  )
                  ),
                  RefreshIndicator(
                    onRefresh: () async{
                      _initializeData();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child:
                  Center(
                    child:  userProvider.recharges.isEmpty ? 
                          const Center(
                            child: Text(
                              'Aucune recharge',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ) :
                          ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: userProvider.recharges.keys.length,
                                  itemBuilder: (context, index) {
                                    final day = userProvider.recharges.keys.elementAt(index);
                                    final recharges = userProvider.recharges[day]!;
                                    return ExpansionTile(
                                      initiallyExpanded: true,
                                      title: Text(
                                        DateFormat('dd/MM/yyyy').format(DateTime.parse(day)),
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      children: recharges.map((recharge) {
                                        DateTime dateTimeDebut = DateTime.parse('${recharge.dateDebut} ${recharge.heureDebut}');
                                        DateTime dateTimeFin = DateTime.parse('${recharge.dateFin} ${recharge.heureFin}');
                                        Duration difference = dateTimeFin.difference(dateTimeDebut);
                                        String duree = '';
                                        if (difference.inDays != 0) {
                                          duree = '${difference.inDays} jours';
                                        }
                                        if (difference.inHours % 24 != 0) {
                                          duree = '$duree ${difference.inHours % 24} heures';
                                        }
                                        if (difference.inMinutes % 60 != 0) {
                                          duree = '$duree ${difference.inMinutes % 60} minutes';
                                        }
                                        if (difference.inSeconds % 60 != 0) {
                                          duree = '$duree ${difference.inSeconds % 60} secondes';
                                        }
                                        duree = duree.trim();
                                        return ListTile(
                                          title: Text('de ${recharge.heureDebut} à ${recharge.heureFin}\nDurée : $duree',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.normal,
                                                      color: Colors.grey[800],
                                                    )),
                                          subtitle: Text('Consommation: ${recharge.totalConsommation} kWh\nCoût: ${recharge.cout} €',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.normal,
                                                      color: Colors.black,
                                                    ),),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                        )
                    )
                  )
                ]
              )
            
            ,
            bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            onTap: (index) {
              _currentIndex = index;
              setState(() {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.monetization_on),
                label: 'Remboursements',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.battery_charging_full),
                label: 'Recharges',
              ),
            ],
          )
            
            );
          
        } /*else if (user.roleUser == "ROLE_ADMIN") {
           return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                toolbarHeight: 70,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    iconSize: 40 ,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TabDeBordUserPage()),
                      );
                    },
                  ),
                ],
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          "Bienvenue ${user.nomUser} ${user.prenomUser}",
                          style: const TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ),
              body: Container( 
                  color: Colors.white,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UsersOfAdminPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(245, 248, 253, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), 
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Vos employés',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 30, 
                                      fontFamily: 'Arial', 
                                      height: 3, 
                                    ),
                                  ),
                                  const Spacer(), 
                                  Container(
                                    alignment: Alignment.bottomLeft,
                                    child:const Text(
                                      'Gérer vos employés, gérer leurs droits...',
                                      style: TextStyle(
                                        fontSize: 22, // Taille du texte plus petite
                                        fontFamily: 'Arial', // Police du texte
                                        color: Colors.grey, // Couleur du texte explicatif
                                        height: 1.5, // Espacement entre les lignes
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25), 
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CablIntAdminPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(245, 248, 253, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Vos Câbles Intelligents',
                                    style: TextStyle(
                                      overflow: TextOverflow.fade,
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 30, 
                                      fontFamily: 'Arial', 
                                      height: 1, 
                                    ),
                                  ),
                                  const Spacer(), // Ajout d'un espace flexible pour pousser le texte vers le bas
                                  Container(
                                    alignment: Alignment.bottomLeft,
                                    child:const Text(
                                      'Gérer cables inteligent, à quels de vos véhicules ils sont attribués...',
                                      style: TextStyle(
                                        overflow: TextOverflow.fade,
                                        fontSize: 22, 
                                        fontFamily: 'Arial', 
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25), 
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const VehiculeOfAdminPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(245, 248, 253, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), 
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Vos E-Véhicules',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 30, 
                                      fontFamily: 'Arial', 
                                      height: 3, 
                                    ),
                                  ),
                                  const Spacer(), 
                                  Container(
                                    alignment: Alignment.bottomLeft,
                                    child:const Text(
                                      'Gérer vos e-véhicule, attribuer-les à vos employés...',
                                      style: TextStyle(
                                        fontSize: 22, 
                                        fontFamily: 'Arial', 
                                        color: Colors.grey, 
                                        height: 1.5, 
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                )
              )
            );
        } */else if(user.roleUser == "ROLE_SUPERADMIN"){
        return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              toolbarHeight: 70,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.monetization_on),
                  iconSize: 40 ,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RemboursementsAdminPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.error),
                  iconSize: 40 ,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoriqueAnomalieAdminPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  iconSize: 40,
                  onPressed: () {
                    userProvider.logout();
                  },
                ),
              ],
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Expanded(
                      child: Text(
                        "Bienvenue ${user.nomUser}",
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                        overflow: TextOverflow.ellipsis, // Ajoute cette ligne pour gérer le débordement
                      ),
                    ),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(padding: EdgeInsets.all(15.0),child: Text(
                      'Que souhaitez-vous gérer ?',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    )) ,
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width / 2,
                          child: Padding(
                            padding: const EdgeInsets.all(13.0),
                            child:
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AllEntreprisePage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Icon(
                                          Icons.business_sharp,
                                          size: 80,
                                          color: Colors.blueAccent,
                                        )
                              ),
                          )
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 2,
                                height: MediaQuery.of(context).size.width / 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(13.0),
                                  child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const UsersOfAdminPage(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[100],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.people,
                                          size: 80,
                                          color: Colors.blueAccent,
                                        )
                                      ),
                                )
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 2,
                                height: MediaQuery.of(context).size.width / 2,
                                child:
                                Padding(
                                  padding: const EdgeInsets.all(13.0),
                                  child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const VehiculeOfAdminPage(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[100],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.directions_car,
                                          size: 80,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                )
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width / 2,
                          child: Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CablIntAdminPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Icon(
                                            Icons.settings_input_component,
                                            size: 80,
                                            color: Colors.blueAccent,
                                          ),
                            ),
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Divider(
                      height: 10,
                      color: Colors.blueAccent,
                      thickness: 2,
                      indent: 20,
                      endIndent: 20,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Statistiques',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 2),
                    ),
                  ],
                ),
              ),
            ),
            );
            
          
        }else {
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
        ); });
        return const Center(child: Text('erreur'));
    }
      
  }
}

class CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint outerCirclePaint = Paint()
      ..color = Colors.blue 
      ..style = PaintingStyle.fill; 

    Paint innerCirclePaint = Paint()
      ..color = Colors.white 
      ..style = PaintingStyle.fill; 

    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double outerRadius = size.width / 2.3;
    double innerRadius = size.width / 2.5;

    canvas.drawCircle(Offset(centerX, centerY), outerRadius, outerCirclePaint);
    canvas.drawCircle(Offset(centerX, centerY), innerRadius, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}