class ProfanityFilter {
  static final List<String> _badWords = [
    // Indonesian
    'anjing', 'anjay', 'asu', 'bangsat', 'babi', 'bajingan', 'brengsek', 
    'monyet', 'tolol', 'goblog', 'goblok', 'kontol', 'memek', 'jembut', 
    'peler', 'tapir', 'kunyuk', 'kampret', 'dancok', 'jancok', 'jancuk', 
    'kirik', 'pepek', 'itil', 'bego', 'idiot', 'pecun', 'lonte', 'jablay', 
    'mampus', 'sialan', 'perek', 'sarap', 'bejat',
    
    // English
    'shit', 'fuck', 'ass', 'bitch', 'damn', 'bastard', 'dick', 'pussy', 
    'cunt', 'suck', 'wanker', 'motherfucker', 'stfu', 'stupid',
    'asshole', 'bullshit', 'cock', 'faggot', 'whore'
  ];

  /// Checks the given text for profanity.
  /// Returns a list of detected bad words.
  static List<String> check(String text) {
    if (text.isEmpty) return [];
    
    List<String> detected = [];
    String lowerText = text.toLowerCase();
    
    for (String word in _badWords) {
      // Use word boundaries to avoid catching substrings of innocent words
      // e.g., 'ass' in 'assets' or 'anjing' in 'keranjingan'
      final RegExp regex = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
      if (regex.hasMatch(lowerText)) {
        detected.add(word);
      }
    }
    
    return detected;
  }
}

