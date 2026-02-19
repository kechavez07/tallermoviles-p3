import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:estudio_musica_taller/offline/index.dart';

/// Ejemplo completo de cómo usar el sistema offline & local data
class OfflineProjectsExample extends StatefulWidget {
  const OfflineProjectsExample({Key? key}) : super(key: key);

  @override
  State<OfflineProjectsExample> createState() => _OfflineProjectsExampleState();
}

class _OfflineProjectsExampleState extends State<OfflineProjectsExample> {
  late final String _currentUserId;
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // En una app real, obtener userId del servicio de autenticación
    _currentUserId = 'user_${const Uuid().v4().substring(0, 8)}';
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos (Offline)'),
        elevation: 0,
        actions: [
          // Indicador de conectividad
          Consumer<ConnectivityManager>(
            builder: (context, connectivity, _) {
              return Container(
                padding: const EdgeInsets.all(8),
                child: Chip(
                  backgroundColor: connectivity.isOnline ? Colors.green : Colors.red,
                  label: Text(
                    connectivity.isOnline ? '🟢 Online' : '🔴 Offline',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
          // Indicador de sincronización
          Consumer<SyncService>(
            builder: (context, syncService, _) {
              if (syncService.isSyncing) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de estadísticas
          Consumer2<SyncService, CacheManager>(
            builder: (context, syncService, cache, _) {
              return FutureBuilder<Map<String, dynamic>>(
                future: syncService.getSyncStats(_currentUserId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final stats = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          label: 'Pendientes',
                          value: '${stats['pendingProjects']}',
                          icon: Icons.cloud_upload,
                        ),
                        _StatItem(
                          label: 'Conflictos',
                          value: '${stats['unresolvedConflicts']}',
                          icon: Icons.warning,
                        ),
                        _StatItem(
                          label: 'En Cola',
                          value: '${stats['syncQueueItems']}',
                          icon: Icons.queue,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Lista de proyectos
          Expanded(
            child: Consumer<CacheManager>(
              builder: (context, cache, _) {
                return FutureBuilder<List<LocalProject>>(
                  future: cache.getProjectsByUser(_currentUserId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final projects = snapshot.data!;

                    if (projects.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay proyectos',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text('Crea uno para comenzar'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return _ProjectCard(
                          project: project,
                          userId: _currentUserId,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // FAB para crear proyecto
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Proyecto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _projectNameController,
              decoration: const InputDecoration(hintText: 'Nombre del proyecto'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _projectDescController,
              decoration: const InputDecoration(hintText: 'Descripción'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _createProject(context);
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _createProject(BuildContext context) async {
    final name = _projectNameController.text;
    final description = _projectDescController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    try {
      // Crear proyecto
      final newProject = LocalProject(
        id: const Uuid().v4(),
        userId: _currentUserId,
        name: name,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      // Guardar localmente
      final db = DatabaseManager();
      await db.insertProject(newProject);

      // Agregar a cola de sincronización
      final syncService = context.read<SyncService>();
      await syncService.addProjectToSync(
        newProject,
        SyncOperationType.create,
      );

      // Actualizar caché
      final cache = context.read<CacheManager>();
      await cache.saveProject(newProject);

      _projectNameController.clear();
      _projectDescController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Proyecto creado')),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }
}

/// Tarjeta de proyecto
class _ProjectCard extends StatefulWidget {
  final LocalProject project;
  final String userId;

  const _ProjectCard({
    required this.project,
    required this.userId,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.folder_music,
          color: _getStatusColor(widget.project.syncStatus),
        ),
        title: Text(widget.project.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.project.description),
            const SizedBox(height: 4),
            Text(
              _getSyncStatusText(widget.project.syncStatus),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(widget.project.syncStatus),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _editProject(context),
              child: const Text('Editar'),
            ),
            PopupMenuItem(
              onTap: () => _deleteProject(context),
              child: const Text('Eliminar'),
            ),
            if (widget.project.syncStatus == SyncStatus.pending)
              PopupMenuItem(
                onTap: () => _forceSync(context),
                child: const Text('Sincronizar ahora'),
              ),
          ],
        ),
      ),
    );
  }

  void _editProject(BuildContext context) {
    final nameController = TextEditingController(text: widget.project.name);
    final descController =
        TextEditingController(text: widget.project.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Proyecto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(hintText: 'Descripción'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = widget.project.copyWith(
                name: nameController.text,
                description: descController.text,
                updatedAt: DateTime.now(),
                syncStatus: SyncStatus.pending,
              );

              final db = DatabaseManager();
              await db.updateProject(updated);

              final syncService = context.read<SyncService>();
              await syncService.addProjectToSync(
                updated,
                SyncOperationType.update,
              );

              if (!mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar proyecto?'),
        content: const Text('Esta acción no se puede deshacer'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = DatabaseManager();
      await db.deleteProject(widget.project.id);

      final cache = context.read<CacheManager>();
      await cache.deleteProject(widget.project.id);

      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _forceSync(BuildContext context) async {
    final syncService = context.read<SyncService>();
    await syncService.forceSynchronization(widget.userId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Sincronización iniciada')),
    );
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return '✅ Sincronizado';
      case SyncStatus.pending:
        return '⏳ Pendiente de sincronizar';
      case SyncStatus.conflicted:
        return '⚠️ Conflicto detectado';
      case SyncStatus.failed:
        return '❌ Error en sincronización';
    }
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.conflicted:
        return Colors.red;
      case SyncStatus.failed:
        return Colors.red;
    }
  }
}

/// Widget de estadística
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(label),
      ],
    );
  }
}
