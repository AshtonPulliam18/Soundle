import 'package:heardle/song.dart';

class Guess {
  late bool isSkipped;
  late Song guess;

  static Guess skipped() => Guess(true, Song('', '', "", ''));

  static Guess guessed(Song guess) => Guess(false, guess);

  String stringifySongName() {
    return isSkipped ? 'SKIPPED' : guess.name.toUpperCase();
  }

  String stringifySongAuthor() {
    return isSkipped ? '' : guess.author.toUpperCase();
  }

  Guess(this.isSkipped, this.guess);
}
