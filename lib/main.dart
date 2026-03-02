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

class CoreLogic {
  static final CoreLogic _instance = CoreLogic._internal();
  factory CoreLogic() => _instance;
  CoreLogic._internal();
  static const plat = MethodChannel("wasd");
  int steps = 0;
  String lastDate = "";
  List<double> _7d = List.filled(7, 0);
  List<double> m = List.filled(12, 0);
  Function? _onUpdate;
  void init(Function onUpdate){
    _onUpdate = onUpdate;
    load().then((data){
      if(data.containsKey('step')){
        steps = data['step'];
        lastDate = data['date'] ?? "";
        if(data.containsKey('7d')) _7d = List<double>.from(data['7d']);
        if(data.containsKey('12m')) m = List<double>.from(data['12m']);
        _checkDate();
        _7d.last = steps.toDouble();
        _onUpdate?.call();
      }else{
        lastDate = DateTime.now().toString().split(' ')[0];
        save();
      }
    });
    plat.setMethodCallHandler((handler) async{
      if(handler.method == "onsss"){
        _checkDate();
        steps++;
        _7d.last = steps.toDouble();
        save();
        _onUpdate?.call();
      }
    });
  }
  Future<void> save() async{
    if(lastDate == "") lastDate = DateTime.now().toString().split(' ')[0];
    String jS = json.encode({
      'step': steps,
      'date': lastDate,
      '7d': _7d,
      '12m': m
    });
    await plat.invokeMethod("save",{"json": jS});
  }
  Future<Map<String,dynamic>> load() async{
    String? jS = await plat.invokeMethod("load");
    if(jS == null || jS.isEmpty) return{};
    return json.decode(jS);
  }
  Future<void> clearData() async{
    steps = 0;
    lastDate = DateTime.now().toString().split(' ')[0];
    _7d = List.filled(7, 0);
    m = List.filled(12, 0);
    await save();
    _onUpdate?.call();
  }
  void _checkDate(){
    String todayStr = DateTime.now().toString().split(' ')[0];
    if(lastDate == "" && lastDate == todayStr) return;
    DateTime last = DateTime.parse(lastDate);
    DateTime today = DateTime.parse(todayStr);
    int dayOff = today.difference(last).inDays;
    if(dayOff > 0){
      for(int i = 0;i<dayOff;i++){
        _7d.removeAt(0);
        _7d.add(0.0);
      }
      steps = 0;
      lastDate = todayStr;
      _7d.last = 0.0;
      save();
    }
  }
}


class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final core = CoreLogic();
  @override
  void initState() {
    super.initState();
    core.init(()=>setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("需求一"),
        actions: [IconButton(onPressed: ()=>core.clearData(), icon: Icon(Icons.delete))],
      ),
      body: ListView(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${core.steps} 步',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${(core.steps * 0.7).toInt()} m',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  isk(),
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
    );
  }

  String isk() {
    String www;
    if(core.steps * 0.03 >= 1){
      www =  "${(core.steps * 0.03).toInt()} kcal";
    } else www = "${(core.steps * 30).toInt()} cal";
    return www;
  }
}

class WP extends StatefulWidget {
  const WP({super.key});

  @override
  State<WP> createState() => _WPState();
}

class _WPState extends State<WP> {
  final core = CoreLogic();
  List<double> _cd = [0, 0, 0, 0, 0, 0, 0];
  bool _isWeek = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500),(){
      setState(() {
        _cd = core._7d;
      });
    });
  }
  void _tg(bool toWeek) {
    if (_isWeek == toWeek) return;
    setState(() {
      _isWeek = toWeek;
      _cd = toWeek ? core._7d : core.m;
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
        actions: [IconButton(onPressed: ()=>core.clearData(), icon: Icon(Icons.delete))],
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
            _cd = List.filled((_isWeek ? core._7d : core.m).length, 0);
            Future.delayed(Duration(milliseconds: 1000),(){
              setState(() {
                _cd = _isWeek ? core._7d : core.m;
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
