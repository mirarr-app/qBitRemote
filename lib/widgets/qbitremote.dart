import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qBitRemote/functions/addtorrent.dart';
import 'package:qBitRemote/widgets/login.dart';
import 'package:qbittorrent_api/qbittorrent_api.dart';
import 'dart:io';

class QBitRemote extends StatefulWidget {
  const QBitRemote({super.key});

  @override
  _QBitRemoteState createState() => _QBitRemoteState();
}

class _QBitRemoteState extends State<QBitRemote> {
  late QBittorrentApiV2 qbittorrent;
  List<TorrentInfo> torrents = [];
  List<TorrentInfo> filteredTorrents = [];
  String? baseUrl;
  String? username;
  String? password;
  bool isUserLoggedIn = false;
  String? magnetUrl;
  List<String> categories = [];
  List<String> tags = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  TorrentSort currentSortMethod = TorrentSort.completed;
  String? selectedCategory;
  String? selectedTag;
  Set<String> selectedTorrents = {};
  @override
  void initState() {
    super.initState();
    _initHive();
    searchController.addListener(_filterTorrents);
  }

  void _toggleSelection(String hash) {
    setState(() {
      if (selectedTorrents.contains(hash)) {
        selectedTorrents.remove(hash);
      } else {
        selectedTorrents.add(hash);
      }
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_filterTorrents);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoriesAndTags() async {
    try {
      final fetchedCategories = await qbittorrent.torrents.getCategories();
      final fetchedTags = await qbittorrent.torrents.getTags();
      setState(() {
        categories = fetchedCategories.keys.toList();
        tags = fetchedTags;
      });
      _fetchSortedTorrents(); // Refresh the torrent list after fetching categories and tags
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching categories and tags: $e');
      }
    }
  }

  String roundUpToHundredth(double number) {
    return ((number * 100).ceil() / 100.0).toStringAsFixed(2);
  }

  String _getTorrentStateString(TorrentState? state) {
    switch (state) {
      case TorrentState.stalledUP:
        return 'Seeding (Stalled)';
      case TorrentState.stalledDL:
        return 'Downloading (Stalled)';
      case TorrentState.uploading:
        return 'Seeding';
      case TorrentState.downloading:
        return 'Downloading';
      case TorrentState.pausedUP:
        return 'Paused (Seeding)';
      case TorrentState.pausedDL:
        return 'Paused (Downloading)';
      case TorrentState.queuedUP:
        return 'Queued for Seeding';
      case TorrentState.queuedDL:
        return 'Queued for Download';
      case TorrentState.checkingUP:
        return 'Checking (Seeding)';
      case TorrentState.checkingDL:
        return 'Checking (Downloading)';
      case TorrentState.checkingResumeData:
        return 'Checking Resume Data';
      case TorrentState.moving:
        return 'Moving';
      case TorrentState.unknown:
        return 'Unknown';
      case TorrentState.missingFiles:
        return 'Missing Files';
      case TorrentState.forcedUP:
        return 'Forced Seeding';
      case TorrentState.forcedDL:
        return 'Forced Downloading';
      default:
        return 'Unknown';
    }
  }

  Color _getProgressColor(TorrentState? state) {
    switch (state) {
      case TorrentState.uploading:
      case TorrentState.forcedUP:
      case TorrentState.stalledUP:
        return Colors.grey; // Seeding
      case TorrentState.downloading:
      case TorrentState.forcedDL:
      case TorrentState.stalledDL:
        return Colors.orange; // Downloading
      case TorrentState.pausedUP:
      case TorrentState.pausedDL:
        return Colors.deepOrange; // Paused
      default:
        return Colors.grey; // Other states
    }
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    var box = await Hive.openBox('serverBox');
    setState(() {
      baseUrl = box.get('baseUrl');
      username = box.get('username');
      password = box.get('password');
    });
    if (baseUrl != null && username != null && password != null) {
      await _initClient();
    } else {
      _showLoginDialog();
    }
  }

  Future<void> _initClient() async {
    if (baseUrl != null && username != null && password != null) {
      final directory = await getApplicationDocumentsDirectory();
      final cookiePath = directory.path;

      qbittorrent = QBittorrentApiV2(
        baseUrl: baseUrl!,
        cookiePath: cookiePath,
        logger: true,
      );
      await _login();
    }
  }

  Future<void> _login() async {
    try {
      await qbittorrent.auth.login(username: username!, password: password!);
      isUserLoggedIn = true;
      _subscribeToMainData();
      // Fetch categories and tags in the background
      _fetchCategoriesAndTags();
    } catch (e) {
      throw Exception('Invalid login credentials or network error.');
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: AddServer(
            onLogin: (String url, String user, String pass) async {
              String? errorMessage;
              try {
                setState(() {
                  baseUrl = url;
                  username = user;
                  password = pass;
                });
                await _saveServerDetails(url, user, pass);
                await _initClient();
              } catch (e) {
                errorMessage = 'Login failed: ${e.toString()}';
                if (kDebugMode) {
                  print(errorMessage);
                }
              }

              if (errorMessage != null) {
                // Show an error dialog if login fails
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Login Error'),
                      content: Text(errorMessage!),
                      actions: <Widget>[
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context)
                                .pop(); // Dismiss the error dialog
                          },
                        ),
                      ],
                    );
                  },
                );
              } else {
                Navigator.of(context)
                    .pop(); // Dismiss the login dialog on success
              }
            },
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Theme.of(context).primaryColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      baseUrl = null;
                      username = null;
                      password = null;
                      isUserLoggedIn = false;
                    });
                    await _logout();
                    Navigator.of(context).pop();
                    await _initHive();
                  },
                  child: const Text('Logout'),
                ),
              ],
            ));
      },
    );
  }

  Future<void> _logout() async {
    var box = await Hive.openBox('serverBox');
    await box.delete('baseUrl');
    await box.delete('username');
    await box.delete('password');

    try {
      final directory = await getApplicationDocumentsDirectory();
      final cookieDirPath = '${directory.path}/.cookies';
      final cookieDir = Directory(cookieDirPath);

      if (await cookieDir.exists()) {
        await cookieDir.delete(recursive: true);
        print('All contents of .cookie folder deleted successfully.');
      } else {
        print('No .cookie folder found at: $cookieDirPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting .cookie folder: $e');
      }
    }
  }

  Future<void> checkUserLogin() async {
    final box = await Hive.openBox('serverBox');
    final url = box.get('baseUrl');
    final user = box.get('username');
    final pass = box.get('password');
    if (url != null && user != null && pass != null) {
      setState(() {
        isUserLoggedIn = true;
      });
    }
  }

  Future<void> _saveServerDetails(String url, String user, String pass) async {
    var box = await Hive.openBox('serverBox');
    box.put('baseUrl', url);
    box.put('username', user);
    box.put('password', pass);
  }

  Future<void> addTorrent(String? url, QBittorrentApiV2 qbittorrent,
      String? category, List<String> tags, File? torrentFile) async {
    try {
      if (url != null && url.isNotEmpty) {
        final newTorrents =
            NewTorrents.urls(urls: [url], category: category, tags: tags);
        await qbittorrent.torrents.addNewTorrents(torrents: newTorrents);
      } else if (torrentFile != null) {
        final newTorrents = NewTorrents.files(
            files: [torrentFile], category: category, tags: tags);
        await qbittorrent.torrents.addNewTorrents(torrents: newTorrents);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding torrent: $e');
      }
    }
  }

  Future<void> _fetchSortedTorrents() async {
    try {
      final fetchedTorrents = await qbittorrent.torrents.getTorrentsList(
        options: TorrentListOptions(
          category: selectedCategory,
          sort: currentSortMethod,
          reverse: true,
          tag: selectedTag,
        ),
      );
      setState(() {
        torrents = fetchedTorrents;
        _filterTorrents();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sorted torrents: $e');
      }
    }
  }

  void _subscribeToMainData() {
    const interval = Duration(seconds: 3);
    _fetchSortedTorrents(); // Initial fetch
    Timer.periodic(interval, (_) => _fetchSortedTorrents());
  }

  void _filterTorrents() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
      filteredTorrents = torrents
          .where((torrent) => torrent.name!.toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      selectedCategory = category;
      _fetchSortedTorrents();
    });
  }

  void _changeSortMethod(TorrentSort sortMethod) {
    setState(() {
      currentSortMethod = sortMethod;
      _fetchSortedTorrents();
    });
  }

  void _selectTag(String? tag) {
    setState(() {
      selectedTag = tag;
      _fetchSortedTorrents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'qBittorrent Remote',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            isUserLoggedIn == false
                ? IconButton(
                    onPressed: _showLoginDialog,
                    icon: const Icon(
                      Icons.add_box_outlined,
                      color: Colors.black,
                    ))
                : IconButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AddtorrentDialog(
                            onAdd: (String? url, String? category,
                                List<String> selectedTags, File? torrentFile) {
                              setState(() {
                                magnetUrl = url;
                              });
                            },
                            addTorrent: (String? url,
                                    String? category,
                                    List<String> selectedTags,
                                    File? torrentFile) =>
                                addTorrent(url, qbittorrent, category,
                                    selectedTags, torrentFile),
                            categories: categories,
                            tags: tags,
                          ),
                        );
                      },
                    ),
                    icon: const Icon(
                      Icons.add,
                      color: Colors.black,
                    ),
                  ),
            Visibility(
              visible: isUserLoggedIn == true,
              child: PopupMenuButton(
                  itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                        PopupMenuItem(
                            onTap: _showLogoutDialog,
                            child: const ListTile(
                              title: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              leading: Text(
                                'Remove added server',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            ))
                      ]),
            ),
          ]),
      body: baseUrl == null || username == null || password == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Text(
                      'Add a server ↗',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Text(
                      'Remember that you must have a qbittorrent instance running somewhere else and the webUI option for it must be enabled.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            )
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.black,
                        controller: searchController,
                        decoration: InputDecoration(
                          suffixIcon: const Icon(Icons.search),
                          suffixIconColor: Colors.black,
                          labelText: 'Search',
                          labelStyle: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: Colors.orangeAccent[200],
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.orange),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.orange),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                      child: PopupMenuButton(
                        icon:
                            const Icon(Icons.filter_list, color: Colors.orange),
                        onSelected: _changeSortMethod,
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<TorrentSort>>[
                          const PopupMenuItem<TorrentSort>(
                            value: TorrentSort.eta,
                            child: Text(
                              'ETA',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const PopupMenuItem<TorrentSort>(
                            value: TorrentSort.ratio,
                            child: Text(
                              'Ratio',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const PopupMenuItem<TorrentSort>(
                            value: TorrentSort.completed,
                            child: Text(
                              'Completed',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const PopupMenuItem<TorrentSort>(
                            value: TorrentSort.progress,
                            child: Text(
                              'Progress',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const PopupMenuItem<TorrentSort>(
                            value: TorrentSort.name,
                            child: Text(
                              'Name',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Platform.isLinux || Platform.isMacOS || Platform.isWindows
                  ? Row(
                      children: [
                        if (categories.isNotEmpty)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(25, 0, 8, 16),
                              child: ScrollConfiguration(
                                behavior:
                                    ScrollConfiguration.of(context).copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                    PointerDeviceKind.trackpad,
                                  },
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    height: 40,
                                    child: Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              _selectCategory(null),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                selectedCategory == null
                                                    ? Colors.orange
                                                    : Colors.grey[800],
                                          ),
                                          child: const Text('All',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                        ),
                                        const SizedBox(width: 8),
                                        ...categories.map((category) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _selectCategory(category),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      selectedCategory ==
                                                              category
                                                          ? Colors.orange
                                                          : Colors.grey[800],
                                                ),
                                                child: Text(category,
                                                    style: const TextStyle(
                                                        color: Colors.white70)),
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (tags.isNotEmpty)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(25, 0, 8, 16),
                              child: ScrollConfiguration(
                                behavior:
                                    ScrollConfiguration.of(context).copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                    PointerDeviceKind.trackpad,
                                  },
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    height: 40,
                                    child: Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _selectTag(null),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: selectedTag == null
                                                ? Colors.orange
                                                : Colors.grey[800],
                                          ),
                                          child: const Text('All Tags',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                        ),
                                        const SizedBox(width: 8),
                                        ...tags.map((tag) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _selectTag(tag),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      selectedTag == tag
                                                          ? Colors.orange
                                                          : Colors.grey[800],
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: const TextStyle(
                                                      color: Colors.white70),
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : SizedBox(
                      height: 110,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (categories.isNotEmpty)
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 8, 15),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    height: 40,
                                    child: Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              _selectCategory(null),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                selectedCategory == null
                                                    ? Colors.orange
                                                    : Colors.grey[800],
                                          ),
                                          child: const Text('All',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                        ),
                                        const SizedBox(width: 8),
                                        ...categories.map((category) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _selectCategory(category),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      selectedCategory ==
                                                              category
                                                          ? Colors.orange
                                                          : Colors.grey[800],
                                                ),
                                                child: Text(category,
                                                    style: const TextStyle(
                                                        color: Colors.white70)),
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (tags.isNotEmpty)
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 8, 16),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    height: 40,
                                    child: Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _selectTag(null),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: selectedTag == null
                                                ? Colors.orange
                                                : Colors.grey[800],
                                          ),
                                          child: const Text('All Tags',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                        ),
                                        const SizedBox(width: 8),
                                        ...tags.map((tag) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _selectTag(tag),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      selectedTag == tag
                                                          ? Colors.orange
                                                          : Colors.grey[800],
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: const TextStyle(
                                                      color: Colors.white70),
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    children: [
                      if (selectedTorrents.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              '#${selectedTorrents.length}    ',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await qbittorrent.torrents.pauseTorrents(
                                  torrents: Torrents(
                                      hashes: selectedTorrents.toList()),
                                );
                                setState(() {
                                  selectedTorrents.clear();
                                });
                              },
                              child: const Icon(Icons.pause),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await qbittorrent.torrents.resumeTorrents(
                                  torrents: Torrents(
                                      hashes: selectedTorrents.toList()),
                                );
                                setState(() {
                                  selectedTorrents.clear();
                                });
                              },
                              child: const Icon(Icons.play_arrow),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await qbittorrent.torrents.deleteTorrents(
                                  torrents: Torrents(
                                      hashes: selectedTorrents.toList()),
                                );
                                setState(() {
                                  selectedTorrents.clear();
                                });
                              },
                              child: const Icon(Icons.delete),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await qbittorrent.torrents.deleteTorrents(
                                  deleteFiles: true,
                                  torrents: Torrents(
                                      hashes: selectedTorrents.toList()),
                                );
                                setState(() {
                                  selectedTorrents.clear();
                                });
                              },
                              child: const Icon(Icons.folder_delete),
                            ),
                          ],
                        ),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                            },
                          ),
                          child: ListView.builder(
                            itemCount: filteredTorrents.length,
                            itemBuilder: (context, index) {
                              final torrent = filteredTorrents[index];
                              selectedTorrents.contains(torrent.hash);

                              return Padding(
                                padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color:
                                        selectedTorrents.contains(torrent.hash)
                                            ? Colors.blue[800]
                                            : Colors.grey[800],
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      torrent.name ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (torrent.category != null)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        0, 5, 0, 5),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                      color: Colors.orange,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  child: Text(
                                                    '${(torrent.category)}',
                                                    style: const TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              '${(torrent.progress! * 100).toStringAsFixed(2)}%',
                                              style: const TextStyle(
                                                  color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                        LinearProgressIndicator(
                                          value: torrent.progress,
                                          backgroundColor: Colors.grey[700],
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              _getProgressColor(torrent.state)),
                                        ),
                                        Text(
                                          'Ratio: ${(torrent.ratio!).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontFamily: 'RobotoMono'),
                                        ),
                                        Text(
                                          _getTorrentStateString(torrent.state),
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontFamily: 'RobotoMono'),
                                        ),
                                        Text(
                                          '${roundUpToHundredth(torrent.downloaded! / 1024 / 1024 / 1024)} GB / ${roundUpToHundredth(torrent.size! / 1024 / 1024 / 1024)} GB',
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontFamily: 'RobotoMono'),
                                        ),
                                      ],
                                    ),
                                    trailing: torrent.state !=
                                                TorrentState.pausedDL &&
                                            torrent.state !=
                                                TorrentState.pausedUP
                                        ? IconButton(
                                            icon: const Icon(Icons.pause),
                                            onPressed: () async {
                                              await qbittorrent.torrents
                                                  .pauseTorrents(
                                                torrents: Torrents(
                                                    hashes: [torrent.hash!]),
                                              );
                                            },
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            onPressed: () async {
                                              await qbittorrent.torrents
                                                  .resumeTorrents(
                                                torrents: Torrents(
                                                    hashes: [torrent.hash!]),
                                              );
                                            },
                                          ),
                                    onTap: () =>
                                        _toggleSelection(torrent.hash!),
                                    onLongPress: () =>
                                        _toggleSelection(torrent.hash!),
                                    selected:
                                        selectedTorrents.contains(torrent.hash),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ]),
    );
  }
}
