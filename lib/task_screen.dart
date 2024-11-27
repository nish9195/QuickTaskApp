import 'package:flutter/material.dart';
import 'login_page.dart'; // Import your login page
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
// import 'dart:developer';

class TaskScreen extends StatefulWidget {
  final String username;
  const TaskScreen(this.username);
  @override
  _TaskScreenState createState() => _TaskScreenState(username);
}

class _TaskScreenState extends State<TaskScreen> {
  final String username;
  _TaskScreenState(this.username);

  final TextEditingController _taskController = TextEditingController();
  final List<Map<String, dynamic>> _tasks = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await initTasks();
  }

  Future<void> initTasks() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Tasks'))
        ..whereEqualTo('username', this.username);

    final response = await query.query();

    if (response.success && response.results != null) {
      setState(() {
        _tasks.clear();
        for (var result in response.results!) {
          final task = result as ParseObject;
          _tasks.add({
            'id': task.objectId,
            'task': task.get<String>('task') ?? '',
            'dueDate': task.get<String>('due_date') ?? '',
            'completed': task.get<bool>('is_completed') ?? false,
          });
        }
        _sortTasks();
      });
    }
  }

  // Function to pick a date
  Future<void> _pickDueDate(BuildContext context, StateSetter setStateDialog) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      setStateDialog(() {}); // Update dialog state
    }
  }

  // Function to add or update a task
  Future<void> _addOrUpdateTask({int? index}) async {
    if (_taskController.text.isNotEmpty && _selectedDate != null) {
      if (index == null) {
        final newTask = ParseObject('Tasks');
        newTask
          ..set('username', this.username)
          ..set('task', _taskController.text)
          ..set('due_date', _selectedDate!.toLocal().toString().split(' ')[0])
          ..set('is_completed', false);

        final response = await newTask.save();

        // log(response);

        if(response.success && response.result != null) {
          // await initTasks();
          setState(() {
            // Add a new task
            _tasks.add({
              'id': response.result.objectId,
              'task': _taskController.text,
              'dueDate': _selectedDate!.toLocal().toString().split(' ')[0],
              'completed': false, // New task is not completed by default
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('New Task Created')),
          );
        }
      } else {
        // Update an existing task
        final updatedTask = ParseObject('Tasks')
          ..objectId = _tasks[index]['id'] // Specify task ID to update
          ..set('task', _taskController.text)
          ..set('due_date', _selectedDate!.toLocal().toString().split(' ')[0]);

        final response = await updatedTask.save();

        if (response.success) {
          // await initTasks();
          setState(() {
            _tasks[index] = {
              'id': _tasks[index]['id'], // retain id
              'task': _taskController.text,
              'dueDate': _selectedDate!.toLocal().toString().split(' ')[0],
              'completed': _tasks[index]['completed'], // Retain completion state
            };
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task Updated')),
          );
        }
      }
      _taskController.clear();
      _selectedDate = null;
      _sortTasks(); // Ensure tasks are sorted after adding/updating
      Navigator.of(context).pop(); // Close the dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both fields')),
      );
    }
  }

  // Function to delete a task
  Future<void> _deleteTask(int index) async {
    final updatedTask = ParseObject('Tasks')
      ..objectId = _tasks[index]['id']; // Specify task ID to delete

    final response = await updatedTask.delete();

    if (response.success) {
      // await initTasks();
      setState(() {
        _tasks.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task Deleted')),
      );
    }
  }

  // Function to toggle task completion state
  Future<void> _toggleTaskCompletion(int index, bool? value) async {
    final updatedTask = ParseObject('Tasks')
      ..objectId = _tasks[index]['id'] // Specify task ID to update
      ..set('is_completed', value);

    final response = await updatedTask.save();

    if (response.success) {
      // await initTasks();
      setState(() {
        _tasks[index]['completed'] = value ?? false;
        _sortTasks(); // Ensure completed tasks move to the bottom
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task Updated')),
      );
    }
  }

  // Function to sort tasks
  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a['completed'] != b['completed']) {
        return a['completed'] ? 1 : -1; // Move completed tasks to the bottom
      }
      DateTime dateA = DateTime.parse(a['dueDate']);
      DateTime dateB = DateTime.parse(b['dueDate']);
      return dateA.compareTo(dateB); // Sort by due date
    });
  }

  // Function to open the task editing dialog
  void _showTaskDialog({int? index}) {
    if (index != null) {
      _taskController.text = _tasks[index]['task'] ?? '';
      _selectedDate = DateTime.parse(_tasks[index]['dueDate'] ?? DateTime.now().toString());
    } else {
      _taskController.clear();
      _selectedDate = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(index == null ? 'Add Task' : 'Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task Name Input
                  TextField(
                    controller: _taskController,
                    decoration: InputDecoration(labelText: 'Task Name'),
                  ),
                  SizedBox(height: 10),
                  // Due Date Picker
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'No date selected'
                              : 'Due Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () => _pickDueDate(context, setStateDialog),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            'Pick Date',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async => await _addOrUpdateTask(index: index),
                  child: Text(index == null ? 'Add' : 'Save'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Task Button
              Center(
                child: ElevatedButton(
                  onPressed: () => _showTaskDialog(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Add Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Display Tasks
              Expanded(
                child: ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final bool isCompleted = task['completed'] ?? false;
                    return Card(
                      color: Colors.white.withOpacity(0.9),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: isCompleted,
                          onChanged: (value) => _toggleTaskCompletion(index, value),
                        ),
                        title: Text(
                          task['task'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.green : Colors.red,
                          ),
                        ),
                        subtitle: Text('Due Date: ${task['dueDate']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showTaskDialog(index: index),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTask(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
