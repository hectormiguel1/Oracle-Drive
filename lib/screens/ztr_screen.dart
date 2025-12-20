import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_ribbon.dart';
import 'package:oracle_drive/components/ztr/ztr_action_buttons.dart';
import 'package:oracle_drive/components/ztr/ztr_search_field.dart';
import 'package:oracle_drive/components/ztr/ztr_table.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/ztr_model.dart';
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class ZtrScreen extends StatefulWidget {
  final AppGameCode selectedGame;
  const ZtrScreen({super.key, required this.selectedGame});

  @override
  State<ZtrScreen> createState() => _ZtrScreenState();
}

class _ZtrScreenState extends State<ZtrScreen>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('ZtrScreen');
  late AppGameCode _selectedGame;
  bool _isLoading = false;
  int _stringCount = 0;
  List<ZtrEntry> _ztrEntries = []; // To hold all fetched entries
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ZtrEntry> _filteredZtrEntries = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.selectedGame;
    _searchController.addListener(_onSearchChanged);
    _updateAndFetchStrings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ZtrScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedGame != oldWidget.selectedGame) {
      _selectedGame = widget.selectedGame;
      _updateAndFetchStrings();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterEntries();
    });
  }

  void _filterEntries() {
    if (_searchQuery.isEmpty) {
      _filteredZtrEntries = List.from(_ztrEntries);
    } else {
      _filteredZtrEntries = _ztrEntries.where((entry) {
        final queryLower = _searchQuery.toLowerCase();
        return entry.id.toLowerCase().contains(queryLower) ||
            entry.text.toLowerCase().contains(queryLower);
      }).toList();
    }
  }

  Future<void> _handleEntryUpdated(ZtrEntry updatedEntry) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await AppDatabase.ensureInitialized();
      AppDatabase.instance
          .getRepositoryForGame(_selectedGame)
          .updateString(updatedEntry.id, updatedEntry.text);
      _showSnackBar("Entry '${updatedEntry.id}' updated.");
      _updateAndFetchStrings(); // Refresh the list
    } catch (e) {
      _logger.severe("Error updating entry: $e");
      _showSnackBar("Error updating entry: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEntryRemoved(String entryId) async {
    showDialog(
      context: context,
      builder: (context) => CrystalDialog(
        title: "Confirm Deletion",
        content: Text("Are you sure you want to delete entry '$entryId'?"),
        actions: [
          CrystalButton(
            label: "Cancel",
            onPressed: () => Navigator.of(context).pop(),
          ),
          CrystalButton(
            label: "Delete",
            isPrimary: true,
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              setState(() {
                _isLoading = true;
              });
              try {
                await AppDatabase.ensureInitialized();
                AppDatabase.instance
                    .getRepositoryForGame(_selectedGame)
                    .deleteString(entryId);
                _showSnackBar("Entry '$entryId' deleted.");
                _updateAndFetchStrings(); // Refresh the list
              } catch (e) {
                _logger.severe("Error deleting entry: $e");
                _showSnackBar("Error deleting entry: $e");
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addZtrEntry() async {
    final TextEditingController idController = TextEditingController();
    final TextEditingController textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => CrystalDialog(
        title: "Add New ZTR Entry",
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(labelText: "Reference ID"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "ID cannot be empty";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: textController,
                decoration: const InputDecoration(labelText: "String Value"),
                maxLines: null,
              ),
            ],
          ),
        ),
        actions: [
          CrystalButton(
            label: "Cancel",
            onPressed: () => Navigator.of(context).pop(),
          ),
          CrystalButton(
            label: "Add",
            isPrimary: true,
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(); // Close dialog
                setState(() {
                  _isLoading = true;
                });
                try {
                  await AppDatabase.ensureInitialized();
                  AppDatabase.instance
                      .getRepositoryForGame(_selectedGame)
                      .addString(idController.text, textController.text);
                  _showSnackBar("Entry '${idController.text}' added.");
                  _updateAndFetchStrings(); // Refresh the list
                } catch (e) {
                  _logger.severe("Error adding entry: $e");
                  _showSnackBar("Error adding entry: $e");
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateAndFetchStrings() async {
    setState(() {
      _isLoading = true;
      _ztrEntries = []; // Clear previous entries
      _filteredZtrEntries = []; // Clear filtered entries as well
    });
    try {
      await AppDatabase.ensureInitialized();
      final db = AppDatabase.instance;
      final repo = db.getRepositoryForGame(_selectedGame);
      final count = repo.getStringCount();
      setState(() {
        _stringCount = count;
      });

      if (count > 0) {
        final stream = repo.getStrings();
        int fetchedCount = 0;
        await for (final chunk in stream) {
          final newEntries = chunk.entries
              .map((e) => ZtrEntry(e.key, e.value))
              .toList();
          fetchedCount += newEntries.length;
          setState(() {
            _ztrEntries.addAll(newEntries);
            _filterEntries();
            _isLoading = false; // Show data as it arrives
          });
        }
        _logger.info("Fetched $fetchedCount strings for display.");
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe("Error getting string count or fetching strings: $e");
      _showSnackBar("Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadZtrFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ztr'],
      dialogTitle: 'Select .ztr file to load',
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _isLoading = true;
      });
      try {
        await AppDatabase.ensureInitialized();
        _logger.info(
          "Extracting ZTR: $path for game ${_selectedGame.displayName}",
        );
        await NativeService.instance.extractZtrData(path, _selectedGame);
        _logger.info("ZTR extracted and loaded into database.");
        _showSnackBar("ZTR data loaded successfully!");
        _updateAndFetchStrings(); // Refresh UI after loading
      } catch (e, stack) {
        _logger.severe("Error loading ZTR: $e\n$stack");
        _showSnackBar("Error loading ZTR: $e");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _dumpZtrFile() async {
    if (_stringCount == 0) {
      _showSnackBar("No strings in database to dump.");
      return;
    }

    String? savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save ZTR file',
      fileName: '${_selectedGame.name}_dump.ztr',
      type: FileType.custom,
      allowedExtensions: ['ztr'],
    );

    if (savePath != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        await AppDatabase.ensureInitialized();
        _logger.info(
          "Dumping ZTR data from DB to $savePath for game ${_selectedGame.displayName}",
        );
        await NativeService.instance.dumpZtrFileFromDb(_selectedGame, savePath);
        _logger.info("ZTR data dumped successfully.");
        _showSnackBar("ZTR data dumped successfully!");
      } catch (e, stack) {
        _logger.severe("Error dumping ZTR: $e\n$stack");
        _showSnackBar("Error dumping ZTR: $e");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _dumpTxtFile() async {
    if (_stringCount == 0) {
      _showSnackBar("No strings in database to dump.");
      return;
    }

    String? savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Text file',
      fileName: '${_selectedGame.name}_dump.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (savePath != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        await AppDatabase.ensureInitialized();
        _logger.info(
          "Dumping ZTR data from DB to $savePath as text for game ${_selectedGame.displayName}",
        );
        await NativeService.instance.dumpTxtFileFromDb(_selectedGame, savePath);
        _logger.info("ZTR data dumped to text successfully.");

        _showSnackBar("ZTR data dumped to text successfully!");

        _logger.fine("ZTR data dumped to text successfully.");
      } catch (e, stack) {
        _logger.severe("Error dumping ZTR to text: $e\n$stack");

        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Error dumping ZTR to text: $e");
      } finally {
        _logger.fine("Finished dumpTxtFile operation.");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onResetDatabasePressed() {
    showDialog(
      context: context,
      builder: (context) => CrystalDialog(
        title: "Confirm Reset",
        content: const Text(
          "Are you sure you want to reset the database? This will delete all loaded strings.",
        ),
        actions: [
          CrystalButton(
            label: "Cancel",
            onPressed: () => Navigator.of(context).pop(),
          ),
          CrystalButton(
            label: "Reset",
            isPrimary: true,
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              setState(() {
                _isLoading = true;
              });
              try {
                await AppDatabase.ensureInitialized();
                final db = AppDatabase.instance;
                db.getRepositoryForGame(_selectedGame).clearDatabase();
                _logger.info("Database reset for ${_selectedGame.displayName}");
                _showSnackBar("Database reset successfully.");
                _updateAndFetchStrings(); // Refresh UI after reset
              } catch (e) {
                _logger.severe("Error resetting database: $e");
                _showSnackBar("Error resetting DB: $e");
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CrystalRibbon(message: message),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: .center,
              children: [
                // Buttons/Info Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: _stringCount == 0
                      ? Center(
                          // Center content when no data
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Current Game: ${_selectedGame.displayName}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 20), // Add some space
                              CrystalButton(
                                onPressed: _loadZtrFile,
                                icon: Icons.folder_open,
                                label: "Load ZTR File",
                                isPrimary: true,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              "Current Game: ${_selectedGame.displayName}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ZtrSearchField(
                              controller: _searchController,
                              onChanged: (query) => _onSearchChanged(),
                            ),
                            const SizedBox(height: 10),
                            ZtrActionButtons(
                              selectedGame: _selectedGame,
                              stringCount: _stringCount,
                              onLoadZtrFile: _loadZtrFile,
                              onDumpZtrFile: _dumpZtrFile,
                              onDumpTxtFile: _dumpTxtFile,
                              onResetDatabase: _onResetDatabasePressed,
                              onAddEntry: _addZtrEntry,
                            ),
                          ],
                        ),
                ),

                // Table Section
                if (_stringCount > 0 && _filteredZtrEntries.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CrystalPanel(
                        child: ZtrTable(
                          gameCode: _selectedGame,
                          entries: _filteredZtrEntries,
                          onEntryUpdated: _handleEntryUpdated,
                          onEntryRemoved: _handleEntryRemoved,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
