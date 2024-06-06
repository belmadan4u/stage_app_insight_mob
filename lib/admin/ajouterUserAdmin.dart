import 'package:flutter/material.dart';

void main() {
  runApp( const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: const Color(0xFF008EFE)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AddUserPage(),
    );
  }
}

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});
  
  @override
  State<AddUserPage> createState() => AddUserPageState();
}

class AddUserPageState extends State<AddUserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un nouvel utilisateur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'ID Utilisateur'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Prénom'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Téléphone'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Mot de passe'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Rôle'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Adresse'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Ville'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Code Postal'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Pays'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'ID Abonnement'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Ajoutez votre logique ici pour créer un nouvel utilisateur
                  // Récupérez les valeurs saisies dans les champs de texte et créez un nouvel utilisateur
                  // Vous pouvez appeler une fonction dans votre modèle pour effectuer cette tâche
                  // Après l'ajout de l'utilisateur, vous pouvez afficher un message de confirmation ou retourner à la liste des utilisateurs
                },
                child: Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
