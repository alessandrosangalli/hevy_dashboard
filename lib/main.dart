import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    fetchWorkouts();
  }

  Future<void> fetchWorkouts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/workouts?startDate=2025-03-17'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          weeks = data.map((weekData) => Week.fromJson(weekData)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load workouts: ${response.statusCode}');
      }
    } catch (e) {
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
      body: isLoading
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
                            'Week ${weeks[weekIndex].number}',
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
                                workout: weeks[weekIndex].workouts[workoutIndex]);
                          },
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

class Week {
  final int number;
  final List<Workout> workouts;

  Week(this.number, this.workouts);

  factory Week.fromJson(Map<String, dynamic> json) {
    return Week(
      json['week'],
      (json['workouts'] as List)
          .expand((workoutList) => workoutList)
          .map((workout) => Workout.fromJson(workout))
          .toList(),
    );
  }
}

class Workout {
  final String name;
  final List<Exercise> exercises;
  final String startTime;

  Workout(this.name, this.exercises, this.startTime);

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      json['name'],
      (json['exercises'] as List)
          .map((exercise) => Exercise.fromJson(exercise))
          .toList(),
      json['start_time'],
    );
  }
}

class Exercise {
  final String name;
  final int reps;
  final double? rpe;
  final int sets;
  final double? weight;

  Exercise(this.name, this.reps, this.rpe, this.sets, this.weight);

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      json['name'],
      json['reps'],
      json['rpe']?.toDouble(),
      json['sets'],
      json['weight_kg']?.toDouble(),
    );
  }
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
                      'Sets: ${exercise.sets}, Reps: ${exercise.reps}${exercise.weight != null ? ', Weight: ${exercise.weight}kg' : ''}${exercise.rpe != null ? ', RPE: ${exercise.rpe}' : ''}',
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}