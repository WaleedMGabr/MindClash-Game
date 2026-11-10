import 'package:mindclash/features/game/domain/entities/round_entity.dart';

class RoundModel extends RoundEntity {
  const RoundModel({
    super.roundIndex = 0,
    super.question = '',
    required super.trapperId,
    required super.answererId,
    required super.roundStatus,
    required super.currentChoices,
    required super.playerAnswer,
    required super.correctAnswer,
    required super.phaseDeadline,
    super.awardedTo,
    super.isTrapperTimedOut = false,
  });

  factory RoundModel.fromMap(Map<dynamic, dynamic> map) {
    final rawChoices = map['currentChoices'];
    final List<Map<String, Trapper>> parsedChoices = [];

    if (rawChoices is List) {
      for (final item in rawChoices) {
        if (item is Map) {
          // Check for safe format: {'text': '...', 'type': '...'}
          if (item.containsKey('text') && item.containsKey('type')) {
            final text = item['text']?.toString() ?? '';
            final typeStr = item['type']?.toString();
            final trapper = Trapper.values.firstWhere(
              (t) => t.name == typeStr,
              orElse: () => Trapper.system,
            );
            parsedChoices.add({text: trapper});
          } else {
            // Legacy fallback: { 'choiceText': 'type' }
            final Map<String, Trapper> choiceMap = {};
            item.forEach((key, value) {
              final trapper = Trapper.values.firstWhere(
                (t) => t.name == value?.toString(),
                orElse: () => Trapper.system,
              );
              choiceMap[key.toString()] = trapper;
            });
            parsedChoices.add(choiceMap);
          }
        }
      }
    }

    return RoundModel(
      roundIndex: (map['roundIndex'] as num?)?.toInt() ?? 0,
      question: map['question'] as String? ?? '',
      trapperId: map['trapperId'] as String? ?? '',
      answererId: map['answererId'] as String? ?? '',
      roundStatus: RoundStatus.values.firstWhere(
        (status) => status.name == map['roundStatus'],
        orElse: () => RoundStatus.settingTrapper,
      ),
      currentChoices: parsedChoices,
      playerAnswer: map['playerAnswer'] as String? ?? '',
      correctAnswer: map['correctAnswer'] as String? ?? '',
      phaseDeadline: (map['phaseDeadline'] as num?)?.toInt() ?? 0,
      awardedTo: map['awardedTo'] as String?,
      isTrapperTimedOut: map['isTrapperTimedOut'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roundIndex': roundIndex,
      'question': question,
      'trapperId': trapperId,
      'answererId': answererId,
      'roundStatus': roundStatus.name,
      'currentChoices': currentChoices.map((map) {
        final text = map.keys.isNotEmpty ? map.keys.first : '';
        final type = map.values.isNotEmpty ? map.values.first.name : Trapper.system.name;
        return {
          'text': text,
          'type': type,
        };
      }).toList(),
      'playerAnswer': playerAnswer,
      'correctAnswer': correctAnswer,
      'phaseDeadline': phaseDeadline,
      'awardedTo': awardedTo,
      'isTrapperTimedOut': isTrapperTimedOut,
    };
  }
}