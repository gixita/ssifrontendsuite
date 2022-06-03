import 'package:flutter/material.dart';
import 'package:ssifrontendsuite/vc.dart';

// Create a Form widget.
class DefineIssuerLabelPage extends StatefulWidget {
  const DefineIssuerLabelPage({super.key});

  @override
  DefineIssuerLabelPageState createState() {
    return DefineIssuerLabelPageState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class DefineIssuerLabelPageState extends State<DefineIssuerLabelPage> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    String did = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Define a label"),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Flexible(child: Text("Enter a label for the new issuer")),
              TextFormField(
                controller: _labelController,
                // The validator receives the text that the user has entered.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Validate returns true if the form is valid, or false otherwise.
                    if (_formKey.currentState!.validate()) {
                      // If the form is valid, display a snackbar. In the real world,
                      // you'd often call a server or save the information in a database.
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Processing Data')),
                      // );
                      await VCService()
                          .storeIssuerLabel(_labelController.text, did)
                          .then((res) {
                        Navigator.popUntil(context, ModalRoute.withName('/'));
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ));
  }
}
