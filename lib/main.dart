import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/stock_provider.dart';
import 'screens/home_screen.dart';
import 'config/config.dart';

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
        home: const HomeScreen(),
      ),
    );
  }
}
