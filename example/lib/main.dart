import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initPersistentReactiveValue();

  runApp(
    const MaterialApp(
      title: "Application",
      home: HomeView(),
    ),
  );
}

final counter = PersistentReactiveValue<int>("counter", 0);

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeView'),
        centerTitle: true,
      ),
      body: Center(
        child: ReactiveWidget(
          () => Text(
            '${counter.value}',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          counter.value++;
        },
        tooltip: 'Increment',
        child: const Icon(Icons.plus_one_outlined),
      ),
    );
  }
}
