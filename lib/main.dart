import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Week> weeks = [];
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // Carrega dados salvos ao iniciar
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString('startDate');
    final cachedWeeks = prefs.getString('weeks');

    if (cachedDate != null && cachedWeeks != null) {
      setState(() {
        _dateController.text = cachedDate;
        weeks = (jsonDecode(cachedWeeks) as List)
            .map((weekData) => Week.fromJson(weekData))
            .toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveCachedData(String startDate, List<Week> weeks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('startDate', startDate);
    await prefs.setString('weeks', jsonEncode(weeks));
  }

  Future<void> fetchWorkouts(String startDate) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('https://hevy-dashboard-api-6f642e263370.herokuapp.com/workouts?startDate=$startDate'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('JSON Response: $data');
        setState(() {
          weeks = data.map((weekData) {
            print('Parsing week: $weekData');
            return Week.fromJson(weekData);
          }).toList();
          isLoading = false;
        });
        await _saveCachedData(startDate, weeks); // Salva no cache
      } else {
        throw Exception('Failed to load workouts: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error loading workouts: $e');
      print('StackTrace: $stackTrace');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading workouts: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Tracker')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Start Date (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final startDate = _dateController.text;
                    if (startDate.isNotEmpty) {
                      fetchWorkouts(startDate);
                    }
                  },
                  child: const Text('Fetch Workouts'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : ListView.builder(
                        itemCount: weeks.length,
                        itemBuilder: (context, weekIndex) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  weeks[weekIndex].number != null
                                      ? 'Week ${weeks[weekIndex].number}'
                                      : 'Week (No Number)',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: weeks[weekIndex].workouts.length,
                                itemBuilder: (context, workoutIndex) {
                                  return WorkoutTile(
                                      workout: weeks[weekIndex]
                                          .workouts[workoutIndex]);
                                },
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class Week {
  final int? number;
  final List<Workout> workouts;

  Week(this.number, this.workouts);

  factory Week.fromJson(Map<String, dynamic> json) {
    print('Week JSON: $json');
    var workoutsData = json['workouts'];
    List<dynamic> workoutList;

    if (workoutsData is List) {
      workoutList = workoutsData;
    } else if (workoutsData is Map<String, dynamic>) {
      workoutList = workoutsData.values.first as List<dynamic>;
    } else {
      throw Exception('Unexpected workouts format: $workoutsData');
    }

    return Week(
      json['week'],
      workoutList.map((workout) {
        print('Parsing workout: $workout');
        return Workout.fromJson(workout);
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'week': number,
        'workouts': workouts.map((workout) => workout.toJson()).toList(),
      };
}

class Workout {
  final String name;
  final List<Exercise> exercises;
  final String startTime;

  Workout(this.name, this.exercises, this.startTime);

  factory Workout.fromJson(Map<String, dynamic> json) {
    print('Workout JSON: $json');
    return Workout(
      json['name'] ?? 'Unknown',
      (json['exercises'] as List? ?? []).map((exercise) {
        print('Parsing exercise: $exercise');
        return Exercise.fromJson(exercise);
      }).toList(),
      json['start_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
        'start_time': startTime,
      };
}

class Exercise {
  final String name;
  final List<Set> sets;
  final double? weight;

  Exercise(this.name, this.sets, this.weight);

  factory Exercise.fromJson(Map<String, dynamic> json) {
    print('Exercise JSON: $json');
    var setsData = json['sets'] as List<dynamic>? ?? [];
    return Exercise(
      json['name'] ?? 'Unknown',
      setsData.map((set) => Set.fromJson(set)).toList(),
      json['weight_kg']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets.map((set) => set.toJson()).toList(),
        'weight_kg': weight,
      };

  int get setCount => sets.length;

  double? get averageReps {
    if (sets.isEmpty) return null;
    var validReps = sets.where((set) => set.reps != null).map((set) => set.reps!).toList();
    return validReps.isEmpty ? null : validReps.reduce((a, b) => a + b) / validReps.length;
  }

  double? get averageRpe {
    if (sets.isEmpty) return null;
    var validRpe = sets.where((set) => set.rpe != null).map((set) => set.rpe!).toList();
    return validRpe.isEmpty ? null : validRpe.reduce((a, b) => a + b) / validRpe.length;
  }
}

class Set {
  final int? reps;
  final double? rpe;
  final String? type;
  final double? weight;

  Set(this.reps, this.rpe, this.type, this.weight);

  factory Set.fromJson(Map<String, dynamic> json) {
    return Set(
      json['setReps'],
      json['setRpe']?.toDouble(),
      json['setType'],
      json['setWeightKg']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'setReps': reps,
        'setRpe': rpe,
        'setType': type,
        'setWeightKg': weight,
      };
}

class WorkoutTile extends StatefulWidget {
  final Workout workout;
  const WorkoutTile({super.key, required this.workout});

  @override
  _WorkoutTileState createState() => _WorkoutTileState();
}

class _WorkoutTileState extends State<WorkoutTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[50],
      child: ExpansionTile(
        title: Text(widget.workout.name),
        subtitle: Text(widget.workout.startTime),
        onExpansionChanged: (expanded) {
          setState(() {
            isExpanded = expanded;
          });
        },
        children: widget.workout.exercises
            .map((exercise) => Container(
                  color: Colors.yellow[50],
                  child: ListTile(
                    title: Text(exercise.name),
                    subtitle: Text(
                      'Sets: ${exercise.setCount}, Avg Reps: ${exercise.averageReps?.toStringAsFixed(1) ?? 'N/A'}${exercise.weight != null ? ', Weight: ${exercise.weight}kg' : ''}${exercise.averageRpe != null ? ', Avg RPE: ${exercise.averageRpe}' : ''}',
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}