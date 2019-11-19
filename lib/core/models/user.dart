import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class UserProfile {
  final String uid;
  final User user;
  final UserStats stats;
  final String bio;
//  final bool isPrivate;
  final bool isVerified;

  UserProfile({
    @required this.uid,
    @required this.user,
    @required this.stats,
    @required this.bio,
//    @required this.isPrivate,
    @required this.isVerified,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final user = User(
      isPrivate: doc['is_private'] ?? false,
      uid: doc.documentID,
      username: doc['username'] ?? '',
      displayName: doc['display_name'] ?? '',
      photoUrl: doc['photo_url'] ?? '',
    );

    final stats = UserStats(
      postCount: doc['post_count'] ?? 0,
      followerCount: doc['follower_count'] ?? 0,
      followingCount: doc['following_count'] ?? 0,
    );

    return UserProfile(
      uid: doc.documentID,
      user: user,
      stats: stats,
      bio: doc['bio'] ?? '',
//      isPrivate: doc['is_private'] ?? false,
      isVerified: doc['is_verified'] ?? false,
    );
  }

  UserProfile copyWith({
    String username,
    String displayName,
    String email,
    String photoUrl,
    String bio,
    UserStats stats,
    bool isPrivate,
    bool isVerified,
    int postCount,
    int followerCount,
    int followingCount,
    bool hasRequestedFollow,
  }) {
    return UserProfile(
      uid: this.uid,
      user: this.user.copyWith(
            username: username,
            displayName: displayName,
            photoUrl: photoUrl,
            isPrivate: isPrivate,
            hasRequestedFollow: hasRequestedFollow,
          ),
//      isPrivate: isPrivate ?? false,
      isVerified: isVerified ?? false,
      bio: bio ?? this.bio,
      stats: this.stats.copyWith(
                postCount: postCount ?? this.stats.postCount,
                followerCount: followerCount ?? this.stats.followerCount,
                followingCount: followingCount ?? this.stats.followingCount,
              ) ??
          this.stats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'user': user.toMap(),
      'username': user.username,
      'display_name': user.displayName,
      'photo_url': user.photoUrl,
      'bio': bio,
      'is_verified': isVerified,
//      'is_private': isPrivate,
      'post_count': stats.postCount,
      'follower_count': stats.followerCount,
      'following_count': stats.followingCount,
    };
  }
}

enum UStoryState { seen, unseen, none }

///For when there is no need to display any other data
///other than user's username and photo
class User {
  final String uid;
  final String username;
  final String displayName;
  final String photoUrl;
  final bool isPrivate;
  final UStoryState storyState;
  final bool hasRequestedFollow;

  User({
    @required this.uid,
    @required this.username,
    @required this.displayName,
    @required this.photoUrl,
    @required this.isPrivate,
    this.storyState,
    this.hasRequestedFollow,
  });

  factory User.fromDoc(DocumentSnapshot doc) {
    final data = doc.data;
    if (data == null || doc.documentID == 'list') return null;
    return User(
      isPrivate: data['is_private'] ?? false,
      uid: doc.documentID,
      username: data['username'] ?? '',
      displayName: data['display_name'] ?? '',
      photoUrl: data['photo_url'] ?? '',
    );
  }

  factory User.fromMap(Map map, {String uid}) {
    return User(
      isPrivate: map['is_private'] ?? false,
      uid: uid ?? map['uid'] ?? '',
      username: map['username'] ?? '',
      displayName: map['display_name'] ?? '',
      photoUrl: map['photo_url'] ?? '',
    );
  }

  Map toMap() {
    return {
      'is_private': isPrivate,
      'uid': uid,
      'username': username,
      'display_name': displayName,
      'photo_url': photoUrl,
    };
  }

  User copyWith({
    String username,
    String displayName,
    String email,
    String photoUrl,
    bool isPrivate,
    storyState,
    hasRequestedFollow,
  }) {
    return User(
      isPrivate: isPrivate ?? this.isPrivate,
      uid: this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      storyState: storyState ?? this.storyState,
      hasRequestedFollow: hasRequestedFollow ?? this.hasRequestedFollow,
    );
  }
}

//class User {
//  final String uid;
//  final String username;
//  final String displayName;
//  final String email;
//  final String photoUrl;
//  final String bio;
//  final bool isPrivate;
//  final bool isVerified;
//
//  final UserStats stats;
//
//  User(
//      {this.isPrivate,
//      this.isVerified,
//      this.uid,
//      this.username,
//      this.displayName,
//      this.email,
//      this.photoUrl,
//      this.bio,
//      this.stats});
//
//  factory User.empty() {
//    return User(
//      isPrivate: false,
//      isVerified: false,
//      uid: '',
//      username: '',
//      displayName: '',
//      email: '',
//      photoUrl: '',
//      bio: '',
//      stats: null,
//    );
//  }
//
//  Map<String, dynamic> toMap() {
//    return {
//      'uid': uid,
//      'is_verified': isVerified,
//      'username': username,
//      'display_name': displayName,
//      'photo_url': photoUrl,
//    };
//  }
//
//  factory User.fromMap(Map map) {
//    return User(
//      isPrivate: map['is_private'] ?? false,
//      isVerified: map['is_verified'] ?? false,
//      uid: map['uid'] ?? '',
//      username: map['username'] ?? '',
//      displayName: map['display_name'] ?? '',
//      email: map['email'] ?? '',
//      photoUrl: map['photo_url'] ?? '',
//      bio: map['bio'] ?? '',
//    );
//  }
//
//  factory User.fromDoc({DocumentSnapshot snap, UserStats stats}) {
//    final data = snap.data;
//
//    if (data != null) {
//      return User(
//        uid: snap.documentID,
//        isPrivate: snap['is_private'] ?? false,
//        isVerified: snap['is_verified'] ?? false,
//        username: data['username'] ?? '',
//        displayName: data['display_name'] ?? '',
//        email: data['email'] ?? '',
//        photoUrl: data['photo_url'] ?? '',
//        bio: data['bio'] ?? '',
//      );
//    } else
//      return null;
//  }
//
//  User copyWith({
//    String uid,
//    String username,
//    String displayName,
//    String email,
//    String photoUrl,
//    String bio,
//    UserStats stats,
//    bool isPrivate,
//    bool isVerified,
//  }) {
//    return User(
//      isPrivate: isPrivate ?? false,
//      isVerified: isVerified ?? false,
//      uid: uid ?? this.uid,
//      username: username ?? this.username,
//      displayName: displayName ?? this.displayName,
//      email: email ?? this.email,
//      photoUrl: photoUrl ?? this.photoUrl,
//      bio: bio ?? this.bio,
//      stats: stats ?? this.stats,
//    );
//  }
//}

class UserStats {
  final int postCount;
  final int followerCount;
  final int followingCount;

  UserStats({
    @required this.postCount,
    @required this.followerCount,
    @required this.followingCount,
  });

  factory UserStats.empty() {
    return UserStats(postCount: 0, followerCount: 0, followingCount: 0);
  }

  factory UserStats.fromDoc(DocumentSnapshot doc) {
    if (doc.data == null) {
      return UserStats(postCount: 0, followerCount: 0, followingCount: 0);
    }
    final data = doc.data;
    return UserStats(
      postCount: data['post_count'] ?? 0,
      followerCount: data['follower_count'] ?? 0,
      followingCount: data['following_count'] ?? 0,
    );
  }

  factory UserStats.fromSnap(DataSnapshot snap) {
    if (snap.value == null) {
      return UserStats(postCount: 0, followerCount: 0, followingCount: 0);
    }
    final data = snap.value;
    return UserStats(
      postCount: data['post_count'] ?? 0,
      followerCount: data['follower_count'] ?? 0,
      followingCount: data['following_count'] ?? 0,
    );
  }

  UserStats copyWith({int postCount, int followerCount, int followingCount}) {
    return UserStats(
      postCount: postCount ?? this.postCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  UserStats incrementFollowerCount() {
    return this.copyWith(followerCount: this.followerCount + 1);
  }

  UserStats decrementFollowerCount() {
    return this.copyWith(followerCount: this.followerCount - 1);
  }
}
