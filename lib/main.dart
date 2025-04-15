import 'package:flutter/material.dart';

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
  int? selectedMacrocycle;
  final Map<int, List<Week>> macrocycles = {
    1: [
      Week(1, [
        Workout('Workout 1', [
          Exercise('Bench Press', 80, 10),
          Exercise('Squats', 100, 8),
        ]),
        Workout('Workout 2', [
          Exercise('Deadlift', 120, 6),
          Exercise('Pull-ups', 0, 12),
        ]),
      ]),
      Week(2, [
        Workout('Workout 1', [
          Exercise('Bench Press', 85, 9),
          Exercise('Squats', 105, 7),
        ]),
      ]),
      Week(3, []),
      Week(4, []),
    ],
    2: [
      Week(1, []),
      Week(2, []),
      Week(3, []),
      Week(4, []),
    ],
    3: [
      Week(1, []),
      Week(2, []),
      Week(3, []),
      Week(4, []),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Tracker')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<int>(
              hint: const Text('Select Macrocycle'),
              value: selectedMacrocycle,
              isExpanded: true,
              items: macrocycles.keys
                  .map((macrocycle) => DropdownMenuItem(
                        value: macrocycle,
                        child: Text('Macrocycle $macrocycle'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMacrocycle = value;
                });
              },
            ),
          ),
          if (selectedMacrocycle != null)
            Expanded(
              child: ListView.builder(
                itemCount: macrocycles[selectedMacrocycle!]!.length,
                itemBuilder: (context, index) {
                  return WeekTile(
                      week: macrocycles[selectedMacrocycle!]![index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class Week {
  final int number;
  final List<Workout> workouts;
  Week(this.number, this.workouts);
}

class Workout {
  final String name;
  final List<Exercise> exercises;
  Workout(this.name, this.exercises);
}

class Exercise {
  final String name;
  final int weight;
  final int reps;
  Exercise(this.name, this.weight, this.reps);
}

class WeekTile extends StatefulWidget {
  final Week week;
  const WeekTile({super.key, required this.week});

  @override
  _WeekTileState createState() => _WeekTileState();
}

class _WeekTileState extends State<WeekTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.blue[50], // Light blue for weeks
      child: ExpansionTile(
        title: Text('Week ${widget.week.number}'),
        onExpansionChanged: (expanded) {
          setState(() {
            isExpanded = expanded;
          });
        },
        children: widget.week.workouts
            .map((workout) => WorkoutTile(workout: workout))
            .toList(),
      ),
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
      color: Colors.green[50], // Light green for workouts
      child: ExpansionTile(
        title: Text(widget.workout.name),
        onExpansionChanged: (expanded) {
          setState(() {
            isExpanded = expanded;
          });
        },
        children: widget.workout.exercises
            .map((exercise) => Container(
                  color: Colors.yellow[50], // Light yellow for exercises
                  child: ListTile(
                    title: Text(exercise.name),
                    subtitle: Text(
                        'Weight: ${exercise.weight}kg, Reps: ${exercise.reps}'),
                  ),
                ))
            .toList(),
      ),
    );
  }
}