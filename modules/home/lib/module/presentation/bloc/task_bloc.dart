import 'package:common/main.dart';
import 'package:dependencies/bloc.dart';

import '../../../main.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasks getTasks;
  final AddTask addTask;
  final DeleteTask deleteTask;

  TaskBloc({required this.getTasks, required this.addTask, required this.deleteTask}) : super(TaskInitial()) {
    on<LoadTasksWithCount>(_onLoadTasksWithCount);
    on<AddTaskEvent>(_onAddTask);
    on<DeleteTaskEvent>(_onDeleteTask);
  }

  Future<void> loadTasksWithCount(int count) async {
    add(LoadTasksWithCount(count));
  }

  Future<void> _onLoadTasksWithCount(LoadTasksWithCount event, Emitter<TaskState> emit) async {
    final tracker = PerformanceTracker();

    emit(TaskLoading());

    final memBefore = tracker.getCurrentMemoryMB();

    final dbStopwatch = Stopwatch()..start();
    final result = await getTasks(GetTasksParams(event.count));
    dbStopwatch.stop();
    tracker.recordOperationMicros('db_load_${event.count}_tasks', dbStopwatch.elapsedMicroseconds);

    final blocStopwatch = Stopwatch()..start();
    result.fold((failure) => emit(TaskError(failure.message)), (tasks) => emit(TaskLoaded(tasks)));
    blocStopwatch.stop();
    tracker.recordOperationMicros('bloc_load_${event.count}_tasks', blocStopwatch.elapsedMicroseconds);

    final memAfter = tracker.getCurrentMemoryMB();
    tracker.recordMemoryDelta('memory_delta_${event.count}_tasks', memBefore, memAfter);

    tracker.printSummary();
  }

  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    await addTask(AddTaskParams(event.task));
    add(LoadTasksWithCount(0));
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    await deleteTask(DeleteTaskParams(event.id));
    add(LoadTasksWithCount(0));
  }
}
