import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: 10, // Nombre de notifications fictives
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: IconButton(
              onPressed: () {
                // Action à effectuer lorsque l'utilisateur appuie sur l'icône
                // Par exemple, afficher plus d'informations sur la notification
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Détails de la notification'),
                      content: Text('Contenu de la notification $index'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Fermer'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.notifications),
              iconSize: 40,
            ),
            title: Text('Notification $index'), // Titre de la notification
            subtitle: Text('Description de la notification $index'), // Description de la notification
            trailing: Icon(Icons.arrow_forward_ios), // Icône pour afficher plus d'informations
            onTap: () {
              // Action à effectuer lorsque l'utilisateur appuie sur la notification
              // Par exemple, afficher plus d'informations sur la notification
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Détails de la notification'),
                    content: Text('Contenu de la notification $index'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Fermer'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: NotificationsPage(),
  ));
}
