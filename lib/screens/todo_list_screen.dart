import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

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
    _checkDueDates(); // Check due dates on initialization
    // Test Notification
    _showNotification("Test notification to check if notifications are working!");
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

  void _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Use the default launcher icon

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String taskTitle) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        icon: '@mipmap/ic_launcher'); // Reference to default icon

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
        0, // Notification ID
        'Task Completed', // Title
        taskTitle, // Body
        platformChannelSpecifics);
  }

  Future<void> _requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _scheduleDueDateNotification(DateTime dueDate, String title) async {
    var scheduledDate = DateTime.now();
    if (dueDate.year == scheduledDate.year &&
        dueDate.month == scheduledDate.month &&
        dueDate.day == scheduledDate.day) {
      _showNotification(title); // Directly call if the due date is today
    }
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

    // Check if the due date is today and show notification
    DateTime now = DateTime.now();
    if (_dueDate!.year == now.year && _dueDate!.month == now.month && _dueDate!.day == now.day) {
      _showNotification('Task Due Today: ${_titleController.text}'); // Show notification for due date today
    }

    // Clear the controllers and due date
    _titleController.clear();
    _detailsController.clear();
    _dueDate = null;

    // Log the task title to confirm it was added
    print('Task Created: ${_titleController.text}');
    _showNotification('Task Created: ${_titleController.text}'); // Show notification for task creation
  }

  void _toggleCompletion(int index) {
    setState(() {
      _tasks[index]['completed'] = !_tasks[index]['completed'];
    });
    _saveTasks();
    if (_tasks[index]['completed']) {
      // Log completion
      print('Task Completed: ${_tasks[index]['title']}');
      _showNotification('Task Completed: ${_tasks[index]['title']}'); // Show notification for task completion
    }
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
      print('Task Deleted: ${_tasks[index]['title']}'); // Log deletion
      _showNotification('Task Deleted: ${_tasks[index]['title']}'); // Show notification for task deletion
      setState(() {
        _tasks.removeAt(index);
      });
      _saveTasks();
    }
  }

  void _checkDueDates() {
    DateTime now = DateTime.now();
    for (var task in _tasks) {
      if (!task['completed'] && task['dueDate'].isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
        print('Notifying for task: ${task['title']}'); // Debugging statement
        _showNotification('Task Due Today: ${task['title']}');
      }
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
                  bool isToday = task['dueDate'].isAtSameMomentAs(DateTime.now());

                  return ListTile(
                    leading: Checkbox(
                      value: task['completed'],
                      onChanged: (value) => _toggleCompletion(index),
                      activeColor: Colors.redAccent,
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        task['title'],
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.grey, size: 18), // Icon for due date
                            const SizedBox(width: 8), // Space between icon and text
                            Text(
                              DateFormat.yMd().format(task['dueDate']),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        // Show message if due date is today
                        if (isToday)
                          const Text(
                            'Today is the last date of this task',
                            style: TextStyle(fontSize: 11, color: Colors.redAccent),
                          ),
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
