import 'package:xml/xml.dart' as xml;

class Recharge {
  String? idRecharge;
  String? dateDebut;
  String? dateFin;
  String? heureDebut;
  String? heureFin;
  String? totalConsommation;
  String? cout;

  Recharge({
    required this.idRecharge,
    required this.dateDebut,
    required this.dateFin,
    required this.heureDebut,
    required this.heureFin,
    required this.totalConsommation,
    required this.cout
  });

  factory Recharge.fromXml(xml.XmlElement recharge) {
    return Recharge(
      idRecharge: recharge.findElements('id_recharge').first.innerText,
      dateDebut: recharge.findElements('date_debut').first.innerText,
      dateFin: recharge.findElements('date_fin').first.innerText,
      heureDebut: recharge.findElements('heure_debut').first.innerText,
      heureFin: recharge.findElements('heure_fin').first.innerText,
      totalConsommation: recharge.findElements('total_consommation').first.innerText,
      cout: recharge.findElements('cout').first.innerText
    );
  }
}
