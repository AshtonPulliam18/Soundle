import 'package:flutter/material.dart';
import 'package:heardle/song.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class LoseScreen extends StatelessWidget {
  final Song song;

  const LoseScreen({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCADEBC),
      appBar: AppBar(
        title: const Text(
          'LOSER!',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF4E6E58),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('WRONG! THE ANSWER WAS. . .'),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    song.name,
                    style: const TextStyle(fontSize: 36.0),
                  ),
                  Text(
                    'By ${song.author}',
                    style: const TextStyle(fontSize: 24.0),
                  ),
                ],
              ),
            ),
            Material(
              color: const Color(0xFFF6F4D2),
              child: InkWell(
                onTap: () async {
                  await SpotifySdk.pause();

                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF4E6E58), width: 4.0),
                  ),
                  child: const Text(
                    "RESTART",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
