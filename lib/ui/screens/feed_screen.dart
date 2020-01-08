import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutes/core/models/post.dart';
import 'package:nutes/core/models/story.dart';
import 'package:nutes/core/models/user.dart';
import 'package:nutes/core/services/events.dart';
import 'package:nutes/core/services/firestore_service.dart';
import 'package:nutes/core/services/local_cache.dart';
import 'package:nutes/core/services/repository.dart';
import 'package:nutes/ui/shared/comment_overlay.dart';
import 'package:nutes/ui/shared/loading_indicator.dart';
import 'package:nutes/ui/shared/refresh_list_view.dart';
import 'package:nutes/ui/shared/story_avatar.dart';
import 'package:nutes/ui/widgets/empty_view.dart';
import 'package:nutes/ui/widgets/feed_app_bar.dart';
import 'package:nutes/ui/shared/post_list.dart';
import 'package:nutes/ui/widgets/inline_stories.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback onCreatePressed;
  final VoidCallback onDM;
  final VoidCallback onDoodleStart;
  final VoidCallback onDoodleEnd;
  final ScrollController scrollController;
//  final UserProfile profile;

  FeedScreen({
    Key key,
    this.onCreatePressed,
    this.onDM,
    this.scrollController,
    this.onDoodleStart,
    this.onDoodleEnd,
//    @required this.profile,
//      this.onAddStoryPressed,
  }) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin, RouteAware {
  final routeObserver = RouteObserver();

  Stream<QuerySnapshot> myStoryStream;

  final cache = LocalCache.instance;

//  UserProfile profile;

  List<Post> posts = [];

  bool isFetchingPosts = false;

  ///Comment overlay fields
  String commentingTo;
  bool showCommentTextField = false;
  final commentController = TextEditingController();
  final commentFocusNode = FocusNode();

  UserStory myStory;

  List<UserStory> followingsStories = [];

  DocumentSnapshot startAfter;

  User auth = FirestoreService.ath.user;

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context));
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    print('did push next: home');
    cache.homeIsFirst = false;
    super.didPushNext();
  }

  @override
  void didPopNext() {
    print('did pop next: home');

    cache.homeIsFirst = true;
    super.didPopNext();
  }

  @override
  void initState() {
    myStory = UserStory(
      story: Story.empty(),
      uploader: auth,
      lastTimestamp: null,
    );
    _getInitialPosts();
    _getMyStory();
    _getStoriesOfFollowings();

    eventBus.on().listen((event) {
      print(event);
    });

    eventBus.on<UserProfileChangedEvent>().listen((event) {
      print(event.profile.user.urls.small);
      BotToast.showText(text: 'profile change ${event.profile.user.username}');
      setState(() {
        auth = event.profile.user;
      });
    });

    eventBus.on<UserFollowEvent>().listen((event) {
      print('Bus Followed ${event.user.username}');
      BotToast.showText(text: 'Followed ${event.user.username}');
    });
    super.initState();
  }

  bool headerRefreshIndicatorVisible = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final topPadding = MediaQuery.of(context).padding.top;

    final profile = Provider.of<UserProfile>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: FeedAppBar(
        onCreatePressed: widget.onCreatePressed,
        onLogoutPressed: () => Repo.logout(),
        onDM: widget.onDM,
      ),
      body: profile == null
          ? LoadingIndicator()
          : CommentOverlay(
              onSend: (text) {
                if (commentingTo == null) return;

                final comment = Repo.createComment(
                  text: text,
                  postId: commentingTo,
                );

                Repo.uploadComment(postId: commentingTo, comment: comment);
                final post =
                    posts.firstWhere((post) => post.id == commentingTo);

                if (mounted)
                  setState(() {
                    post.topComments.add(comment);
                    showCommentTextField = false;
                    commentingTo = null;
                  });
              },
              controller: commentController,
              focusNode: commentFocusNode,
              showTextField: showCommentTextField,
              onScroll: () {
//                print('on scroll');
                setState(() {
                  commentingTo = null;
                  showCommentTextField = false;
                });
                return;
              },
              child: RefreshListView(
//          physics: isDoodling
//              ? NeverScrollableScrollPhysics()
//              : BouncingScrollPhysics(),
                controller: widget.scrollController,
                onRefresh: () {
                  _getStoriesOfFollowings();
                  return _getInitialPosts();
                },
                onLoadMore: _getMorePosts,
                children: <Widget>[
                  Container(
                    height: 112,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.white,
                    child: myStory == null
                        ? Center(child: LoadingIndicator())
                        : Row(
                            children: <Widget>[
                              Visibility(
                                visible: myStory.story.moments.isEmpty,
                                child: StoryAvatar(
                                  isOwner: true,
//                            user: User.empty(),

                                  ///TODO: fix this bug causing app to not load
                                  user: profile.user,
                                  isEmpty: true,
                                  onTap: widget.onCreatePressed,
                                  onLongPress: widget.onCreatePressed,
                                ),
                              ),
                              InlineStories(
                                userStories: [
                                      if (myStory.story.moments.isNotEmpty)
                                        myStory
                                    ] +
                                    followingsStories,
//                          onCreateStory: widget.onCreatePressed,
                                topPadding: topPadding,
                              ),
                            ],
                          ),
                  ),
                  Divider(),
                  isFetchingPosts
                      ? LoadingIndicator()
                      : posts.isEmpty
                          ? EmptyView(
                              title: 'No posts to show',
                              subtitle:
                                  'Start following users to see their posts',
                            )
                          : PostListView(
                              posts: posts,
                              onUnfollow: (uid) {
                                print('onUnfollow $uid');
                                return setState(() {
                                  posts = List<Post>.from(posts)
                                    ..removeWhere(
                                        (post) => post.owner.uid == uid);
                                });
                              },
                              onAddComment: (postId) {
                                print('add comment for post $postId');
                                setState(() {
                                  commentingTo = postId;
                                  showCommentTextField = !showCommentTextField;
                                });
                                FocusScope.of(context)
                                    .requestFocus(commentFocusNode);
                                return;
                              },
                              onDoodleStart: _onDoodleStart,
                              onDoodleEnd: _onDoodleEnd,
                            ),
                  SizedBox(height: 64),
                ],
              ),
            ),
    );
  }

  Future<void> _getInitialPosts() async {
    if (mounted)
      setState(() {
//        startAfter = null;
        isFetchingPosts = true;
      });

    final result = await Repo.getFeed();

    if (mounted)
      setState(() {
        posts = result.posts;
        startAfter = result.startAfter;
        isFetchingPosts = false;
      });
  }

  Future<void> _getMorePosts() async {
    final result = await Repo.getFeed(startAfter: startAfter);

    if (mounted)
      setState(() {
        posts = posts + result.posts;
        startAfter = result.startAfter;
      });
  }

  ///TODO: sort the user stories
  Future<List<UserStory>> _getStoriesOfFollowings() async {
    final result = await Repo.getStoriesOfFollowings();
    setState(() {
      followingsStories = result;
    });
  }

  @override
  bool get wantKeepAlive => true;

  void _getMyStory() async {
    myStoryStream = Repo.myStoryStream();

    ///Listen to changes to my story
    myStoryStream.listen((event) {
      final moments = event.documentChanges
          .map((dc) => Moment.fromDoc(dc.document))
          .toList();

      myStory.story.moments.addAll(moments);

      if (moments.isNotEmpty && mounted)
        setState(() {
          myStory = myStory.copyWith(
              lastTimestamp: moments[moments.length - 1].timestamp);
        });
    });
  }

  bool isDoodling = false;
  VoidCallback _onDoodleStart() {
    print('feed on doodle');
    setState(() {
      isDoodling = true;
    });
    return widget.onDoodleStart;
  }

  VoidCallback _onDoodleEnd() {
    setState(() {
      isDoodling = false;
    });
    return widget.onDoodleEnd;
  }
}
