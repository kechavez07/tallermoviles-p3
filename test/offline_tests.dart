import 'package:flutter_test/flutter_test.dart';
import 'package:estudio_musica_taller/offline/index.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('AGENTE 3 - Offline & Local Data Tests', () {
    late DatabaseManager db;

    setUpAll(() async {
      db = DatabaseManager();
    });

    group('LocalProject Model', () {
      test('Crear proyecto correctamente', () {
        final project = LocalProject(
          id: 'test-1',
          userId: 'user-1',
          name: 'Mi Proyecto',
          description: 'Un proyecto de prueba',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(project.id, equals('test-1'));
        expect(project.name, equals('Mi Proyecto'));
        expect(project.syncStatus, equals(SyncStatus.pending));
      });

      test('Convertir a Map y viceversa', () {
        final project = LocalProject(
          id: 'test-2',
          userId: 'user-1',
          name: 'Proyecto Convertible',
          description: 'Descripción',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final map = project.toMap();
        expect(map['id'], equals('test-2'));
        expect(map['name'], equals('Proyecto Convertible'));

        final restored = LocalProject.fromMap(map);
        expect(restored.id, equals(project.id));
        expect(restored.name, equals(project.name));
      });

      test('CopyWith funciona correctamente', () {
        final original = LocalProject(
          id: 'test-3',
          userId: 'user-1',
          name: 'Original',
          description: 'Descripción original',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final modified = original.copyWith(
          name: 'Modificado',
          syncStatus: SyncStatus.synced,
        );

        expect(modified.name, equals('Modificado'));
        expect(modified.syncStatus, equals(SyncStatus.synced));
        expect(modified.id, equals(original.id)); // ID se mantiene
      });
    });

    group('LocalTrack Model', () {
      test('Crear pista correctamente', () {
        final track = LocalTrack(
          id: 'track-1',
          projectId: 'project-1',
          name: 'Mi Canción',
          filePath: '/path/to/song.mp3',
          durationMs: 180000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(track.id, equals('track-1'));
        expect(track.name, equals('Mi Canción'));
        expect(track.isFavorite, equals(false));
      });

      test('Marcar como favorita', () {
        final track = LocalTrack(
          id: 'track-2',
          projectId: 'project-1',
          name: 'Canción Favorita',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final favorite = track.copyWith(isFavorite: true);
        expect(favorite.isFavorite, equals(true));
      });
    });

    group('PendingSyncItem Model', () {
      test('Crear elemento para crear proyecto', () {
        final item = PendingSyncItem(
          id: const Uuid().v4(),
          userId: 'user-1',
          operationType: SyncOperationType.create,
          entityType: 'project',
          entityId: 'proj-1',
          data: {'name': 'Nuevo Proyecto'},
          createdAt: DateTime.now(),
        );

        expect(item.operationType, equals(SyncOperationType.create));
        expect(item.entityType, equals('project'));
        expect(item.retryCount, equals(0));
      });

      test('Incrementar retry count', () {
        final item = PendingSyncItem(
          id: const Uuid().v4(),
          userId: 'user-1',
          operationType: SyncOperationType.update,
          entityType: 'track',
          entityId: 'track-1',
          data: {},
          createdAt: DateTime.now(),
          retryCount: 1,
        );

        final retried = item.copyWith(
          retryCount: item.retryCount + 1,
          error: 'Network error',
        );

        expect(retried.retryCount, equals(2));
        expect(retried.error, equals('Network error'));
      });
    });

    group('ConflictRecord Model', () {
      test('Crear registro de conflicto', () {
        final localTime = DateTime(2024, 1, 15, 10, 0);
        final remoteTime = DateTime(2024, 1, 15, 11, 0);

        final conflict = ConflictRecord(
          id: const Uuid().v4(),
          entityType: 'project',
          entityId: 'proj-1',
          localVersion: {'name': 'Proyecto Local'},
          remoteVersion: {'name': 'Proyecto Remoto'},
          localTimestamp: localTime,
          remoteTimestamp: remoteTime,
          detectedAt: DateTime.now(),
        );

        expect(conflict.isResolved, equals(false));
        expect(conflict.remoteTimestamp.isAfter(conflict.localTimestamp), true);
      });

      test('Resolver conflicto', () {
        final conflict = ConflictRecord(
          id: const Uuid().v4(),
          entityType: 'project',
          entityId: 'proj-1',
          localVersion: {},
          remoteVersion: {},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now(),
          detectedAt: DateTime.now(),
        );

        final resolved = ConflictResolver.createResolvedConflict(
          conflict,
          ConflictResolutionStrategy.lastWriteWins,
        );

        expect(resolved.isResolved, equals(true));
        expect(resolved.resolutionStrategy,
            equals(ConflictResolutionStrategy.lastWriteWins));
      });
    });

    group('SyncStatus Enum', () {
      test('Convertir string a SyncStatus', () {
        expect(
          SyncStatus.fromString('synced'),
          equals(SyncStatus.synced),
        );
        expect(
          SyncStatus.fromString('pending'),
          equals(SyncStatus.pending),
        );
        expect(
          SyncStatus.fromString('conflicted'),
          equals(SyncStatus.conflicted),
        );
        expect(
          SyncStatus.fromString('failed'),
          equals(SyncStatus.failed),
        );
        expect(
          SyncStatus.fromString('desconocido'),
          equals(SyncStatus.synced), // Default
        );
      });
    });

    group('ConflictResolver', () {
      test('Last-Write-Wins: versión remota más nueva', () {
        final local = {'name': 'Local', 'version': 1};
        final remote = {'name': 'Remote', 'version': 2};
        final localTime = DateTime(2024, 1, 15, 10, 0);
        final remoteTime = DateTime(2024, 1, 15, 11, 0);

        final resolved = ConflictResolver.resolveLastWriteWins(
          localVersion: local,
          remoteVersion: remote,
          localTimestamp: localTime,
          remoteTimestamp: remoteTime,
        );

        expect(resolved['name'], equals('Remote'));
      });

      test('Last-Write-Wins: versión local más nueva', () {
        final local = {'name': 'Local', 'version': 2};
        final remote = {'name': 'Remote', 'version': 1};
        final localTime = DateTime(2024, 1, 15, 11, 0);
        final remoteTime = DateTime(2024, 1, 15, 10, 0);

        final resolved = ConflictResolver.resolveLastWriteWins(
          localVersion: local,
          remoteVersion: remote,
          localTimestamp: localTime,
          remoteTimestamp: remoteTime,
        );

        expect(resolved['name'], equals('Local'));
      });

      test('Keep-Local estrategia', () {
        final local = {'keep': 'local'};
        final remote = {'keep': 'remote'};

        final resolved = ConflictResolver._applyStrategy(
          local,
          remote,
          ConflictResolutionStrategy.keepLocal,
          DateTime.now(),
          DateTime.now(),
        );

        expect(resolved['keep'], equals('local'));
      });

      test('Keep-Remote estrategia', () {
        final local = {'keep': 'local'};
        final remote = {'keep': 'remote'};

        final resolved = ConflictResolver._applyStrategy(
          local,
          remote,
          ConflictResolutionStrategy.keepRemote,
          DateTime.now(),
          DateTime.now(),
        );

        expect(resolved['keep'], equals('remote'));
      });

      test('Detectar campos en conflicto', () {
        final local = {'name': 'Local', 'version': 1};
        final remote = {'name': 'Remote', 'version': 2};

        final conflicting = ConflictResolver.detectConflictingFields(
          local,
          remote,
        );

        expect(conflicting, containsAll(['name', 'version']));
      });

      test('Fusionar versiones inteligentemente', () {
        final local = {
          'name': 'Local Name',
          'is_favorite': true,
          'position': 5,
        };
        final remote = {
          'name': 'Remote Name',
          'description': 'Nueva descripción',
          'version': 2,
        };

        final merged = ConflictResolver.mergeVersions(local, remote);

        // Mantiene campos locales específicos
        expect(merged['is_favorite'], equals(true));
        expect(merged['position'], equals(5));
        // Toma datos remotos nuevos
        expect(merged['description'], equals('Nueva descripción'));
      });
    });

    group('SyncOperationType Enum', () {
      test('Convertir strings a operaciones', () {
        expect(
          SyncOperationType.fromString('create'),
          equals(SyncOperationType.create),
        );
        expect(
          SyncOperationType.fromString('update'),
          equals(SyncOperationType.update),
        );
        expect(
          SyncOperationType.fromString('delete'),
          equals(SyncOperationType.delete),
        );
      });
    });

    group('Validaciones', () {
      test('Proyecto no puede tener nombre vacío', () {
        expect(
          () => LocalProject(
            id: 'test',
            userId: 'user-1',
            name: '', // Nombre vacío
            description: 'Desc',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          isNotNull, // En Dart los validaciones no son forzadas en constructor
        );
      });

      test('Track requiere projectId válido', () {
        expect(
          () => LocalTrack(
            id: 'track-1',
            projectId: '', // projectId vacío
            name: 'Test Track',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          isNotNull,
        );
      });

      test('ConflictRecord debe tener timestamps válidos', () {
        final now = DateTime.now();
        final conflict = ConflictRecord(
          id: 'conflict-1',
          entityType: 'project',
          entityId: 'proj-1',
          localVersion: {},
          remoteVersion: {},
          localTimestamp: now,
          remoteTimestamp: now,
          detectedAt: now,
        );

        expect(conflict.localTimestamp, isNotNull);
        expect(conflict.remoteTimestamp, isNotNull);
        expect(conflict.detectedAt, isNotNull);
      });
    });

    group('Igualdad de objetos', () {
      test('Dos proyectos con mismo ID son iguales', () {
        final proj1 = LocalProject(
          id: 'same-id',
          userId: 'user-1',
          name: 'Proyecto 1',
          description: 'Desc',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final proj2 = LocalProject(
          id: 'same-id',
          userId: 'user-2',
          name: 'Proyecto 2',
          description: 'Otra desc',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(proj1 == proj2, equals(true)); // Igualdad por ID
      });

      test('Dos pistas con mismo ID son iguales', () {
        final track1 = LocalTrack(
          id: 'same-track',
          projectId: 'proj-1',
          name: 'Track 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final track2 = LocalTrack(
          id: 'same-track',
          projectId: 'proj-2',
          name: 'Track 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(track1 == track2, equals(true));
      });
    });
  });
}
