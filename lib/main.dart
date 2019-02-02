import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


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
//        DateAndTimePicker.routeName: (context) => DateAndTimePicker(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Timer {
  DateTime timerDate;
  TimeOfDay timerTime;

  Timer(this.timerDate, this.timerTime);
}

class _MyHomePageState extends State<MyHomePage> {
  List _timers = <Timer>[];

  void _addTimer() {
    setState(() {
      _timers.add(Timer(DateTime.now(), TimeOfDay.now()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: timerList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTimer,
        tooltip: 'Add',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget timerListTime(Timer timer) {
    return
      RaisedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>
              DateAndTimePicker(
                date: timer.timerDate,
                time: timer.timerTime
              )
            )
          );
        },
        child: Container(
          color: Colors.lightBlueAccent,
          height: 50.0,
          child: Padding(
            padding: EdgeInsets.all(5.0),
            child:
            Center(
              child: Text(
                '鳴らす！' + timer.timerDate.toString() + ' ' + timer.timerTime.toString(),
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ),
        )
      );
  }

  Widget timerList() {
    List widgets = <Widget>[];
    for(var timer in _timers) {
      widgets.add(timerListTime(timer));
    }
    return SingleChildScrollView(
      child: Column(
        children: widgets,
      ),
    );
  }
}

class _InputDropdown extends StatelessWidget {
  const _InputDropdown({
    Key key,
    this.child,
    this.labelText,
    this.valueText,
    this.valueStyle,
    this.onPressed }) : super(key: key);

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
                color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade700 : Colors.white70
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({
    Key key,
    this.labelText,
    this.selectedDate,
    this.selectedTime,
    this.selectDate,
    this.selectTime
  }) : super(key: key);

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
        lastDate: DateTime(2101)
    );
    if (picked != null && picked != selectedDate)
      selectDate(picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
        context: context,
        initialTime: selectedTime
    );
    if (picked != null && picked != selectedTime)
      selectTime(picked);
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
            onPressed: () { _selectDate(context); },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 3,
          child: _InputDropdown(
            valueText: selectedTime.format(context),
            valueStyle: valueStyle,
            onPressed: () { _selectTime(context); },
          ),
        ),
      ],
    );
  }
}

class DateAndTimePicker extends StatefulWidget {
//  static final String routeName = '/timer';

  const DateAndTimePicker({Key key, this.date, this.time}): super(key: key);

  final DateTime date;
  final TimeOfDay time;

  @override
  _DateAndTimePickerState createState() => _DateAndTimePickerState();
}

class _DateAndTimePickerState extends State<DateAndTimePicker> {
  DateTime _timerDate; // = DateTime.now();
  TimeOfDay _timerTime; // = const TimeOfDay(hour: 7, minute: 28);

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
              ),
              _DateTimePicker(
                labelText: 'Alert Time',
                selectedDate: widget.date == null ? DateTime.now():widget.date,
                selectedTime: widget.time == null ? TimeOfDay.now():widget.time,
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
            ],
          ),
        ),
      ),
    );
  }
}
