import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/stock_provider.dart';
import 'screens/home_screen.dart';
import 'screens/stock_entry_list_screen.dart';
import 'screens/item_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (context) => ApiService(),  // Akan menggunakan config secara otomatis
        ),
        ChangeNotifierProxyProvider<ApiService, StockProvider>(
          create: (context) => StockProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) =>
              previous ?? StockProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'ERPNext Stock Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    StockEntryListScreen(),
    ItemListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stock Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Stock Entries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Items',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
