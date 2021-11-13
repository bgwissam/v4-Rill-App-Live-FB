import 'package:flutter/material.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  //Controller
  DatabaseService db = DatabaseService();

  //variables
  int numberOfViews = 0;
  int numberOfComments = 0;
  int numberOfFollowers = 0;
  int numberOfLikes = 0;

  bool _viewNumer = false;
  bool _commentNumber = false;
  bool _followerNumber = false;
  bool _likeNumber = false;
  var size;

  @override
  void initState() {
    super.initState();
    _getTotalViews();
    _getTotalComment();
    _getNumberOfFolloers();
    _getNumberOfLikes();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Container(
      height: size.height,
      width: size.width,
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildAnalytics(),
      ),
    );
  }

  Widget _buildAnalytics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 45, 0, 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Title
          Text('Profile Analytics',
              style: Theme.of(context).textTheme.headline6),
          //Like container
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListTile(
                    leading: Image.asset(
                      'assets/icons/heart_rill_icon_light.png',
                      color: color_4,
                      height: 30,
                    ),
                    title: _likeNumber
                        ? Text(
                            numberOfLikes.toString().isEmpty
                                ? '0'
                                : numberOfLikes.toString(),
                          )
                        : Container(
                            padding: EdgeInsets.only(right: size.width / 2),
                            height: 8,
                            child: LinearProgressIndicator(
                              backgroundColor: color_6,
                              color: color_4,
                            ),
                          ),
                    subtitle:
                        Text('Number of Likes this week', style: textStyle_21),
                  ),
                ),
                Divider(thickness: 0.4, color: color_14)
              ],
            ),
          ),
          //Followers container
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListTile(
                    leading: Image.asset(
                      'assets/icons/bell_rill_icon.png',
                      color: color_4,
                      height: 30,
                    ),
                    title: _followerNumber
                        ? Text(
                            numberOfFollowers.toString().isEmpty
                                ? '0'
                                : numberOfFollowers.toString(),
                          )
                        : Container(
                            padding: EdgeInsets.only(right: size.width / 2),
                            height: 8,
                            child: LinearProgressIndicator(
                              backgroundColor: color_6,
                              color: color_4,
                            ),
                          ),
                    subtitle:
                        Text('Followers gained this week', style: textStyle_21),
                  ),
                ),
                Divider(thickness: 0.4, color: color_14)
              ],
            ),
          ),
          //Comments container
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListTile(
                    leading: Image.asset(
                      'assets/icons/pop_rill_icon_light.png',
                      color: color_4,
                      height: 30,
                    ),
                    title: _commentNumber
                        ? Text(
                            numberOfComments.toString().isEmpty
                                ? '0'
                                : numberOfComments.toString(),
                          )
                        : Container(
                            padding: EdgeInsets.only(right: size.width / 2),
                            height: 8,
                            child: LinearProgressIndicator(
                              backgroundColor: color_6,
                              color: color_4,
                            ),
                          ),
                    subtitle:
                        Text('Total Comments this week', style: textStyle_21),
                  ),
                ),
                Divider(thickness: 0.4, color: color_14)
              ],
            ),
          ),
          //Views container
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListTile(
                    leading: Image.asset(
                      'assets/icons/eye_rill_icon_light.png',
                      color: color_4,
                      height: 30,
                    ),
                    title: _viewNumer
                        ? Text(
                            numberOfViews.toString().isEmpty
                                ? '0'
                                : numberOfViews.toString(),
                          )
                        : Container(
                            padding: EdgeInsets.only(right: size.width / 2),
                            height: 8,
                            child: LinearProgressIndicator(
                              backgroundColor: color_6,
                              color: color_4,
                            ),
                          ),
                    subtitle: Text('Total views', style: textStyle_21),
                  ),
                ),
                Divider(thickness: 0.4, color: color_14)
              ],
            ),
          ),
          //Reach container
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 30),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListTile(
                    leading: Image.asset(
                      'assets/icons/Graphs_Rill_Icon.png',
                      color: color_4,
                      height: 30,
                    ),
                    title: const Text(
                      '0',
                    ),
                    subtitle: Text('Accounts reached', style: textStyle_21),
                  ),
                ),
                Divider(thickness: 0.4, color: color_14)
              ],
            ),
          ),
          //Top streams
          Text('Top Streams', style: Theme.of(context).textTheme.headline6),
          //List view for top 5 streams
        ],
      ),
    );
  }

  //Will calculate the total views per user
  _getTotalViews() async {
    var result = await db.getUserViewToFiles(userId: widget.userId);
    setState(() {
      numberOfViews = result;
      _viewNumer = true;
    });
  }

  //will caluclate the total number of comments
  _getTotalComment() async {
    var result = await db.getUserImageVideoList(userId: widget.userId);
    setState(() {
      numberOfComments = result;
      _commentNumber = true;
    });
  }

  //will caluclate the number of followers gained
  _getNumberOfFolloers() async {
    var result = await db.getFollowersList(userId: widget.userId);
    setState(() {
      numberOfFollowers = result;
      _followerNumber = true;
    });
  }

  //will calculate the number of like for each user
  _getNumberOfLikes() async {
    var result = await db.getLikesList(userId: widget.userId);
    print('the result: $result');
    setState(() {
      numberOfLikes = result;
      _likeNumber = true;
    });
  }
}
