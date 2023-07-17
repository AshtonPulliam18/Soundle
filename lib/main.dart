import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heardle/lose_screen.dart';
import 'package:heardle/progress.dart';
import 'package:heardle/song.dart';
import 'package:heardle/win_screen.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'dart:convert';
import 'dart:math';
import 'guess.dart';
import 'dart:io';
import 'dart:html' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heardle',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.nunito().fontFamily),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ProgressBarController progressBarController = ProgressBarController();
  final TextEditingController textFieldController = TextEditingController();

  bool _hasStarted = false;
  bool _choosingSong = false;
  bool _isPlaying = false;
  String token = "";
  final List<Guess> _guesses = [];

  late Song chosenSong;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    textFieldController.dispose();

    super.dispose();
  }

  void chooseSong() async {
    setState(() {
      _choosingSong = true;
    });

    token = await requestAccessToken();

    chosenSong = await getRandomSongFromSpotifyAPI(token);

    playSongSnippet();

    setState(() {
      _hasStarted = true;
      _choosingSong = false;
    });
  }


  Future<String> requestAccessToken() async {
    const clientId = '33cf867fdd2e400699512d46c5a1166b'; // 33cf867fdd2e400699512d46c5a1166b || 1ee102c11b7c46f580950c2ea107c677
    const clientSecret = '088e8b416dc04e978bff4b45e57283bb'; // 088e8b416dc04e978bff4b45e57283bb || 3a3fa28818654999aca6a5b1924668ac

    String accessToken;
    if (!kIsWeb) {
      accessToken = await SpotifySdk.getAccessToken(
          clientId: clientId,
          redirectUrl: 'flutterspotify://heardle.com',
          scope:
          'user-read-private user-read-email streaming user-read-playback-state user-modify-playback-state user-read-currently-playing user-library-read user-library-modify playlist-read-private playlist-modify-public playlist-modify-private user-top-read user-read-recently-played user-follow-read user-follow-modify');
    }
    else {
      accessToken = "";
      authenticateSpotifyWeb();
    }
    return accessToken;
  }



  void authenticateSpotifyWeb(String clientId) {
    // Set your Spotify app credentials
    final redirectUri = 'https://ashtonp18.github.io/musicle/callback';

    // Define the Spotify API endpoint for authorization
    final authEndpoint = 'https://accounts.spotify.com/authorize';

    // Set the required scopes for the API access
    final scopes = ['user-read-private', 'user-read-email'];

    // Generate the URL for Spotify authorization
    final authUrl = '$authEndpoint?client_id=$clientId&redirect_uri=${Uri.encodeComponent(redirectUri)}&scope=${Uri.encodeComponent(scopes.join(' '))}&response_type=token';

    // Open the Spotify authorization page in a new window
    html.window.open(authUrl, 'Spotify Authorization', 'width=500,height=800');
  }

  Future<Song> getRandomSongFromSpotifyAPI(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/browse/categories'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final categories = jsonData['categories']['items'];

      final random = Random();
      final randomIndex = random.nextInt(categories.length);
      final randomCategory = categories[randomIndex];

      final categoryId = randomCategory['id'];

      final playlistsResponse = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/browse/categories/$categoryId/playlists'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (playlistsResponse.statusCode == 200) {
        final playlistsData = json.decode(playlistsResponse.body);
        final playlists = playlistsData['playlists']['items'];

        final randomPlaylistIndex = random.nextInt(playlists.length);
        final randomPlaylist = playlists[randomPlaylistIndex];

        final playlistId = randomPlaylist['id'];

        final playlistTracksResponse = await http.get(
          Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (playlistTracksResponse.statusCode == 200) {
          final playlistTracksData = json.decode(playlistTracksResponse.body);
          final tracks = playlistTracksData['items'];

          final randomTrackIndex = random.nextInt(tracks.length);
          final randomTrackData = tracks[randomTrackIndex]['track'];

          final song = Song(
            randomTrackData['name'],
            randomTrackData['artists'][0]['name'],
            randomTrackData['id'],
            randomTrackData['uri'],
          );

          return song;
        } else {
          throw Exception('Failed to fetch tracks from the Spotify API');
        }
      } else {
        throw Exception('Failed to fetch playlists from the Spotify API');
      }
    } else {
      throw Exception('Failed to fetch categories from the Spotify API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCADEBC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4D2),
                  border:
                      Border.all(color: const Color(0xFF4E6E58), width: 4.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [for (var i = 0; i < 5; i++) rowElement(i)],
                ),
              ),
              ProgressBar(
                controller: progressBarController,
              ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  margin: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF4E6E58), width: 4.0),
                  ),
                  child: AbsorbPointer(
                      absorbing: !_hasStarted || _isPlaying,
                      child: TypeAheadField(
                        direction: AxisDirection.up,
                        loadingBuilder: (context) =>
                            const CircularProgressIndicator(),
                        minCharsForSuggestions: 3,
                        textFieldConfiguration: TextFieldConfiguration(
                            controller: textFieldController,
                            autofocus: false,
                            decoration:
                                const InputDecoration(hintText: 'GOT IT YET?')),
                        suggestionsCallback: (pattern) async {
                          // TODO RETURN A LIST OF SONGS FOR THE SEARCHED `PATTERN`
                          final suggestions = await http.get(
                            Uri.parse(
                                'https://api.spotify.com/v1/search?q=${textFieldController.text}&type=track&limit=5'),
                            headers: {
                              'Authorization': 'Bearer $token',
                            },
                          );
                          List<Song> songsReturned = [];
                          if (suggestions.statusCode == 200) {
                            final suggestionData =
                                json.decode(suggestions.body);
                            for (var i = 0;
                                i < suggestionData['tracks']['items'].length;
                                i++) {
                              songsReturned.add(Song(
                                suggestionData['tracks']['items'][i]['name'],
                                suggestionData['tracks']['items'][i]['artists']
                                    [0]['name'],
                                suggestionData['tracks']['items'][i]['id'],
                                "",
                              ));
                            }
                          }
                          return songsReturned;
                        },
                        itemBuilder: (BuildContext context, Song song) {
                          return ListTile(
                            title: Text(song.name.toUpperCase()),
                            subtitle: Text(song.author.toUpperCase()),
                          );
                        },
                        onSuggestionSelected: (Song suggestion) {
                          addGuess(suggestion);
                          textFieldController.clear();
                        },
                      ))),
              Container(
                  margin: const EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: const Color(0xFFF6F4D2),
                        child: InkWell(
                          onTap: _hasStarted ? null : () => chooseSong(),
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFF4E6E58), width: 4.0),
                            ),
                            child: _choosingSong
                                ? const SizedBox(
                                    width: 16.0,
                                    height: 16.0,
                                    child: Center(
                                        child: CircularProgressIndicator()))
                                : Text(
                                    "START",
                                    style: TextStyle(
                                        color: _hasStarted
                                            ? Colors.grey
                                            : Colors.black),
                                  ),
                          ),
                        ),
                      ),
                      Material(
                        color: const Color(0xFFF6F4D2),
                        child: InkWell(
                          onTap: () => !_hasStarted
                              ? null
                              : setState(() {
                                  addGuess(null);
                                }),
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFF4E6E58), width: 4.0),
                            ),
                            child: Text(
                              "SKIP",
                              style: TextStyle(
                                  color:
                                      _hasStarted ? Colors.black : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Widget rowElement(int index) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AbsorbPointer(
              child: Checkbox(value: boolify(index), onChanged: (value) {})),
          if (index < _guesses.length)
            if (_guesses[index].isSkipped)
              const Text('SKIPPED')
            else
              Expanded(
                  child: ListTile(
                title: Text(_guesses[index].guess.name),
                subtitle: Text(_guesses[index].guess.author),
                contentPadding: EdgeInsets.zero,
              ))
        ],
      ),
    );
  }

  bool boolify(int index) {
    return index < _guesses.length;
  }

  void playSongSnippet() async {
    final songUri = chosenSong.uri;
    var duration = progressBarController.next();

    setState(() {
      _isPlaying = true;
    });

    if (!kIsWeb) {
      if (_hasStarted) {
        await SpotifySdk.resume();
      } else {
        await SpotifySdk.play(spotifyUri: chosenSong.uri);
      }
    } else {
      final response = await http.put(
        Uri.parse('https://api.spotify.com/v1/me/player/play'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: '{"uris": ["$songUri"]}',
      );

      if (response.statusCode == 204) {
        print('Track playback started successfully');
      } else {
        print('Failed to start track playback: ${response.statusCode}');
      }
    }

    await Future.delayed(duration);

    setState(() {
      _isPlaying = false;
    });

    kIsWeb
        ? await http.put(
            Uri.parse('https://api.spotify.com/v1/me/player/pause'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
        : SpotifySdk.pause();
  }

  void addGuess(Song? suggestion) async {
    if (_isPlaying) return;

    setState(() {
      if (suggestion == null) {
        _guesses.add(Guess.skipped());
      } else {
        _guesses.add(Guess.guessed(suggestion));
      }
    });

    if (suggestion != null && suggestion.id == chosenSong.id) {
      await SpotifySdk.resume();

      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (context) => WinScreen(song: chosenSong)))
          .then((value) => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MyApp())));
    } else if (_guesses.length >= 5) {
      await SpotifySdk.resume();

      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (context) => LoseScreen(song: chosenSong)))
          .then((value) => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MyApp())));
    } else {
      playSongSnippet();
    }
  }
}
