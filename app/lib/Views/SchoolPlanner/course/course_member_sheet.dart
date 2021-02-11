import 'package:bloc/bloc_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:schulplaner8/Data/plannerdatabase.dart';
import 'package:schulplaner8/Helper/EasyWidget.dart';
import 'package:schulplaner8/Helper/MyCloudFunctions.dart';
import 'package:schulplaner8/Helper/PermissionManagement.dart';
import 'package:schulplaner8/Helper/helper_data.dart';
import 'package:schulplaner8/Helper/helper_views.dart';
import 'package:schulplaner_functions/schulplaner_functions.dart';
import 'package:schulplaner_models/schulplaner_models.dart';
import 'package:schulplaner8/models/member.dart';
import 'package:schulplaner8/models/user.dart';
import 'package:schulplaner_translations/schulplaner_translations.dart';
import 'package:schulplaner_widgets/schulplaner_common.dart';
import 'package:schulplaner_widgets/schulplaner_dialogs.dart';

class CourseMemberSheet extends SchulplanerSheet {
  final String courseId;
  final MemberData memberData;
  final UserProfile userProfile;
  final PlannerDatabase database;
  CourseMemberSheet({
    required this.courseId,
    required this.database,
    required this.memberData,
    required this.userProfile,
  });
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MemberData>(
      stream: database.courseinfo
          .getItemStream(courseId)
          .map((settings) => settings?.membersData[memberData.id]),
      builder: (context, snapshot) {
        final memberitem = snapshot.data ?? memberData;
        return getFlexList([
          ListTile(
            title: Text(getString(context).admin),
            trailing: memberitem.role.isAdminOrOwner()
                ? Icon(
                    Icons.done,
                    color: Colors.green,
                  )
                : null,
            onTap: !memberitem.role.isAdminOrOwner()
                ? () {
                    _setMemberType(
                      context,
                      memberitem,
                      MemberRole.admin,
                      courseId,
                    );
                  }
                : null,
          ),
          ListTile(
            title: Text(bothlang(context, de: 'Ersteller', en: 'Creator')),
            trailing: memberitem.role == MemberRole.creator
                ? Icon(
                    Icons.done,
                    color: Colors.green,
                  )
                : null,
            onTap: memberitem.role != MemberRole.creator
                ? () {
                    _setMemberType(
                      context,
                      memberitem,
                      MemberRole.creator,
                      courseId,
                    );
                  }
                : null,
          ),
          ListTile(
            title: Text(getString(context).default_),
            trailing: memberitem.role == MemberRole.standard
                ? Icon(
                    Icons.done,
                    color: Colors.green,
                  )
                : null,
            onTap: memberitem.role != MemberRole.standard
                ? () {
                    _setMemberType(
                      context,
                      memberitem,
                      MemberRole.standard,
                      courseId,
                    );
                  }
                : null,
          ),
          ButtonBar(
            children: <Widget>[
              RButton(
                  text: getString(context).remove,
                  onTap: () {
                    _tapRemoveMember(context);
                  },
                  iconData: Icons.remove_circle_outline)
            ],
          )
        ]);
      },
    );
  }

  Future<void> _tapRemoveMember(BuildContext context) async {
    final confirmResult = await ConfirmDialog(
      title:
          '${userProfile?.name ?? getString(context).anonymoususer} ${getString(context).remove}',
      message: '',
    ).show<bool>(context);
    if (confirmResult == true) {
      var notifier = showResultStateSheet(context: context);
      final hasPermission = await requestPermissionCourse(
        database: database,
        category: PermissionAccessType.membermanagement,
        courseid: courseId,
      );
      if (hasPermission == true) {
        notifier.value = ResultItem(
          loading: true,
          text: bothlang(context,
              de: 'Authentifiziert, bitte waren...',
              en: 'Authenticated, please wait...'),
        );
        final removeResult = await _removeMemberFromCourse(context);

        if (removeResult == true) {
          notifier.value = ResultItem(
              loading: null,
              text: getString(context).done,
              iconData: Icons.done,
              color: Colors.green);
          await Future.delayed(Duration(milliseconds: 500)).then((value) {
            Navigator.pop(context);
            popNavigatorBy(context, text: 'memberid');
          });
        } else {
          notifier.value = ResultItem(
              loading: null,
              text: getString(context).failed,
              iconData: Icons.error,
              color: Colors.red);
        }
      } else {
        notifier.value = ResultItem(
            loading: false,
            text: getString(context).nopermissionretrieved,
            iconData: Icons.lock,
            color: Colors.red);
      }
    }
  }

  Future<bool> _removeMemberFromCourse(BuildContext context) async {
    final schulplanerFunctions =
        BlocProvider.of<SchulplanerFunctionsBloc>(context);
    final result = await schulplanerFunctions.removeMemberFromGroup(
      groupId: courseId,
      groupType: GroupType.course,
      memberId: memberData.id,
      myMemberId: database.getMemberId(),
    );
    return result.hasData && result.data == true;
  }

  void _setMemberType(
    BuildContext context,
    MemberData member,
    MemberRole newRole,
    String courseID,
  ) {
    if (member.role == MemberRole.owner) return;
    var notifier = showResultStateSheet(context: context);
    requestPermissionCourse(
            database: database,
            category: PermissionAccessType.membermanagement,
            courseid: courseID)
        .then((result) {
      if (result == true) {
        notifier.value = ResultItem(
          loading: true,
          text: bothlang(context,
              de: 'Authentifiziert, bitte waren...',
              en: 'Authenticated, please wait...'),
        );
        changeMemberTypeUserCourse(
                courseID: courseID, memberID: member.id, newRole: newRole)
            .then((newresult) {
          if (result == true) {
            notifier.value = ResultItem(
                loading: null,
                text: getString(context).done,
                iconData: Icons.done,
                color: Colors.green);
            Future.delayed(Duration(milliseconds: 500)).then((value) {
              Navigator.pop(context);
            });
          } else {
            notifier.value = ResultItem(
                loading: null,
                text: getString(context).failed,
                iconData: Icons.error,
                color: Colors.red);
          }
        });
      } else {
        notifier.value = ResultItem(
            loading: false,
            text: getString(context).nopermissionretrieved,
            iconData: Icons.lock,
            color: Colors.red);
      }
    });
  }
}
