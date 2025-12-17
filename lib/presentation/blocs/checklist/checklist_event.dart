import 'package:equatable/equatable.dart';

import '../../../domain/entities/checklist_section.dart';

abstract class ChecklistEvent extends Equatable {
  const ChecklistEvent();

  @override
  List<Object?> get props => [];
}

/// Initialise le service checklist (charge depuis asset)
class ChecklistInitialize extends ChecklistEvent {
  const ChecklistInitialize();
}

/// Detecte une section depuis l'input utilisateur
class ChecklistDetectSection extends ChecklistEvent {
  final String userInput;

  const ChecklistDetectSection(this.userInput);

  @override
  List<Object?> get props => [userInput];
}

/// Demarre une session pour une section
class ChecklistStartSession extends ChecklistEvent {
  final ChecklistSection section;

  const ChecklistStartSession(this.section);

  @override
  List<Object?> get props => [section];
}

/// Traite une reponse de l'utilisateur
class ChecklistProcessAnswer extends ChecklistEvent {
  final String userInput;

  const ChecklistProcessAnswer(this.userInput);

  @override
  List<Object?> get props => [userInput];
}

/// Affiche les questions restantes
class ChecklistShowRemaining extends ChecklistEvent {
  const ChecklistShowRemaining();
}

/// Genere le rapport JSON
class ChecklistGenerateReport extends ChecklistEvent {
  const ChecklistGenerateReport();
}

/// Termine la session courante
class ChecklistEndSession extends ChecklistEvent {
  const ChecklistEndSession();
}

/// Passe a la question suivante sans repondre
class ChecklistNextQuestion extends ChecklistEvent {
  const ChecklistNextQuestion();
}

/// Saute la question courante
class ChecklistSkipQuestion extends ChecklistEvent {
  const ChecklistSkipQuestion();
}

/// Efface la reponse LLM affichee
class ChecklistClearResponse extends ChecklistEvent {
  const ChecklistClearResponse();
}
