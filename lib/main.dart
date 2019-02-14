import 'dart:async';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';

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
        '/': (context) => MyHomePage(title: 'タイマー一覧'),
      },
    );
  }
}

class Timer {
  int id;
  String eventName;
  DateTime timerDate;
  TimeOfDay timerTime;
  bool isEnable;

  Timer(this.id, this.eventName, this.timerDate, this.timerTime, this.isEnable);

  int getId() {
    return id;
  }

  DateTime getDatetime() {
    return timerDate;
  }

  static int newId() {
    return (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).round();
  }

  static Timer createTimer(String _eventName, DateTime _timerDate, TimeOfDay _timerTime, bool _isEnable) {
    return Timer(Timer.newId(), _eventName, _timerDate, _timerTime, _isEnable);
  }

  static Timer createDefaultTimer() {
    return Timer(Timer.newId(), '', DateTime.now(), TimeOfDay.now(), true);
  }
}

class DatabaseDriver {
  static const dbName = "timer.db";

  String dbPath;
  String path;

  void getPath() async {
    dbPath = await getDatabasesPath();
    path = join(dbPath, dbName);
  }

}

class TimerList {
  List _timers = <Timer>[];

  static final TimerList _singleton = TimerList._internal();

  factory TimerList() {
    return _singleton;
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  void initNotification() {
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid,
        initializationSettingsIOS
    );
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: onSelectNotification
    );
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
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    var timerDt = DateTime(
      timer.timerDate.year,
      timer.timerDate.month,
      timer.timerDate.day,
      timer.timerTime.hour,
      timer.timerTime.minute,
    );
//    var timerDt = DateTime.now().add(Duration(seconds: 5));

    print("set timer:" + timer.getId().toString() + " " + timerDt.toIso8601String());
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

  List<Timer> get() {
    return _timers;
  }

  void add(Timer timer) {
    setSchedular(timer);
    _timers.add(timer);
  }

  void del(Timer timer) {
    cancelSchedular(timer);
    _timers.remove(timer);
  }

  void save(Timer timer) {
    var idx = _timers.indexOf(timer);
    if (idx != -1) {
      print("save: " + idx.toString());
      _timers[idx] = timer;

      cancelSchedular(timer);
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
    super.initState();
    _timers.initNotification();
  }

  Function delTimer(Timer timer) {
    return () {
      setState(() {
        _timers.del(timer);
      });
    };
  }

  Function _onPressed(BuildContext context, Timer timer) {
    return () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DateAndTimePicker(timer: timer)
            )
        );
      };
  }

  @override
  Widget build(BuildContext context) {
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
  String _eventName;
  DateTime _timerDate;
  TimeOfDay _timerTime;
  bool _isEnable;

  TimerList _timers = TimerList();

  void setSelfTimer(Timer timer) {
    _eventName = timer.eventName;
    _timerDate = timer.timerDate;
    _timerTime = timer.timerTime;
    _isEnable  = timer.isEnable;
  }

  void setTimerFromSelf(Timer timer) {
    timer.eventName = _eventName;
    timer.timerDate = _timerDate;
    timer.timerTime = _timerTime;
    timer.isEnable  = _isEnable;
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
        title: const Text('タイマー設定'),
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
                controller: TextEditingController(text: _eventName),
                onChanged: (text) {
                  setState(() {
                    _eventName = text;
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
                      }
                    ),
                  ],
                ),
              )
//              Switch(
//                value: _isEnable,
//                onChanged: (bool value) {
//                  setState(() {
//                    _isEnable = value;
//                  });
//                }
//              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.timer == null) {
            _timers.add(Timer.createTimer(_eventName, _timerDate, _timerTime, _isEnable));
          } else {
            setTimerFromSelf(widget.timer);
            _timers.save(widget.timer);
          }
          Navigator.pop(context);
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
                  leading: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 36.0
                  )
              )
          ),
          child: Container(
            decoration: BoxDecoration(
                color: theme.canvasColor,
                border: Border(
                    bottom: BorderSide(
                        color: theme.dividerColor
                    )
                )
            ),
            child: ListTile(
              title: Text(timer.eventName),
              subtitle: Text(timer.timerDate.toString() + ' ' + timer.timerTime.toString()),
              isThreeLine: true,
              onTap: _handleEdit,
            ),
          ),
        ));
  }
}
