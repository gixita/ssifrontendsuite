import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ssifrontendsuite/globalvar.dart';
import 'login.dart';

class IssueIdentityPage extends StatefulWidget {
  const IssueIdentityPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<IssueIdentityPage> createState() => _IssueIdentityPageState();
}

class _IssueIdentityPageState extends State<IssueIdentityPage> {
  String errorMessage = "";
  String? token;
  List<String> genderList = ["Male", "Female"];
  String? genderSelected = "Male";
  String? countrySelected = "Belgium";
  String vc = "";

  Future<String?> getToken() async {
    String? local = await AuthUtils.getToken();
    setState(() {
      token = local;
    });
    return token;
  }

  @override
  void initState() {
    super.initState();
    getToken();
  }

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final birthdateController = TextEditingController();
    final firstnameController = TextEditingController();
    final lastnameController = TextEditingController();
    final registrationController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Email"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email of the receiver',
                      hintText: 'Enter valid receiver email'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Gender"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: dropdownMenuSSI(genderList, genderSelected),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Birthdate"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: birthdateController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Birthdate (yyyy-mm-dd)',
                      hintText: 'YYYY-MM-DD'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("First name"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: firstnameController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'First name',
                      hintText: 'John'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Last name"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: lastnameController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Last name',
                      hintText: 'Smith'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("National registration number"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: registrationController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'National registration number',
                      hintText: 'xx.xx.xx-xxx.xx'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Birth country"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: dropdownMenuSSI(countries, countrySelected),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                  onPressed: () async {
                    String local = '''{
                      "unsignedvcs": {
    "email": "<---email--->", 
    "unsignedvcs": {
  "credential": {
      "@context":[
            "https://www.w3.org/2018/credentials/v1",
            "https://w3id.org/citizenship/v1"
      ],
      "id":"https://issuer.oidp.uscis.gov/credentials/83627465",
      "type":[
            "VerifiableCredential",
            "PermanentResidentCard"
      ],
      "issuer":"<---authorityPortalDid.id--->",
      "issuanceDate":"2019-12-03T12:19:52Z",
      "expirationDate":"2029-12-03T12:19:52Z",
      "credentialSubject":{
            "id":"<---mobileAppDid--->",
            "type":[
              "PermanentResident",
              "Person"
            ],
            "givenName":"<---firstname--->",
            "familyName":"<---lastname--->",
            "gender":"<---gender--->",
            "image":"",
            "residentSince":"",
            "lprCategory":"",
            "lprNumber":"<---registration--->",
            "commuterClassification":"",
            "birthCountry":"<---birthcountry--->",
            "birthDate":"<---birthdate--->"
      }
    },
    "options": {
        "verificationMethod": "<---authorityPortalDid.verificationMethod--->",
        "proofPurpose": "assertionMethod"
    }
}
}}''';
                    local =
                        local.replaceAll("<---email--->", emailController.text);
                    local = local.replaceAll(
                        "<---firstname--->", firstnameController.text);
                    local = local.replaceAll(
                        "<---lastname--->", lastnameController.text);
                    local = local.replaceAll("<---gender--->", genderSelected!);
                    local = local.replaceAll(
                        "<---registration--->", registrationController.text);
                    local = local.replaceAll(
                        "<---birthcountry--->", countrySelected!);
                    local = local.replaceAll(
                        "<---birthdate--->", birthdateController.text);
                    await http
                        .post(Uri.parse("${GlobalVar.host}/api/unsignedvcs"),
                            headers: {'Authorization': 'Token $token'},
                            body: local)
                        .then((res) {
                      if (res.statusCode == 201) {
                        Navigator.popUntil(
                            context, ModalRoute.withName('/vcissued'));
                      } else {
                        setState(() {
                          errorMessage =
                              "Something went wrong while sending the VC";
                        });
                      }
                    });
                  },
                  child: const Text("Save and publish")),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Text(errorMessage),
              ),
            ]),
      ),
    );
  }

  DropdownButtonFormField<String> dropdownMenuSSI(
      List<String> menuList, String? currentSelected) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey)),
      ),
      value: currentSelected,
      items: menuList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          currentSelected = newValue!;
        });
      },
      isExpanded: true,
    );
  }

  List<String> countries = [
    "Afghanistan",
    "Albania",
    "Algeria",
    "Andorra",
    "Angola",
    "Antigua and Barbuda",
    "Argentina",
    "Armenia",
    "Australia",
    "Austria",
    "Azerbaijan",
    "Bahamas",
    "Bahrain",
    "Bangladesh",
    "Barbados",
    "Belarus",
    "Belgium",
    "Belize",
    "Benin",
    "Bhutan",
    "Bolivia",
    "Bosnia and Herzegovina",
    "Botswana",
    "Brazil",
    "Brunei",
    "Bulgaria",
    "Burkina Faso",
    "Burundi",
    "Côte d'Ivoire",
    "Cabo Verde",
    "Cambodia",
    "Cameroon",
    "Canada",
    "Central African Republic",
    "Chad",
    "Chile",
    "China",
    "Colombia",
    "Comoros",
    "Congo (Congo-Brazzaville)",
    "Costa Rica",
    "Croatia",
    "Cuba",
    "Cyprus",
    "Czechia (Czech Republic)",
    "Democratic Republic of the Congo",
    "Denmark",
    "Djibouti",
    "Dominica",
    "Dominican Republic",
    "Ecuador",
    "Egypt",
    "El Salvador",
    "Equatorial Guinea",
    "Eritrea",
    "Estonia",
    "Eswatini",
    "Ethiopia",
    "Fiji",
    "Finland",
    "France",
    "Gabon",
    "Gambia",
    "Georgia",
    "Germany",
    "Ghana",
    "Greece",
    "Grenada",
    "Guatemala",
    "Guinea",
    "Guinea-Bissau",
    "Guyana",
    "Haiti",
    "Holy See",
    "Honduras",
    "Hungary",
    "Iceland",
    "India",
    "Indonesia",
    "Iran",
    "Iraq",
    "Ireland",
    "Israel",
    "Italy",
    "Jamaica",
    "Japan",
    "Jordan",
    "Kazakhstan",
    "Kenya",
    "Kiribati",
    "Kuwait",
    "Kyrgyzstan",
    "Laos",
    "Latvia",
    "Lebanon",
    "Lesotho",
    "Liberia",
    "Libya",
    "Liechtenstein",
    "Lithuania",
    "Luxembourg",
    "Madagascar",
    "Malawi",
    "Malaysia",
    "Maldives",
    "Mali",
    "Malta",
    "Marshall Islands",
    "Mauritania",
    "Mauritius",
    "Mexico",
    "Micronesia",
    "Moldova",
    "Monaco",
    "Mongolia",
    "Montenegro",
    "Morocco",
    "Mozambique",
    "Myanmar (formerly Burma)",
    "Namibia",
    "Nauru",
    "Nepal",
    "Netherlands",
    "New Zealand",
    "Nicaragua",
    "Niger",
    "Nigeria",
    "North Korea",
    "North Macedonia",
    "Norway",
    "Oman",
    "Pakistan",
    "Palau",
    "Palestine State",
    "Panama",
    "Papua New Guinea",
    "Paraguay",
    "Peru",
    "Philippines",
    "Poland",
    "Portugal",
    "Qatar",
    "Romania",
    "Russia",
    "Rwanda",
    "Saint Kitts and Nevis",
    "Saint Lucia",
    "Saint Vincent and the Grenadines",
    "Samoa",
    "San Marino",
    "Sao Tome and Principe",
    "Saudi Arabia",
    "Senegal",
    "Serbia",
    "Seychelles",
    "Sierra Leone",
    "Singapore",
    "Slovakia",
    "Slovenia",
    "Solomon Islands",
    "Somalia",
    "South Africa",
    "South Korea",
    "South Sudan",
    "Spain",
    "Sri Lanka",
    "Sudan",
    "Suriname",
    "Sweden",
    "Switzerland",
    "Syria",
    "Tajikistan",
    "Tanzania",
    "Thailand",
    "Timor-Leste",
    "Togo",
    "Tonga",
    "Trinidad and Tobago",
    "Tunisia",
    "Turkey",
    "Turkmenistan",
    "Tuvalu",
    "Uganda",
    "Ukraine",
    "United Arab Emirates",
    "United Kingdom",
    "United States of America",
    "Uruguay",
    "Uzbekistan",
    "Vanuatu",
    "Venezuela",
    "Vietnam",
    "Yemen",
    "Zambia",
    "Zimbabwe",
  ];
}
