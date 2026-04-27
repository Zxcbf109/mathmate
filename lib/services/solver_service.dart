import 'package:mathmate/models/pipeline_models.dart';
import 'package:mathmate/services/deepseek_service.dart';
import 'package:mathmate/services/prompts/solve_prompt.dart';

class SolverService {
  final DeepSeekService _client;

  SolverService({DeepSeekService? client})
    : _client = client ?? DeepSeekService();

  Future<SolveResult> solveQuestionMarkdown(String questionMarkdown) async {
    final String raw = await _client.callTextPrompt(
      prompt: solvePrompt,
      userText: questionMarkdown,
    );

    return SolveResult(
      solutionMarkdown: raw.trim(),
      rawOutput: raw,
    );
  }
}
