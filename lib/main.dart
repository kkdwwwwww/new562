import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aaaa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _counter = 0;
  final plat = MethodChannel("wasd");

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
    plat.setMethodCallHandler((handler) async {
      if (handler.method == "onsss") {
        setState(() {
          _counter++;
        });
      }
      if(_counter % 5 == 0){
        LoadStore.save({
          'step': _counter,
          'date': DateTime.now().toString().split(' ')[0],
        });
      }
      ;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("需求一"),
      ),
      body: ListView(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$_counter 步',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${(_counter * 0.7).toInt()} m',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${(_counter * 0.5).toInt()} cal',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (builder) => WP()),
                    );
                  },
                  icon: Icon(Icons.bar_chart),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WP extends StatefulWidget {
  const WP({super.key});

  @override
  State<WP> createState() => _WPState();
}

class _WPState extends State<WP> {
  final List<double> _w = [1200, 2500, 1800, 3200, 2100, 4500, 2800];
  final List<double> _m = [
    800,
    1500,
    2200,
    3100,
    1900,
    4000,
    3500,
    2800,
    4200,
    3000,
  ];
  List<double> _cd = [0, 0, 0, 0, 0, 0, 0];
  bool _isWeek = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _cd = _w;
      });
    });
  }

  void _tg(bool toWeek) {
    if (_isWeek == toWeek) return;
    setState(() {
      _isWeek = toWeek;
      _cd = toWeek ? _w : _m;
    });
  }

  @override
  Widget build(BuildContext context) {
    double maxV = _cd.isEmpty ? 1 : _cd.reduce((a, b) => a > b ? a : b);
    if (maxV == 0) maxV = 1;
    return Scaffold(
      appBar: AppBar(
        title: Text("需求二"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text("7d"),
                selected: _isWeek,
                onSelected: (_) => _tg(true),
              ),
              SizedBox(width: 10),
              ChoiceChip(
                label: Text("12m"),
                selected: !_isWeek,
                onSelected: (_) => _tg(false),
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(
            child: Container(
              width: 300,
              height: 300,
              color: Colors.grey[300],
              child: ListView.builder(
                itemCount: _cd.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      SizedBox(width: 10),
                      Column(
                        children: [
                          Spacer(),
                          AnimatedContainer(duration: Duration(milliseconds: 1000),curve: Curves.easeOut,width: 25,height: (_cd[index]/maxV) * 250,color: Colors.orange,)
                        ],
                      ),
                      SizedBox(width: 10),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _cd = List.filled((_isWeek ? _w : _m).length, 0);
            Future.delayed(Duration(milliseconds: 1000),(){
              setState(() {
                _cd = _isWeek ? _w : _m;
              });
            });
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
class PP extends StatefulWidget {
  const PP({super.key});

  @override
  State<PP> createState() => _PPState();
}

class _PPState extends State<PP> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class LoadStore{
  static const plat = MethodChannel("wasd");
  static Future<void> save(Map<String,dynamic> data) async{
    String jS = json.encode(data);
    await plat.invokeListMethod("save",{"json": jS});
  }
  static Future<Map<String,dynamic>> load() async{
    String? jS = await plat.invokeMethod("load");
    if(jS == null || jS.isEmpty) return{};
    return json.decode(jS);
  }
}