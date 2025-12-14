#!/usr/bin/env dart
// ignore_for_file: avoid_print
// Script pour analyser et afficher le rapport de coverage lcov.info
//
// Usage:
//   dart run tool/coverage_report.dart [options]
//
// Options:
//   --min=<percent>    Afficher uniquement les fichiers sous ce seuil (ex: --min=80)
//   --sort=<field>     Trier par: name, coverage, lines (default: coverage)
//   --html             Generer un rapport HTML simple
//   --summary          Afficher uniquement le resume

import 'dart:io';

class FileCoverage {
  final String path;
  int linesFound = 0;
  int linesHit = 0;
  final Map<int, int> lineHits = {};

  FileCoverage(this.path);

  double get coverage => linesFound > 0 ? (linesHit / linesFound) * 100 : 0;

  String get shortPath {
    final parts = path.split('/');
    if (parts.length > 3) {
      return '.../${parts.sublist(parts.length - 3).join('/')}';
    }
    return path;
  }
}

class CoverageReport {
  final Map<String, FileCoverage> files = {};

  int get totalLinesFound =>
      files.values.fold(0, (sum, f) => sum + f.linesFound);
  int get totalLinesHit => files.values.fold(0, (sum, f) => sum + f.linesHit);
  double get totalCoverage =>
      totalLinesFound > 0 ? (totalLinesHit / totalLinesFound) * 100 : 0;

  void parse(String content) {
    FileCoverage? current;

    for (final line in content.split('\n')) {
      final trimmed = line.trim();

      if (trimmed.startsWith('SF:')) {
        final path = trimmed.substring(3);
        current = FileCoverage(path);
        files[path] = current;
      } else if (trimmed.startsWith('DA:') && current != null) {
        final parts = trimmed.substring(3).split(',');
        if (parts.length >= 2) {
          final lineNum = int.tryParse(parts[0]) ?? 0;
          final hits = int.tryParse(parts[1]) ?? 0;
          current.lineHits[lineNum] = hits;
        }
      } else if (trimmed.startsWith('LF:') && current != null) {
        current.linesFound = int.tryParse(trimmed.substring(3)) ?? 0;
      } else if (trimmed.startsWith('LH:') && current != null) {
        current.linesHit = int.tryParse(trimmed.substring(3)) ?? 0;
      } else if (trimmed == 'end_of_record') {
        current = null;
      }
    }
  }

  List<FileCoverage> getSortedFiles({
    String sortBy = 'coverage',
    double? minThreshold,
  }) {
    var sorted = files.values.toList();

    if (minThreshold != null) {
      sorted = sorted.where((f) => f.coverage < minThreshold).toList();
    }

    switch (sortBy) {
      case 'name':
        sorted.sort((a, b) => a.path.compareTo(b.path));
        break;
      case 'lines':
        sorted.sort((a, b) => b.linesFound.compareTo(a.linesFound));
        break;
      case 'coverage':
      default:
        sorted.sort((a, b) => a.coverage.compareTo(b.coverage));
    }

    return sorted;
  }
}

String getBar(double percent, int width) {
  final filled = (percent / 100 * width).round();
  final empty = width - filled;
  return '${'█' * filled}${'░' * empty}';
}

String getColor(double percent) {
  if (percent >= 80) return '\x1B[32m'; // Green
  if (percent >= 60) return '\x1B[33m'; // Yellow
  return '\x1B[31m'; // Red
}

const reset = '\x1B[0m';
const bold = '\x1B[1m';
const dim = '\x1B[2m';

void printSummary(CoverageReport report) {
  print('');
  print(
    '$bold╔══════════════════════════════════════════════════════════════╗$reset',
  );
  print(
    '$bold║                    RAPPORT DE COVERAGE                       ║$reset',
  );
  print(
    '$bold╚══════════════════════════════════════════════════════════════╝$reset',
  );
  print('');

  final color = getColor(report.totalCoverage);
  print(
    '  Coverage total: $color${report.totalCoverage.toStringAsFixed(1)}%$reset',
  );
  print(
    '  Lignes couvertes: ${report.totalLinesHit} / ${report.totalLinesFound}',
  );
  print('  Fichiers analyses: ${report.files.length}');
  print('');
  print(
    '  ${getBar(report.totalCoverage, 50)} $color${report.totalCoverage.toStringAsFixed(1)}%$reset',
  );
  print('');
}

void printDetails(
  CoverageReport report, {
  String sortBy = 'coverage',
  double? minThreshold,
}) {
  final files = report.getSortedFiles(
    sortBy: sortBy,
    minThreshold: minThreshold,
  );

  if (files.isEmpty) {
    print('${dim}Aucun fichier ne correspond aux criteres.$reset');
    return;
  }

  print(
    '$bold┌─────────────────────────────────────────────────────────────────────────┐$reset',
  );
  print(
    '$bold│ Fichier                                        │ Coverage │   Lignes  │$reset',
  );
  print(
    '$bold├─────────────────────────────────────────────────────────────────────────┤$reset',
  );

  for (final file in files) {
    final color = getColor(file.coverage);
    final name = file.shortPath.padRight(46).substring(0, 46);
    final cov = '${file.coverage.toStringAsFixed(1)}%'.padLeft(7);
    final lines = '${file.linesHit}/${file.linesFound}'.padLeft(9);

    print('│ $name │ $color$cov$reset │ $lines │');
  }

  print(
    '$bold└─────────────────────────────────────────────────────────────────────────┘$reset',
  );
  print('');
}

void printByFolder(CoverageReport report) {
  final folders = <String, List<FileCoverage>>{};

  for (final file in report.files.values) {
    final parts = file.path.split('/');
    String folder;
    if (parts.length >= 3) {
      folder = parts.sublist(0, 3).join('/');
    } else {
      folder = parts.first;
    }
    folders.putIfAbsent(folder, () => []).add(file);
  }

  print('$bold═══ Coverage par dossier ═══$reset');
  print('');

  final sortedFolders = folders.entries.toList()
    ..sort((a, b) {
      final covA =
          a.value.fold<int>(0, (s, f) => s + f.linesHit) /
          a.value.fold<int>(0, (s, f) => s + f.linesFound) *
          100;
      final covB =
          b.value.fold<int>(0, (s, f) => s + f.linesHit) /
          b.value.fold<int>(0, (s, f) => s + f.linesFound) *
          100;
      return covA.compareTo(covB);
    });

  for (final entry in sortedFolders) {
    final linesFound = entry.value.fold<int>(0, (s, f) => s + f.linesFound);
    final linesHit = entry.value.fold<int>(0, (s, f) => s + f.linesHit);
    final coverage = linesFound > 0 ? (linesHit / linesFound) * 100 : 0.0;
    final color = getColor(coverage);

    print(
      '  ${entry.key.padRight(40)} $color${coverage.toStringAsFixed(1).padLeft(5)}%$reset  ${getBar(coverage, 20)}',
    );
  }
  print('');
}

void generateHtml(CoverageReport report, String outputPath) {
  final buffer = StringBuffer();

  buffer.writeln('''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Coverage Report - IAckathon</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0; padding: 20px; background: #1a1a2e; color: #eee;
    }
    h1 { color: #00d9ff; margin-bottom: 10px; }
    .summary {
      background: #16213e; padding: 20px; border-radius: 8px;
      margin-bottom: 20px; display: flex; gap: 40px; align-items: center;
    }
    .summary-item { text-align: center; }
    .summary-value { font-size: 2em; font-weight: bold; }
    .summary-label { color: #888; font-size: 0.9em; }
    .progress {
      width: 200px; height: 20px; background: #333; border-radius: 10px;
      overflow: hidden;
    }
    .progress-bar { height: 100%; transition: width 0.3s; }
    .green { background: linear-gradient(90deg, #00b894, #00cec9); }
    .yellow { background: linear-gradient(90deg, #fdcb6e, #e17055); }
    .red { background: linear-gradient(90deg, #e74c3c, #c0392b); }
    table { width: 100%; border-collapse: collapse; background: #16213e; border-radius: 8px; overflow: hidden; }
    th { background: #0f3460; padding: 12px; text-align: left; color: #00d9ff; }
    td { padding: 10px 12px; border-bottom: 1px solid #333; }
    tr:hover { background: #1f4068; }
    .file-path { font-family: 'Fira Code', monospace; font-size: 0.9em; }
    .coverage-cell { width: 120px; }
    .mini-bar { width: 60px; height: 8px; background: #333; border-radius: 4px; display: inline-block; overflow: hidden; vertical-align: middle; margin-right: 8px; }
    .mini-bar-fill { height: 100%; }
  </style>
</head>
<body>
  <h1>📊 Coverage Report</h1>
  <p style="color: #888;">IAckathon - ${DateTime.now().toString().split('.').first}</p>

  <div class="summary">
    <div class="summary-item">
      <div class="summary-value" style="color: ${report.totalCoverage >= 80
      ? '#00cec9'
      : report.totalCoverage >= 60
      ? '#fdcb6e'
      : '#e74c3c'}">
        ${report.totalCoverage.toStringAsFixed(1)}%
      </div>
      <div class="summary-label">Coverage Total</div>
    </div>
    <div class="summary-item">
      <div class="progress">
        <div class="progress-bar ${report.totalCoverage >= 80
      ? 'green'
      : report.totalCoverage >= 60
      ? 'yellow'
      : 'red'}"
             style="width: ${report.totalCoverage}%"></div>
      </div>
    </div>
    <div class="summary-item">
      <div class="summary-value">${report.totalLinesHit}</div>
      <div class="summary-label">Lignes couvertes</div>
    </div>
    <div class="summary-item">
      <div class="summary-value">${report.totalLinesFound}</div>
      <div class="summary-label">Lignes totales</div>
    </div>
    <div class="summary-item">
      <div class="summary-value">${report.files.length}</div>
      <div class="summary-label">Fichiers</div>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Fichier</th>
        <th class="coverage-cell">Coverage</th>
        <th>Lignes</th>
      </tr>
    </thead>
    <tbody>
''');

  final sortedFiles = report.getSortedFiles(sortBy: 'coverage');
  for (final file in sortedFiles) {
    final colorClass = file.coverage >= 80
        ? 'green'
        : file.coverage >= 60
        ? 'yellow'
        : 'red';
    buffer.writeln('''
      <tr>
        <td class="file-path">${file.shortPath}</td>
        <td class="coverage-cell">
          <span class="mini-bar"><span class="mini-bar-fill $colorClass" style="width: ${file.coverage}%"></span></span>
          ${file.coverage.toStringAsFixed(1)}%
        </td>
        <td>${file.linesHit} / ${file.linesFound}</td>
      </tr>
''');
  }

  buffer.writeln('''
    </tbody>
  </table>
</body>
</html>
''');

  File(outputPath).writeAsStringSync(buffer.toString());
  print('✓ Rapport HTML genere: $outputPath');
}

void main(List<String> args) {
  final lcovPath = 'coverage/lcov.info';

  if (!File(lcovPath).existsSync()) {
    print('❌ Fichier $lcovPath non trouve.');
    print('   Lancez d\'abord: flutter test --coverage');
    exit(1);
  }

  // Parse arguments
  double? minThreshold;
  String sortBy = 'coverage';
  bool summaryOnly = false;
  bool generateHtmlReport = false;

  for (final arg in args) {
    if (arg.startsWith('--min=')) {
      minThreshold = double.tryParse(arg.substring(6));
    } else if (arg.startsWith('--sort=')) {
      sortBy = arg.substring(7);
    } else if (arg == '--summary') {
      summaryOnly = true;
    } else if (arg == '--html') {
      generateHtmlReport = true;
    } else if (arg == '--help' || arg == '-h') {
      print('''
Coverage Report - Analyse le fichier lcov.info

Usage: dart run tool/coverage_report.dart [options]

Options:
  --min=<percent>    Afficher uniquement les fichiers sous ce seuil
  --sort=<field>     Trier par: name, coverage, lines (default: coverage)
  --summary          Afficher uniquement le resume
  --html             Generer un rapport HTML (coverage/report.html)
  --help, -h         Afficher cette aide

Exemples:
  dart run tool/coverage_report.dart
  dart run tool/coverage_report.dart --min=80
  dart run tool/coverage_report.dart --sort=name --html
''');
      exit(0);
    }
  }

  final content = File(lcovPath).readAsStringSync();
  final report = CoverageReport()..parse(content);

  printSummary(report);

  if (!summaryOnly) {
    printByFolder(report);
    printDetails(report, sortBy: sortBy, minThreshold: minThreshold);
  }

  if (generateHtmlReport) {
    generateHtml(report, 'coverage/report.html');
  }
}
