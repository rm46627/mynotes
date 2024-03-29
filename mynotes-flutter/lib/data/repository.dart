import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mynotes/data/database.dart';
import 'package:mynotes/data/local_data_source.dart';
import 'package:mynotes/data/notes_dao.dart';
import 'package:mynotes/data/remote_data_source.dart';
import 'package:mynotes/services/auth/auth_service.dart';

class Repository extends NotesDao {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;

  Repository(this._localDataSource, this._remoteDataSource) {
    _notesStreamController = StreamController<List<Note>>.broadcast(onListen: () {
      _notesStreamController.sink.add(_notes);
    });
  }

  // singleton
  static final Repository _singleton = Repository(LocalDataSource(), RemoteDataSource());
  factory Repository.get() => _singleton;
  // factory Repository.crud() => Repository(LocalDataSource(), RemoteDataSource());

  final userId = AuthService.rest().currentUser.id;

  List<Note> _notes = [];
  late final StreamController<List<Note>> _notesStreamController;

  Stream<List<Note>> get allNotes => _notesStreamController.stream;

  @override
  Future<Note> createNote(String text) async {
    // create local note
    final note = await _localDataSource.createNote(text);
    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  @override
  Future<void> removeNote(Note note) async {
    // remove from local
    _localDataSource.removeNote(note);
    _notes.removeWhere((element) => element.id == note.id);
    _notesStreamController.add(_notes);
  }

  @override
  Future<List<Note>> selectNotesByUserId(int userId) async {
    // from local
    final userNotesFromLocal = await _localDataSource.selectNotesByUserId(userId);
    _notes = userNotesFromLocal;
    _notesStreamController.add(userNotesFromLocal);

    return userNotesFromLocal;
  }

  @override
  Future<void> updateNote(Note note) async {
    // update local
    _localDataSource.updateNote(note);
    _notes.removeWhere((element) => element.id == note.id);
    _notes.add(note);
    _notesStreamController.add(_notes);
  }

  Future<void> syncNotes() async {
    // sync remote
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      final userNotesFromLocal = await _localDataSource.selectNotesByUserId(userId);
      _remoteDataSource.syncNotes(userNotesFromLocal);
    }
  }

  Future<List<Note>> getNotesFromRemote() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    List<Note> notesFromRemote;
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      notesFromRemote = await _remoteDataSource.selectNotesByUserId(userId);
      addNotes(notesFromRemote);
      return notesFromRemote;
    }
    return [];
  }

  @override
  Future<void> addNotes(List<Note> notes) => _localDataSource.addNotes(notes);

  @override
  Future<void> removeAllNotes() => _localDataSource.removeAllNotes();
}
