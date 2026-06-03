// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getFirestore } from "firebase/firestore";

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyCvMQIj-HOjvE6_yq-jnn_gQDYFtuyJSmM",
  authDomain: "fast-lit.firebaseapp.com",
  projectId: "fast-lit",
  storageBucket: "fast-lit.firebasestorage.app",
  messagingSenderId: "759289841259",
  appId: "1:759289841259:web:dbcee4ba27b6a4cc36532e",
  measurementId: "G-5GZ3D7T4ZM"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const db = getFirestore(app);

export {
    db
};
