import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:insight_mobility_app/api_config/api_config.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const EmailInputPage(),
    );
  }
}

class EmailInputPage extends StatefulWidget {
  const EmailInputPage({super.key});
  @override
  State<EmailInputPage> createState() => EmailInputPageState();
}

class EmailInputPageState extends State<EmailInputPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void envoiMailReiMdp() {
    setState(() {
      _isLoading = true;
    });
    String email = _emailController.text;

    http.get(Uri.parse('${ApiConfig.baseUrl}/token/insertTokenAndSendMail/$email')).then((response) {

      if(response.statusCode == 200) {
        setState(() {
          _isLoading = false; 
        });
        return ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mail envoyé avec succès'),
                              backgroundColor: Colors.greenAccent,
                            ),
                          );
      } else {
        setState(() {
          _isLoading = false; 
        });
        return ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors de l\'envoi du mail'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
      }
    });
      
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: 'E-mail',
                filled: true,
                fillColor: Colors.grey[200], 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0), 
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Entrez votre e-mail';
                }

                final mailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                if (mailRegex.hasMatch(value)) {
                  _emailController.text = value.trim();
                  return null;
                } else {
                  return 'Entrez une adresse e-mail valide';
                }
              },
            ),
            const SizedBox(height: 16.0),
              _isLoading ? const CircularProgressIndicator() : FilledButton(
              onPressed: () {
                envoiMailReiMdp();
                FocusScope.of(context).unfocus();// cacher clavier
              },
              child: const Text('Validate'),
            ),
          ],
        ),
      ),
    );
  }
}