import 'package:xml/xml.dart' as xml;

class Entreprise {
  String? idEntreprise;
  String? nomEntreprise;
  String? villeEntreprise;
  String? paysEntreprise;
  String? cpEntreprise;
  String? dateAnniversaire;

  Entreprise({
    required this.idEntreprise,
    required this.nomEntreprise,
    required this.villeEntreprise,
    required this.paysEntreprise,
    required this.cpEntreprise,
    required this.dateAnniversaire
  });

  factory Entreprise.fromXml(xml.XmlElement entreprise) {
    return Entreprise(
      idEntreprise: entreprise.findElements('id_entreprise').first.innerText,
      nomEntreprise: entreprise.findElements('nom_entreprise').first.innerText,
      villeEntreprise: entreprise.findElements('ville_entreprise').first.innerText,
      paysEntreprise: entreprise.findElements('pays_entreprise').first.innerText,
      cpEntreprise: entreprise.findElements('cp_entreprise').first.innerText,
      dateAnniversaire: entreprise.findElements('date_anniversaire').first.innerText
    );
  }
}
