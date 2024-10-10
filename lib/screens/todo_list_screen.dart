import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ToDoListScreen extends StatefulWidget {
  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();
  DateTime? _dueDate;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  String _username = 'User';
  String _searchQuery = '';
  bool _isSearching = false; // State variable for search visibility

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
      _tasks = prefs.getStringList('tasks')?.map((task) {
        final taskData = Map<String, dynamic>.from(Map.castFrom(json.decode(task)));
        taskData['dueDate'] = DateTime.parse(taskData['dueDate']);
        return taskData;
      }).toList() ?? [];
    });
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('tasks', _tasks.map((task) {
      return json.encode({
        'title': task['title'],
        'details': task['details'],
        'dueDate': (task['dueDate'] as DateTime).toIso8601String(),
        'completed': task['completed'],
      });
    }).toList());
  }

  Future<void> _updateUsername(String newName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = newName;
    });
    await prefs.setString('username', newName);
  }

  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    _notificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String title) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    _notificationsPlugin.show(
      0,
      'Task Due Today',
      title,
      platformChannelSpecifics,
    );
  }

  void _addTask() {
    if (_titleController.text.isEmpty || _dueDate == null) return;
    setState(() {
      _tasks.add({
        'title': _titleController.text,
        'details': _detailsController.text,
        'dueDate': _dueDate,
        'completed': false,
      });
    });
    _saveTasks();
    _titleController.clear();
    _detailsController.clear();
    _dueDate = null;
  }

  void _toggleCompletion(int index) {
    setState(() {
      _tasks[index]['completed'] = !_tasks[index]['completed'];
    });
    _saveTasks();
  }

  void _removeTask(int index) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm) {
      setState(() {
        _tasks.removeAt(index);
      });
      _saveTasks();
    }
  }

  void _selectDueDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  void _showRenameDialog() {
    _renameController.text = _username;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(child: Text('Rename Username', style: TextStyle(fontSize: 24, color: Colors.redAccent),)),
          content: TextField(
            controller: _renameController,
            decoration: const InputDecoration(labelText: 'New Username'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateUsername(_renameController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Rename', style: TextStyle(color: Colors.red),),
            ),
          ],
        );
      },
    );
  }

  // Add this method to your _ToDoListScreenState class
  void _showTaskDetailsDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Details: ${task['details']}'),
              const SizedBox(height: 10),
              Text('Due Date: ${DateFormat.yMd().format(task['dueDate'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close', style: TextStyle(color: Colors.redAccent),),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Center(child: Text('Add New Task', style: TextStyle(fontSize: 24, color: Colors.redAccent),)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', suffixStyle: TextStyle(color: Colors.grey)),
                  ),
                  TextField(
                    controller: _detailsController,
                    decoration: const InputDecoration(labelText: 'Details'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dueDate = pickedDate;
                        });
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey), // Icon for due date
                        const SizedBox(width: 8), // Space between icon and text
                        Text(
                          _dueDate == null
                              ? 'Select Due Date'
                              : DateFormat.yMd().format(_dueDate!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _addTask();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _tasks.where((task) => task['completed']).length;
    final uncompletedTasks = _tasks.length - completedTasks;

    // Filtered tasks based on search query
    final filteredTasks = _searchQuery.isEmpty
        ? _tasks
        : _tasks
        .where((task) => task['title']
        .toString()
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey,),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back
          },
        ),
        title: const Center(child: Text('TO-DO', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey,),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching; // Toggle search visibility
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.supervised_user_circle_sharp, size: 50, color: Colors.grey,),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome Back', style: TextStyle(color: Colors.grey, fontSize: 11),),
                    Text(
                      _username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.redAccent),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.pending, color: Colors.grey, size: 30,),
                  onPressed: _showRenameDialog,
                ),
              ],
            ),
            const Divider(),
            Text(
                'Tasks: ${filteredTasks.length} -  Completed: $completedTasks  -  Uncompleted: $uncompletedTasks', style: const TextStyle(color: Colors.grey, fontSize: 12),),
            const Divider(),

            // Search box
            if (_isSearching)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value; // Update the search query
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: ' Search tasks...',
                    border: InputBorder.none,
                  ),
                ),
              ),

            // Task List
            // Modify the ListTile in the build method
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return ListTile(
                    leading: Checkbox(
                      value: task['completed'],
                      onChanged: (value) => _toggleCompletion(index),
                      activeColor: Colors.redAccent,
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(task['title'], style: TextStyle(color: Colors.grey[800])),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.grey, size: 18), // Icon for due date
                        const SizedBox(width: 8), // Space between icon and text
                        Text(DateFormat.yMd().format(task['dueDate']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                          onPressed: () => _removeTask(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.read_more, color: Colors.redAccent),
                          onPressed: () => _showTaskDetailsDialog(task), // Show task details
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add, color: Colors.white70,),
        shape: const CircleBorder(),
        backgroundColor: Colors.redAccent,// Ensures it's circular
      ),
    );
  }
}
