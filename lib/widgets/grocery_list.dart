import 'dart:convert';

import 'package:bai11_flutter/data/categories.dart';
import 'package:bai11_flutter/widgets/new_item.dart';
import 'package:flutter/material.dart';
import '../models/grocery_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems =  _loadingData();
  }

  Future<List<GroceryItem>> _loadingData() async {
    final url = Uri.https('lutter-prep-f5f13-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery items.');
    }

    if (response.body == 'null') {
      return [];
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere((catItem) =>
      catItem.value.title == item.value['selectedCategory'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    return loadedItems;
}

  void _addItem() async {
    final newItem =  await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (ctx) => const NewItem())
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('flutter-prep-f5f13-default-rtdb.firebaseio.com', 'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add)
          )
        ],
      ),

      /** nếu màn chỉ cần lấy dữ liệu 1 lần thì nên dùng FutureBuilder,
       *  nếu cần chình sửa dữ liệu đó thì ko nên sử dụng Widget này.
       * **/
      body: FutureBuilder(future: _loadedItems, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text(
                  snapshot.error.toString()
              )
          );
        }

        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No item added yet.'));
        }
        final data = snapshot.data!;

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (ctx, index) => Dismissible(
            onDismissed: (direction) {
              _removeItem(data[index]);
            },
            key: ValueKey(data[index].id),
            child: ListTile(
              title: Text(data[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: data[index].category.color,
              ),
              trailing: Text(
                data[index].quantity.toString(),
              ),
            ),
          ),
        );
      }),
    );
  }
}