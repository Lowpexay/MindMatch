importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAybtUIEKLhMCn1ouUCKjy2gw_GliKeFoI',
  appId: '1:1033810261503:web:edc5bba01b1501549fe3ca',
  messagingSenderId: '1033810261503',
  projectId: 'mindmatch-ba671',
  authDomain: 'mindmatch-ba671.firebaseapp.com',
  storageBucket: 'mindmatch-ba671.appspot.com',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || payload.data?.title || 'MindMatch';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || 'Nova mensagem',
    icon: 'icons/Icon-192.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
