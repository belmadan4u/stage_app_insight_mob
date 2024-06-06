import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:insight_mobility_app/types/types.vehicule.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import './types/types.entreprise.dart';
import 'api_config/api_config.dart';
import 'login.dart';
import 'home.dart';
import 'changerMdp.dart';
import 'provider/provider_user.dart';
import './types/types.user.dart';
import 'qr_code_scanner_screen.dart';
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const TabDeBordUserPage(),
    );
  }
}

class TabDeBordUserPage extends StatefulWidget {
  const TabDeBordUserPage({Key? key});

  @override
  State<TabDeBordUserPage> createState() => TabDeBordUserState();
}

class TabDeBordUserState extends State<TabDeBordUserPage> with TickerProviderStateMixin{ // ajout du with .. pour que le _tabController fonctionne
  PageController _pageController = PageController();
  late TabController _tabController;
  Vehicule? vehiculeUser;
  String? referenceCabInt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 4);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> getVehiculeUser(idUser) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/vehicule/getVehiculeNumVinMarqueModeleImmatByIdUser/$idUser'));
    if (mounted) {
      if (response.statusCode == 200) {
        final xmlDoc = xml.XmlDocument.parse(response.body);
        final vehiculeNode = xmlDoc.findElements('vehicule').first;
        setState(() {
          vehiculeUser = Vehicule(numVin: vehiculeNode.findElements('num_vin').single.innerText, 
                   marque: vehiculeNode.findElements('marque').single.innerText, 
                   modele: vehiculeNode.findElements('modele').single.innerText,
                   user: null, 
                   entreprise: null,
                   immat: vehiculeNode.findElements('immat').single.innerText, 
                   idCablint: null);
        });
      } else if (response.statusCode == 404) {
        setState(() {
          vehiculeUser = Vehicule(numVin: 'Vous n\'avez pas de véhicule enregistré', 
                   marque: null, 
                   modele: null,
                   user: null, 
                   entreprise: null,
                   immat: null, 
                   idCablint: null);
        });
      } else if(response.statusCode == 500) {
        throw Exception('Erreur serveur');
      } else {
        throw Exception('Erreur: ${response.reasonPhrase}');
      }
    }
  }

  Future<void> getIdCableIntbyIdUser(idUser) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/cable/getIdCableIntbyIdUser/$idUser'));
    if (mounted) {
      if (response.statusCode == 200) {
        final xmlDoc = xml.XmlDocument.parse(response.body);
        final vehiculeNode = xmlDoc.findElements('cable_int').first;
        setState(() {
          referenceCabInt = vehiculeNode.findElements('id_cablint').single.innerText;
        });
      } else if (response.statusCode == 404 || response.statusCode == 500) {
        setState(() {
          referenceCabInt = 'Non renseigné';
        });
      } else {
        throw Exception('Erreur: ${response.reasonPhrase}');
      }
    }
  }
  
  Widget _buildTab(String title, int index) {
    return Tab(
      child: SizedBox(
        width: double.infinity,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user != null) {
      

      getVehiculeUser(user.idUser);
      getIdCableIntbyIdUser(user.idUser);

      return DefaultTabController(
        length: 4,
        child : Scaffold(
          appBar: AppBar(
            title: const Text('Tableau de Bord'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                iconSize: 40,
                onPressed: () {
                  userProvider.logout();
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorWeight: 4.0,
              labelPadding: EdgeInsets.zero,
              onTap: (index) {
                setState(() {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                });
              },
              tabs: [
                _buildTab('Véhicule', 0),
                _buildTab('Câble', 1),
                _buildTab('Entreprise', 2),
                _buildTab('Informations Personnelles', 3),
              ],
            ),
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (int index) {
              _tabController.animateTo(index);
            },
            children: [
              VehiculePage(vehiculeUser : vehiculeUser),
              CablePage(referenceCabInt: referenceCabInt),
              EntreprisePage(entreprise: user.idEntrepriseUser,),
              InformationsPersonnellesPage(user: user),
            ],
          ),
        )
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyLoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                );
      return const SizedBox.shrink();
    }
  }
}

class VehiculePage extends StatelessWidget {
  final Vehicule? vehiculeUser;

  const VehiculePage({super.key, this.vehiculeUser});

  @override
  Widget build(BuildContext context) {
    if(vehiculeUser?.numVin == 'Vous n\'avez pas de véhicule enregistré'){
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Vous n\'avez pas de véhicule enregistré', style: TextStyle(fontSize: 20)),
            
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          title: const Text('Marque et modèle :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          subtitle: Text(vehiculeUser == null ? 'Chargement...' : "${vehiculeUser?.marque} ${vehiculeUser?.modele}", style: const TextStyle(fontSize: 20)),
        ),
        ListTile(
          title: const Text('Immatriculation :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          subtitle: Text(vehiculeUser == null ? 'Chargement...' : "${vehiculeUser?.immat}", style: const TextStyle(fontSize: 20)),
        ),
        ListTile(
          title: const Text('Véhicule identification number (V.I.N.) :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          subtitle: Text(vehiculeUser == null ? 'Chargement...' : "${vehiculeUser?.numVin}", style: const TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
}

class CablePage extends StatelessWidget {
  final String? referenceCabInt;

  const CablePage({super.key, this.referenceCabInt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          title: const Text('Référence CabInt:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(referenceCabInt == null ? 'Chargement...' : referenceCabInt!, style: const TextStyle(fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.qr_code, size: 40,),
                color: Colors.black,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QRCodeScannerScreen()),
                  );
                },
              ),
            ]
          ),
        ),
      ],
    );
  }
}

class EntreprisePage extends StatelessWidget {
  final Entreprise? entreprise;

  const EntreprisePage({super.key, this.entreprise});

  @override
  Widget build(BuildContext context) {
    String prochainRemboursement = '';
    if(entreprise == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Vous n\'êtes pas rattaché à une entreprise', style: TextStyle(fontSize: 20)),
          ],
        ),
      );
    }

    

    if(DateTime.now().day < int.parse(entreprise!.dateAnniversaire!)) { // date actuelle : 03/06/2024, periode remb : 07/05/2024 au 07/06/2024
      if(DateTime.now().month < 12) {
        prochainRemboursement = "${int.parse(entreprise!.dateAnniversaire!)}/${DateTime.now().month}/${DateTime.now().year}";
      } 
    }else if(DateTime.now().day >= int.parse(entreprise!.dateAnniversaire!)){ // date actuelle : 30/05/2024, periode remb : 07/05/2024 au 07/06/2024
      if(DateTime.now().month < 12) {
        prochainRemboursement = "${int.parse(entreprise!.dateAnniversaire!)}/${DateTime.now().month + 1}/${DateTime.now().year}";
      } 
    }else {
      prochainRemboursement = "${int.parse(entreprise!.dateAnniversaire!)}/01/${DateTime.now().year  + 1}";
    }
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          title: const Text('Employé chez :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          subtitle: Text(entreprise == null ? 'Chargement...' : "${entreprise?.nomEntreprise}", style: const TextStyle(fontSize: 20)),
        ),
        ListTile(
          title: const Text('Domicilisation de l\'entreprise :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          subtitle: Text(entreprise == null ? 'Chargement...' : "${entreprise?.cpEntreprise}, ${entreprise?.villeEntreprise}, ${entreprise?.paysEntreprise}", style: const TextStyle(fontSize: 20)),
        ),

        if(entreprise!.dateAnniversaire != null)
          ListTile(
            title: const Text('Periodicité de remboursements :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            subtitle: Text(entreprise == null ? 'Chargement...' : "Tous les ${entreprise?.dateAnniversaire} du mois.", style: const TextStyle(fontSize: 20)),
          ),
          ListTile(
            title: const Text('Prochain remboursement prévu le :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            subtitle: Text(entreprise == null ? 'Chargement...' : prochainRemboursement, style: const TextStyle(fontSize: 20)),
          ),
      ],
    );
  }
}

class InformationsPersonnellesPage extends StatelessWidget {
  final User user;

  const InformationsPersonnellesPage({Key? key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoTile(context, 'Nom:', user.nomUser!, 'Nom'),
        _buildInfoTile(context, 'Prénom:', user.prenomUser!, 'Prénom'),
        _buildInfoTile(context, 'Email:', user.emailUser!, 'Email'),
        _buildInfoTile(context, 'Téléphone:', user.telUser!, 'Téléphone'),
        _buildInfoTile(context, 'Adresse:', user.adresseUser!, 'Adresse'),
        _buildInfoTile(context, 'Mot de passe:', user.mdpUser!, 'Mot de passe', hasButton: 'changeMdp'),
        _buildInfoTile(context, 'Contrat abonnement électrique:', user.idAboUser == null ? 'Non renseigné' : user.idAboUser!.nomAbo!, 'Abonnement électrique', hasButton: 'changerAbo'),
      ],
    );
  }
  
  Widget _buildInfoTile(BuildContext context, String title, String value, String fieldName, {String hasButton = 'edit'}) {
    String NumTelFormatte = '';
    if(fieldName == 'Téléphone') {
      for(int i = 0; i < value.length; i++) {
        NumTelFormatte = NumTelFormatte + value[i];
        if(i.isEven) {
          NumTelFormatte += ' ';
        }
      }
      NumTelFormatte = '+33 $NumTelFormatte';
    }

    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text( fieldName == 'Téléphone' ? NumTelFormatte : value, style: const TextStyle(fontSize: 20)),
          ),
          if (hasButton == 'edit')
            IconButton(
              onPressed: () {
                _showEditDialog(context, fieldName, value);
              },
              icon: const Icon(Icons.edit_document, size: 30),
            ),
          if(hasButton == 'changeMdp')
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangerMdpUser()),
                );
              },
              child: const Text('Changer'),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String fieldName, String value) {
    String? newValue = value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        Map<String, String> fieldToText = {
          'Nom': 'votre nom',
          'Prénom': 'votre prénom',
          'Email': 'votre email',
          'Téléphone': 'votre numéro de téléphone',
          'Adresse': 'votre adresse',
        };
        return AlertDialog(
          title: Text('Modifier ${fieldToText[fieldName]}'),
          content: fieldName == 'Téléphone' ?
            Row(
              children: [
                const Text('+33  ', style: TextStyle(fontSize: 19),),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Nouveau numéro',
                    ),
                    controller: TextEditingController(text: value),
                    onChanged: (text) {
                      newValue = text;
                    },
                    keyboardType: TextInputType.number, 
                  ),
                ),
              ],
            ) : fieldName == 'Adresse' ? 
              TextField(
              decoration: const InputDecoration(
                hintText: 'Nouvelle valeur',
              ),
              onChanged: (text) async {
                print('text : ' +Uri.encodeFull(text));
                try {
                  final response = await http.get(Uri.parse('https://api-adresse.data.gouv.fr/search/?q=${Uri.encodeComponent(text)}&type=housenumber&autocomplete=1'));
                  if (response.statusCode == 200) {
                    print(response.body);
                  } else {
                    print('Erreur de requête: ${response.statusCode}');
                  }
                } catch (e) {
                  print('Exception: $e');
                }
              },
            ):
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Nouvelle valeur',
                ),
                controller: TextEditingController(text: value),
                onChanged: (text) {
                  newValue = text;
                },
              ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () { 
                _updateUser(context, fieldName, newValue);
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  void _updateUser(BuildContext context, String fieldName, String? newValue) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    newValue = newValue!.trim();
    // Validation en fonction du champ à mettre à jour
    switch (fieldName) {
      case 'Nom':
      case 'Prénom':
        if (RegExp(r'^[a-zA-Z- ]{2,}$').hasMatch(newValue!)) {
          if (fieldName == 'Nom') {
            final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/user/updateNomUser/${userProvider.user!.idUser}/$newValue'));
            if(response.statusCode == 200) {
              userProvider.updateUserNom(newValue);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Le $fieldName a été mis à jour avec succès.'),
                  backgroundColor: Colors.greenAccent,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur dans le changement du $fieldName. Veuillez réessayer.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          } else {
            final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/user/updatePrenomUser/${userProvider.user!.idUser}/$newValue'));
            if(response.statusCode == 200) {
              userProvider.updateUserPrenom(newValue);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Le $fieldName a été mis à jour avec succès.'),
                  backgroundColor: Colors.greenAccent,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur dans le changement du $fieldName. Veuillez réessayer.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Le $fieldName doit être composé de lettres et contenir au moins 2 caractères.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        break;
      case 'Email':
        if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newValue!)) {
          final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/user/updateMailUser/${userProvider.user!.idUser}/$newValue'));
            if(response.statusCode == 200) {
              userProvider.updateUserEmail(newValue);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Le $fieldName a été mis à jour avec succès.'),
                  backgroundColor: Colors.greenAccent,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur dans le changement du $fieldName. Veuillez réessayer.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez entrer une adresse email valide.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        break;
      case 'Téléphone':
        if (RegExp(r'^[0-9]+$').hasMatch(newValue!) && newValue.length == 9) {
          final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/user/updateTelUser/${userProvider.user!.idUser}/$newValue'));
            if(response.statusCode == 200) {
              userProvider.updateUserTelephone(newValue);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Le $fieldName a été mis à jour avec succès.'),
                  backgroundColor: Colors.greenAccent,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur dans le changement du $fieldName. Veuillez réessayer.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
        } else {
          if(newValue.length != 9) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Le numéro de téléphone doit contenir 9 caractères sans l\'indicatif (+33).')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Le numéro de téléphone doit contenir uniquement des chiffres.')),
            );
          }
        }
        break;
      case 'Adresse':
        //userProvider.updateUserAdresse(newValue);
        break;
    }
  }

}
