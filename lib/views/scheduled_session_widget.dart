import 'dart:developer';

import 'package:devfest_florida_app/data/session.dart';
import 'package:devfest_florida_app/data/speaker.dart';
import 'package:devfest_florida_app/data/timeslot.dart';
import 'package:devfest_florida_app/main.dart';
import 'package:devfest_florida_app/views/session_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduledSessionWidget extends StatefulWidget {
  final TimeSlot timeSlot;

  ScheduledSessionWidget({this.timeSlot});

  @override
  ScheduledSessionWidgetState createState() =>
      new ScheduledSessionWidgetState(timeSlot: timeSlot);
}

class ScheduledSessionWidgetState extends State<ScheduledSessionWidget> {
  ScheduledSessionWidgetState({this.timeSlot});

  final TimeSlot timeSlot;
  final sessionWidgets = <Widget>[];
  final sessionRows = <Widget>[];

  @override
  Widget build(BuildContext context) {
    if (mSessions.length > 0 && mSpeakers.length > 0) {
      return new Container(
        decoration: new BoxDecoration(
            border: new Border(
          bottom: new BorderSide(color: kColorDivider, width: .5),
        )),
        child: new Container(child: buildRow()),
      );
    } else {
      return new Container(child: new Text(''));
    }
  }

  Widget buildRow() {
    List<Widget> sessionCards = <Widget>[];
    sessionWidgets.clear();
    timeSlot.sessions.forEach((sessionIter) {
      Session session;
      if (sessionIter is List) {
        session =
            mSessions[sessionIter[0].toString()]; // ignore: undefined_operator
      } else if (sessionIter is int) {
        session = mSessions[sessionIter.toString()];
      }
      if (session != null) {
        Widget sessionCard = buildSessionCard(timeSlot, session);
        sessionCards.add(sessionCard);
      }
    });

    Widget titleSection = new Container(
      margin: const EdgeInsets.only(
          left: 4.0,
          right: kMaterialPadding,
          top: kMaterialPadding,
          bottom: kMaterialPadding),
      child: new Row(
        children: [
          new Column(children: <Widget>[
            new Container(
                margin:
                    const EdgeInsets.only(right: 4.0, top: kMaterialPadding),
                child: new SizedBox(
                    width: 70.0,
                    child: new Text(
                      sessionTimePeriod(timeSlot),
                      textAlign: TextAlign.right,
                      style: new TextStyle(fontSize: 15.0),
                    ))),
          ]),
          new Expanded(
              child: new Column(
            children: sessionCards,
          )),
        ],
      ),
    );

    return titleSection;
  }

  Widget buildSessionCard(TimeSlot timeslot, Session session) {
    var roomOrTrack = "";
    if (session != null && (session.room != "" && session.room != null)) {
      roomOrTrack = session.room;
    } else if (session != null &&
        (session.track != "" && session.track != null)) {
      roomOrTrack = session.track;
    }

    bool sessionOver = false;
    Color cardBackground = const Color(0xffffffff);
    if (timeslot.endDate.compareTo(new DateTime.now()) < 0) {
      cardBackground = const Color(0xffdee0e2);
      sessionOver = true;
    }

    String speakerString = getSpeakerNames(session);
    Widget card = new Card(
        child: new GestureDetector(
      onTap: () {
        mSelectedSession = session;
        mSelectedTimeSlot = timeSlot;
        Timeline.instantSync('Start Transition', arguments: <String, String>{
          'from': '/',
          'to': SessionDetailsWidget.routeName
        });
        Navigator.pushNamed(context, SessionDetailsWidget.routeName);
      },
      child: new Container(
        padding: new EdgeInsets.only(
            left: kPadding, top: kMaterialPadding, right: kPadding),
        color: cardBackground,
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Row(children: <Widget>[
              new Expanded(
                child: new Text(
                  session.title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: new TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
            new Padding(padding: const EdgeInsets.only(top: kMaterialPadding)),
            new Row(children: <Widget>[
              new Flexible(
                child: new Text(speakerString,
                    overflow: TextOverflow.ellipsis,
                    style: new TextStyle(fontSize: 15.0, color: kColorText,)),
              ),
            ]),
            new Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Row(
                      children: sessionCardRowWidgets(
                          roomOrTrack, session, sessionOver)),
                ]),
          ],
        ),
      ),
    ));
    return card;
  }

  List<Widget> sessionCardRowWidgets(
      String roomOrTrack, Session session, bool isSessionOver) {
    List<Widget> cardWidgets = <Widget>[];
    cardWidgets.add(new Icon(
      Icons.location_on,
      color: kColorText,
    ));

    cardWidgets.add(new Expanded(
      child: new Text(
        roomOrTrack,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: new TextStyle(color: kColorText, fontSize: 14.0),
      ),
    ));

    if (!isSessionOver) {
      cardWidgets.add(new IconButton(
        alignment: FractionalOffset.centerRight,
        padding: const EdgeInsets.all(0.0),
        onPressed: () {
          toggleFavorite(session);
        },
        icon: session.isFavorite
            ? new Icon(Icons.star, color: kColorFavoriteOn)
            : new Icon(Icons.star_border, color: kColorFavoriteOff),
      ));
    }

    if (isSessionOver) {
      cardWidgets.add(new IconButton(
        alignment: FractionalOffset.centerRight,
        padding: const EdgeInsets.all(0.0),
        onPressed: () {
        },
        icon: new Icon(Icons.star, color: session.isFavorite ? kColorFavoriteOn : const Color.fromARGB(0, 0, 0, 0))
      ));
    }

    return cardWidgets;
  }

  String getSpeakerNames(Session session) {
    var speakerString = "";
    if (session != null && session.speakers != null) {
      session.speakers.forEach((speakerId) {
        if (mSpeakers.containsKey(speakerId.toString())) {
          Speaker speaker = mSpeakers[speakerId.toString()];
          speakerString += speaker.name + ", ";
        }
      });
      if (speakerString.length > 2) {
        speakerString = speakerString.substring(0, speakerString.length - 2);
      }
    }
    return speakerString;
  }

  String sessionTimePeriod(TimeSlot timeSlot) {
    return formatter.format(timeSlot.startDate).replaceAll(" ", "") +
        "\nto\n" +
        formatter.format(timeSlot.endDate).replaceAll(" ", "");
  }

  void toggleFavorite(Session session) {
    setState(() {
      if (session.isFavorite) {
        session.isFavorite = false;
        _unFavorite(session);
      } else {
        session.isFavorite = true;
        _favorite(session);
      }
    });
  }

  _unFavorite(Session session) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteSessions = prefs.getStringList("favoriteSessions");
    if (favoriteSessions == null) {
      return;
    }
    if (favoriteSessions.contains(session.sessionId)) {
      List<String> updatedFavorites = new List<String>();
      updatedFavorites.addAll(favoriteSessions);
      updatedFavorites.remove(session.sessionId);
      prefs.setStringList("favoriteSessions", updatedFavorites);
      prefs.commit();
    }
  }

  _favorite(Session session) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteSessions = prefs.getStringList("favoriteSessions");
    if (favoriteSessions == null) {
      favoriteSessions = <String>[];
    }
    if (!favoriteSessions.contains(session.sessionId)) {
      List<String> updatedFavorites = new List<String>();
      updatedFavorites.addAll(favoriteSessions);
      updatedFavorites.add(session.sessionId);
      prefs.setStringList("favoriteSessions", updatedFavorites);
      prefs.commit();
    }
  }
}
