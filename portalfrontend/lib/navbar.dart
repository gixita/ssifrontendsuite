import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Remove padding
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.blue,
            child: Column(
              children: const [
                SizedBox(
                  height: 20,
                ),
                Center(
                    child: Text(
                  "Menu",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                )),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner),
            title: const Text('Documents issued to me'),
            onTap: () =>
                Navigator.pushNamed(context, '/vcissued', arguments: "others"),
          ),
          ListTile(
            leading: const Icon(Icons.send),
            title: const Text('Documents issued by me'),
            onTap: () =>
                Navigator.pushNamed(context, '/vcissued', arguments: "me"),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Issue a document'),
            onTap: () =>
                Navigator.pushNamed(context, '/vcissued', arguments: "me"),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () =>
                Navigator.pushNamed(context, '/vcissued', arguments: "me"),
          ),
        ],
      ),
    );
  }
}
