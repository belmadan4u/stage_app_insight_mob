import 'package:xml/xml.dart' as xml;
import 'types.cablInt.dart';

class HistoriqueAnomalie {
  CablInt? cablInt;
  DateTime? dateReceptionDonnee;
  int? codeErreur;
  
  HistoriqueAnomalie({
    required this.cablInt,
    required this.dateReceptionDonnee,
    required this.codeErreur
  });
  
  factory HistoriqueAnomalie.fromXml(xml.XmlElement anomalieNode) {
    return HistoriqueAnomalie(
      cablInt: CablInt.fromXml(anomalieNode.findElements('cable').single),
      dateReceptionDonnee: DateTime.parse(anomalieNode.findElements('date_reception_donnee').single.innerText),
      codeErreur: int.parse(anomalieNode.findElements('code_erreur').single.innerText),
    );
  }
  
}