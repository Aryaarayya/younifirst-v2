import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:younifirst_app/views/barang/barang_pages.dart';
import 'package:younifirst_app/views/event/Event_pages.dart';
import 'package:younifirst_app/views/Home_pages.dart';
import 'package:younifirst_app/views/profil/Profil_pages.dart';
import 'package:younifirst_app/views/team/Teams_pages.dart';

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
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: [
          BottomNavigationBarItem(icon: Icon(_currentIndex == 0 ? Icons.home_filled : Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Event"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Teams"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: "Barang"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }
}
