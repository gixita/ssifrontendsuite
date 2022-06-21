import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ssifrontendsuite/globalvar.dart';
import 'login.dart';

class ElectricVehiculeIssuePage extends StatefulWidget {
  const ElectricVehiculeIssuePage({Key? key, required this.title})
      : super(key: key);
  final String title;

  @override
  State<ElectricVehiculeIssuePage> createState() =>
      _ElectricVehiculeIssuePageState();
}

class _ElectricVehiculeIssuePageState extends State<ElectricVehiculeIssuePage> {
  String errorMessage = "";
  String? token;
  List<String> manufacturerList = ["Tesla", "BMW", "VW", "Renault", "Audi"];
  String? manufacturerSelected = "Tesla";
  String? countrySelected = "Belgium";
  String vc = "";
  final emailController = TextEditingController();
  final vehiculeTypeController = TextEditingController();
  final vinController = TextEditingController();
  final productController = TextEditingController();
  final capacityInWhController = TextEditingController();
  final efficiencyChargeRatioController = TextEditingController();
  final efficiencyDischargeRatio = TextEditingController();
  final maxChargePowerInWController = TextEditingController();
  final maxDischargePowerInWController = TextEditingController();
  final minSocInWhController = TextEditingController();
  final degradationCostInEurPerkWhController = TextEditingController();
  Map<String, bool> checkboxes = {
    "readingTypeBattery": false,
    "readingTypeElectricity": false,
    "readingTypeLocation": false,
    "commandTypeChargingStart": false,
    "commandTypeChargingRate": false,
  };
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
                child: Text("Full model name with year or assimilated"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: vehiculeTypeController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Full model name',
                      hintText: 'Enter the car model'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Manufacturer"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: dropdownMenuSSI(manufacturerList, manufacturerSelected),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Product"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: productController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Product',
                      hintText: 'Example model 3'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("VIN number"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: vinController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Vin number',
                      hintText: 'Enter the car VIN number'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Battery capacity in Wh"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: capacityInWhController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Battery capacity in Wh',
                      hintText: 'example 3000'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Efficiency charge ratio"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: efficiencyChargeRatioController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Efficiency charge ratio',
                      hintText: 'example 0.22'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Efficiency discharge ratio"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: efficiencyDischargeRatio,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Efficiency discharge ratio',
                      hintText: 'example 0.22'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Max charge power in W"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: maxChargePowerInWController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Max charge power in W',
                      hintText: 'example 250'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Max discharge power in W"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: maxDischargePowerInWController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Max discharge power in W',
                      hintText: 'example 250'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Minimum State of charge in Wh"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: minSocInWhController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Minimum State of charge in Wh',
                      hintText: 'example 250'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Degradetion cost in euros per kWh"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: degradationCostInEurPerkWhController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Degradetion cost in euros per kWh',
                      hintText: 'example 3.25'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Battery reading capability"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: checkboxMenuSSI("readingTypeBattery"),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Electricity reading capability"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: checkboxMenuSSI("readingTypeElectricity"),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Location reading capability"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: checkboxMenuSSI("readingTypeLocation"),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Charging start command capability"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: checkboxMenuSSI("commandTypeChargingStart"),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Charging rate command capability"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: checkboxMenuSSI("commandTypeChargingRate"),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                  onPressed: () async {
                    String local = """{
  "unsignedvcs": {
    "email": "<---email--->", 
    "unsignedvcs": {
      "credential": {
        "@context":[
            "https://www.w3.org/2018/credentials/v1",
            {
                "issuerFields":{
                    "@id":"ev:issuerFields",
                    "@type":"ev:IssuerFields"
                },
                "vehiculeType":"ev:vehiculeType",
                "manufacturer":"ev:manufacturer",
                "vin":"ev:vin",
                "product":"ev:product",
                "capacityInWh":"ev:capacityInWh",
                "efficiencyChargeRatio":"ev:efficiencyChargeRatio",
                "efficiencyDischargeRatio":"ev:efficiencyDischargeRatio",
                "maxChargePowerInW":"ev:maxChargePowerInW",
                "maxDischargePowerInW":"ev:maxDischargePowerInW",
                "minSocInWh":"ev:minSocInWh",
                "degradationCostInEurPerkWh":"ev:degradationCostInEurPerkWh",
                "readingTypes":{
                    "@id":"ev:readingTypes",
                    "@type":"ev:readingTypes"
                },
                "commandTypes":{
                    "@id":"ev:commandTypes",
                    "@type":"ev:commandTypes"
                },
                "ev":"https://eliagroup.eu/ld-context-2022/ev",
                "ElectricalVehicule":"ev:ElectricalVehicule"
            }
        ],
        "id":"https://www.eliagroup.eu/vc/893893938",
        "type":[
            "VerifiableCredential",
            "ElectricalVehicule"
        ],
        "credentialSubject":{
            "id":"<---mobileAppDid--->",
            "vehiculeType": "<----vehiculeType---->",
            "manufacturer": "<----manufacturer---->",
            "vin": "<----vin---->",
            "product": "<----product---->",
            "capacityInWh": "<----capacityInWh---->",
            "efficiencyChargeRatio": "<----efficiencyChargeRatio---->",
            "efficiencyDischargeRatio": "<----efficiencyDischargeRatio---->",
            "maxChargePowerInW": "<----maxChargePowerInW---->",
            "maxDischargePowerInW": "<----maxDischargePowerInW---->",
            "minSocInWh": "<----minSocInWh---->",
            "degradationCostInEurPerkWh": "<----degradationCostInEurPerkWh---->",

            "readingTypes": [<----readingTypesList---->],
            "commandTypes": [<----commandTypesList---->]
        },
        "issuer":"<---authorityPortalDid.id--->",
        "issuanceDate":"2022-03-18T08:57:32.477Z",
        "expirationDate":"2029-03-18T08:57:32.477Z"
    },
    "options": 
    {
        "verificationMethod": "<---authorityPortalDid.verificationMethod--->",
        "proofPurpose": "assertionMethod"
    }
  }
}
}""";

                    local =
                        local.replaceAll("<---email--->", emailController.text);
                    local = local.replaceAll(
                        "<----vehiculeType---->", vehiculeTypeController.text);
                    local = local.replaceAll(
                        "<----manufacturer---->", manufacturerSelected!);
                    local =
                        local.replaceAll("<----vin---->", vinController.text);
                    local = local.replaceAll(
                        "<----product---->", productController.text);
                    local = local.replaceAll(
                        "<----capacityInWh---->", capacityInWhController.text);
                    local = local.replaceAll("<----efficiencyChargeRatio---->",
                        efficiencyChargeRatioController.text);
                    local = local.replaceAll(
                        "<----efficiencyDischargeRatio---->",
                        efficiencyDischargeRatio.text);
                    local = local.replaceAll("<----maxChargePowerInW---->",
                        maxChargePowerInWController.text);

                    local = local.replaceAll("<----maxDischargePowerInW---->",
                        maxDischargePowerInWController.text);
                    local = local.replaceAll(
                        "<----minSocInWh---->", minSocInWhController.text);
                    local = local.replaceAll(
                        "<----degradationCostInEurPerkWh---->",
                        degradationCostInEurPerkWhController.text);
                    List<String> readingTypesList = [];
                    List<String> commandTypesList = [];

                    if (checkboxes["readingTypeBattery"]!) {
                      readingTypesList.add('"readingTypeBattery"');
                    }
                    if (checkboxes["readingTypeElectricity"]!) {
                      readingTypesList.add('"readingTypeElectricity"');
                    }
                    if (checkboxes["readingTypeLocation"]!) {
                      readingTypesList.add('"readingTypeLocation"');
                    }
                    if (checkboxes["commandTypeChargingStart"]!) {
                      commandTypesList.add('"commandTypeChargingStart"');
                    }
                    if (checkboxes["commandTypeChargingRate"]!) {
                      commandTypesList.add('"commandTypeChargingRate"');
                    }
                    local = local.replaceAll("<----readingTypesList---->",
                        readingTypesList.join(", "));
                    local = local.replaceAll("<----commandTypesList---->",
                        commandTypesList.join(", "));
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

  Row checkboxMenuSSI(String checkbox) {
    return Row(
      children: [
        Checkbox(
          checkColor: Colors.white,
          value: checkboxes[checkbox],
          onChanged: (bool? value) {
            setState(() {
              checkboxes[checkbox] = value!;
            });
          },
        ),
        Text(checkbox)
      ],
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
}
