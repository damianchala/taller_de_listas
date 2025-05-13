import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          secondary: Colors.tealAccent,
          background: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TodoListScreen(),
    );
  }
}

enum TaskFilter { all, active, completed }

class Task {
  String title;
  bool isCompleted;
  DateTime createdAt;
  Color? color;

  Task({
    required this.title, 
    this.isCompleted = false,
    DateTime? createdAt,
    this.color,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'color': color?.value,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      color: json['color'] != null ? Color(json['color']) : null,
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({Key? key}) : super(key: key);

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> with SingleTickerProviderStateMixin {
  List<Task> _tasks = [];
  final TextEditingController _textController = TextEditingController();
  late AnimationController _animationController;
  TaskFilter _currentFilter = TaskFilter.all;
  Color _selectedColor = Colors.indigoAccent;
  
  final List<Color> _availableColors = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.amberAccent,
    Colors.greenAccent,
    Colors.tealAccent,
    Colors.indigoAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Cargar tareas desde SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];

    setState(() {
      _tasks = tasksJson
          .map((task) => Task.fromJson(jsonDecode(task)))
          .toList();
    });
  }

  // Guardar tareas en SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks
        .map((task) => jsonEncode(task.toJson()))
        .toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  // Añadir una nueva tarea
  void _addTask(String title) {
    if (title.isNotEmpty) {
      setState(() {
        _tasks.add(Task(
          title: title,
          color: _selectedColor,
        ));
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
      _saveTasks();
      _textController.clear();
      
      // Animación de confirmación
      _animationController.forward().then((_) => _animationController.reverse());
    }
  }

  // Cambiar el estado de completado de una tarea
  void _toggleTaskCompletion(int index) {
    final actualIndex = _getActualIndex(index);
    if (actualIndex != -1) {
      setState(() {
        _tasks[actualIndex].isCompleted = !_tasks[actualIndex].isCompleted;
      });
      _saveTasks();
    }
  }

  // Eliminar una tarea
  void _deleteTask(int index) {
    final actualIndex = _getActualIndex(index);
    if (actualIndex != -1) {
      setState(() {
        _tasks.removeAt(actualIndex);
      });
      _saveTasks();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tarea eliminada'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Deshacer',
            textColor: Colors.white,
            onPressed: () {
              // Funcionalidad para deshacer no implementada
            },
          ),
        ),
      );
    }
  }

  // Mostrar diálogo para editar una tarea
  void _showEditDialog(int index) {
    final actualIndex = _getActualIndex(index);
    if (actualIndex == -1) return;
    
    final TextEditingController editController = TextEditingController();
    editController.text = _tasks[actualIndex].title;
    Color selectedColor = _tasks[actualIndex].color ?? _selectedColor;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Tarea'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editController,
                    decoration: const InputDecoration(
                      hintText: 'Editar tarea',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Color de la tarea:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (editController.text.isNotEmpty) {
                      setState(() {
                        _tasks[actualIndex].title = editController.text;
                        _tasks[actualIndex].color = selectedColor;
                      });
                      _saveTasks();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Obtener el índice real de la tarea en la lista original
  int _getActualIndex(int displayIndex) {
    final List<Task> filteredTasks = _getFilteredTasks();
    if (displayIndex < 0 || displayIndex >= filteredTasks.length) {
      return -1;
    }
    
    final Task task = filteredTasks[displayIndex];
    return _tasks.indexOf(task);
  }

  // Obtener tareas filtradas según el filtro actual
  List<Task> _getFilteredTasks() {
    switch (_currentFilter) {
      case TaskFilter.active:
        return _tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.completed:
        return _tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.all:
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Mi Lista de Tareas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo, Colors.deepPurple],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterChip(TaskFilter.all, 'Todas'),
                    _buildFilterChip(TaskFilter.active, 'Activas'),
                    _buildFilterChip(TaskFilter.completed, 'Completadas'),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nueva Tarea',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                hintText: 'Añadir nueva tarea',
                                prefixIcon: Icon(Icons.task),
                              ),
                              onSubmitted: (value) {
                                _addTask(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              _addTask(_textController.text);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Color:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: _selectedColor == color
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: filteredTasks.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 70,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyStateMessage(),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filteredTasks[index];
                        return _buildTaskCard(task, index);
                      },
                      childCount: filteredTasks.length,
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 80), // Espacio para que no choque con el FAB
          ),
        ],
      ),
      floatingActionButton: FilterChip(
        label: Text(
          '${filteredTasks.length} tarea${filteredTasks.length != 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.white),
        ),
        selected: true,
        selectedColor: Colors.indigo,
        onSelected: (_) {},
      ),
    );
  }

  Widget _buildFilterChip(TaskFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.indigoAccent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
          });
        }
      },
    );
  }

  Widget _buildTaskCard(Task task, int index) {
    final borderColor = task.color ?? Colors.indigoAccent;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Dismissible(
          key: Key(task.title + task.createdAt.toString()),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            _deleteTask(index);
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Checkbox(
              activeColor: task.color ?? Colors.indigoAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              value: task.isCompleted,
              onChanged: (bool? value) {
                _toggleTaskCompletion(index);
              },
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black87,
                fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _getFormattedDate(task.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: Colors.grey[700],
              onPressed: () {
                _showEditDialog(index);
              },
            ),
            onTap: () {
              _toggleTaskCompletion(index);
            },
          ),
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getEmptyStateMessage() {
    switch (_currentFilter) {
      case TaskFilter.active:
        return 'No hay tareas pendientes';
      case TaskFilter.completed:
        return 'No hay tareas completadas';
      case TaskFilter.all:
      default:
        return 'No has añadido ninguna tarea';
    }
  }
}