import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
  int allsteps = 0;
  String lastDate = "";
  List<double> _7d = List.filled(7, 0);
  List<double> m = List.filled(12, 0);
  Function? _onUpdate;

  void init(Function onUpdate) {
    _onUpdate = onUpdate;
    load().then((data) {
      if (data.containsKey('step')) {
        steps = data['step'];
        lastDate = data['date'] ?? "";
        if (data.containsKey('7d')) _7d = List<double>.from(data['7d']);
        if (data.containsKey('12m')) m = List<double>.from(data['12m']);
        allsteps = data['allstep'];
        _checkDate();
        _7d.last = steps.toDouble();
        _onUpdate?.call();
      } else {
        lastDate = DateTime.now().toString().split(' ')[0];
        save();
      }
    });
    plat.setMethodCallHandler((handler) async {
      if (handler.method == "onsss") {
        _checkDate();
        steps++;
        allsteps++;
        _7d.last = steps.toDouble();
        save();
        _onUpdate?.call();
      }
    });
  }

  Future<void> save() async {
    if (lastDate == "") lastDate = DateTime.now().toString().split(' ')[0];
    String jS = json.encode({
      'step': steps,
      'date': lastDate,
      '7d': _7d,
      '12m': m,
      'allstep': allsteps,
    });
    await plat.invokeMethod("save", {"json": jS});
  }

  Future<Map<String, dynamic>> load() async {
    String? jS = await plat.invokeMethod("load");
    if (jS == null || jS.isEmpty) return {};
    return json.decode(jS);
  }

  Future<void> clearData() async {
    steps = 0;
    allsteps = 0;
    lastDate = DateTime.now().toString().split(' ')[0];
    _7d = List.filled(7, 0);
    m = List.filled(12, 0);
    await save();
    _onUpdate?.call();
  }

  void _checkDate() {
    String todayStr = DateTime.now().toString().split(' ')[0];
    if (lastDate == "" && lastDate == todayStr) return;
    DateTime last = DateTime.parse(lastDate);
    DateTime today = DateTime.parse(todayStr);
    int dayOff = today.difference(last).inDays;
    if (dayOff > 0) {
      for (int i = 0; i < dayOff; i++) {
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
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    core.init(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("需求一"),
        actions: [
          IconButton(
            onPressed: () => core.clearData(),
            icon: Icon(Icons.delete),
          ),
        ],
      ),
      body: ListView(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: CircularProgressIndicator(
                        value: core.steps / 10000,
                        strokeWidth: 12,
                        color: Colors.orange,
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
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
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "設定步數",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          int? w = int.tryParse(_controller.text);
                          if (w != null) {
                            core.steps = w;
                            core._7d.last = core.steps.toDouble();
                            core.save();
                            _controller.clear();
                            FocusScope.of(context).unfocus();
                          }
                        },
                        child: Text("設定"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (builder) => PP()),
                    ).then((_){core.init(() => setState(() {}));});
                  },
                  icon: Icon(Icons.emoji_events),
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
    if (core.steps * 0.03 >= 1) {
      www = "${(core.steps * 0.03).toInt()} kcal";
    } else
      www = "${(core.steps * 30).toInt()} cal";
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
    Future.delayed(Duration(milliseconds: 500), () {
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
        actions: [
          IconButton(
            onPressed: () => core.clearData(),
            icon: Icon(Icons.delete),
          ),
        ],
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
                          AnimatedContainer(
                            duration: Duration(milliseconds: 1000),
                            curve: Curves.easeOut,
                            width: 25,
                            height: (_cd[index] / maxV) * 250,
                            color: Colors.orange,
                          ),
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
            Future.delayed(Duration(milliseconds: 1000), () {
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

class _PPState extends State<PP> with TickerProviderStateMixin {
  final core = CoreLogic();
  late AnimationController _controller;
  late AnimationController _Bcontroller;
  double _a = 0.0;
  double _b = 0.0;
  @override
  void initState() {
    super.initState();
    core.init((){
      if(mounted) setState(() {});
    });
    _controller = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener((){
      setState(() {
        _a = _controller.value;
      });
    });
    _Bcontroller = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener((){
      setState(() {
        _b = _Bcontroller.value;
      });
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    _Bcontroller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    bool inUnlocked = core.allsteps >= 10000;
    return Scaffold(
      appBar: AppBar(
        title: Text("需求三"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(inUnlocked ? "解鎖" : "${core.allsteps}/10000"),
            SizedBox(height: 50),
            GestureDetector(
              onPanUpdate: (deltails) {
                _controller.stop();
                _Bcontroller.stop();
                setState(() {
                  _a += deltails.delta.dx * 0.02;
                  _b += deltails.delta.dy * 0.02;
                  _controller.value = _a;
                  _Bcontroller.value = _b;
                });
              },
              onPanEnd: (deltails) {
                double va = deltails.velocity.pixelsPerSecond.dx / 1000;
                double vb = deltails.velocity.pixelsPerSecond.dy / 1000;
                Future fy = _controller.animateWith(FrictionSimulation(0.15, _a, va));
                Future fx = _Bcontroller.animateWith(FrictionSimulation(0.15, _b, vb));
                Future.wait([fy, fx]).then((_){
                  if(!mounted) return;
                  double ta = (_a / pi).round() * pi;
                  double tb = (_b / (2 * pi)).round() * (2 * pi);
                  final sp = SpringDescription(mass: 1, stiffness: 120, damping: 15);
                  _controller.animateWith(SpringSimulation(sp, _a, ta, 0));
                  _Bcontroller.animateWith(SpringSimulation(sp, _b, tb, 0));
                });
              },
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_b)
                  ..rotateY(-_a),
                alignment: FractionalOffset.center,
                child: _bM(inUnlocked),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bM(bool unlock) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: unlock
              ? [Colors.amber, Colors.orangeAccent, Colors.yellow]
              : [Colors.grey, Colors.blueGrey, Colors.grey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5),
        ],
        border: Border.all(color: Colors.white, width: 5),
      ),
      child: Icon(
        unlock ? Icons.emoji_events : Icons.lock,
        size: 100,
        color: Colors.white,
      ),
    );
  }
}
