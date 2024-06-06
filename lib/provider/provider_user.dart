import 'package:flutter/material.dart';
import 'package:insight_mobility_app/types/types.user.dart';
import '../api_config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../types/types.remboursement.dart';
import '../types/types.recharge.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  double _montantARembourser = 0.0;
  List<Remboursement> _remboursements = [];
  Map<String, List<Recharge>> _recharges = {};
  String _idCablint = '';

  User? get user => _user;
  double get montantARembourser => _montantARembourser;
  List<Remboursement> get remboursements => _remboursements;
  Map<String, List<Recharge>> get recharges => _recharges;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  Future<void> fetchMontantARembourser() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/cable/getIdCableIntbyIdUser/${_user!.idUser}'));
      if (response.statusCode == 200) {
        final xmlDoc = xml.XmlDocument.parse(response.body);
        final cableNode = xmlDoc.findElements('cable_int').first;
        _idCablint = cableNode.findElements('id_cablint').single.innerText;
        final response2 = await http.get(Uri.parse("${ApiConfig.baseUrl}/user/getMontantPourPeriode/$_idCablint"));
        if (response2.statusCode == 200) {
          _montantARembourser = double.parse(response2.body);
          notifyListeners();
        } else {
          _montantARembourser = 0.0;
          notifyListeners();
        }

      } else if (response.statusCode == 404) {
        throw Exception('Erreur: ${response.reasonPhrase}');
      } else if(response.statusCode == 500){
        throw Exception('Erreur: ${response.reasonPhrase}');
      }else{
        throw Exception('Erreur: ${response.reasonPhrase}');
      }
  }

  Future<void> fetchRemboursement() async {
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/remboursement/getByIdUser/${_user!.idUser}"));
    if (response.statusCode == 200) {
      final parsed = xml.XmlDocument.parse(response.body);
      final remboursementList = parsed.findAllElements('remboursement');
      _remboursements = remboursementList.map((nodeRemboursement) => Remboursement.fromXml(nodeRemboursement)).toList();
      notifyListeners();
    } else if(response.statusCode == 404){
      _remboursements = [];
      notifyListeners();
    }else {
      throw Exception('Failed to load remboursements');
    }
  } 
  
  Future<void> fetchRecharges() async {
    final response = await http.get(Uri.parse("${ApiConfig.baseUrl}/user/getRechargeByIdCable/$_idCablint"));
    if (response.statusCode == 200) {
      final xmlDoc = xml.XmlDocument.parse(response.body);
      final List<Recharge> recharges = xmlDoc.findAllElements('recharge').map((element) => Recharge.fromXml(element)).toList();
      // Regrouper les recharges par jour
      final Map<String, List<Recharge>> groupedRecharges = {};
      for (var recharge in recharges) {
        if (groupedRecharges.containsKey(recharge.dateDebut!)) {
          groupedRecharges[recharge.dateDebut!]!.add(recharge);
        } else {
          groupedRecharges[recharge.dateDebut!] = [recharge];
        }
      }

      // inverser la liste pour qu'elle s'affiche du plus récent au plus ancien
      final reversedEntries = groupedRecharges.entries.toList().reversed.toList();

      _recharges = Map<String, List<Recharge>>.fromEntries(reversedEntries);
      notifyListeners();
    } else if (response.statusCode == 404) {
      _recharges = {};
      notifyListeners();
    } else {
      throw Exception('Failed to load recharges');
    }
  }

  void updateUserNom(String newNom) {
    if (_user != null) {
      _user!.nomUser = newNom; 
      notifyListeners();
    }
  }

  void updateUserPrenom(String newPrenom) {
    if (_user != null) {
      _user!.prenomUser = newPrenom; 
      notifyListeners();
    }
  }

  void updateUserEmail(String newMail) {
    if (_user != null) {
      _user!.emailUser = newMail; 
      notifyListeners();
    }
  }

  void updateUserTelephone(String newTel) {
    if (_user != null) {
      _user!.telUser = newTel; 
      notifyListeners();
    }
  }
}