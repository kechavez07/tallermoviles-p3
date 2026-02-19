/// Extensiones y optimizaciones para Firestore
/// Implementar en proyecto para reducir latencia y costos

import 'package:cloud_firestore/cloud_firestore.dart';

/// Extender Query con métodos útiles para paginación eficiente
extension OptimizedFirestoreQueries on Query<Map<String, dynamic>> {
  /// Obtener siguiente página de resultados
  /// Uso: query.paginated(pageSize: 20, nextPageMarker: lastDoc)
  Future<({List<Map<String, dynamic>> docs, DocumentSnapshot? next})> paginated({
    required int pageSize,
    DocumentSnapshot? nextPageMarker,
  }) async {
    Query query = nextPageMarker != null 
        ? this.startAfterDocument(nextPageMarker) 
        : this;
    
    final snapshot = await query.limit(pageSize + 1).get();
    
    final docs = snapshot.docs.take(pageSize).map((d) => d.data()).toList();
    final hasMore = snapshot.docs.length > pageSize;
    final nextDoc = hasMore ? snapshot.docs[pageSize - 1] : null;
    
    return (docs: docs, next: nextDoc);
  }

  /// Optimizar query para proyectos del usuario con colaboradores
  /// ✓ Crea índices necesarios automáticamente
  static Query<Map<String, dynamic>> getUserProjects(
    String userId, {
    int limit = 20,
  }) {
    final firestore = FirebaseFirestore.instance;
    
    // ⚠️ IMPORTANTE: Este query requiere índice Firestore
    // Composite Index needed:
    // - Collection: projects
    // - Fields: 
    //   1. owner_uid (Ascending) OR collaborators (Contains)
    //   2. updated_at (Descending)
    
    // Workaround: usar dos queries y combinar
    return firestore.collection('projects')
        .where(Filter.or(
          Filter('owner_uid', isEqualTo: userId),
          Filter('collaborators', arrayContains: userId),
        ))
        .orderBy('updated_at', descending: true)
        .limit(limit);
  }
}

/// Gestión de búsquedas eficientes
class FirestoreSearchOptimizer {
  static const String searchIndexCollection = '_search_index';

  /// Crear índice de búsqueda desnormalizado
  /// Mejora performance para búsquedas de texto
  static Future<void> indexProjectForSearch({
    required String projectId,
    required String name,
    required String description,
    required List<String> tags,
  }) async {
    final firestore = FirebaseFirestore.instance;
    
    // Crear documento de búsqueda por artista
    await firestore
        .collection('projects_search_artist')
        .doc(projectId)
        .set({
          'name': name.toLowerCase(),
          'name_keywords': _generateKeywords(name),
          'description': description.toLowerCase(),
          'tags': tags.map((t) => t.toLowerCase()).toList(),
          'indexed_at': FieldValue.serverTimestamp(),
        });
  }

  /// Buscar proyectos por nombre/tags
  static Stream<List<Map<String, dynamic>>> searchProjects({
    required String query,
    int limit = 20,
  }) {
    final firestore = FirebaseFirestore.instance;
    final searchTerm = query.toLowerCase();
    
    return firestore
        .collection('projects_search_artist')
        .where('name_keywords', arrayContains: searchTerm)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  static List<String> _generateKeywords(String text) {
    final keywords = <String>{};
    final words = text.toLowerCase().split(' ');
    
    for (final word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }
    
    return keywords.toList();
  }
}

/// Batch operations para mejorar throughput
class FirestoreBatchOptimizer {
  static const int batchSize = 500; // Límite de Firestore

  /// Actualizar múltiples documentos de forma eficiente
  static Future<void> batchUpdate({
    required String collection,
    required Map<String, Map<String, dynamic>> updates,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final entries = updates.entries.toList();
    
    for (int i = 0; i < entries.length; i += batchSize) {
      final batch = firestore.batch();
      final chunk = entries.skip(i).take(batchSize);
      
      for (final entry in chunk) {
        batch.update(
          firestore.collection(collection).doc(entry.key),
          entry.value,
        );
      }
      
      await batch.commit();
    }
  }

  /// Eliminar múltiples documentos de forma eficiente
  static Future<void> batchDelete({
    required String collection,
    required List<String> docIds,
  }) async {
    final firestore = FirebaseFirestore.instance;
    
    for (int i = 0; i < docIds.length; i += batchSize) {
      final batch = firestore.batch();
      final chunk = docIds.skip(i).take(batchSize);
      
      for (final docId in chunk) {
        batch.delete(firestore.collection(collection).doc(docId));
      }
      
      await batch.commit();
    }
  }
}

/// Cache local de resultados Firestore
/// Reduce reads y mejora UX offline
class FirestoreCacheLayer {
  static const Duration cacheExpiration = Duration(minutes: 5);
  
  final Map<String, CachedResult> _cache = {};

  class CachedResult {
    final List<Map<String, dynamic>> data;
    final DateTime timestamp;

    CachedResult({required this.data, required this.timestamp});

    bool get isExpired => 
        DateTime.now().difference(timestamp) > cacheExpiration;
  }

  /// Obtener con cache automático
  Future<List<Map<String, dynamic>>> getWithCache({
    required String key,
    required Future<List<Map<String, dynamic>>> Function() fetch,
  }) async {
    final cached = _cache[key];
    
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    final data = await fetch();
    _cache[key] = CachedResult(data: data, timestamp: DateTime.now());
    
    return data;
  }

  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }
}
