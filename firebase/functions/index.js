const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ==================== User Management ====================

// Delete user data when account is deleted
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  try {
    // Delete user document
    await db.collection("user").doc(user.uid).delete();
    
    // Delete user's settings
    const settingsDocs = await db.collection("settings")
      .where("user_uid", "==", user.uid)
      .get();
    
    const deleteSettingsPromises = settingsDocs.docs.map(doc => doc.ref.delete());
    await Promise.all(deleteSettingsPromises);
    
    // Archive user's projects (don't delete, preserve history)
    const projectDocs = await db.collection("projects")
      .where("owner_uid", "==", user.uid)
      .get();
    
    const archiveProjectsPromises = projectDocs.docs.map(doc =>
      doc.ref.update({
        archived: true,
        archived_at: admin.firestore.FieldValue.serverTimestamp()
      })
    );
    await Promise.all(archiveProjectsPromises);
    
    console.log(`Successfully cleaned up data for user ${user.uid}`);
  } catch (error) {
    console.error(`Error cleaning up user ${user.uid}:`, error);
  }
});

// ==================== Project Sync ====================

// Sync project updates to all collaborators
exports.syncProject = functions.firestore
  .document("projects/{projectId}")
  .onUpdate(async (change, context) => {
    const projectId = context.params.projectId;
    const newData = change.after.data();
    const previousData = change.before.data();
    
    try {
      // Track changes for version control
      const changeLog = {
        project_id: projectId,
        changed_at: admin.firestore.FieldValue.serverTimestamp(),
        changed_by: newData.updated_by || previousData.owner_uid,
        changes: {}
      };
      
      // Store only changed fields
      for (const key in newData) {
        if (JSON.stringify(newData[key]) !== JSON.stringify(previousData[key])) {
          changeLog.changes[key] = {
            from: previousData[key],
            to: newData[key]
          };
        }
      }
      
      // Log the change
      await db.collection("projects")
        .doc(projectId)
        .collection("changelog")
        .add(changeLog);
      
      // Notify collaborators
      await notifyCollaborators(projectId, `Project "${newData.name}" was updated`, newData.owner_uid);
      
      console.log(`Project ${projectId} synced successfully`);
    } catch (error) {
      console.error(`Error syncing project ${projectId}:`, error);
    }
  });

// ==================== Track Sync ====================

// Update track count when tracks are added/removed
exports.updateTrackCount = functions.firestore
  .document("tracks/{trackId}")
  .onWrite(async (change, context) => {
    const trackId = context.params.trackId;
    const trackData = change.after.data();
    
    if (!trackData) {
      // Track was deleted
      console.log(`Track ${trackId} was deleted`);
      return;
    }
    
    try {
      const projectId = trackData.project_id;
      
      // Get count of tracks in project
      const trackCount = await db.collection("tracks")
        .where("project_id", "==", projectId)
        .count()
        .get();
      
      // Update project track count
      await db.collection("projects").doc(projectId).update({
        track_count: trackCount.data().count,
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`Updated track count to ${trackCount.data().count} for project ${projectId}`);
    } catch (error) {
      console.error(`Error updating track count:`, error);
    }
  });

// ==================== Collaboration Notifications ====================

// Notify when user is added as collaborator
exports.collabNotifications = functions.firestore
  .document("projects/{projectId}")
  .onUpdate(async (change, context) => {
    const projectId = context.params.projectId;
    const newCollaborators = change.after.data().collaborators || [];
    const previousCollaborators = change.before.data().collaborators || [];
    
    try {
      // Find newly added collaborators
      const newCollabs = newCollaborators.filter(uid => !previousCollaborators.includes(uid));
      const removedCollabs = previousCollaborators.filter(uid => !newCollaborators.includes(uid));
      
      const projectName = change.after.data().name;
      const ownerUid = change.after.data().owner_uid;
      
      // Get owner info for notification
      const ownerDoc = await db.collection("user").doc(ownerUid).get();
      const ownerName = ownerDoc.data()?.display_name || "A user";
      
      // Notify newly added collaborators
      for (const collaboratorUid of newCollabs) {
        await createNotification(
          collaboratorUid,
          "Collaboration Invitation",
          `${ownerName} invited you to collaborate on "${projectName}"`,
          { projectId, type: "collaboration_invite" }
        );
        
        // Send email notification would go here in production
      }
      
      // Notify removed collaborators
      for (const collaboratorUid of removedCollabs) {
        await createNotification(
          collaboratorUid,
          "Removed from Project",
          `You were removed from the project "${projectName}"`,
          { projectId, type: "collaboration_removed" }
        );
      }
      
      console.log(`Collaboration notifications sent for project ${projectId}`);
    } catch (error) {
      console.error(`Error sending collaboration notifications:`, error);
    }
  });

// ==================== Audio File Processing ====================

// Process uploaded audio files
exports.processAudioFile = functions.storage
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const fileName = filePath.split('/').pop();
    
    // Only process audio files
    if (!filePath.includes('audio_uploads/') || !isAudioFile(filePath)) {
      return;
    }
    
    try {
      console.log(`Processing audio file: ${fileName}`);
      
      // Extract metadata from filename
      const [projectId, trackName] = fileName.split('___');
      
      if (!projectId || !trackName) {
        console.error('Invalid filename format');
        return;
      }
      
      // Get audio file URL
      const bucket = admin.storage().bucket();
      const audioUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;
      
      // Create track record with audio file
      const trackRef = await db.collection("tracks").add({
        project_id: projectId,
        title: trackName.replace('.mp3', '').replace('.wav', ''),
        audio_url: audioUrl,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        version: 1,
        created_by: 'system' // Would be extracted from upload context in real implementation
      });
      
      console.log(`Created track record: ${trackRef.id}`);
      
      // Notify project collaborators
      const projectDoc = await db.collection("projects").doc(projectId).get();
      if (projectDoc.exists) {
        await notifyCollaborators(
          projectId,
          `New audio file uploaded: ${trackName}`,
          projectDoc.data().owner_uid
        );
      }
    } catch (error) {
      console.error(`Error processing audio file:`, error);
    }
  });

// ==================== Chat Real-Time Sync ====================

// Trigger notifications on new messages
exports.notifyNewMessage = functions.firestore
  .document("messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const projectId = messageData.project_id;
    
    try {
      // Get project to find collaborators
      const projectDoc = await db.collection("projects").doc(projectId).get();
      const collaborators = projectDoc.data().collaborators || [];
      const ownerUid = projectDoc.data().owner_uid;
      
      const allUsers = [...collaborators, ownerUid];
      
      // Notify all collaborators except sender
      for (const uid of allUsers) {
        if (uid !== messageData.sender_uid) {
          await createNotification(
            uid,
            "New Message",
            `${messageData.sender_name}: ${messageData.message.substring(0, 50)}...`,
            { projectId, messageId: context.params.messageId, type: "chat" }
          );
        }
      }
      
      console.log(`Notifications sent for message ${context.params.messageId}`);
    } catch (error) {
      console.error(`Error notifying message:`, error);
    }
  });

// ==================== Helper Functions ====================

async function notifyCollaborators(projectId, title, senderUid) {
  try {
    const projectDoc = await db.collection("projects").doc(projectId).get();
    const collaborators = projectDoc.data().collaborators || [];
    const ownerUid = projectDoc.data().owner_uid;
    
    const allUsers = [...collaborators, ownerUid];
    
    const notificationPromises = allUsers
      .filter(uid => uid !== senderUid)
      .map(uid => createNotification(
        uid,
        "Project Update",
        title,
        { projectId, type: "project_update" }
      ));
    
    await Promise.all(notificationPromises);
  } catch (error) {
    console.error(`Error notifying collaborators:`, error);
  }
}

async function createNotification(uid, title, message, data = {}) {
  try {
    // Store notification in Firestore
    await db.collection("notifications").add({
      recipient_uid: uid,
      title,
      message,
      data,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });
    
    // Send push notification (requires FCM tokens)
    // In production, retrieve FCM token from user document and send via messaging.send()
  } catch (error) {
    console.error(`Error creating notification for ${uid}:`, error);
  }
}

function isAudioFile(fileName) {
  const audioExtensions = ['.mp3', '.wav', '.flac', '.aac', '.m4a'];
  return audioExtensions.some(ext => fileName.toLowerCase().endsWith(ext));
}

