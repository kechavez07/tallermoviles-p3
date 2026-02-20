import '/components/musiclibrary/musiclibrary_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/main/mixer/mixer_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'musiclibrary1_model.dart';
export 'musiclibrary1_model.dart';

class Musiclibrary1Widget extends StatefulWidget {
  const Musiclibrary1Widget({super.key});

  static String routeName = 'Musiclibrary1';
  static String routePath = '/musiclibrary1';

  @override
  State<Musiclibrary1Widget> createState() => _Musiclibrary1WidgetState();
}

class _Musiclibrary1WidgetState extends State<Musiclibrary1Widget> {
  late Musiclibrary1Model _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Musiclibrary1Model());
    _initializeAndLoadProjects();
  }

  Future<void> _initializeAndLoadProjects() async {
    try {
      await _model.initializeServices();
      await _refreshProjects();
    } catch (e) {
      print('Error initializing: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshProjects() async {
    final projects = await _model.getProjects();
    setState(() {
      _model.projects = projects;
    });
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Proyecto Musical'),
        contentPadding: EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nombre del proyecto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  hintText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final projectId = await _model.createProject(
                  name: nameController.text,
                  description: descController.text.isNotEmpty
                      ? descController.text
                      : null,
                );

                Navigator.pop(context);

                if (projectId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Proyecto creado exitosamente ✓'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _refreshProjects();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creando proyecto'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _editProject(String projectId, String projectName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MixerWidget(),
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateProjectDialog,
          backgroundColor: FlutterFlowTheme.of(context).primary,
          icon: Icon(Icons.add),
          label: Text('Nuevo Proyecto'),
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // Header
                    SliverAppBar(
                      pinned: true,
                      backgroundColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      title: Text(
                        'Mi Biblioteca Musical',
                        style:
                            FlutterFlowTheme.of(context).headlineMedium.override(
                                  fontFamily: 'Outfit',
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      elevation: 0,
                    ),
                    // Projects Grid
                    SliverPadding(
                      padding: EdgeInsets.all(16),
                      sliver: _model.projects.isEmpty
                          ? SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 64),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.library_music,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No hay proyectos aún',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Presiona + para crear tu primer proyecto',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final project = _model.projects[index];
                                  return _buildProjectCard(
                                    context,
                                    project['id'] ?? '',
                                    project['name'] ?? 'Sin nombre',
                                    project['description'] ?? '',
                                    project['createdAt'] ?? DateTime.now(),
                                  );
                                },
                                childCount: _model.projects.length,
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    String projectId,
    String projectName,
    String description,
    DateTime createdDate,
  ) {
    return GestureDetector(
      onTap: () => _editProject(projectId, projectName),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: FlutterFlowTheme.of(context).secondaryBackground,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A3A52).withOpacity(0.8),
                    Color(0xFF0F5C75).withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF00D4FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Color(0xFF00D4FF),
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Project name
                  Text(
                    projectName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  Spacer(),
                  // Date
                  Text(
                    'Creado: ${createdDate.day}/${createdDate.month}/${createdDate.year}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _editProject(projectId, projectName),
                          icon: Icon(Icons.edit, size: 16),
                          label: Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00D4FF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Eliminar Proyecto'),
                                content: Text(
                                    '¿Estás seguro de que deseas eliminar "$projectName"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _model.deleteProject(projectId);
                              await _refreshProjects();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Proyecto eliminado ✓')),
                              );
                            }
                          },
                          icon: Icon(Icons.delete, size: 16),
                          label: Text('Eliminar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
