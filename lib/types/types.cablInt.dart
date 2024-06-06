import 'types.entreprise.dart';
import 'types.user.dart';
import 'package:xml/xml.dart' as xml;

class CablInt {
  String idCablInt;
  User? user;
  Entreprise? entreprise;
  
  CablInt({
    required this.idCablInt,
    this.user,
    this.entreprise
  });

  factory CablInt.fromXml(xml.XmlElement cablInt) {
    return CablInt(
      idCablInt: cablInt.findElements('id_cablint').first.innerText,
      user: User(idUser: cablInt.findAllElements('id_user').first.innerText, nomUser: cablInt.findAllElements('nom_user').first.innerText, prenomUser: cablInt.findAllElements('prenom_user').first.innerText),
      entreprise: Entreprise.fromXml(cablInt.findElements('entreprise').first)
    ); 
  }
}