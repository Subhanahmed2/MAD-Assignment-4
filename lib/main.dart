import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'provider/activity_provider.dart';
import 'repository/activity_repository.dart';
import 'ui/screen/home_screen.dart'; // matches your folder structure

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = ActivityRepository(
    baseUrl: 'https://your-backend.com/api', // Replace with your real backend
  );

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final ActivityRepository repository;
  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActivityProvider(repository: repository)
        ..fetchActivitiesFromApi(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartTracker55572',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(), // directly use the updated HomeScreen
      ),
    );
  }
}
