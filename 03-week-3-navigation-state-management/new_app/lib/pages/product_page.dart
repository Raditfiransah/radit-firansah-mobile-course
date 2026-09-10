import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $err'),
              FilledButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (products) => RefreshIndicator(
          onRefresh: () => ref.read(productsProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) =>
                ListTile(title: Text(products[index])),
          ),
        ),
      ),
    );
  }
}
