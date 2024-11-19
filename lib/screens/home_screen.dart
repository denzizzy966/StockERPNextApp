import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import 'stock_entry_screen.dart';
import 'stock_status_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final provider = Provider.of<StockProvider>(context, listen: false);
    await provider.loadItems();
    if (!mounted) return;
    await provider.loadWarehouses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            'Material Receipt',
            Icons.add_box,
            () => _navigateToStockEntry(context, 'Material Receipt'),
          ),
          _buildMenuCard(
            context,
            'Material Issue',
            Icons.remove_circle,
            () => _navigateToStockEntry(context, 'Material Issue'),
          ),
          _buildMenuCard(
            context,
            'Material Transfer',
            Icons.compare_arrows,
            () => _navigateToStockEntry(context, 'Material Transfer'),
          ),
          _buildMenuCard(
            context,
            'Stock Status',
            Icons.inventory,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StockStatusScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToStockEntry(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockEntryScreen(stockEntryType: type),
      ),
    );
  }
}
