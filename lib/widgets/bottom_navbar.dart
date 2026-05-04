import 'package:flutter/material.dart';
import 'package:younifirst_app/pages/barang/barang_pages.dart';
import 'package:younifirst_app/pages/event/Event_pages.dart';
import 'package:younifirst_app/pages/Home_pages.dart';
import 'package:younifirst_app/pages/profil/Profil_pages.dart';
import 'package:younifirst_app/pages/team/Teams_pages.dart';

class BottomNavbar extends StatefulWidget {
  @override
  _BottomNavbarState createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {

  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    EventPage(),
    TeamsPage(),
    BarangPage(),
    ProfilPage(),   
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Event"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Teams"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Barang"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}