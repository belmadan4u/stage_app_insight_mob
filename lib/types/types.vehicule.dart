import 'package:insight_mobility_app/types/types.entreprise.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import 'package:xml/xml.dart' as xml;
class Vehicule {
  String? numVin;
  String? marque;
  String? modele;
  User? user;
  Entreprise? entreprise;
  String? immat;
  String? idCablint;

  Vehicule({
    required this.numVin,
    required this.marque,
    required this.modele,
    required this.user,
    required this.entreprise,
    required this.immat,
    required this.idCablint,
  });

  factory Vehicule.fromXml(xml.XmlElement vehiculeNode) {
    var userElement = vehiculeNode.findElements('user').single;
    var entrepriseElement = vehiculeNode.findElements('entreprise').single;
    Entreprise? entrepriseVehicule;
    User? userVehicule;

    if (vehiculeNode.findElements('entreprise').toList().isEmpty || vehiculeNode.findElements('entreprise').toList().single.children.isEmpty) {
      entrepriseVehicule = null;
    } else {
      entrepriseVehicule = Entreprise(
      idEntreprise: entrepriseElement.findElements('id_entreprise').single.innerText, 
      nomEntreprise: entrepriseElement.findElements('nom_entreprise').single.innerText, 
      villeEntreprise: null, 
      paysEntreprise: null, 
      cpEntreprise: null, 
      dateAnniversaire: null
      );
    } 
    
    if (vehiculeNode.findElements('user').toList().isEmpty || vehiculeNode.findElements('user').toList().single.children.isEmpty) {
      userVehicule = null;
      
    } else {
        userVehicule= User(
          idUser: userElement.findElements('id_user').single.innerText,
          nomUser: userElement.findElements('nom_user').single.innerText,
          prenomUser: userElement.findElements('prenom_user').single.innerText,
        );
      
    }

    return Vehicule(
        numVin: vehiculeNode.findElements('num_vin').single.innerText,
        marque: vehiculeNode.findElements('marque').single.innerText, 
        modele: vehiculeNode.findElements('modele').single.innerText,
        user: userVehicule,
        entreprise: entrepriseVehicule, 
        immat: vehiculeNode.findElements('immat').single.innerText,
        idCablint: vehiculeNode.findElements('id_cablint').single.innerText,
      );
  }

}
