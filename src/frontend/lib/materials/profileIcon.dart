import 'package:flutter/material.dart';

class ProfileIconDropdown extends StatefulWidget {
  const ProfileIconDropdown({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileIconDropdownState createState() => _ProfileIconDropdownState();
}

class _ProfileIconDropdownState extends State<ProfileIconDropdown> {
  bool _isDropdownVisible = true;

  void _toggleDropdown() {
    setState(() {
      _isDropdownVisible = !_isDropdownVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(Icons.person, size: 32),
            if (_isDropdownVisible)
              Positioned(
                top: 40,
                right: 0,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Name: John Doe',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Language:',
                                style: TextStyle(color: Colors.black)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: 'English',
                              items: <String>['English', 'Spanish']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                // Handle language change
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // Handle logout
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

