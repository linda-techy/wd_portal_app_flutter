// Firebase Cloud Messaging Service Worker — Portal App
// This file must be served from the root of your web app (web/ directory maps to /).
//
// IMPORTANT: Replace the firebaseConfig below with your actual Firebase web config.
// Firebase Console → Project Settings → Your Apps → Web app → firebaseConfig

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// REPLACE with your actual Firebase web config
firebase.initializeApp({
  apiKey: 'REPLACE_WITH_WEB_API_KEY',
  authDomain: 'REPLACE_WITH_PROJECT_ID.firebaseapp.com',
  projectId: 'REPLACE_WITH_PROJECT_ID',
  storageBucket: 'REPLACE_WITH_PROJECT_ID.appspot.com',
  messagingSenderId: 'REPLACE_WITH_SENDER_ID',
  appId: 'REPLACE_WITH_WEB_APP_ID',
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
