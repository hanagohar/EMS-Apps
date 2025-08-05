import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management_app/View/Auth/login_and_signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;
  DocumentSnapshot? myDocument;

  var allUsers = <DocumentSnapshot>[].obs;
  var filteredUsers = <DocumentSnapshot>[].obs;
  var allEvents = <DocumentSnapshot>[].obs;
  var filteredEvents = <DocumentSnapshot>[].obs;
  var joinedEvents = <DocumentSnapshot>[].obs;

  var isEventsLoading = false.obs;
  var isUsersLoading = false.obs;
  var isMessageSending = false.obs;

  // ✅ إرسال رسالة للمحادثة وتحديث آخر رسالة
  sendMessageToFirebase({
    Map<String, dynamic>? data,
    String? lastMessage,
    String? groupId,
  }) async {
    isMessageSending(true);

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(groupId)
        .collection('chatroom')
        .add(data!);

    await FirebaseFirestore.instance.collection('chats').doc(groupId).set({
      'lastMessage': lastMessage,
      'groupId': groupId,
      'group': groupId!.split('-'),
    }, SetOptions(merge: true));

    isMessageSending(false);
  }

  // ✅ إنشاء إشعار في قاعدة البيانات
  createNotification(String recUid) {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(recUid)
        .collection('myNotifications')
        .add({
      'message': "Send you a message.",
      'image': (myDocument!.data() as Map<String, dynamic>)['image'],
      'name': "${myDocument!.get('first')} ${myDocument!.get('last')}",
      'time': DateTime.now(),
    });
  }

  // ✅ استرجاع بيانات المستخدم الحالي
  getMyDocument() {
    var user = auth.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((event) {
        myDocument = event;
      });
    } else {
      Future.delayed(Duration.zero, () {
        Get.to(() => LoginAndSignupScreen());
      });
    }
  }

  // ✅ إنشاء حدث
  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    bool isCompleted = false;

    await FirebaseFirestore.instance.collection('events').add(eventData).then(
      (value) {
        isCompleted = true;
        Get.snackbar(
          'Event Uploaded',
          'Event is uploaded successfully.',
          colorText: Colors.white,
          backgroundColor: Colors.blue,
        );
      },
    ).catchError((e) {
      isCompleted = false;
    });

    return isCompleted;
  }

  @override
  void onInit() {
    super.onInit();
    getMyDocument();
    getUsers();
    getEvents();
  }

  // ✅ استرجاع جميع المستخدمين
  getUsers() {
    isUsersLoading(true);
    FirebaseFirestore.instance.collection('users').snapshots().listen((event) {
      allUsers.value = event.docs;
      filteredUsers.assignAll(allUsers); // ✅ بدون .value
      isUsersLoading(false);
    });
  }

  // ✅ استرجاع جميع الأحداث
  getEvents() {
    isEventsLoading(true);

    FirebaseFirestore.instance.collection('events').snapshots().listen((event) {
      allEvents.assignAll(event.docs);
      filteredEvents.assignAll(event.docs);

      joinedEvents.assignAll(allEvents.where((e) {
        List joinedIds = e.get('joined');
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return false;
        return joinedIds.contains(currentUser.uid);
      }).toList());

      isEventsLoading(false);
    });
  }
}
