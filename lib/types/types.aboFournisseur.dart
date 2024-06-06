import 'package:insight_mobility_app/types/types.fournisseur.dart';

class AboFournisseur{
  String? idAbo;
  String? nomAbo;
  Fournisseur? idFournisseur;

  AboFournisseur({
    required this.idAbo,
    required this.nomAbo,
    required this.idFournisseur
  });
}