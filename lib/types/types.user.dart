import 'package:insight_mobility_app/types/types.aboFournisseur.dart';
import 'package:insight_mobility_app/types/types.entreprise.dart';
import 'package:insight_mobility_app/types/types.fournisseur.dart';
import 'package:http/http.dart' as http;
import 'package:insight_mobility_app/api_config/api_config.dart';
import 'package:xml/xml.dart' as xml;
class User {
  String? idUser;
  String? nomUser;
  String? prenomUser;
  String? telUser;
  String? emailUser;
  String? mdpUser;
  String? roleUser;
  Entreprise? idEntrepriseUser;
  String? adresseUser;
  String? villeUser;
  String? cpUser;
  String? paysUser;
  AboFournisseur? idAboUser;

  User({
    required this.idUser,
    required this.nomUser,
    required this.prenomUser,
     this.telUser,
     this.emailUser,
     this.mdpUser,
     this.roleUser,
     this.idEntrepriseUser,
     this.adresseUser,
     this.villeUser,
     this.cpUser,
     this.paysUser,
     this.idAboUser,
  });

  updatePsw(String newPsw) async{
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/user/updatePwdUser/$idUser/$newPsw'));

    if (response.statusCode != 200) {
      throw Exception('Erreur : modification du mot de passe impossible');
    } 
    
  }

  factory User.fromXml(xml.XmlElement userNode, pwdLength) {
      String password = '';
      for(int i = 0; i< pwdLength; i++){
        password = '$password•';
      }
      Entreprise? entreprise; 
      if(userNode.findElements('entreprise').single.innerText == "pas d'entreprise renseigné"){
        entreprise = null;
      } else {
        final entrepriseNode = userNode.findElements('entreprise').single;
        entreprise = Entreprise.fromXml(entrepriseNode);
      }
      

        

      
      if(userNode.findElements('abo_fournisseur').single.innerText == "pas d'abo_fournisseur renseigné"){
        return User(
          idUser: userNode.findElements('id').single.innerText,
          nomUser: userNode.findElements('nom').single.innerText,
          prenomUser: userNode.findElements('prenom').single.innerText,
          telUser: userNode.findElements('tel_user').single.innerText,
          emailUser: userNode.findElements('email_user').single.innerText,
          mdpUser: password,
          roleUser: userNode.findElements('role_user').single.innerText,
          idEntrepriseUser: entreprise,
          adresseUser: userNode.findElements('adresse_user').single.innerText,
          villeUser: userNode.findElements('ville_user').single.innerText,
          cpUser: userNode.findElements('cp_user').single.innerText,
          paysUser: userNode.findElements('pays_user').single.innerText,
          idAboUser: null ,
        );
      } else {
        final aboFournisseurNode = userNode.findElements('abo_fournisseur').single;

          final fournisseurNode = aboFournisseurNode.findElements('fournisseur').single;
          
        final abofournisseur = AboFournisseur(
          idAbo: aboFournisseurNode.findElements('id_abo').single.innerText,
          nomAbo: aboFournisseurNode.findElements('nom_abo').single.innerText,
          idFournisseur: Fournisseur(
            idFournisseur: int.parse(fournisseurNode.findElements('id_fournisseur').single.innerText),
            nomFournisseur: fournisseurNode.findElements('nom_fournisseur').single.innerText
          )
        );

        return User(
          idUser: userNode.findElements('id').single.innerText,
          nomUser: userNode.findElements('nom').single.innerText,
          prenomUser: userNode.findElements('prenom').single.innerText,
          telUser: userNode.findElements('tel_user').single.innerText,
          emailUser: userNode.findElements('email_user').single.innerText,
          mdpUser: password,
          roleUser: userNode.findElements('role_user').single.innerText,
          idEntrepriseUser: entreprise,
          adresseUser: userNode.findElements('adresse_user').single.innerText,
          villeUser: userNode.findElements('ville_user').single.innerText,
          cpUser: userNode.findElements('cp_user').single.innerText,
          paysUser: userNode.findElements('pays_user').single.innerText,
          idAboUser: abofournisseur ,
        );
      }
  }

}
