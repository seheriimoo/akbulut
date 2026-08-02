class ThemePromptBuilder {
  static String buildRelationshipPrompt(String theme) {
    switch (theme) {
      case 'noReturn':
        return '''
The user still thinks about this person.

However, they already know they do not want the relationship back.

Observe.
Narrow.
Release.

Keep the response warm, gentle and brief.
''';

      case 'futureLost':
        return '''
The user is grieving the future they imagined with this person.

Observe.
Narrow.
Release.

Keep the response warm, gentle and brief.
''';

      default:
        return '''
Relationship concern.

Observe.
Narrow.
Release.

Keep the response warm, gentle and brief.
''';
    }
  }
}
