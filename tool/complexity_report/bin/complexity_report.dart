import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

const Map<String, List<String>> _approachFiles = {
  'bloc': [
    'modules/task/lib/module/presentation/bloc/task_bloc.dart',
    'modules/task/lib/module/presentation/bloc/task_event.dart',
    'modules/task/lib/module/presentation/bloc/task_state.dart',
    'modules/task/lib/module/presentation/views/bloc_home_view.dart',
  ],
  'provider': [
    'modules/task/lib/module/presentation/provider/provider_task_notifier.dart',
    'modules/task/lib/module/presentation/views/provider_home_view.dart',
  ],
  'riverpod': [
    'modules/task/lib/module/presentation/riverpod/riverpod_task_notifier.dart',
    'modules/task/lib/module/presentation/riverpod/providers.dart',
    'modules/task/lib/module/presentation/views/riverpod_home_view.dart',
  ],
  'getx': [
    'modules/task/lib/module/presentation/getx/task_controller.dart',
    'modules/task/lib/module/presentation/getx/task_binding.dart',
    'modules/task/lib/module/presentation/views/getx_home_view.dart',
  ],
};

class MethodMetrics {
  final String label;
  final String file;
  final int complexity;
  final int startLine;
  final int endLine;

  MethodMetrics({
    required this.label,
    required this.file,
    required this.complexity,
    required this.startLine,
    required this.endLine,
  });

  int get loc => endLine - startLine + 1;
}

class _DecisionPointVisitor extends RecursiveAstVisitor<void> {
  int decisions = 0;

  @override
  void visitIfStatement(IfStatement node) {
    decisions++;
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    decisions++;
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    decisions++;
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    decisions++;
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    decisions++;
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    decisions++;
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    decisions++;
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    decisions++;
    super.visitCatchClause(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    decisions++;
    super.visitConditionalExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (operator == '&&' || operator == '||') {
      decisions++;
    }
    super.visitBinaryExpression(node);
  }
}

class _DeclarationFinder extends RecursiveAstVisitor<void> {
  final List<AstNode> declarations = [];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.body is! EmptyFunctionBody) {
      declarations.add(node);
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    declarations.add(node);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.functionExpression.body is! EmptyFunctionBody) {
      declarations.add(node);
    }
    super.visitFunctionDeclaration(node);
  }
}

String _labelFor(AstNode node) {
  if (node is MethodDeclaration) {
    final prefix = node.isGetter
        ? 'get '
        : node.isSetter
        ? 'set '
        : '';
    return '$prefix${node.name.lexeme}';
  }
  if (node is ConstructorDeclaration) {
    final ctorName = node.name?.lexeme;
    return ctorName == null ? 'constructor' : 'constructor.$ctorName';
  }
  if (node is FunctionDeclaration) {
    return node.name.lexeme;
  }
  return node.runtimeType.toString();
}

int _startLine(LineInfo lineInfo, AstNode node) => lineInfo.getLocation(node.offset).lineNumber;

int _endLine(LineInfo lineInfo, AstNode node) => lineInfo.getLocation(node.end).lineNumber;

List<MethodMetrics> _analyzeFile(String path) {
  final content = File(path).readAsStringSync();
  final result = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
    featureSet: FeatureSet.latestLanguageVersion(),
  );
  final unit = result.unit;
  final lineInfo = result.lineInfo;

  final finder = _DeclarationFinder();
  unit.accept(finder);

  final metrics = <MethodMetrics>[];
  for (final node in finder.declarations) {
    final visitor = _DecisionPointVisitor();
    node.accept(visitor);

    metrics.add(
      MethodMetrics(
        label: _labelFor(node),
        file: p.basename(path),
        complexity: 1 + visitor.decisions,
        startLine: _startLine(lineInfo, node),
        endLine: _endLine(lineInfo, node),
      ),
    );
  }
  return metrics;
}

int _countClasses(String path) {
  final content = File(path).readAsStringSync();
  final result = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
    featureSet: FeatureSet.latestLanguageVersion(),
  );
  var count = 0;
  for (final declaration in result.unit.declarations) {
    if (declaration is ClassDeclaration) count++;
  }
  return count;
}

void _printApproach(String repoRoot, String approach, List<String> relativeFiles) {
  final methods = <MethodMetrics>[];
  var totalFileLoc = 0;
  var classCount = 0;
  var missing = 0;

  for (final relativePath in relativeFiles) {
    final path = p.join(repoRoot, relativePath);
    final file = File(path);
    if (!file.existsSync()) {
      missing++;
      continue;
    }
    totalFileLoc += file.readAsLinesSync().length;
    classCount += _countClasses(path);
    methods.addAll(_analyzeFile(path));
  }

  print('');
  print('=' * 70);
  print('  ${approach.toUpperCase()}');
  print('=' * 70);

  if (missing > 0) {
    print('  ⚠ $missing file(s) not found — run this from the repository root.');
  }

  print('  Files analyzed      : ${relativeFiles.length - missing}');
  print('  Classes             : $classCount');
  print('  Total LOC (file)    : $totalFileLoc');

  if (methods.isEmpty) {
    print('  No method/constructor with a body found.');
    return;
  }

  final totalComplexity = methods.fold<int>(0, (sum, m) => sum + m.complexity);
  final totalMethodLoc = methods.fold<int>(0, (sum, m) => sum + m.loc);
  final avgComplexity = totalComplexity / methods.length;
  final avgLoc = totalMethodLoc / methods.length;
  final worst = methods.reduce((a, b) => a.complexity >= b.complexity ? a : b);

  print('  Methods/constructors: ${methods.length}');
  print('  Total complexity    : $totalComplexity');
  print('  Average complexity  : ${avgComplexity.toStringAsFixed(2)} / method');
  print('  Average LOC / method: ${avgLoc.toStringAsFixed(2)}');
  print(
    '  Worst method        : ${worst.label} (${worst.file}:${worst.startLine}) '
    '— complexity ${worst.complexity}, ${worst.loc} LOC',
  );

  final sorted = [...methods]..sort((a, b) => b.complexity.compareTo(a.complexity));
  final top = sorted.take(5);
  print('  Top 5 by complexity:');
  for (final m in top) {
    print('    ${m.complexity.toString().padLeft(2)}  ${m.label} (${m.file}:${m.startLine})');
  }
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bin/complexity_report.dart <path to the tcc repository root>');
    stderr.writeln('Example (running from tool/complexity_report): dart run bin/complexity_report.dart ../..');
    exit(64);
  }

  final repoRoot = p.normalize(p.absolute(args.first));
  if (!Directory(p.join(repoRoot, 'modules', 'task')).existsSync()) {
    stderr.writeln('Could not find modules/task under "$repoRoot" — check the path you passed.');
    exit(66);
  }

  print('Cyclomatic complexity report (McCabe) — TCC');
  print('Repository root: $repoRoot');

  for (final entry in _approachFiles.entries) {
    _printApproach(repoRoot, entry.key, entry.value);
  }

  print('');
  print('=' * 70);
  print('  END OF REPORT');
  print('=' * 70);
}
