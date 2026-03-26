// Firebase Cloud Messaging Service Worker — Portal App
// This file must be served from the root of your web app (web/ directory maps to /).
//
// IMPORTANT: Replace the firebaseConfig below with your actual Firebase web config.
// Firebase Console → Project Settings → Your Apps → Web app → firebaseConfig

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// REPLACE with your actual Firebase web config
firebase.initializeApp({
  apiKey: 'AIzaSyCeX1XoNNCCqLlRalpjGmHEHwmkza23Nl0',
  authDomain: 'walldot-portal-73856.firebaseapp.com',
  projectId: 'walldot-portal-73856',
  storageBucket: 'walldot-portal-73856.firebasestorage.app',
  messagingSenderId: '27851314244',
  appId: '1:27851314244:web:63e66501eb4b5c07df9811',
});

const messaging = firebase.messaging();

// Handle background messages (app not in foreground)
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'Walldot Portal';
  const body = payload.notification?.body ?? '';
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
  });
});
