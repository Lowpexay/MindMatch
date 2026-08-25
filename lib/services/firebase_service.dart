import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/mood_data.dart';
import '../models/question_models.dart';
import '../models/conversation_models.dart';
import '../models/conversation_history.dart';
import '../models/consultation_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // If true, on Android try putData (non-resumable) first to avoid resumable session issues.
  final bool forcePutDataOnAndroid;

  FirebaseService({this.forcePutDataOnAndroid = true});

  // Helper to wrap Firestore streams and prevent unhandled exceptions
  // If the underlying stream emits an error (e.g., missing composite index),
  // log it and convert it into an empty stream so the UI doesn't crash.
  Stream<T> _guardedStream<T>(Stream<T> source, String tag) {
    // Use async* to yield events and catch errors
    final controller = StreamController<T>.broadcast();

    source.listen((event) {
      try {
        controller.add(event);
      } catch (e) {
        print('⚠️ Error while forwarding event for $tag: $e');
      }
    }, onError: (err, stack) {
      // Cloud Firestore may throw FAILED_PRECONDITION when a composite index is missing.
      print('❌ Firestore stream error for $tag: $err');
      // Do not close the controller so consumers can keep working with previous/empty state.
      // Optionally we could emit a special empty value, but for QuerySnapshot/DocumentSnapshot
      // consumers generally expect the stream to remain open.
    }, onDone: () {
      try {
        controller.close();
      } catch (e) {}
    }, cancelOnError: false);

    return controller.stream;
  }

  // Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String conversationsCollection = 'conversations';
  static const String patientsCollection = 'patients';
  static const String psychologistsCollection = 'psychologists';
  static const String consultationsCollection = 'consultations';

  /// Delete basic user related data (best-effort) before account deletion.
  /// This avoids leaving orphaned profile docs or storage assets.
  Future<void> deleteUserData(String userId) async {
    try {
      // Delete user document if exists
      final userDoc = _firestore.collection(usersCollection).doc(userId);
      final snap = await userDoc.get();
      if (snap.exists) {
        await userDoc.delete();
      }
    } catch (e) {
      print('⚠️ deleteUserData Firestore doc error: $e');
    }
    // Attempt to delete profile image
    try {
      final ref = _storage.ref().child('users/$userId/profile.jpg');
      await ref.delete();
    } catch (e) {
      // Ignore if not found
      print('ℹ️ deleteUserData storage image skip: $e');
    }
    // Could extend to conversations/messages if GDPR-like full wipe is needed.
  }

    /// Faz upload da imagem de perfil do usuário para o Firebase Storage e retorna a URL pública.
    Future<String?> uploadUserProfileImage(String userId, Uint8List imageBytes) async {
      try {
        final ref = _storage.ref().child('users/$userId/profile.jpg');
    // Provide explicit metadata to avoid null-metadata issues on some Android plugin versions
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(imageBytes, metadata);
        final url = await ref.getDownloadURL();
        return url;
      } catch (e) {
        print('Erro ao fazer upload da imagem: $e');
        return null;
      }
    }
  // ULTRA SIMPLE TEST - Just write to Firestore without any validation
  Future<bool> simpleFirestoreTest() async {
    try {
      print('🚀 ULTRA SIMPLE FIRESTORE TEST');
      
      // Try to write the simplest possible data
      await _firestore.collection('test').doc('simple').set({
        'message': 'Hello World',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('✅ Simple write successful');
      
      // Try to read it back
      final doc = await _firestore.collection('test').doc('simple').get();
      if (doc.exists) {
        print('✅ Simple read successful: ${doc.data()}');
        return true;
      } else {
        print('❌ Document not found after write');
        return false;
      }
      
    } catch (e) {
      print('❌ Simple test failed: $e');
      return false;
    }
  }

  // DEBUG: List all users in Firestore to see if test users persist
  Future<void> debugListAllUsers() async {
    try {
      print('🔍 DEBUG: Listing all users in Firestore...');
      
      final QuerySnapshot snapshot = await _firestore
          .collection(usersCollection)
          .get();
      
      print('📊 Total users found: ${snapshot.docs.length}');
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('👤 User ${doc.id}: ${data['name']} (${data['email']})');
      }
      
    } catch (e) {
      print('❌ Error listing users: $e');
    }
  }

  // TEST: Verify if Firestore is working
  Future<bool> testFirestoreConnection() async {
    try {
      print('🧪 Testing Firestore connection...');
      
      if (_auth.currentUser == null) {
        print('❌ No authenticated user for test');
        return false;
      }
      
      final testData = {
        'test': 'Hello Firestore',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'user': _auth.currentUser!.uid,
      };
      
      print('🧪 Writing test data: $testData');
      
      await _firestore.collection('test').doc('connection_test').set(testData);
      
      print('✅ Test data written successfully');
      
      // Try to read it back
      final doc = await _firestore.collection('test').doc('connection_test').get();
      if (doc.exists) {
        print('✅ Test data read back: ${doc.data()}');
        return true;
      } else {
        print('❌ Test data not found after write');
        return false;
      }
      
    } catch (e) {
      print('❌ Firestore test failed: $e');
      if (e is FirebaseException) {
        print('❌ Firebase error code: ${e.code}');
        print('❌ Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  // FINAL SOLUTION: Simple profile creation without complex types
  Future<void> createCompleteProfile(String userId, Map<String, dynamic> userData) async {
    try {
      print('🔧 Creating complete profile for: $userId');
      print('📝 User data received: $userData');
      
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        throw Exception('❌ No authenticated user found');
      }
      
      if (_auth.currentUser!.uid != userId) {
        throw Exception('❌ User ID mismatch: ${_auth.currentUser!.uid} vs $userId');
      }
      
      print('✅ User authentication verified');
      
      // Convert all data to safe types for Firestore
      final safeData = <String, dynamic>{
        'name': userData['name']?.toString() ?? '',
        'email': userData['email']?.toString() ?? '',
        'age': userData['age'] is int ? userData['age'] : int.tryParse(userData['age']?.toString() ?? '0') ?? 0,
        'city': userData['city']?.toString() ?? '',
        'bio': userData['bio']?.toString() ?? '',
        'goal': userData['goal']?.toString() ?? '',
        'created': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Handle profile image URL separately
      if (userData['profileImageUrl'] != null && userData['profileImageUrl'].toString().isNotEmpty) {
        safeData['profileImageUrl'] = userData['profileImageUrl'].toString();
      }
      
      // Handle tags with extreme care - convert to simple strings
      if (userData['tags'] != null && userData['tags'] is List) {
        final List<String> cleanTags = [];
        final tagsList = userData['tags'] as List;
        
        for (var tag in tagsList) {
          if (tag != null) {
            final tagString = tag.toString().trim();
            if (tagString.isNotEmpty) {
              cleanTags.add(tagString);
            }
          }
        }
        
        print('🏷️ Clean tags: $cleanTags');
        
        // Store tags as individual fields to avoid List<Object?> issues
        for (int i = 0; i < cleanTags.length; i++) {
          safeData['tag_$i'] = cleanTags[i];
        }
        safeData['tag_count'] = cleanTags.length;
        
        // Also try to store as a single string
        safeData['tags_string'] = cleanTags.join(',');
        
        // Try storing as array too
        safeData['tags'] = cleanTags;
      }
      
      print('🛡️ Safe data prepared: $safeData');
      print('🔥 Attempting to write to Firestore...');
      
      // Create the document with all safe data at once
      await _firestore.collection('users').doc(userId).set(safeData);
      
      print('✅ Complete profile created successfully in Firestore!');
      
      // Verify the document was created
      print('🔍 Verifying document creation...');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        print('✅ Document verified: ${doc.data()}');
      } else {
        print('❌ Document not found after creation!');
      }
      
    } catch (e) {
      print('❌ Error creating complete profile: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('❌ Firebase error code: ${e.code}');
        print('❌ Firebase error message: ${e.message}');
      }
      throw e;
    }
  }

  // -------------------------
  // User Extra Data Helpers
  // -------------------------
  // Armazena dados auxiliares do usuário (ex.: estado de checkup diário) em subdocumento
  Future<Map<String, dynamic>?> getUserExtraData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('meta').doc('extra').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('⚠️ getUserExtraData error: $e');
    }
    return null;
  }

  Future<void> updateUserExtraData(String userId, Map<String, dynamic> updates) async {
    try {
      final ref = _firestore.collection('users').doc(userId).collection('meta').doc('extra');
      await ref.set(updates, SetOptions(merge: true));
    } catch (e) {
      print('⚠️ updateUserExtraData error: $e');
    }
  }

  // Ultra simple profile creation - bypassing potential type issues
  Future<void> createBasicProfile(String userId, String name, String email) async {
    try {
      print('Creating ultra basic profile for: $userId');
      
      // Most basic possible document creation
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'created': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('Basic profile created successfully');
    } catch (e) {
      print('Error creating basic profile: $e');
      throw e;
    }
  }

  // Add fields one by one to isolate the problematic field
  Future<void> addProfileFields(String userId, Map<String, dynamic> fields) async {
    try {
      print('Adding fields to profile: $fields');
      
      for (String key in fields.keys) {
        print('Adding field: $key = ${fields[key]} (${fields[key].runtimeType})');
        
        await _firestore.collection('users').doc(userId).update({
          key: fields[key],
        });
        
        print('Successfully added field: $key');
      }
      
    } catch (e) {
      print('Error adding profile fields: $e');
      throw e;
    }
  }

  // Alternative simple user profile creation
  Future<void> createSimpleUserProfile(String name, String email, List<String> tags, String goal) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      print('Creating simple profile for user: $userId');
      
      // Create the simplest possible profile
      final simpleData = {
        'name': name,
        'email': email,
        'tags': tags,
        'goal': goal,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print('Simple data: $simpleData');
      await _firestore.collection(usersCollection).doc(userId).set(simpleData);
      print('Simple profile created successfully');
      
    } catch (e) {
      print('Error creating simple profile: $e');
      throw Exception('Failed to create simple profile: $e');
    }
  }

  // User Management
  Future<void> createUserProfile(Map<String, dynamic> userData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      print('Starting profile creation for user: $userId');
      print('Original userData: $userData');
      
      // Process tags safely
      List<String> tagsList = [];
      if (userData['tags'] != null) {
        if (userData['tags'] is List) {
          for (var tag in userData['tags']) {
            if (tag != null) {
              tagsList.add(tag.toString());
            }
          }
        }
      }
      print('Processed tags: $tagsList');

      // Create minimal user data first - only basic fields
      final Map<String, dynamic> basicUserData = {
        'name': userData['name']?.toString() ?? '',
        'email': userData['email']?.toString() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print('Creating basic profile first...');
      await _firestore.collection(usersCollection).doc(userId).set(basicUserData);
      print('Basic profile created successfully');

      // Now update with additional fields
      final Map<String, dynamic> additionalData = {
        'age': userData['age'] is int ? userData['age'] : int.tryParse(userData['age'].toString()) ?? 0,
        'city': userData['city']?.toString() ?? '',
        'bio': userData['bio']?.toString() ?? '',
        'goal': userData['goal']?.toString() ?? '',
        'tags': tagsList,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add profile image URL if provided
      if (userData['profileImageUrl'] != null && userData['profileImageUrl'].toString().isNotEmpty) {
        additionalData['profileImageUrl'] = userData['profileImageUrl'].toString();
      }
      
      print('Updating with additional data: $additionalData');
      await _firestore.collection(usersCollection).doc(userId).update(additionalData);
      print('User profile completed successfully');
      
    } catch (e) {
      print('Error creating user profile: $e');
      print('Error type: ${e.runtimeType}');
      print('Error stack: ${StackTrace.current}');
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user profile: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getRegisteredPsychologists({int limit = 50}) async {
    try {
      final usersSnapshot = await _firestore
          .collection(usersCollection)
          .where('role', isEqualTo: 'PSYCHOLOGIST')
          .limit(limit)
          .get();

      final psychologists = <Map<String, dynamic>>[];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        Map<String, dynamic> psychologistData = {};

        try {
          final psychDoc = await _firestore.collection(psychologistsCollection).doc(userDoc.id).get();
          if (psychDoc.exists) {
            psychologistData = psychDoc.data() ?? {};
          }
        } catch (e) {
          print('⚠️ Error loading psychologist doc ${userDoc.id}: $e');
        }

        final fullName = (userData['fullname'] ?? userData['name'] ?? userData['displayName'] ?? 'Profissional').toString();
        final specialty = (psychologistData['specialty'] ?? psychologistData['personalizedMessage'] ?? '').toString();
        final modalityRaw = (psychologistData['modality'] ?? '').toString();
        final availabilityDays = (psychologistData['availabilityDays'] ?? '').toString();
        final availabilityHours = (psychologistData['availabilityHours'] ?? '').toString();
        final officeAddress = (psychologistData['officeAddress'] ?? '').toString();
        final officePhone = (psychologistData['officePhone'] ?? '').toString();
        final healthPlans = (psychologistData['healthPlans'] ?? psychologistData['healthPlanCover'] ?? '').toString();

        final modality = _normalizePsychologistModality(modalityRaw);
        final availability = [
          if (availabilityDays.isNotEmpty) availabilityDays,
          if (availabilityHours.isNotEmpty) availabilityHours,
        ].join(' • ');

        psychologists.add({
          'id': userDoc.id,
          'name': fullName,
          'fullname': fullName,
          'email': userData['email'],
          'profileImageUrl': userData['profileImageUrl'],
          'profileImageBase64': userData['profileImageBase64'],
          'crp': psychologistData['crp'],
          'careerStart': psychologistData['careerStart'],
          'specialty': specialty,
          'modality': modality,
          'availability': availability,
          'availabilityDays': availabilityDays,
          'availabilityHours': availabilityHours,
          'officeAddress': officeAddress,
          'officePhone': officePhone,
          'healthPlans': healthPlans,
          'personalizedMessage': psychologistData['personalizedMessage'],
          'tags_string': psychologistData['specialties'] is List
              ? (psychologistData['specialties'] as List).join(', ')
              : (psychologistData['specialties']?.toString() ?? ''),
          'role': 'PSYCHOLOGIST',
        });
      }

      psychologists.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      return psychologists;
    } catch (e) {
      print('❌ Error fetching registered psychologists: $e');
      return [];
    }
  }

  String _normalizePsychologistModality(String raw) {
    final value = raw.trim().toUpperCase();
    if (value.contains('BOTH') || value.contains('ONLINE E PRESENCIAL')) {
      return 'Online e presencial';
    }
    if (value.contains('PRESENTIAL')) {
      return 'Presencial';
    }
    if (value.contains('ONLINE')) {
      return 'Online';
    }
    if (value.contains('CALL')) {
      return 'Online';
    }
    if (value.contains('MESSAGE')) {
      return 'Mensagens';
    }
    return raw.isNotEmpty ? raw : 'Online';
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  /// Create a user document in the users collection
  Future<DocumentReference> createUser(
    Map<String, dynamic> userData, [
    String? documentId,
  ]) async {
    try {
      final safeData = <String, dynamic>{
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = _firestore.collection(usersCollection);
      if (documentId != null) {
        await docRef.doc(documentId).set(safeData);
        return docRef.doc(documentId);
      } else {
        return await docRef.add(safeData);
      }
    } catch (e) {
      print('Error creating user: $e');
      throw e;
    }
  }

  /// Create a patient document in the patients collection
  Future<DocumentReference> createPatient(
    Map<String, dynamic> patientData, [
    String? documentId,
  ]) async {
    try {
      final safeData = <String, dynamic>{
        ...patientData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = _firestore.collection(patientsCollection);
      if (documentId != null) {
        await docRef.doc(documentId).set(safeData);
        return docRef.doc(documentId);
      } else {
        return await docRef.add(safeData);
      }
    } catch (e) {
      print('Error creating patient: $e');
      throw e;
    }
  }

  /// Create a psychologist document in the psychologists collection
  Future<DocumentReference> createPsychologist(
    Map<String, dynamic> psychologistData, [
    String? documentId,
  ]) async {
    try {
      final safeData = <String, dynamic>{
        ...psychologistData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = _firestore.collection(psychologistsCollection);
      if (documentId != null) {
        await docRef.doc(documentId).set(safeData);
        return docRef.doc(documentId);
      } else {
        return await docRef.add(safeData);
      }
    } catch (e) {
      print('Error creating psychologist: $e');
      throw e;
    }
  }

  /// Create user with role-specific data using atomic batch operation
  ///
  /// Creates documents in three collections with the same documentId:
  /// - users: Common data (birthDate, cpf, email, password, fullname, genre, phone, role)
  /// - patients: Patient-specific data (healthPlan, documents)
  /// - psychologists: Psychologist-specific data (crp, specialty, availability, etc)
  ///
  /// Example for PATIENT:
  /// ```dart
  /// await createUserWithRole(
  ///   userData: {
  ///     'fullname': 'João Silva',
  ///     'email': 'joao@example.com',
  ///     'cpf': '12345678900',
  ///     'birthDate': 1990,
  ///     'genre': 'Masculino',
  ///     'phone': '11999999999',
  ///   },
  ///   role: 'PATIENT',
  ///   roleSpecificData: {
  ///     'healthPlan': 'Unimed',
  ///     'documents': 'base64encodeddata',
  ///   },
  /// );
  /// ```
  ///
  /// Example for PSYCHOLOGIST:
  /// ```dart
  /// await createUserWithRole(
  ///   userData: {
  ///     'fullname': 'Dra. Maria Santos',
  ///     'email': 'maria@example.com',
  ///     'cpf': '98765432100',
  ///     'birthDate': 1985,
  ///     'genre': 'Feminino',
  ///     'phone': '11988888888',
  ///   },
  ///   role: 'PSYCHOLOGIST',
  ///   roleSpecificData: {
  ///     'crp': '06/12345',
  ///     'careerStart': 2010,
  ///     'specialty': 'Terapia Cognitivo-Comportamental',
  ///     'healthPlanCover': 'Bradesco, Unimed',
  ///     'personalizedMessage': 'Especialista em ansiedade',
  ///     'modality': 'messages,calls,in-person',
  ///     'officeAddress': 'Rua das Flores 123, São Paulo',
  ///     'officePhone': '1133334444',
  ///     'availabilities': [
  ///       {
  ///         'dayOfWeek': 'MONDAY',
  ///         'startTime': '08:00',
  ///         'endTime': '12:00',
  ///       },
  ///       {
  ///         'dayOfWeek': 'WEDNESDAY',
  ///         'startTime': '14:00',
  ///         'endTime': '18:00',
  ///       },
  ///     ],
  ///   },
  /// );
  /// ```
  ///
  /// Returns the documentId used for all documents (same ID across collections)
  /// Throws exception if role is invalid or no documentId/authenticated user available
  Future<String> createUserWithRole({
    required Map<String, dynamic> userData,
    required String role,
    required Map<String, dynamic> roleSpecificData,
    String? documentId,
  }) async {
    try {
      // Validate role
      if (role != 'PATIENT' && role != 'PSYCHOLOGIST') {
        throw Exception('Invalid role: $role. Must be PATIENT or PSYCHOLOGIST');
      }

      // Use provided documentId or auth user ID
      final id = documentId ?? _auth.currentUser?.uid;
      if (id == null) {
        throw Exception('No documentId provided and no authenticated user found');
      }

      print('🔄 Creating user with role=$role, documentId=$id');

      // Add role to user data
      final finalUserData = <String, dynamic>{
        ...userData,
        'role': role,
      };

      // Create batch operation for atomicity
      final batch = _firestore.batch();

      // Add user document to batch
      final userRef = _firestore.collection(usersCollection).doc(id);
      batch.set(userRef, {
        ...finalUserData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add role-specific document to batch
      if (role == 'PATIENT') {
        final patientRef = _firestore.collection(patientsCollection).doc(id);
        batch.set(patientRef, {
          ...roleSpecificData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('📝 Added patient document to batch');
      } else {
        final psychologistRef = _firestore.collection(psychologistsCollection).doc(id);
        batch.set(psychologistRef, {
          ...roleSpecificData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('📝 Added psychologist document to batch');
      }

      // Commit batch (all or nothing)
      await batch.commit();
      print('✅ User with role created successfully. DocumentId: $id');

      return id;
    } catch (e) {
      print('❌ Error creating user with role: $e');
      throw e;
    }
  }

  // Create Consultation
  Future<DocumentReference> createConsultation(
    Map<String, dynamic> consultationData, [
    String? documentId,
  ]) async {
    try {
      final safeData = <String, dynamic>{
        ...consultationData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = _firestore.collection(consultationsCollection);
      if (documentId != null) {
        await docRef.doc(documentId).set(safeData);
        print('✅ Consultation created with documentId: $documentId');
        return docRef.doc(documentId);
      } else {
        final newDocRef = await docRef.add(safeData);
        print('✅ Consultation created with auto-generated id: ${newDocRef.id}');
        return newDocRef;
      }
    } catch (e) {
      print('❌ Error creating consultation: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> findPsychologistByName(String psychologistName) async {
    try {
      final normalizedTarget = psychologistName.trim().toLowerCase();
      if (normalizedTarget.isEmpty) return null;

      final snapshot = await _firestore
          .collection(usersCollection)
          .where('role', isEqualTo: 'PSYCHOLOGIST')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final candidates = <String?>[
          data['name']?.toString(),
          data['fullname']?.toString(),
          data['displayName']?.toString(),
        ];

        for (final candidate in candidates) {
          final normalizedCandidate = candidate?.trim().toLowerCase() ?? '';
          if (normalizedCandidate.isNotEmpty &&
              (normalizedCandidate == normalizedTarget || normalizedCandidate.contains(normalizedTarget) || normalizedTarget.contains(normalizedCandidate))) {
            return {
              ...data,
              'id': doc.id,
            };
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Error finding psychologist by name: $e');
      return null;
    }
  }

  Future<List<Consultation>> getConsultationsForDay(
    String userId,
    String role, {
    DateTime? day,
  }) async {
    try {
      final targetDay = day ?? DateTime.now();
      final startOfDay = DateTime(targetDay.year, targetDay.month, targetDay.day).millisecondsSinceEpoch;

      Query<Map<String, dynamic>> query = _firestore.collection(consultationsCollection);
      if (role == 'PSYCHOLOGIST') {
        query = query.where('idPsychologist', isEqualTo: userId);
      } else if (role == 'PATIENT') {
        query = query.where('idPatient', isEqualTo: userId);
      } else {
        throw Exception('Invalid role: $role. Must be PATIENT or PSYCHOLOGIST');
      }

      final snapshot = await query.where('date', isEqualTo: startOfDay).get();
      final consultations = snapshot.docs
          .map((doc) => Consultation.fromFirestore(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.hour.compareTo(b.hour));

      print('✅ Found ${consultations.length} consultations for $role on day $startOfDay');
      return consultations;
    } catch (e) {
      print('❌ Error fetching consultations for day: $e');
      return [];
    }
  }

  Stream<List<Consultation>> watchConsultationsForDay(
    String userId,
    String role, {
    DateTime? day,
  }) {
    final targetDay = day ?? DateTime.now();
    final startOfDay = DateTime(targetDay.year, targetDay.month, targetDay.day).millisecondsSinceEpoch;

    Query<Map<String, dynamic>> query = _firestore.collection(consultationsCollection);
    if (role == 'PSYCHOLOGIST') {
      query = query.where('idPsychologist', isEqualTo: userId);
    } else if (role == 'PATIENT') {
      query = query.where('idPatient', isEqualTo: userId);
    }

    return _guardedStream(
      query.where('date', isEqualTo: startOfDay).snapshots().map((snapshot) {
        final consultations = snapshot.docs
            .map((doc) => Consultation.fromFirestore(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => a.hour.compareTo(b.hour));
        return consultations;
      }),
      'consultations-$role-$userId',
    );
  }

  Future<List<Consultation>> getUpcomingConsultationsForUser(
    String userId,
    String role, {
    DateTime? fromDay,
  }) async {
    try {
      if (role != 'PATIENT' && role != 'PSYCHOLOGIST') {
        throw Exception('Invalid role: $role. Must be PATIENT or PSYCHOLOGIST');
      }

      final start = fromDay ?? DateTime.now();
      final startOfDay = DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;

      Query<Map<String, dynamic>> query = _firestore.collection(consultationsCollection);
      if (role == 'PSYCHOLOGIST') {
        query = query.where('idPsychologist', isEqualTo: userId);
      } else {
        query = query.where('idPatient', isEqualTo: userId);
      }

      final snapshot = await query.get();
      final consultations = snapshot.docs
          .map((doc) => Consultation.fromFirestore(doc.data(), doc.id))
          .where((consultation) => consultation.date >= startOfDay)
          .toList()
        ..sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.hour.compareTo(b.hour);
        });

      print('✅ Found ${consultations.length} upcoming consultations for $role starting at $startOfDay');
      return consultations;
    } catch (e) {
      print('❌ Error fetching upcoming consultations: $e');
      return [];
    }
  }

  Stream<List<Consultation>> watchUpcomingConsultationsForUser(
    String userId,
    String role, {
    DateTime? fromDay,
  }) {
    final start = fromDay ?? DateTime.now();
    final startOfDay = DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;

    Query<Map<String, dynamic>> query = _firestore.collection(consultationsCollection);
    if (role == 'PSYCHOLOGIST') {
      query = query.where('idPsychologist', isEqualTo: userId);
    } else if (role == 'PATIENT') {
      query = query.where('idPatient', isEqualTo: userId);
    }

    return _guardedStream(
      query.snapshots().map((snapshot) {
        final consultations = snapshot.docs
            .map((doc) => Consultation.fromFirestore(doc.data(), doc.id))
            .where((consultation) => consultation.date >= startOfDay)
            .toList()
          ..sort((a, b) {
            final dateCompare = a.date.compareTo(b.date);
            if (dateCompare != 0) return dateCompare;
            return a.hour.compareTo(b.hour);
          });
        return consultations;
      }),
      'upcoming-consultations-$role-$userId',
    );
  }

  // Get all consultations for a user (patient or psychologist)
  Future<List<Consultation>> getUserConsultations(
    String userId,
    String role,
  ) async {
    try {
      if (role != 'PATIENT' && role != 'PSYCHOLOGIST') {
        throw Exception('Invalid role: $role. Must be PATIENT or PSYCHOLOGIST');
      }

      Query<Map<String, dynamic>> query;

      if (role == 'PATIENT') {
        query = _firestore
            .collection(consultationsCollection)
            .where('idPatient', isEqualTo: userId);
        print('🔍 Querying consultations for patient: $userId');
      } else {
        query = _firestore
            .collection(consultationsCollection)
            .where('idPsychologist', isEqualTo: userId);
        print('🔍 Querying consultations for psychologist: $userId');
      }

      final snapshot = await query.get();
      final consultations = snapshot.docs
          .map((doc) => Consultation.fromFirestore(doc.data(), doc.id))
          .toList();

      print('✅ Found ${consultations.length} consultations for $role: $userId');
      return consultations;
    } catch (e) {
      print('❌ Error fetching consultations: $e');
      throw e;
    }
  }

  // Get psychologist availability and modality
  Future<Map<String, dynamic>> getPsychologistAvailability(
    String psychologistId,
  ) async {
    try {
      print('🔍 Fetching availability for psychologist: $psychologistId');

      final doc = await _firestore
          .collection(psychologistsCollection)
          .doc(psychologistId)
          .get();

      if (!doc.exists) {
        throw Exception('Psychologist not found: $psychologistId');
      }

      final data = doc.data()!;
      final availabilityData = <String, dynamic>{
        'availability': data['availability'],
        'modality': data['modality'],
      };

      print('✅ Retrieved availability and modality for psychologist: $psychologistId');
      return availabilityData;
    } catch (e) {
      print('❌ Error fetching psychologist availability: $e');
      throw e;
    }
  }


  // File Upload
  Future<String> uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final fileSize = await file.length();
    // Diagnostic info to help debug 404 / session termination issues
    try {
      final bucketFromOptions = _storage.app.options.storageBucket;
      print('🔎 FirebaseStorage configured bucket (from FirebaseOptions): $bucketFromOptions');
    } catch (e) {
      print('🔎 Could not read storage bucket from FirebaseOptions: $e');
    }
    try {
      print('🔎 Storage reference fullPath: ${ref.fullPath}');
    } catch (e) {
      print('🔎 Could not read ref.fullPath: $e');
    }
    print('⬆️ Starting upload to [$path] size=${fileSize} bytes');

    const int maxAttempts = 2; // initial try + 1 retry
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Provide explicit metadata to avoid a null Pigeon metadata object in the Android plugin
        String contentType = 'application/octet-stream';
        final lower = file.path.toLowerCase();
        if (lower.endsWith('.png')) {
          contentType = 'image/png';
        } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (lower.endsWith('.webp')) {
          contentType = 'image/webp';
        }
        final metadata = SettableMetadata(contentType: contentType);

        // Decide whether to use putData (non-resumable) or putFile (resumable).
        // If configured to force putData on Android, use putData from the first attempt.
        bool usePutData = attempt > 1;
        try {
          if (forcePutDataOnAndroid && Platform.isAndroid) {
            usePutData = true;
          }
        } catch (_) {}
        if (usePutData) {
          print('⬆️ Attempting upload via putData fallback for $path (attempt $attempt)');
        }
        final UploadTask uploadTask = usePutData
            ? ref.putData(await file.readAsBytes(), metadata)
            : ref.putFile(file, metadata);

        // Log progress
        StreamSubscription? sub;
        try {
          sub = uploadTask.snapshotEvents.listen((snapshot) {
            final total = snapshot.totalBytes == 0 ? fileSize : snapshot.totalBytes;
            final progress = total > 0 ? (snapshot.bytesTransferred / total) * 100.0 : 0.0;
            print('⬆️ Upload progress [$path] (attempt $attempt/$maxAttempts): ${progress.toStringAsFixed(1)}% state=${snapshot.state} transferred=${snapshot.bytesTransferred}/$total');
          }, onError: (err) {
            print('⚠️ Upload snapshot stream error for $path (attempt $attempt): $err');
          });

          // Wait for completion
          final snapshot = await uploadTask.whenComplete(() {});
          await sub.cancel();

          final url = await snapshot.ref.getDownloadURL();
          print('✅ Upload finished for [$path] (attempt $attempt), url=$url');
          return url;
        } catch (e, st) {
          print('⚠️ Upload encountered an error while waiting for completion (attempt $attempt): $e\n$st');

          // If the task shows success despite the channel error, try to read the URL directly
          try {
              if (uploadTask.snapshot.state == TaskState.success) {
                final url = await ref.getDownloadURL();
                print('✅ Upload completed (stream failed) for [$path] (attempt $attempt), url=$url');
                final s = sub;
                if (s != null) await s.cancel();
                return url;
              }
          } catch (e2, st2) {
            print('⚠️ Failed to recover URL after stream error (attempt $attempt): $e2\n$st2');
          }

          final s2 = sub;
          if (s2 != null) await s2.cancel();
          // if not last attempt, retry after a short delay
          if (attempt < maxAttempts) {
            print('↩️ Retrying upload to $path (next attempt ${attempt + 1}/$maxAttempts)');
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          // Do not rethrow here; allow REST fallback to run after SDK attempts fail.
          print('⚠️ SDK upload attempts exhausted for $path — will try REST fallback');
          break;
        }
      } catch (e, st) {
        print('❌ Error uploading file to $path (attempt $attempt): $e\n$st');
        // If this is a Firebase Storage exception, try to extract more details
        try {
          if (e is FirebaseException) {
            print('🔔 FirebaseException code=${e.code} message=${e.message}');
          }
        } catch (_) {}
        if (attempt < maxAttempts) {
          print('↩️ Retrying upload to $path (next attempt ${attempt + 1}/$maxAttempts)');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        // Do not rethrow here to allow REST fallback below to execute.
        print('⚠️ Final SDK attempt failed for $path — will fall back to REST upload');
        break;
      }
    }

    // After SDK attempts failed, try a non-resumable REST upload as a last resort.
    try {
      String contentType = 'application/octet-stream';
      final lower = file.path.toLowerCase();
      if (lower.endsWith('.png')) {
        contentType = 'image/png';
      } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (lower.endsWith('.webp')) {
        contentType = 'image/webp';
      }

      print('🔁 Trying REST fallback upload for $path with contentType=$contentType');
      final restSuccess = await _uploadViaSimpleRest(file, path, contentType);
      if (restSuccess) {
        try {
          final url = await _storage.ref().child(path).getDownloadURL();
          print('✅ REST fallback upload finished, url=$url');
          return url;
        } catch (e, st) {
          print('⚠️ Could not get download URL after REST upload: $e\n$st');
        }
      }
    } catch (e, st) {
      print('⚠️ REST fallback attempt failed: $e\n$st');
    }

    throw Exception('Failed to upload file to $path after $maxAttempts attempts');
  }

  // Non-resumable REST fallback using Firebase Storage JSON API (uploadType=media)
  Future<bool> _uploadViaSimpleRest(File file, String path, String contentType) async {
    try {
      final bucket = _storage.app.options.storageBucket;
      if (bucket == null || bucket.isEmpty) {
        print('⚠️ _uploadViaSimpleRest: storageBucket is not configured');
        return false;
      }

  // Refresh token to increase chance the token is valid for REST call
  final idToken = await _auth.currentUser?.getIdToken(true);
      if (idToken == null) {
        print('⚠️ _uploadViaSimpleRest: user is not authenticated (no idToken)');
        return false;
      }
  final uriPrimary = Uri.parse('https://firebasestorage.googleapis.com/v0/b/$bucket/o?uploadType=media&name=${Uri.encodeComponent(path)}');
  print('🔁 Attempting non-resumable REST upload to $uriPrimary');

      final bytes = await file.readAsBytes();
  final httpClient = HttpClient();
  final request = await httpClient.postUrl(uriPrimary);
      request.headers.set('Authorization', 'Bearer $idToken');
      request.headers.set('Content-Type', contentType);
      request.add(bytes);
      final response = await request.close().timeout(Duration(seconds: 30));
      final body = await utf8.decodeStream(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ REST upload succeeded: ${response.statusCode} body=$body');
        return true;
      }

      // If primary returned 404 Not Found, try an alternate bucket naming pattern used by GCS
      if (response.statusCode == 404 && bucket.contains('.firebasestorage.app')) {
        final altBucket = bucket.replaceAll('.firebasestorage.app', '.appspot.com');
        final uriAlt = Uri.parse('https://firebasestorage.googleapis.com/v0/b/$altBucket/o?uploadType=media&name=${Uri.encodeComponent(path)}');
        print('🔁 Primary REST upload returned 404; trying alternate bucket name: $uriAlt');

        // retry with same bytes
        final httpClient2 = HttpClient();
        final request2 = await httpClient2.postUrl(uriAlt);
        request2.headers.set('Authorization', 'Bearer $idToken');
        request2.headers.set('Content-Type', contentType);
        request2.add(bytes);
        final response2 = await request2.close().timeout(Duration(seconds: 30));
        final body2 = await utf8.decodeStream(response2);
        if (response2.statusCode >= 200 && response2.statusCode < 300) {
          print('✅ REST upload (alt bucket) succeeded: ${response2.statusCode} body=$body2');
          return true;
        } else {
          print('❌ REST upload (alt bucket) failed: status=${response2.statusCode} body=$body2');
          return false;
        }
      }

      print('❌ REST upload failed: status=${response.statusCode} body=$body');
      return false;
    } catch (e, st) {
      print('❌ _uploadViaSimpleRest error: $e\n$st');
      return false;
    }
  }

  Future<String> uploadProfilePicture(File file, String userId) async {
    return uploadFile(file, 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}');
  }

  // Diagnostic helper: upload a small byte array to Storage to isolate upload/session issues
  Future<String?> testUploadBytes() async {
    final path = 'debug_uploads/test_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);
    print('🔧 Running testUploadBytes to path: $path');
    try {
      print('🔎 FirebaseStorage configured bucket (from FirebaseOptions): ${_storage.app.options.storageBucket}');
    } catch (e) {
      print('🔎 Could not read storage bucket from FirebaseOptions: $e');
    }
    try {
      print('🔎 Storage reference fullPath: ${ref.fullPath}');
    } catch (e) {
      print('🔎 Could not read ref.fullPath: $e');
    }

    // Small test payload
    final bytes = Uint8List.fromList(List<int>.generate(1024, (i) => i % 256));
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    try {
      final task = ref.putData(bytes, metadata);
      final snapshot = await task.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      print('✅ testUploadBytes succeeded: url=$url');
      return url;
    } catch (e, st) {
      print('❌ testUploadBytes failed: $e\n$st');
      try {
        if (e is FirebaseException) print('🔔 FirebaseException code=${e.code} message=${e.message}');
      } catch (_) {}
      return null;
    }
  }

  // Search Users
  Future<List<Map<String, dynamic>>> searchUsersByTags(List<String> tags) async {
    try {
      final query = await _firestore
          .collection(usersCollection)
          .where('tags', arrayContainsAny: tags)
          .get();
      
      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      throw e;
    }
  }

  // Real-time data streams
  Stream<DocumentSnapshot> getUserProfileStream(String userId) {
    return _guardedStream<DocumentSnapshot>(
      _firestore.collection(usersCollection).doc(userId).snapshots(),
      'userProfile:$userId',
    );
  }

  Stream<QuerySnapshot> getChatsStream(String userId) {
    return _guardedStream<QuerySnapshot>(
      _firestore
          .collection(chatsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      'chats:$userId',
    );
  }

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _guardedStream<QuerySnapshot>(
      _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      'messages:$chatId',
    );
  }

  // Chat functionality
  Future<String> createChat(List<String> participants) async {
    try {
      final chatDoc = await _firestore.collection(chatsCollection).add({
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });
      return chatDoc.id;
    } catch (e) {
      print('Error creating chat: $e');
      throw e;
    }
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> messageData) async {
    try {
      await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .add({
        ...messageData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat's last message
      await _firestore.collection(chatsCollection).doc(chatId).update({
        'lastMessage': messageData['text'] ?? '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  // Mood tracking functionality
  Future<void> saveMoodData(MoodData moodData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user');

      await _firestore
          .collection('mood_tracking')
          .doc('${userId}_${DateTime.now().millisecondsSinceEpoch}')
          .set(moodData.toMap());
    } catch (e) {
      print('Error saving mood data: $e');
      throw e;
    }
  }

  Future<MoodData?> getTodayMood(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final query = await _firestore
          .collection('mood_tracking')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('date', isLessThan: endOfDay.millisecondsSinceEpoch)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return MoodData.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting today mood: $e');
      return null;
    }
  }

  // Question and response functionality
  Future<void> saveQuestion(ReflectiveQuestion question) async {
    try {
      await _firestore
          .collection('questions')
          .doc(question.id)
          .set(question.toMap());
    } catch (e) {
      print('Error saving question: $e');
      throw e;
    }
  }

  Future<void> saveQuestionResponse(QuestionResponse response) async {
    try {
      await _firestore
          .collection('question_responses')
          .doc('${response.userId}_${response.questionId}')
          .set(response.toMap());
    } catch (e) {
      print('Error saving question response: $e');
      throw e;
    }
  }

  Future<List<ReflectiveQuestion>> getAllQuestions() async {
    try {
      final query = await _firestore
          .collection('questions')
          .orderBy('createdAt')
          .get();

      return query.docs
          .map((doc) => ReflectiveQuestion.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all questions: $e');
      return [];
    }
  }

  // Método para obter apenas as perguntas criadas hoje
  Future<List<ReflectiveQuestion>> getTodayQuestions() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('🔍 Getting questions from ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');

      final query = await _firestore
          .collection('questions')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('createdAt', isLessThan: endOfDay.millisecondsSinceEpoch)
          .orderBy('createdAt')
          .get();

      final questions = query.docs
          .map((doc) => ReflectiveQuestion.fromMap(doc.data()))
          .toList();
      
      print('📊 Found ${questions.length} questions for today');
      return questions;
    } catch (e) {
      print('❌ Error getting today questions: $e');
      return [];
    }
  }

  Future<List<QuestionResponse>> getUserResponses(String userId) async {
    try {
      final query = await _firestore
          .collection('question_responses')
          .where('userId', isEqualTo: userId)
          .get();

      return query.docs
          .map((doc) => QuestionResponse.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user responses: $e');
      return [];
    }
  }

  // Método para obter apenas as respostas do usuário para hoje
  Future<List<QuestionResponse>> getTodayUserResponses(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('🔍 Getting user responses from ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');

      try {
        final query = await _firestore
            .collection('question_responses')
            .where('userId', isEqualTo: userId)
            .where('answeredAt', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
            .where('answeredAt', isLessThan: endOfDay.millisecondsSinceEpoch)
            .get();

        final responses = query.docs
            .map((doc) => QuestionResponse.fromMap(doc.data()))
            .toList();
        print('📊 Found ${responses.length} responses for today (via composite query)');
        return responses;
      } catch (e) {
        // Firestore may require a composite index for this compound query.
        print('⚠️ Composite query failed (maybe missing index): $e');
        print('⚠️ Falling back to single-field query + client-side filter');

        // Fallback: query only by userId and filter locally by answeredAt range
        final fallbackQuery = await _firestore
            .collection('question_responses')
            .where('userId', isEqualTo: userId)
            .get();

    final responses = fallbackQuery.docs
      .map((doc) => QuestionResponse.fromMap(doc.data()))
      .where((r) => !r.answeredAt.isBefore(startOfDay) && r.answeredAt.isBefore(endOfDay))
      .toList();

        print('📊 Found ${responses.length} responses for today (via fallback)');
        return responses;
      }
    } catch (e) {
      print('❌ Error getting today user responses: $e');
      return [];
    }
  }

  // Compatibility calculation
  Future<double> calculateCompatibility(String userId1, String userId2) async {
    try {
      print('🔄 Calculating compatibility between $userId1 and $userId2');
      
      final responses1 = await getUserResponses(userId1);
      final responses2 = await getUserResponses(userId2);

      print('📝 User1 responses: ${responses1.length}, User2 responses: ${responses2.length}');

      // Se qualquer um dos usuários não tem respostas, usar compatibilidade base
      if (responses1.isEmpty || responses2.isEmpty) {
        print('⚠️ One or both users have no responses, using base compatibility');
        return _calculateBaseCompatibility(userId1, userId2);
      }

      // Criar mapas de respostas
      final responses1Map = <String, bool>{};
      final responses2Map = <String, bool>{};

      for (var response in responses1) {
        responses1Map[response.questionId] = response.answer;
      }

      for (var response in responses2) {
        responses2Map[response.questionId] = response.answer;
      }

      // Encontrar perguntas em comum
      final commonQuestions = responses1Map.keys.toSet()
          .intersection(responses2Map.keys.toSet());

      print('🤝 Common questions: ${commonQuestions.length}');

      if (commonQuestions.isEmpty) {
        print('⚠️ No common questions found, using base compatibility');
        return _calculateBaseCompatibility(userId1, userId2);
      }

      // Calcular compatibilidade baseada nas respostas comuns
      int matches = 0;
      for (String questionId in commonQuestions) {
        if (responses1Map[questionId] == responses2Map[questionId]) {
          matches++;
        }
      }

      final compatibility = (matches / commonQuestions.length) * 100;
      print('🎯 Final compatibility: $compatibility% ($matches/${commonQuestions.length} matches)');

      // Garantir pelo menos 20% de compatibilidade se há alguma interação
      return compatibility < 20 ? 20.0 : compatibility;
    } catch (e) {
      print('❌ Error calculating compatibility: $e');
      return 0.0;
    }
  }

  double _calculateBaseCompatibility(String userId1, String userId2) {
    // Compatibilidade base entre 30-70% baseada nos IDs dos usuários
    final combined = (userId1 + userId2).hashCode.abs();
    final baseScore = 30 + (combined % 41); // Entre 30-70%
    print('🎲 Base compatibility: $baseScore%');
    return baseScore.toDouble();
  }

  Future<List<Map<String, dynamic>>> getCompatibleUsers(String userId, {int limit = 10}) async {
    try {
      print('🔍 Looking for compatible users for: $userId');
      
      // Busca todos os usuários (sem filtro de ID para evitar problemas de permissão)
      final usersQuery = await _firestore
          .collection(usersCollection)
          .limit(50) // Limite para performance
          .get();

      print('📊 Found ${usersQuery.docs.length} total users');

      final compatibleUsers = <Map<String, dynamic>>[];

      for (var userDoc in usersQuery.docs) {
        // Pula o próprio usuário
        if (userDoc.id == userId) {
          print('⏭️ Skipping own user: ${userDoc.id}');
          continue;
        }
        
        print('🧮 Calculating compatibility with: ${userDoc.id}');
        final compatibility = await calculateCompatibility(userId, userDoc.id);
        print('💯 Compatibility score: $compatibility%');
        
        if (compatibility > 0) {
          final userData = userDoc.data();
          userData['id'] = userDoc.id;
          userData['compatibility'] = compatibility;
          
          // Debug: verificar se as imagens estão sendo carregadas
          print('📸 User ${userData['name']} image data:');
          print('   - profileImageUrl: ${userData['profileImageUrl']}');
          print('   - profileImageBase64: ${userData['profileImageBase64'] != null ? 'Present (${userData['profileImageBase64'].toString().length} chars)' : 'null'}');
          
          compatibleUsers.add(userData);
          print('✅ Added compatible user: ${userData['name']} (${compatibility.toInt()}%)');
          // Persist lightweight compatibility snapshot to reduce need for re-calculation
          try {
            final docId = _compatibilityDocId(userId, userDoc.id);
            await _firestore.collection('compatibilities').doc(docId).set({
              'userA': userId,
              'userB': userDoc.id,
              'compatibility': compatibility,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
          } catch (e) {
            print('⚠️ Error saving compatibility snapshot: $e');
          }
        }
      }

      print('🎯 Total compatible users found: ${compatibleUsers.length}');

      // Ordena por compatibilidade
      compatibleUsers.sort((a, b) => 
          (b['compatibility'] as double).compareTo(a['compatibility'] as double));

      return compatibleUsers.take(limit).toList();
    } catch (e) {
      print('❌ Error getting compatible users: $e');
      return [];
    }
  }

  // Helper to create deterministic doc id for a pair of users (order-independent)
  String _compatibilityDocId(String a, String b) {
    final parts = [a, b]..sort();
    return '${parts[0]}_${parts[1]}';
  }

  /// Delete questions created before [cutoff] (millisecondsSinceEpoch)
  Future<void> deleteQuestionsBefore(int cutoffMillis) async {
    try {
      const int pageSize = 400; // keep below 500 write limit
      while (true) {
        final query = await _firestore
            .collection('questions')
            .where('createdAt', isLessThan: cutoffMillis)
            .orderBy('createdAt')
            .limit(pageSize)
            .get();

        if (query.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (var doc in query.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('🧹 Deleted ${query.docs.length} old questions batch before $cutoffMillis');

        // Small pause to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      print('❌ Error deleting old questions: $e');
    }
  }

  /// Delete question responses answered before [cutoff] (millisecondsSinceEpoch)
  Future<void> deleteResponsesBefore(int cutoffMillis) async {
    try {
      const int pageSize = 400; // keep below 500 write limit
      while (true) {
        final query = await _firestore
            .collection('question_responses')
            .where('answeredAt', isLessThan: cutoffMillis)
            .orderBy('answeredAt')
            .limit(pageSize)
            .get();

        if (query.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (var doc in query.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('🧹 Deleted ${query.docs.length} old question responses batch before $cutoffMillis');

        // Small pause to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      print('❌ Error deleting old question responses: $e');
    }
  }

  // ==================== CHAT METHODS ====================

  // Garantir que o usuário atual existe no Firestore
  Future<void> ensureCurrentUserExists() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return;
      }

      final userId = user.uid;
      print('🔍 Checking if user exists in Firestore: $userId');
      
      final userDoc = await _firestore.collection(usersCollection).doc(userId).get();
      
      if (!userDoc.exists) {
        print('🆕 User not found in Firestore, creating profile...');
        
        // Criar perfil básico do usuário
        final userData = {
          'id': userId,
          'name': user.displayName ?? user.email?.split('@').first ?? 'Usuário',
          'email': user.email ?? '',
          'profileImageUrl': user.photoURL,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'isOnline': true,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
          'age': null,
          'city': '',
          'bio': '',
          'goal': '',
          'tags_string': '',
        };
        
        await _firestore.collection(usersCollection).doc(userId).set(userData);
        print('✅ User profile created in Firestore');
      } else {
        print('✅ User already exists in Firestore');
      }
    } catch (e) {
      print('❌ Error ensuring user exists: $e');
    }
  }

  // Buscar ou criar conversa entre dois usuários
  Future<String?> getOrCreateConversation(String userId1, String userId2) async {
    try {
      print('🔍 Attempting to create conversation between:');
      print('   User1: $userId1');
      print('   User2: $userId2');
      
      // Garantir que o usuário atual existe no Firestore
      await ensureCurrentUserExists();
      
      // Criar ID único para a conversa (sempre o mesmo independente da ordem)
      final participants = [userId1, userId2]..sort();
      final conversationId = '${participants[0]}_${participants[1]}';
      print('   Conversation ID: $conversationId');

      final conversationRef = _firestore
          .collection(conversationsCollection)
          .doc(conversationId);

      final conversation = await conversationRef.get();

      if (!conversation.exists) {
        print('🆕 Conversation does not exist, creating new one...');
        
        // Buscar dados dos usuários
        print('🔍 Looking for user1 data...');
        final user1Data = await _firestore.collection(usersCollection).doc(userId1).get();
        print('   User1 exists: ${user1Data.exists}');
        if (user1Data.exists) {
          print('   User1 data: ${user1Data.data()}');
        }
        
        print('🔍 Looking for user2 data...');
        final user2Data = await _firestore.collection(usersCollection).doc(userId2).get();
        print('   User2 exists: ${user2Data.exists}');
        if (user2Data.exists) {
          print('   User2 data: ${user2Data.data()}');
        }

        if (!user1Data.exists || !user2Data.exists) {
          print('❌ One or both users not found');
          print('   User1 ($userId1) exists: ${user1Data.exists}');
          print('   User2 ($userId2) exists: ${user2Data.exists}');
          return null;
        }

        // Criar nova conversa
        final now = DateTime.now();
        final conversationData = {
          'id': conversationId,
          'participants': [userId1, userId2],
          'createdAt': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
          'lastMessage': null,
          'unreadCount_$userId1': 0,
          'unreadCount_$userId2': 0,
          'isArchived_$userId1': false,
          'isArchived_$userId2': false,
          'isBlocked': false,
          'blockedBy': null,
        };

        await conversationRef.set(conversationData);
        print('✅ New conversation created: $conversationId');
        
        // Verificar se foi criada corretamente
        final createdConversation = await conversationRef.get();
        if (createdConversation.exists) {
          print('✅ Conversation verified: ${createdConversation.data()}');
        } else {
          print('❌ Conversation not found after creation');
        }
      } else {
        print('✅ Conversation already exists: $conversationId');
      }

      return conversationId;
    } catch (e) {
      print('❌ Error getting/creating conversation: $e');
      return null;
    }
  }

  // Enviar mensagem de chat
  Future<void> sendChatMessage(ChatMessage message) async {
    try {
      print('🚀 Starting sendChatMessage process...');
      print('   Message ID: ${message.id}');
      print('   Conversation ID: ${message.conversationId}');
      print('   Content: ${message.content}');
      print('   Sender: ${message.senderId}');
      print('   Receiver: ${message.receiverId}');
      
      // 1. Primeiro, vamos garantir que a conversa existe
      final conversationRef = _firestore
          .collection(conversationsCollection)
          .doc(message.conversationId);
      
      final conversationDoc = await conversationRef.get();
      
      if (!conversationDoc.exists) {
        print('🆕 Conversation does not exist, creating it...');
        
        // Buscar dados dos usuários
        final senderDoc = await _firestore.collection(usersCollection).doc(message.senderId).get();
        final receiverDoc = await _firestore.collection(usersCollection).doc(message.receiverId).get();
        
        if (!senderDoc.exists || !receiverDoc.exists) {
          throw Exception('One or both users not found');
        }
        
        // Criar nova conversa
        final now = DateTime.now();
        final conversationData = {
          'id': message.conversationId,
          'participants': [message.senderId, message.receiverId],
          'createdAt': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
          'lastMessage': null,
          'unreadCount_${message.senderId}': 0,
          'unreadCount_${message.receiverId}': 0,
          'isArchived_${message.senderId}': false,
          'isArchived_${message.receiverId}': false,
          'isBlocked': false,
          'blockedBy': null,
        };
        
        await conversationRef.set(conversationData);
        print('✅ Conversation created successfully');
      }
      
      // 2. Salvar a mensagem
      final messageRef = _firestore
          .collection(conversationsCollection)
          .doc(message.conversationId)
          .collection('messages')
          .doc(message.id);

      print('📝 Writing message to Firestore...');
      await messageRef.set(message.toFirestore());
      print('✅ Message written successfully');

      // 3. Atualizar conversa com última mensagem
      print('🔄 Updating conversation with last message...');
      await conversationRef.update({
        'lastMessage': {
          'id': message.id,
          'content': message.content,
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
          'type': message.type.toString().split('.').last,
          'isRead': false,
          'isDelivered': true,
        },
        'updatedAt': message.timestamp.millisecondsSinceEpoch,
        'unreadCount_${message.receiverId}': FieldValue.increment(1),
      });
      print('✅ Conversation updated successfully');

      // 4. Criar notificação para o receptor
      print('🔔 Creating notification...');
      await _createMessageNotification(message);
      print('✅ Notification created successfully');

      print('🎉 Message sent successfully - ALL STEPS COMPLETED');
    } catch (e) {
      print('❌ Error sending message: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      throw e;
    }
  }

  // Escutar mensagens em tempo real
  void listenToMessages(String conversationId, Function(ChatMessage) onMessage) {
    _firestore
        .collection(conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final message = ChatMessage.fromFirestore(change.doc.data()!);
          onMessage(message);
        }
      }
    }, onError: (err) {
      print('❌ listenToMessages stream error for $conversationId: $err');
    });
  }

  // Buscar mensagens da conversa
  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 50}) async {
    try {
      final messagesQuery = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final messages = messagesQuery.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data()))
          .toList();

      return messages.reversed.toList(); // Retorna em ordem cronológica
    } catch (e) {
      print('❌ Error getting messages: $e');
      return [];
    }
  }

  // Marcar mensagens como lidas
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // Atualizar contador de não lidas na conversa
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .update({
        'unreadCount_$userId': 0,
      });

      // Marcar mensagens como lidas
      final batch = _firestore.batch();
      final unreadMessages = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // Buscar conversas do usuário
  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      final conversationsQuery = await _firestore
          .collection(conversationsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final conversations = <Conversation>[];

      for (var doc in conversationsQuery.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');

        if (otherUserId.isNotEmpty) {
          // Buscar dados do outro usuário
          final otherUserDoc = await _firestore
              .collection(usersCollection)
              .doc(otherUserId)
              .get();

          if (otherUserDoc.exists) {
            final otherUserData = otherUserDoc.data()!;
            
            // Construir lastMessage se existir
            ChatMessage? lastMessage;
            final lastMessageData = data['lastMessage'];
            if (lastMessageData != null) {
              lastMessage = ChatMessage(
                id: lastMessageData['id'] ?? '',
                conversationId: doc.id,
                senderId: lastMessageData['senderId'] ?? '',
                receiverId: lastMessageData['receiverId'] ?? '',
                content: lastMessageData['content'] ?? '',
                type: _parseMessageType(lastMessageData['type']),
                timestamp: DateTime.fromMillisecondsSinceEpoch(lastMessageData['timestamp'] ?? 0),
                isRead: lastMessageData['isRead'] ?? false,
                isDelivered: lastMessageData['isDelivered'] ?? true,
              );
            }
            
            final conversation = Conversation(
              id: doc.id,
              userId1: participants[0],
              userId2: participants[1],
              otherUser: ChatUser(
                id: otherUserId,
                name: otherUserData['name'] ?? 'Usuário',
                profileImageUrl: otherUserData['profileImageUrl'],
                isOnline: otherUserData['isOnline'] ?? false,
                lastSeen: otherUserData['lastSeen'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(otherUserData['lastSeen'])
                    : null,
              ),
              lastMessage: lastMessage,
              createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
              unreadCount: data['unreadCount_$userId'] ?? 0,
              isArchived: data['isArchived_$userId'] ?? false,
              isBlocked: data['isBlocked'] ?? false,
            );

            conversations.add(conversation);
          }
        }
      }

      return conversations;
    } catch (e) {
      print('❌ Error getting user conversations: $e');
      return [];
    }
  }

  // Helper method to parse message type
  MessageType _parseMessageType(String? typeString) {
    switch (typeString) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  // Escutar conversas do usuário em tempo real
  void listenToUserConversations(String userId, Function(List<Conversation>) onConversationsUpdate) {
    try {
      print('👂 Setting up real-time listener for conversations');
    _firestore
      .collection(conversationsCollection)
      .where('participants', arrayContains: userId)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .listen((snapshot) async {
        
        print('🔄 Conversations snapshot received: ${snapshot.docs.length} conversations');
        final conversations = <Conversation>[];

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');

            if (otherUserId.isNotEmpty) {
              // Buscar dados do outro usuário
              final otherUserDoc = await _firestore
                  .collection(usersCollection)
                  .doc(otherUserId)
                  .get();

              if (otherUserDoc.exists) {
                final otherUserData = otherUserDoc.data()!;
                
                // Construir lastMessage se existir
                ChatMessage? lastMessage;
                final lastMessageData = data['lastMessage'];
                if (lastMessageData != null) {
                  lastMessage = ChatMessage(
                    id: lastMessageData['id'] ?? '',
                    conversationId: doc.id,
                    senderId: lastMessageData['senderId'] ?? '',
                    receiverId: lastMessageData['receiverId'] ?? '',
                    content: lastMessageData['content'] ?? '',
                    type: _parseMessageType(lastMessageData['type']),
                    timestamp: DateTime.fromMillisecondsSinceEpoch(lastMessageData['timestamp'] ?? 0),
                    isRead: lastMessageData['isRead'] ?? false,
                    isDelivered: lastMessageData['isDelivered'] ?? true,
                  );
                }
                
                final conversation = Conversation(
                  id: doc.id,
                  userId1: participants[0],
                  userId2: participants[1],
                  otherUser: ChatUser(
                    id: otherUserId,
                    name: otherUserData['name'] ?? 'Usuário',
                    profileImageUrl: otherUserData['profileImageUrl'],
                    profileImageBase64: otherUserData['profileImageBase64'],
                    isOnline: otherUserData['isOnline'] ?? false,
                    lastSeen: otherUserData['lastSeen'] != null
                        ? DateTime.fromMillisecondsSinceEpoch(otherUserData['lastSeen'])
                        : null,
                  ),
                  lastMessage: lastMessage,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
                  updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
                  unreadCount: data['unreadCount_$userId'] ?? 0,
                  isArchived: data['isArchived_$userId'] ?? false,
                  isBlocked: data['isBlocked'] ?? false,
                );

                conversations.add(conversation);
              }
            }
          } catch (e) {
            print('❌ Error processing conversation ${doc.id}: $e');
          }
        }

        print('✅ Processed ${conversations.length} conversations successfully');
        onConversationsUpdate(conversations);
      }, onError: (err) {
        print('❌ listenToUserConversations stream error for $userId: $err');
      });
    } catch (e) {
      print('❌ Error setting up conversations listener: $e');
    }
  }

  // Marcar todas as conversas como lidas
  Future<void> markAllConversationsAsRead(String userId) async {
    try {
      final conversationsQuery = await _firestore
          .collection(conversationsCollection)
          .where('participants', arrayContains: userId)
          .get();

      final batch = _firestore.batch();

      for (var doc in conversationsQuery.docs) {
        batch.update(doc.reference, {
          'unreadCount_$userId': 0,
        });
      }

      await batch.commit();
      print('✅ All conversations marked as read');
    } catch (e) {
      print('❌ Error marking all conversations as read: $e');
    }
  }

  // Limpar conversa
  Future<void> clearConversation(String conversationId) async {
    try {
      // Deletar todas as mensagens
      final messagesQuery = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();

      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Atualizar conversa
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .update({
        'lastMessage': null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Conversation cleared');
    } catch (e) {
      print('❌ Error clearing conversation: $e');
      throw e;
    }
  }

  // Bloquear usuário
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      // Criar ID da conversa
      final participants = [userId, blockedUserId]..sort();
      final conversationId = '${participants[0]}_${participants[1]}';

      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .update({
        'isBlocked': true,
        'blockedBy': userId,
        'blockedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Adicionar à lista de bloqueados do usuário
      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });

      print('✅ User blocked successfully');
    } catch (e) {
      print('❌ Error blocking user: $e');
      throw e;
    }
  }

  // Método privado para criar notificação de mensagem
  Future<void> _createMessageNotification(ChatMessage message) async {
    try {
      print('🔔 Creating notification for message: ${message.id}');
      
      // Buscar dados do remetente
      final senderDoc = await _firestore
          .collection(usersCollection)
          .doc(message.senderId)
          .get();

      if (!senderDoc.exists) {
        print('❌ Sender not found: ${message.senderId}');
        return;
      }

      final senderData = senderDoc.data()!;
      final senderName = senderData['name'] ?? 'Usuário';
      
      print('📝 Creating notification from $senderName to ${message.receiverId}');
      
      // Criar notificação com ID único para evitar duplicatas
      final notificationId = '${message.id}_notification';
      
      await _firestore
          .collection(usersCollection)
          .doc(message.receiverId)
          .collection('notifications')
          .doc(notificationId)
          .set({
        'type': 'message',
        'conversationId': message.conversationId,
        'senderId': message.senderId,
        'senderName': senderName,
        'content': message.content,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'isRead': false,
        'messageId': message.id, // Referência para a mensagem
      });

      print('✅ Message notification created with ID: $notificationId');
    } catch (e) {
      print('❌ Error creating message notification: $e');
      print('❌ Message details: ${message.toFirestore()}');
    }
  }

  // HISTÓRICO DE CONVERSAS
  
  // Buscar histórico de conversas do usuário
  Future<List<ConversationHistory>> getUserConversationHistory(String userId) async {
    try {
      print('🔍 Getting conversation history for user: $userId');
      
      final conversationsQuery = await _firestore
          .collection(conversationsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final conversations = <ConversationHistory>[];
      
      for (var doc in conversationsQuery.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
        
        if (otherUserId.isEmpty) continue;
        
        // Buscar dados do outro usuário
        final otherUserDoc = await _firestore
            .collection(usersCollection)
            .doc(otherUserId)
            .get();
            
        if (!otherUserDoc.exists) continue;
        
  final otherUserData = otherUserDoc.data()!;

  // Criar objeto de histórico com dados do outro usuário
  final enrichedData = Map<String, dynamic>.from(data);
  enrichedData['otherUserName'] = otherUserData['name'] ?? 'Usuário';
  // Prefer explicit profile image URL fields but also carry base64 fallback when present
  enrichedData['otherUserAvatar'] = otherUserData['profileImageUrl'] ?? otherUserData['profilePicture'];
  enrichedData['otherUserAvatarBase64'] = otherUserData['profileImageBase64'];
  enrichedData['otherUserOnline'] = otherUserData['isOnline'] ?? false;
        
        final conversation = ConversationHistory.fromFirestore(enrichedData, userId);
        conversations.add(conversation);
      }
      
      print('📋 Found ${conversations.length} conversations');
      return conversations;
      
    } catch (e) {
      print('❌ Error getting conversation history: $e');
      return [];
    }
  }

  // Escutar mudanças no histórico de conversas em tempo real
  Stream<List<ConversationHistory>> listenToConversationHistory(String userId) {
    return _guardedStream<List<ConversationHistory>>(
      _firestore
          .collection(conversationsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
      final conversations = <ConversationHistory>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
        
        if (otherUserId.isEmpty) continue;
        
        try {
          // Buscar dados do outro usuário
          final otherUserDoc = await _firestore
              .collection(usersCollection)
              .doc(otherUserId)
              .get();
              
          if (!otherUserDoc.exists) continue;
          
          final otherUserData = otherUserDoc.data()!;

          // Criar objeto de histórico com dados do outro usuário
          final enrichedData = Map<String, dynamic>.from(data);
          enrichedData['otherUserName'] = otherUserData['name'] ?? 'Usuário';
          enrichedData['otherUserAvatar'] = otherUserData['profileImageUrl'] ?? otherUserData['profilePicture'];
          enrichedData['otherUserAvatarBase64'] = otherUserData['profileImageBase64'];
          enrichedData['otherUserOnline'] = otherUserData['isOnline'] ?? false;
          
          final conversation = ConversationHistory.fromFirestore(enrichedData, userId);
          conversations.add(conversation);
        } catch (e) {
          print('❌ Error processing conversation: $e');
        }
      }
      
  return conversations;
      }),
      'conversationHistory:$userId',
    );
  }
}
