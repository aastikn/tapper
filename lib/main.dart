import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

enum AppMode { pomodoro, tapper }

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tapper & Pomodoro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
        brightness: Brightness.dark,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainPage(
        isDarkMode: _isDarkMode,
        toggleTheme: _toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  MainPage({required this.isDarkMode, required this.toggleTheme});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  AppMode _currentMode = AppMode.pomodoro;
  final _player = AudioPlayer();

  // Pomodoro state
  static const int _defaultPomodoroDuration = 25;
  int _pomodoroDuration = _defaultPomodoroDuration;
  int _breakDuration = _defaultPomodoroDuration ~/ 5;
  Timer? _timer;
  int _currentDuration = _defaultPomodoroDuration * 60;
  bool _isTimerRunning = false;
  bool _isBreak = false;
  final TextEditingController _controller =
      TextEditingController(text: _defaultPomodoroDuration.toString());

  // Tapper state
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _pomodoroDuration = int.tryParse(_controller.text) ?? _defaultPomodoroDuration;
        _breakDuration = _pomodoroDuration ~/ 5;
        if (!_isTimerRunning) {
          _currentDuration = _pomodoroDuration * 60;
        }
      });
    });
  }

  void _startTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() {
        _isTimerRunning = false;
      });
    } else {
      setState(() {
        _isTimerRunning = true;
      });
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_currentDuration > 0) {
            _currentDuration--;
          } else {
            _timer?.cancel();
            _isTimerRunning = false;
            _isBreak = !_isBreak;
            _currentDuration =
                (_isBreak ? _breakDuration : _pomodoroDuration) * 60;
            _player.play(UrlSource('https://www.soundjay.com/buttons/beep-07.wav'));
            _startTimer();
          }
        });
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isBreak = false;
      _currentDuration = _pomodoroDuration * 60;
    });
  }

  String get _formattedTime {
    int minutes = _currentDuration ~/ 60;
    int seconds = _currentDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _currentMode == AppMode.pomodoro && _isBreak
          ? (widget.isDarkMode ? Colors.green[900] : Colors.green[100])
          : theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Dark Mode'),
                  Switch(
                    value: widget.isDarkMode,
                    onChanged: (value) => widget.toggleTheme(),
                  ),
                ],
              ),
              DropdownButton<AppMode>(
                value: _currentMode,
                onChanged: (AppMode? newValue) {
                  setState(() {
                    _currentMode = newValue!;
                  });
                },
                items: AppMode.values.map((AppMode mode) {
                  return DropdownMenuItem<AppMode>(
                    value: mode,
                    child: Text(mode.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
              ),
              if (_currentMode == AppMode.pomodoro)
                _buildPomodoroUI(theme)
              else
                _buildTapperUI(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroUI(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isBreak ? 'Break' : 'Pomodoro',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: _isBreak ? Colors.green : Colors.blue,
          ),
        ),
        Text(
          _formattedTime,
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.w300,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startTimer,
              child: Text(_isTimerRunning ? 'Pause' : 'Start'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: _resetTimer,
              child: Text('Reset'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
        SizedBox(height: 40),
        Visibility(
          visible: !_isTimerRunning,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Pomodoro Duration (minutes)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTapperUI(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$_counter',
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.w300,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 60),
        GestureDetector(
          onTap: _incrementCounter,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _resetCounter,
          child: Text('Reset'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }
}