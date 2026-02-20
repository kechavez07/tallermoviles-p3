import 'package:flutter/material.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../auth/firebase_auth/auth_util.dart';
import 'favorite_service.dart';

import '../../backend/backend.dart';
import '../../backend/chat_service.dart';
import '../../backend/project_service.dart';

/// Example: Real-Time Chat Widget
/// This demonstrates how to use StreamBuilder with ChatService
class ChatPageExample extends StatefulWidget {
  final String projectId;

  const ChatPageExample({required this.projectId});

  @override
  State<ChatPageExample> createState() => _ChatPageExampleState();
}

class _ChatPageExampleState extends State<ChatPageExample> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Set user as online when entering chat
    chatService.setUserPresence(projectId: widget.projectId, isOnline: true);
  }

  @override
  void dispose() {
    // Set user as offline when leaving
    chatService.setUserPresence(projectId: widget.projectId, isOnline: false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Chat'),
        // Show online users count
        actions: [
          StreamBuilder<List<String>>(
            stream: chatService.getOnlineUsersStream(widget.projectId),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('$count online'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list - Real-time sync
          Expanded(
            child: StreamBuilder<List<ChatMessageRecord>>(
              stream: chatService.getProjectMessagesStream(widget.projectId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest messages at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          // Input area
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _sendMessage(),
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await chatService.sendMessage(
        projectId: widget.projectId,
        message: message,
      );
      _messageController.clear();
      // Scroll to latest message
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Widget _buildMessageBubble(ChatMessageRecord message) {
    final isCurrentUser = message.senderUid == currentUserDocument?.uid;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderPhotoUrl.isNotEmpty
                  ? NetworkImage(message.senderPhotoUrl)
                  : null,
              child: message.senderPhotoUrl.isEmpty
                  ? Icon(Icons.person)
                  : null,
            ),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isCurrentUser ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                  if (message.isEdited)
                    Text(
                      'edited',
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Example: Real-Time Projects List
/// Shows all projects user owns or collaborates on
class ProjectsListExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Projects'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreateProjectDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<ProjectRecord>>(
        stream: projectService.getUserProjectsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No projects yet. Create one to get started!'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectCard(context, project);
            },
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectRecord project) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: project.thumbnailUrl.isNotEmpty
            ? Image.network(project.thumbnailUrl)
            : Icon(Icons.album),
        title: Text(project.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.description),
            Text(
              '${project.trackCount} tracks • ${project.collaborators.length} collaborators',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          // Navigate to project detail
          // Navigator.push(context, ...)
        },
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'Project name'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(hintText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await projectService.createProject(
                  name: nameController.text,
                  description: descriptionController.text,
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// Example: Real-Time Tracks with Favorites
/// Shows tracks in a project with real-time favorite status
class TracksListExample extends StatelessWidget {
  final String projectId;

  const TracksListExample({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tracks')),
      body: StreamBuilder<ProjectWithTracks>(
        stream: projectService.getProjectWithTracksStream(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final projectWithTracks = snapshot.data;
          if (projectWithTracks == null) {
            return Center(child: Text('Project not found'));
          }

          final tracks = projectWithTracks.tracks;

          if (tracks.isEmpty) {
            return Center(
              child: Text('No tracks in this project yet'),
            );
          }

          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _buildTrackTile(context, track);
            },
          );
        },
      ),
    );
  }

  Widget _buildTrackTile(BuildContext context, TrackRecord track) {
    return ListTile(
      leading: Icon(Icons.music_note),
      title: Text(track.title),
      subtitle: Text('${track.artist} • ${track.bpm} BPM'),
      trailing: StreamBuilder<bool>(
        stream: favoriteService.isTrackFavoritedStream(track.reference.id),
        builder: (context, snapshot) {
          final isFavorited = snapshot.data ?? false;
          return IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : null,
            ),
            onPressed: () {
              if (isFavorited) {
                favoriteService
                    .removeFromFavorites(track.reference.id);
              } else {
                favoriteService.addToFavorites(
                  trackId: track.reference.id,
                  projectId: projectId,
                );
              }
            },
          );
        },
      ),
      onTap: () {
        // Navigate to track detail
      },
    );
  }
}
