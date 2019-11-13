import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class RefreshListView extends StatefulWidget {
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final List<Widget> children;

  const RefreshListView(
      {Key key,
      this.controller,
      this.onRefresh,
      this.children,
      this.onLoadMore})
      : super(key: key);

  @override
  _RefreshListViewState createState() => _RefreshListViewState();
}

class _RefreshListViewState extends State<RefreshListView> {
  bool isLoadingMore = false;
  ScrollController controller;

  _loadMore() async {
    if (widget.onLoadMore != null) {
      await widget.onLoadMore();
      isLoadingMore = false;

      if (mounted) setState(() {});
    }

    return;
  }

  @override
  void initState() {
    controller = widget.controller ?? ScrollController();
    controller.addListener(() {
      if (!isLoadingMore &&
          controller.position.pixels > controller.position.maxScrollExtent) {
        _loadMore();
        isLoadingMore = true;

        if (mounted) setState(() {});

        Future.delayed(Duration(seconds: 15))
          ..whenComplete(() {
            isLoadingMore = false;

            if (mounted) setState(() {});
          });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.controller,
      physics: AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        CupertinoSliverRefreshControl(
          refreshIndicatorExtent: 80,
          refreshTriggerPullDistance: 120,
          onRefresh: widget.onRefresh,
          builder: (context, mode, _, __, ___) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: CupertinoActivityIndicator(
              radius: 12,
            ),
          ),
        ),
        ...widget.children.map((child) => SliverToBoxAdapter(
              child: child,
            )),
        if (isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: CupertinoActivityIndicator(),
            ),
          )
      ],
    );
  }
}
