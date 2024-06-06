import 'types.user.dart';
import 'package:xml/xml.dart' as xml;

class Remboursement {
  String? idRemboursement;
  User? user;
  String? montant;
  String? dateTransmission;
  String? periodeDebut;
  String? periodeFin;
  
  Remboursement({
    required this.idRemboursement,
    required this.user,
    required this.montant,
    required this.dateTransmission,
    required this.periodeDebut,
    required this.periodeFin
  });

  factory Remboursement.fromXml(xml.XmlElement nodeRemboursement) {
    return Remboursement(
      idRemboursement: nodeRemboursement.findElements('id_remboursement').first.innerText,
      user: User.fromXml(nodeRemboursement.findElements('user').first, 10),
      montant: nodeRemboursement.findElements('montant').first.innerText,
      dateTransmission: nodeRemboursement.findElements('date_transmission').first.innerText,
      periodeDebut: nodeRemboursement.findElements('periode_debut').first.innerText,
      periodeFin: nodeRemboursement.findElements('periode_fin').first.innerText
    ); 
  }
}