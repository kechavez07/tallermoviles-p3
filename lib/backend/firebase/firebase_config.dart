import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBacwhGZmaKAsd7IWO0_YY0PNFRLpkluDc",
            authDomain: "tallermoviles-a493f.firebaseapp.com",
            projectId: "tallermoviles-a493f",
            storageBucket: "tallermoviles-a493f.firebasestorage.app",
            messagingSenderId: "665776516833",
            appId: "1:665776516833:web:f9c52779f52cd082e4d1a0",
            measurementId: "G-X0YR0KB6N6"));
  } else {
    await Firebase.initializeApp();
  }
}
