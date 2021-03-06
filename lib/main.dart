import 'dart:async';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sprintf/sprintf.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(title: 'Timer'),
      },
    );
  }
}

class Timer {
  int id;
  String name;
  DateTime timerDate;
  TimeOfDay timerTime;
  bool isEnable;

  Timer();

  String convertTimeString(TimeOfDay time) {
    return timerTime.hour.toString().padLeft(2, "0") +
        ":" +
        timerTime.minute.toString().padLeft(2, "0");
  }

  TimeOfDay convertTimeOfDay(String time) {
    var times = time.split(":");
    return TimeOfDay(hour: int.parse(times[0]), minute: int.parse(times[1]));
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'name': name,
      'date': timerDate.toUtc().toString(),
      'time': convertTimeString(timerTime),
      'enable': isEnable == true ? 1 : 0
    };
    if (id != null) {
      map['id'] = id;
    }
    print(map);
    return map;
  }

  Timer.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    timerDate = DateTime.parse(map['date']);
    timerTime = convertTimeOfDay(map['time']);
    isEnable = map['enable'] == 1 ? true : false;
  }

  int getId() {
    return id;
  }

  Timer.createTimer(
      String _name, DateTime _timerDate, TimeOfDay _timerTime, bool _isEnable) {
    name = _name;
    timerDate = _timerDate;
    timerTime = _timerTime;
    isEnable = _isEnable;
  }

  static Timer createDefaultTimer() {
    return Timer.createTimer('', DateTime.now(), TimeOfDay.now(), true);
  }
}

class DatabaseDriver {
  static const dbName = "timer.db";

//  String dbPath;
//  String path;

  Future<String> getPath() async {
    var dbPath = await getDatabasesPath();
    return join(dbPath, dbName);
  }

  Future<Database> open() async {
    var path = await getPath();
    var db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE IF NOT EXISTS timer (" +
          "id INTEGER PRIMARY KEY, " +
          "name TEXT, " +
          "date TEXT, " +
          "time TEXT, " +
          "enable INTEGER)");
    });
    return db;
  }

  Future<Timer> insert(Timer timer) async {
    var db = await open();
    timer.id = await db.insert('timer', timer.toMap());
    return timer;
  }

  Future<void> update(Timer timer) async {
    var db = await open();
    await db
        .update('timer', timer.toMap(), where: 'id = ?', whereArgs: [timer.id]);
  }

  void delete(Timer timer) async {
    var db = await open();
    await db.delete('timer', where: 'id = ?', whereArgs: [timer.id]);
  }

  Future<List<Timer>> getAll() async {
    var db = await open();
    List<Timer> timers = <Timer>[];
    List<Map> result = await db.rawQuery('SELECT * FROM timer');
    for (Map item in result) {
      print(item);
      timers.add(Timer.fromMap(item));
    }
    return timers;
  }
}

class TimerList {
  List _timers = <Timer>[];

  DatabaseDriver database = DatabaseDriver();

  static final TimerList _singleton = TimerList._internal();

  factory TimerList() {
    return _singleton;
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  void init() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
//    await Navigator.push(
//      context,
//      new MaterialPageRoute(builder: (context) => new SecondScreen(payload)),
//    );
  }

  // notification
  Future _showNotification(Timer timer) async {
    var vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      'your channel description',
      importance: Importance.Max,
      priority: Priority.High,
      icon: 'secondary_icon',
      sound: 'slow_spring_board',
      largeIcon: 'sample_large_icon',
      largeIconBitmapSource: BitmapSource.Drawable,
      vibrationPattern: vibrationPattern,
      color: const Color.fromARGB(255, 255, 0, 0),
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    var timerDt = DateTime(
      timer.timerDate.year,
      timer.timerDate.month,
      timer.timerDate.day,
      timer.timerTime.hour,
      timer.timerTime.minute,
    );
//    var timerDt = DateTime.now().add(Duration(seconds: 5));

    print("set timer:" +
        timer.getId().toString() +
        " " +
        timerDt.toIso8601String());
    await flutterLocalNotificationsPlugin.schedule(
      timer.getId(),
      'Timer',
      'You should check the app',
      timerDt,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  Future _cancelNotification(Timer timer) async {
    print("cancel timer:" + timer.getId().toString());
    await flutterLocalNotificationsPlugin.cancel(timer.getId());
  }

  void setSchedular(Timer timer) {
    _showNotification(timer);
  }

  void cancelSchedular(Timer timer) {
    _cancelNotification(timer);
  }

  Future<void> loadDb() async {
    await database.getAll().then((List<Timer> timers) {
      _timers = timers;
    });
  }

  List<Timer> get() {
    return _timers;
  }

  Future<void> add(Timer timer) async {
    timer = await database.insert(timer);
    await loadDb();
    if (timer.isEnable) {
      setSchedular(timer);
    }
  }

  Future<void> del(Timer timer) async {
    cancelSchedular(timer);
    await database.delete(timer);
    await loadDb();
  }

  Future<void> save(Timer timer) async {
    await database.update(timer);
    await loadDb();
    cancelSchedular(timer);
    if (timer.isEnable) {
      setSchedular(timer);
    }
  }

  TimerList._internal();
}

class MyHomePage extends StatefulWidget {
//  final homeKey = GlobalKey();

  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TimerList _timers = TimerList();

  @override
  void initState() {
    print("initState() start");
    super.initState();
    _timers.init();
    _timers.loadDb().then((result) {
      setState(() {
        print("init setState()");
      });
    });

    print("initState() end");
  }

  Function delTimer(Timer timer) {
    return () {
      _timers.del(timer).then((result) {
        setState(() {
          print("delTimer setState()");
        });
      });
    };
  }

  Function _onPressed(BuildContext context, Timer timer) {
    return () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DateAndTimePicker(timer: timer)));
    };
  }

  @override
  Widget build(BuildContext context) {
    print("build() start");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: timerList(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _onPressed(context, null),
        tooltip: 'Add',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      drawer: Drawer(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20.0),
          children: <Widget>[
            drawerTile1(context),
          ],
        ),
      ),
    );
  }

  Widget drawerTile1(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.home),
      title: Text('Home'),
      onTap: () {
        showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: Text("Home"),
                  content: Text("sample"),
                ));
      },
    );
  }

  Widget timerList(BuildContext context) {
    List widgets = <Widget>[];
    for (var timer in _timers.get()) {
      widgets.add(
        _LeaveBehindListItem(
          timer: timer,
          onDelete: delTimer(timer),
          onEdit: _onPressed(context, timer),
          dismissDirection: DismissDirection.startToEnd,
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: widgets,
      ),
    );
  }
}

class _InputDropdown extends StatelessWidget {
  const _InputDropdown(
      {Key key,
      this.child,
      this.labelText,
      this.valueText,
      this.valueStyle,
      this.onPressed})
      : super(key: key);

  final String labelText;
  final String valueText;
  final TextStyle valueStyle;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
        ),
        baseStyle: valueStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(valueText, style: valueStyle),
            Icon(Icons.arrow_drop_down,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade700
                    : Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker(
      {Key key,
      this.labelText,
      this.selectedDate,
      this.selectedTime,
      this.selectDate,
      this.selectTime})
      : super(key: key);

  final String labelText;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<DateTime> selectDate;
  final ValueChanged<TimeOfDay> selectTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) selectDate(picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay picked =
        await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null && picked != selectedTime) selectTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = Theme.of(context).textTheme.title;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: _InputDropdown(
            labelText: labelText,
            valueText: DateFormat.yMMMd().format(selectedDate),
            valueStyle: valueStyle,
            onPressed: () {
              _selectDate(context);
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 3,
          child: _InputDropdown(
            valueText: selectedTime.format(context),
            valueStyle: valueStyle,
            onPressed: () {
              _selectTime(context);
            },
          ),
        ),
      ],
    );
  }
}

class DateAndTimePicker extends StatefulWidget {
  const DateAndTimePicker({Key key, this.timer}) : super(key: key);

  final Timer timer;

  @override
  _DateAndTimePickerState createState() => _DateAndTimePickerState();
}

class _DateAndTimePickerState extends State<DateAndTimePicker> {
  String _name;
  DateTime _timerDate;
  TimeOfDay _timerTime;
  bool _isEnable;

  TimerList _timers = TimerList();

  void setSelfTimer(Timer timer) {
    _name = timer.name;
    _timerDate = timer.timerDate;
    _timerTime = timer.timerTime;
    _isEnable = timer.isEnable;
  }

  void setTimerFromSelf(Timer timer) {
    timer.name = _name;
    timer.timerDate = _timerDate;
    timer.timerTime = _timerTime;
    timer.isEnable = _isEnable;
  }

  @override
  void initState() {
    super.initState();
    if (widget.timer == null) {
      setSelfTimer(Timer.createDefaultTimer());
      return;
    }
    setSelfTimer(widget.timer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Timer'),
      ),
      body: DropdownButtonHideUnderline(
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              TextField(
                enabled: true,
                decoration: const InputDecoration(
                  labelText: 'Event name',
                  border: OutlineInputBorder(),
                ),
                style: Theme.of(context).textTheme.display1,
                controller: TextEditingController(text: _name),
                onChanged: (text) {
                  setState(() {
                    _name = text;
                  });
                },
              ),
              _DateTimePicker(
                labelText: 'Alert Time',
                selectedDate: _timerDate == null ? DateTime.now() : _timerDate,
                selectedTime: _timerTime == null ? TimeOfDay.now() : _timerTime,
                selectDate: (DateTime date) {
                  setState(() {
                    _timerDate = date;
                  });
                },
                selectTime: (TimeOfDay time) {
                  setState(() {
                    _timerTime = time;
                  });
                },
              ),
              Align(
                alignment: const Alignment(0.0, -0.2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Switch.adaptive(
                        value: _isEnable,
                        onChanged: (bool value) {
                          setState(() {
                            _isEnable = value;
                          });
                        }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Future<void> result;
          if (widget.timer == null) {
            result = _timers.add(
                Timer.createTimer(_name, _timerDate, _timerTime, _isEnable));
          } else {
            setTimerFromSelf(widget.timer);
            result = _timers.save(widget.timer);
          }
          result.then((dummy) {
            Navigator.pop(context);
            setState(() {
              print("save/add setState()");
            });
          });
        },
        tooltip: 'Save',
        child: Icon(Icons.save),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _LeaveBehindListItem extends StatelessWidget {
  const _LeaveBehindListItem({
    Key key,
    @required this.timer,
    @required this.onDelete,
    @required this.onEdit,
    @required this.dismissDirection,
  }) : super(key: key);

  final Timer timer;
  final DismissDirection dismissDirection;
  final void Function() onDelete;
  final void Function() onEdit;

  void _handleDelete() {
    onDelete();
  }

  void _handleEdit() {
    onEdit();
  }

  Widget circleButton(String text, Function onPressed) {
    return Center(
        child: InkWell(
      onTap: onPressed,
      child: Container(
        //width: 50.0,
        //height: 50.0,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
//            borderRadius: BorderRadius.circular(30.0),
          color: Colors.lightBlue,
        ),
        child:
            Text(text, style: TextStyle(color: Colors.white, fontSize: 50.0)),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          const CustomSemanticsAction(label: 'Delete'): _handleDelete,
        },
        child: Dismissible(
          key: ObjectKey(timer),
          direction: dismissDirection,
          onDismissed: (DismissDirection direction) {
            if (direction == DismissDirection.startToEnd) _handleDelete();
          },
          background: Container(
              color: theme.primaryColor,
              child: const ListTile(
                  leading:
                      Icon(Icons.delete, color: Colors.white, size: 36.0))),
          child: Container(
            decoration: BoxDecoration(
                color: theme.canvasColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: ListTile(
              title: Text(timer.name),
              subtitle: Text(
                generateTimerText(timer.timerDate, timer.timerTime),
                style: TextStyle(
                  fontSize: 20.0,
                ),
              ),
              isThreeLine: true,
              onTap: _handleEdit,
            ),
          ),
        ));
  }

  String generateTimerText(DateTime date, TimeOfDay time) {
    return sprintf("%04d/%02d/%02d(%s) %02d:%02d", [
      date.year,
      date.month,
      date.day,
      weekdayName(date.weekday),
      time.hour,
      time.minute
    ]);
  }

  String weekdayName(int weekday) {
    List weeks = <String>['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return weeks[weekday - 1];
  }
}
