import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';  // toast message

import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // generated localizations
import 'package:iot_project_demo/data_managers.dart';
import 'package:iot_project_demo/interface_tools.dart' as interface_tools;
import 'package:iot_project_demo/color_themes_presets.dart' as color_themes_presets;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as blue_serial;  // Bluetooth setial (classical bluetooth protocol, RFCOMM)


// General text styles
TextStyle dashboardDefaultTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // default dashboard text style
TextStyle widgetDefaultTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // widget default text style

TextStyle appBarStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);  // dashboard appbar title
TextStyle userNameStyle = dashboardDefaultTextStyle;  // dashboard username
TextStyle emailStyle = const TextStyle(fontSize: 14, color: Colors.orange);  // dashboard emails
TextStyle deviceIdStyle = dashboardDefaultTextStyle;  // dashboard device id
TextStyle scheduleTextStyle = dashboardDefaultTextStyle;  // dashboard schedules widget
TextStyle errorTextStyle = dashboardDefaultTextStyle;  // indicating error messages

TextStyle settingsWidgetTextStyle = widgetDefaultTextStyle;  // settings subtitles
TextStyle settingsWidgetSelectedTextStyle = widgetDefaultTextStyle.copyWith(color: Colors.orange);  // settings values

TextStyle scheduleManagerDateTimeTextStyle = widgetDefaultTextStyle.copyWith(fontSize: 18);  // schedule manager datetime
TextStyle scheduleMagerDialogTextStyle = widgetDefaultTextStyle;  // schedule manger dialog font

TextStyle skinConditionWidgetTitleStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,);
TextStyle skinConditionWidgetDefault = dashboardDefaultTextStyle;

TextStyle deviceConnectionDialogTextStyle = widgetDefaultTextStyle;  // device connection page dialog font
TextStyle deviceManagingDialogTextStyle = widgetDefaultTextStyle;  // device managing page dialog font

// General border radius
Radius generalBorderRadius = const Radius.circular(15);
BorderRadius dashboardCardBorderRadius = BorderRadius.all(generalBorderRadius);

// General data managing module
WeatherDataDownloader weatherDataDownloader = WeatherDataDownloader();  // wether data downloader
ScheduleManager scheduleManager = ScheduleManager();  // download and upload schedule data
SkinConditionManager skinConditionManager = SkinConditionManager();  // download skin condition data


// Toast message method
void showToastMessage(String msg) {
  Fluttertoast.showToast(
    msg: msg,
    backgroundColor: Colors.grey,
    textColor: Colors.white,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
  );
}


/*
 * Main app widget
 *
 * Note:
 *   Theme of the applicaiton is initially defined here
 *   Basically this applicaiton uses named-routes
 *   (Define the name of the route to add pages)
 */

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));

    return MaterialApp(
      // colors and title
      title: 'IoT project demo application',
      theme: Theme.of(context).copyWith(
        colorScheme: color_themes_presets.colorSchemePresets[applicationSettings['themeName']],
      ),

      // application navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/schedules': (context) => const SchedulePage(),
        '/deviceManager': (context) => const DeviceManagingPage(),
        '/deviceManager/deviceConnection': (context) => const DeviceConnectionPage(),
      },

      // application localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}


/*
 * Homepage of the applicaiton
 *   Notify some information (weather, schedules, google account info...)
 */

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isWeatherDataLoaded = false;
  Future<List> currentScheduleData = Future.value([]);
  Future<Map> currentSkinConditionData = Future.value({});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentScheduleData = readSchedule(dateTime2String(DateTime.now()));
    currentSkinConditionData = skinConditionManager.extract(DateTime.now(), monthCnt: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.background,

      body: ScrollConfiguration(
        behavior: interface_tools.GlowRemovedBehavior(),
        child: Container(
          margin: const EdgeInsets.only(left: 15, right: 15),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                expandedHeight: 150.0,
                backgroundColor: Theme.of(context).colorScheme.background,
                elevation: 0.0,
                iconTheme: IconThemeData(color: Theme.of(context).colorScheme.tertiary),

                leading: IconButton(
                  icon: const Icon(Icons.refresh_outlined,),
                  tooltip: AppLocalizations.of(context)!.homePageRefreshTooltip,
                  onPressed: () {
                    setState(() {

                    });
                  },
                ),

                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.settings,),
                    tooltip: AppLocalizations.of(context)!.settingsMenuTitle,
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings').then((value) {
                        setState(() {});
                      });
                    },
                  ),
                ],

                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(AppLocalizations.of(context)!.homePageTitle,
                    style: appBarStyle.copyWith(color: Theme.of(context).colorScheme.tertiary),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  GestureDetector(
                    onTap: () async {
                      if (isLoginActivated()) {
                        await logoutActivation();
                      } else {
                        await loginActivation();
                      }
                      setState(() {});
                    },

                    child: Container(
                      margin: const EdgeInsets.only(top: 15),
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(15),
                            child: applicationSettings['profileImageUrl'] == 'default' ? CircleAvatar(
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ) : CircleAvatar(
                              backgroundImage: NetworkImage(
                                applicationSettings['profileImageUrl']!,
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(applicationSettings['userName'] == 'default' ? AppLocalizations.of(context)!.warningsUserAccountNotAuthenticated : applicationSettings['userName']!, style: userNameStyle),
                              Text(applicationSettings['email'] == 'default' ? 'email@domain.com' : applicationSettings['email']!, style: emailStyle),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/deviceManager').then((value) {
                        setState(() {});
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 15),
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(15),
                            child: CircleAvatar(
                              child: Icon(
                                  Icons.perm_device_info_outlined,
                                  color: Theme.of(context).colorScheme.tertiary
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          Text(applicationSettings['managedDeviceName'] == defaultApplicationSettings['managedDeviceName'] ? AppLocalizations.of(context)!.warningsDeviceNotDetected : applicationSettings['managedDeviceName']!,
                            style: deviceIdStyle,
                          )
                        ],
                      ),
                    ),
                  ),

                  Container(
                    height: 160,
                    margin: const EdgeInsets.only(top: 15),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: dashboardCardBorderRadius,
                    ),
                    child: FutureBuilder(
                        future: weatherDataDownloader.refreshWeather(
                          langCode: AppLocalizations.of(context)!.weatherLangCode,
                          locale: AppLocalizations.of(context)!.fullLocale,
                        ),
                        builder: (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData == false) {
                            isWeatherDataLoaded = false;
                            return Container(
                              alignment: Alignment.center,
                              child: const SizedBox(child: CircularProgressIndicator()),
                            );
                          }
                          else if (snapshot.hasError) {
                            isWeatherDataLoaded = false;
                            return SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  AppLocalizations.of(context)!.errorsInvokeWeather,
                                  style: errorTextStyle,
                                ),
                              ),
                            );
                          }
                          else {
                            isWeatherDataLoaded = true;
                            return Container(
                              padding: const EdgeInsets.only(left: 25, right: 25, top: 15, bottom: 20),
                              alignment: Alignment.centerLeft,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${snapshot.data['name']} ',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${snapshot.data['main']['temp']}°C',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.normal),
                                      ),
                                        snapshot.data['weathericon'],
                                    ],
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      '(${AppLocalizations.of(context)!.weatherFeelsLike} ${snapshot.data['main']['feels_like']}°C, ${AppLocalizations.of(context)!.weatherMinTemp} ${snapshot.data['main']['temp_min']}°C, ${AppLocalizations.of(context)!.weatherMaxTemp} ${snapshot.data['main']['temp_max']}°C)',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),

                                  Text(
                                    '${AppLocalizations.of(context)!.weatherHumidity}: ${snapshot.data['main']['humidity']}%',
                                    style: const TextStyle(fontSize: 22),
                                  ),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${snapshot.data['refreshDateTime']}',
                                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        icon: const Icon(Icons.refresh_outlined),
                                        iconSize: 20,
                                        onPressed: (){
                                          setState(() {});
                                          },
                                        padding: const EdgeInsets.only(left: 5),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }
                        },
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/schedules').then((value) async {
                        // Upload dirty files if auto sync is activated
                        if (applicationSettings['autoSyncActivated'] == 'true') {
                          for (String targetDate in dirtyScheduleDateTime) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return AlertDialog(
                                  content: SizedBox(
                                    height: 120,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 40, height: 40,
                                          child: CircularProgressIndicator(),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 15),
                                          child: Text("${AppLocalizations.of(context)!.scheduleUploadingMsg} ($targetDate)"),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );

                            try {
                              await scheduleManager.upload(targetDate, cachedScheduleData[targetDate]!);
                            } catch (e) {
                              showToastMessage('${AppLocalizations.of(context)!.scheduleUploadingFailedMsg} ($e)');
                            }

                            Navigator.of(context).pop();
                          }

                          // Delete every dirty tag
                          dirtyScheduleDateTime = [];
                        }

                        setState(() {
                          currentScheduleData = readSchedule(dateTime2String(DateTime.now()));
                        });
                      });
                    },

                    child: Container(
                      height: 300,
                      margin: const EdgeInsets.only(top: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),
                      child: FutureBuilder(
                        future: currentScheduleData,
                        builder: (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData == false) {
                            return Container(
                              alignment: Alignment.center,
                              child: const SizedBox(child: CircularProgressIndicator()),
                            );
                          }
                          else if (snapshot.hasError) {
                            return SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  AppLocalizations.of(context)!.errorsInvokeSchedule,
                                  style: errorTextStyle,
                                ),
                              ),
                            );
                          }
                          else if (snapshot.data.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.only(left: 25, right: 25, top: 30, bottom: 30),
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List<Widget>.generate(
                                  snapshot.data.length < 6 ? snapshot.data.length : 6,
                                  (index) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Text(snapshot.data[index][0],
                                      style: scheduleTextStyle.copyWith(
                                        decoration: snapshot.data[index][1] == '1' ? TextDecoration.lineThrough : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ) + [
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.bottomRight,
                                      width: double.infinity,
                                      child: Text(AppLocalizations.of(context)!.scheduleSeeMore,
                                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  AppLocalizations.of(context)!.scheduleAddNew,
                                  style: scheduleTextStyle,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      // Navigator.pushNamed(context, '/deviceManager').then((value) {
                      //   setState(() {});
                      // });
                    },
                    child: FutureBuilder(
                      future: currentSkinConditionData,
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData == false) {
                          return Container(
                            margin: const EdgeInsets.only(top: 15, bottom: 15),
                            alignment: Alignment.center,
                            height: 460,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: dashboardCardBorderRadius,
                            ),
                            child: const SizedBox(child: CircularProgressIndicator()),
                          );
                        }
                        else if (snapshot.hasError) {
                          return Container(
                            margin: const EdgeInsets.only(top: 15, bottom: 15),
                            height: 460,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: dashboardCardBorderRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                AppLocalizations.of(context)!.errorsInvokeSkinCondition,
                                style: errorTextStyle,
                              ),
                            ),
                          );
                        }
                        else {
                          return Container(
                            margin: const EdgeInsets.only(top: 15, bottom: 15),
                            height: 460,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: dashboardCardBorderRadius,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 80,
                                  padding: const EdgeInsets.only(left: 25, right: 25, top: 20, bottom: 12),
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          AppLocalizations.of(context)!.skinConditionTitle,
                                          style: skinConditionWidgetTitleStyle,
                                        ),
                                      ),
                                      Text(
                                        "${AppLocalizations.of(context)!.skinConditionTodayPrefix}: ${snapshot.data['daily']}",
                                        style: skinConditionWidgetDefault,
                                      )
                                    ],
                                  ),
                                ),

                                const Divider(),

                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 25, right: 25, top: 12, bottom: 20),
                                    alignment: Alignment.center,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 30),
                                          child: Text(
                                            AppLocalizations.of(context)!.skinConditionMonthlyTitle,
                                            style: skinConditionWidgetTitleStyle,
                                          ),
                                        ),
                                        AspectRatio(
                                          aspectRatio: 2 / 2,
                                          child: interface_tools.generateMonthlyDataChart(
                                            snapshot.data['monthly'],
                                            AppLocalizations.of(context)!.skinChartXTitle,
                                            AppLocalizations.of(context)!.skinChartXSuffix,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    )
                  ),

                  /* ADD NEW DASHBOARD ELEMENT HERE */

                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/*
 * Settings widget
 *   Changes application settings
 */

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> selectTheme() async {
    List<String> colorPresets = color_themes_presets.colorSchemePresets.keys.toList();
    int selectedIndex = colorPresets.indexOf(applicationSettings['themeName']!);
    bool isChanged = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          title: Text(AppLocalizations.of(context)!.settingsTheme, style: settingsWidgetTextStyle.copyWith(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {
                  if (applicationSettings['themeName'] != colorPresets[selectedIndex]) {
                    isChanged = true;
                  }
                });
                Navigator.of(context).pop();
              },
            )
          ],
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.3,
                alignment: Alignment.center,
                child: ScrollConfiguration(
                  behavior: interface_tools.GlowRemovedBehavior(),
                  child: GridView.builder(
                    itemCount: colorPresets.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Radio <int>(
                            activeColor: Theme.of(context).colorScheme.background,
                            value: index,
                            groupValue: selectedIndex,
                            onChanged: (value) {
                              setState(() {
                                selectedIndex = value!;
                              });
                            },
                          ),

                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color_themes_presets.colorSchemePresets[colorPresets[index]]!.background,
                                borderRadius: dashboardCardBorderRadius,
                                border: Border.all(color: const Color.fromRGBO(225, 225, 225, 1), width: 2),
                              ),
                              child: Text(
                                color_themes_presets.translateColorName(AppLocalizations.of(context), colorPresets[index]),
                                style: settingsWidgetTextStyle.copyWith(color: color_themes_presets.colorSchemePresets[colorPresets[index]]!.tertiary),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (isChanged) {
      applicationSettings['themeName'] = colorPresets[selectedIndex];
      await saveSettings(applicationSettings);
      showToastMessage(AppLocalizations.of(context)!.msgRestartToSaveSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,

      body: ScrollConfiguration(
        behavior: interface_tools.GlowRemovedBehavior(),
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                expandedHeight: 150.0,
                backgroundColor: Theme.of(context).colorScheme.background,
                elevation: 0.0,
                iconTheme: IconThemeData(color: Theme.of(context).colorScheme.tertiary),

                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(AppLocalizations.of(context)!.settingsMenuTitle,
                    style: appBarStyle.copyWith(color: Theme.of(context).colorScheme.tertiary),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  GestureDetector(
                    onTap: selectTheme,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      width: double.infinity, height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(AppLocalizations.of(context)!.settingsTheme, style: settingsWidgetTextStyle),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(right: 15),
                              width: double.infinity,
                              alignment: Alignment.centerRight,
                              child: Text(
                                color_themes_presets.translateColorName(AppLocalizations.of(context)!, applicationSettings['themeName']!),
                                style: settingsWidgetSelectedTextStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      if (applicationSettings['autoSyncActivated'] == 'true') {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              alignment: Alignment.center,
                              title: Text(AppLocalizations.of(context)!.settingsAutoSync, style: settingsWidgetTextStyle.copyWith(fontWeight: FontWeight.bold)),
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () {
                                    setState(() {
                                      applicationSettings['autoSyncActivated'] = 'false';
                                    });
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                              content: Text(AppLocalizations.of(context)!.settingsDeactivationDialogContent, style: settingsWidgetTextStyle,),
                            );
                          },
                        );
                      } else {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              alignment: Alignment.center,
                              title: Text(AppLocalizations.of(context)!.settingsAutoSync, style: settingsWidgetTextStyle.copyWith(fontWeight: FontWeight.bold)),
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () {
                                    setState(() {
                                      applicationSettings['autoSyncActivated'] = 'true';
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                              content: Text(AppLocalizations.of(context)!.settingsActivationDialogContent, style: settingsWidgetTextStyle,),
                            );
                          },
                        );
                      }

                      await saveSettings(applicationSettings);
                      setState(() {});
                    },

                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      width: double.infinity, height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(AppLocalizations.of(context)!.settingsAutoSync, style: settingsWidgetTextStyle),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(right: 15),
                              width: double.infinity,
                              alignment: Alignment.centerRight,
                              child: Text(
                                interface_tools.string2Bool(applicationSettings['autoSyncActivated']!) ? AppLocalizations.of(context)!.settingsActivated : AppLocalizations.of(context)!.settingsDeactivated,
                                style: settingsWidgetSelectedTextStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /* ADD NEW SETTINGS ELEMENT HERE */

                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/*
 * Schedule Page
 *   Changes today's schedules list
 */

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime currentDateTime = DateTime.now();
  Future<List> currentScheduleData = Future.value([]);

  Future<List> showEditingDialog(String initialData, String initialIsChecked) async {
    final scheduleDataController = TextEditingController();
    scheduleDataController.text = initialData;
    String isChecked = initialIsChecked;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          title: Text(AppLocalizations.of(context)!.scheduleEditDialogTitle,
            style: scheduleMagerDialogTextStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          content: SizedBox(
            height: 120,
            child: Column(
              children: [
                TextField(
                  controller: scheduleDataController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.scheduleEditDialogLabel,
                  ),
                ),
                Row(
                  children: [
                    Text(AppLocalizations.of(context)!.scheduleEditDialogCompleted,
                      style: scheduleMagerDialogTextStyle,
                    ),
                    StatefulBuilder(builder: (context, setState) {
                      return Checkbox(
                        value: isChecked == '1' ? true : false,
                        onChanged: (value) {
                          setState(() {
                            isChecked = value! ? '1' : '0';
                          });
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return [scheduleDataController.text, isChecked];
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentScheduleData = readSchedule(dateTime2String(currentDateTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,

      body: ScrollConfiguration(
        behavior: interface_tools.GlowRemovedBehavior(),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 150.0,
              backgroundColor: Theme.of(context).colorScheme.background,
              elevation: 0.0,
              iconTheme: IconThemeData(color: Theme.of(context).colorScheme.tertiary),

              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(AppLocalizations.of(context)!.scheduleMenuTitle,
                  style: appBarStyle.copyWith(color: Theme.of(context).colorScheme.tertiary),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                GestureDetector(
                  onTap: () async {
                    DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: currentDateTime,
                      firstDate: DateTime(1960),
                      lastDate: DateTime(2200),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Theme.of(context).colorScheme.primary,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(primary: Colors.black,),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (selectedDate != null) {
                      setState(() {
                        currentDateTime = selectedDate;
                        currentScheduleData = readSchedule(dateTime2String(currentDateTime));
                      });
                    }
                  },

                  child: Container(
                    margin: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                    width: double.infinity, height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: dashboardCardBorderRadius,
                    ),
                    child: Container(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 25,),

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(left: 15, right: 15),
                              child: Text(dateTime2String(currentDateTime),
                                style: scheduleManagerDateTimeTextStyle,
                              ),
                            ),
                          ),

                          const Icon(Icons.arrow_forward_ios, size: 25,),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(left: 15, right: 15),
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: FutureBuilder(
                    future: currentScheduleData,
                    builder: (context,  AsyncSnapshot<List> snapshot) {
                      if (snapshot.hasData == false) {
                        return Container(
                          height: 50,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(top: 24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: dashboardCardBorderRadius,
                          ),
                          child: const SizedBox(
                            width: 30, height : 30,
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return SizedBox(
                          height: 150,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Text(
                              AppLocalizations.of(context)!.errorsInvokeSchedule,
                              style: errorTextStyle,
                            ),
                          ),
                        );
                      } else if (snapshot.data!.isNotEmpty) {
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length + 1,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == snapshot.data!.length) {  // Tail button
                              return IconButton(
                                icon: Icon(Icons.add, size: 35, color: Theme.of(context).colorScheme.tertiary,),
                                onPressed: () async {
                                  final edited = await showEditingDialog("", "0");
                                  setState(() {
                                    if (edited[0].length != 0) {
                                      snapshot.data!.add(edited.toList());  // update changes
                                      String stringCurrentDateTime = dateTime2String(currentDateTime);

                                      if (!cachedScheduleData.keys.contains(stringCurrentDateTime)) {
                                        cachedScheduleData[stringCurrentDateTime] = [edited.toList()];
                                      } else {
                                        cachedScheduleData[stringCurrentDateTime]![index] = edited.toList();
                                      }

                                      if (!dirtyScheduleDateTime.contains(stringCurrentDateTime)) {
                                        dirtyScheduleDateTime.add(stringCurrentDateTime);  // not uploaded yet
                                      }
                                    }
                                  });
                                  await saveSchedule(dateTime2String(currentDateTime));
                                },
                              );
                            }

                            return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.endToStart,

                              onDismissed: (_) async {
                                String stringCurrentDateTime = dateTime2String(currentDateTime);
                                setState(() {
                                  snapshot.data!.removeAt(index);
                                  cachedScheduleData[stringCurrentDateTime] = snapshot.data!.toList();
                                  if (!dirtyScheduleDateTime.contains(stringCurrentDateTime)) {
                                    dirtyScheduleDateTime.add(stringCurrentDateTime);  // not uploaded yet
                                  }
                                });
                                await saveSchedule(dateTime2String(currentDateTime));
                              },

                              child: GestureDetector(
                                onTap: () async {
                                  String stringCurrentDateTime = dateTime2String(currentDateTime);
                                  final edited = await showEditingDialog(snapshot.data![index][0], snapshot.data![index][1]);
                                  setState(() {
                                    if ((snapshot.data![index][0] != edited[0] || snapshot.data![index][1] != edited[1]) && edited[0].length != 0) {
                                      snapshot.data![index][0] = edited[0];  // update changes
                                      snapshot.data![index][1] = edited[1];  // update changes

                                      // Save changes as cache data
                                      if (!cachedScheduleData.keys.contains(stringCurrentDateTime)) {
                                        cachedScheduleData[stringCurrentDateTime] = [edited.toList()];
                                      } else {
                                        cachedScheduleData[stringCurrentDateTime]![index] = edited.toList();
                                      }

                                      if (!dirtyScheduleDateTime.contains(stringCurrentDateTime)) {
                                        dirtyScheduleDateTime.add(stringCurrentDateTime);  // not uploaded yet
                                      }
                                    } else if (edited[0].length == 0) {
                                      snapshot.data!.removeAt(index);
                                      cachedScheduleData[stringCurrentDateTime] = snapshot.data!.toList();
                                      if (!dirtyScheduleDateTime.contains(stringCurrentDateTime)) {
                                        dirtyScheduleDateTime.add(stringCurrentDateTime);  // not uploaded yet
                                      }
                                    }
                                  });
                                  await saveSchedule(dateTime2String(currentDateTime));
                                },

                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: dashboardCardBorderRadius,
                                  ),
                                  child: ListTile(
                                    title: Container(
                                      height: 30,
                                      alignment: Alignment.centerLeft,
                                      child: Text(snapshot.data![index][0],
                                        style: scheduleTextStyle.copyWith(decoration: snapshot.data![index][1] == '1' ? TextDecoration.lineThrough : TextDecoration.none),
                                      ),
                                    ),
                                    trailing: const Icon(Icons.arrow_back),
                                  ),
                                ),
                              ),

                              background: Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: dashboardCardBorderRadius,
                                ),
                                alignment: Alignment.centerRight,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child:  Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return IconButton(
                          icon: Icon(Icons.add, size: 35, color: Theme.of(context).colorScheme.tertiary,),
                          onPressed: () async {
                            final edited = await showEditingDialog("", "0");
                            setState(() {
                              if (edited[0].length != 0) {
                                snapshot.data!.add(edited.toList());  // update changes
                                String stringCurrentDateTime = dateTime2String(currentDateTime);
                                cachedScheduleData[stringCurrentDateTime] = [edited.toList()];
                                if (!dirtyScheduleDateTime.contains(stringCurrentDateTime)) {
                                  dirtyScheduleDateTime.add(stringCurrentDateTime);  // not uploaded yet
                                }
                              }
                            });
                            await saveSchedule(dateTime2String(currentDateTime));
                          },
                        );
                      }
                    },
                  ),
                ),

                /* ADD NEW SCHEDULES MANAGING ELEMENT HERE */

              ]),
            ),
          ],
        ),
      ),
    );
  }
}


/*
 * Device Managing Page
 *   Smart mirror managing menu
 */

class DeviceManagingPage extends StatefulWidget {
  const DeviceManagingPage({Key? key}) : super(key: key);

  @override
  _DeviceManagingPageState createState() => _DeviceManagingPageState();
}

class _DeviceManagingPageState extends State<DeviceManagingPage> {
  blue_serial.BluetoothConnection? connection;
  List<bool?> tickets = [];
  List<TokenSent> tokens = [];
  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;
  final formKey = GlobalKey<FormState>();

  String musicTitle = 'default';
  bool musicPlaying = false;
  int currentVolume = 50;

  void onDataReceived(Uint8List data) {
    int backspacesCounter = 0;
    for (var byte in data) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    }
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    String dataString = String.fromCharCodes(buffer);
    Map<String, dynamic> decodedData = jsonDecode(dataString);
    print('============= token received: $decodedData');
    final token = TokenReceived.fromJson(decodedData);

    setState(() {
      musicTitle = token.args[0];
      musicPlaying = interface_tools.string2Bool(token.args[1]);
      currentVolume = token.args[2] == 'default' ? 50 : int.parse(token.args[2]);
    });

    if (token.ticket != -1 && tickets[token.ticket] == null) {
      if (token.type == 'failed') {
        tickets[token.ticket] = false;
      } else {
        tickets[token.ticket] = true;
      }
    }
  }

  void sendToken(Map<String, dynamic> tokenContent, {bool showSucceedMsg = false}) async {
    if (isConnected && connection != null) {
      final ticket = tickets.length;
      tokenContent['ticket'] = ticket;
      final token = TokenSent.fromJson(tokenContent);
      tickets.add(null);
      tokens.add(token);

      final encodedToken = jsonEncode(token);
      connection!.output.add(Uint8List.fromList(utf8.encode(encodedToken)));
      await connection!.output.allSent;

      Future.delayed(const Duration(seconds: 1)).then((value) {
        print("========= ticket: $ticket");
        if (tickets[ticket] == null) {
          tickets[ticket] = false;
          showToastMessage(AppLocalizations.of(context)!.deviceManagingTimeoutMsg);
        } else if (tickets[ticket] == true) {
          if (showSucceedMsg) {
            showToastMessage(AppLocalizations.of(context)!.deviceManagingSucceedMsg);
          }
        } else {
          showToastMessage(AppLocalizations.of(context)!.deviceManagingFailedMsg);
        }
      });
    } else {
      showToastMessage(AppLocalizations.of(context)!.deviceManagingFiledConnectionMsg);
    }
  }

  void connectTargetDevice() {
    print(isConnected);
    if (isConnected) {
      return;
    }

    setState(() {
      isConnecting = true;
    });

    if (applicationSettings['managedDeviceMAC'] != defaultApplicationSettings['managedDeviceMAC']) {
      blue_serial.BluetoothConnection.toAddress(applicationSettings['managedDeviceMAC']).then((_connection) {
        connection = _connection;
        sendToken({
          'type': 'init',
          'args': [],
        });

        setState(() {
          isConnecting = false;
          isDisconnecting = false;
        });

        connection!.input!.listen(onDataReceived).onDone(() {
          if (isDisconnecting) {
            print('Disconnecting locally!');
          } else {
            showToastMessage(AppLocalizations.of(context)!.deviceDisconnectionRemoteMsg);
          }
          if (mounted) {
            setState(() {});
          }
        });
      }).catchError((e) {
        showToastMessage(AppLocalizations.of(context)!.deviceConnectionErrorMsg);
        print('========== connection failed: $e');

        setState(() {
          isConnecting = false;
          isDisconnecting = false;
        });
      });
    }
  }

  Future<int> showIntervalEditingDialog() async {
    final hourDataController = TextEditingController();
    final minuteDataController = TextEditingController();

    hourDataController.text = '0';
    minuteDataController.text = '20';

    int minvalue = -1;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          alignment: Alignment.center,
          title: Text(AppLocalizations.of(context)!.deviceManagingMenuSetIntervaldialogTitle,
            style: deviceManagingDialogTextStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final hours = hourDataController.text.isNotEmpty ? hourDataController.text : '0';
                  final minutes = minuteDataController.text.isNotEmpty ? minuteDataController.text : '0';
                  minvalue = int.parse(hours) * 60 + int.parse(minutes);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
          content: SizedBox(
            height: 200,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: hourDataController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.deviceManagingMenuSetIntervaldialogHour,
                    ),
                    validator: (text) {
                      final finalText = text ?? '0';
                      if (finalText.contains('.')) {
                        return AppLocalizations.of(context)!.deviceManagingMenuSetIntervaldialogFloatMsg;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: minuteDataController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.deviceManagingMenuSetIntervaldialogMinutes,
                    ),
                    validator: (text) {
                      final finalText = text ?? '0';
                      if (finalText.contains('.')) {
                        return AppLocalizations.of(context)!.deviceManagingMenuSetIntervaldialogFloatMsg;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return minvalue;
  }

  @override
  void initState() {
    super.initState();

    tokens = [];
    tickets = [];
    connectTargetDevice();
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,

      body: ScrollConfiguration(
        behavior: interface_tools.GlowRemovedBehavior(),
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                expandedHeight: 150.0,
                backgroundColor: Theme.of(context).colorScheme.background,
                elevation: 0.0,
                iconTheme: IconThemeData(color: Theme.of(context).colorScheme.tertiary),

                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(AppLocalizations.of(context)!.deviceManagingMenuTitle,
                    style: appBarStyle.copyWith(color: Theme.of(context).colorScheme.tertiary),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                    height: 130,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: dashboardCardBorderRadius,
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/deviceManager/deviceConnection').then((value) {
                              setState(() {});
                            });
                          },

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 8),
                                child: CircleAvatar(
                                  child: Icon(
                                      Icons.perm_device_info_outlined,
                                      color: Theme.of(context).colorScheme.tertiary
                                  ),
                                  radius: 22,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),

                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    applicationSettings['managedDeviceName'] == defaultApplicationSettings['managedDeviceName'] ?
                                    AppLocalizations.of(context)!.warningsDeviceNotDetected :
                                    applicationSettings['managedDeviceName']!,
                                    style: deviceIdStyle,
                                  ),
                                  Text(
                                    applicationSettings['managedDeviceMAC'] == defaultApplicationSettings['managedDeviceMAC'] ?
                                    '00:00:00:00:00:00' :
                                    applicationSettings['managedDeviceMAC']!,
                                    style: deviceIdStyle.copyWith(color: Colors.orange),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        const Divider(),

                        Container(
                          margin: const EdgeInsets.only(right: 15, left: 15, top: 8),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Text("${
                                  AppLocalizations.of(context)!.deviceStatusPrefix
                              }: ${
                                  isConnected ?
                                  AppLocalizations.of(context)!.deviceStatusConnected :
                                  isConnecting ?
                                  AppLocalizations.of(context)!.deviceStatusConnecting :
                                  isDisconnecting ?
                                  AppLocalizations.of(context)!.deviceStatusDisconnecting :
                                  AppLocalizations.of(context)!.deviceStatusDisconnected
                              }", style: deviceIdStyle),

                              Expanded(
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  width: double.infinity,
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh_outlined),
                                    iconSize: 20,
                                    onPressed: connectTargetDevice,
                                    padding: const EdgeInsets.only(left: 5),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                    height: 150,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: dashboardCardBorderRadius,
                    ),

                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 30,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(top: 20, right: 20, left: 20),
                          child: Text(
                            musicTitle == 'default' ? AppLocalizations.of(context)!.deviceManagingMenuMusicDefault : musicTitle,
                            style: widgetDefaultTextStyle,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final tokenContent = {
                                  'type': 'music_prev',
                                  'args': [],
                                };

                                sendToken(tokenContent);
                              },

                              child: Container(
                                margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                                child: Icon(
                                  Icons.skip_previous,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 35,
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () async {
                                final tokenContent = {
                                  'type': 'music_autoplay',
                                  'args': [],
                                };

                                sendToken(tokenContent);
                              },

                              child: Container(
                                margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                                child: CircleAvatar(
                                  child: Icon(
                                    musicPlaying ? Icons.pause : Icons.play_arrow_rounded,
                                    color: Theme.of(context).colorScheme.tertiary,
                                    size: 35,
                                  ),
                                  radius: 30,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () async {
                                final tokenContent = {
                                  'type': 'music_next',
                                  'args': [],
                                };

                                sendToken(tokenContent);
                              },

                              child: Container(
                                margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                                child: Icon(
                                  Icons.skip_next,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                    height: 75,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: dashboardCardBorderRadius,
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 20),
                            child: Text(
                              "${AppLocalizations.of(context)!.deviceManagingMenuCurrentVolume}: $currentVolume",
                              style: widgetDefaultTextStyle,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () async {
                            final tokenContent = {
                              'type': 'master_volume_down',
                              'args': [],
                            };

                            sendToken(tokenContent);
                          },

                          child: Container(
                            margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                            child: Icon(
                              Icons.volume_down_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 35,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () async {
                            final tokenContent = {
                              'type': 'master_volume_up',
                              'args': [],
                            };

                            sendToken(tokenContent);
                          },

                          child: Container(
                            margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                            child: Icon(
                              Icons.volume_up_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final tokenContent = {
                        'type': 'assistant',
                        'args': [],
                      };

                      sendToken(tokenContent);
                    },

                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      height: 75,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),

                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                            child: CircleAvatar(
                              child: Icon(
                                  Icons.assistant_outlined,
                                  color: Theme.of(context).colorScheme.tertiary
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          Text(
                            AppLocalizations.of(context)!.deviceManagingMenuAssistant,
                            style: deviceIdStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final tokenContent = {
                        'type': 'moisture',
                        'args': [],
                      };

                      showToastMessage(AppLocalizations.of(context)!.deviceManagingMenuSkinDialog);
                      sendToken(tokenContent);
                    },

                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      height: 75,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),

                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                            child: CircleAvatar(
                              child: Icon(
                                  Icons.water_drop_outlined,
                                  color: Theme.of(context).colorScheme.tertiary
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          Text(
                            AppLocalizations.of(context)!.deviceManagingMenuSkin,
                            style: deviceIdStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final tokenContent = {
                        'type': 'play_music_by_emotion',
                        'args': [],
                      };

                      showToastMessage(AppLocalizations.of(context)!.deviceManagingMenuEmotionDialog);
                      sendToken(tokenContent);
                    },

                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      height: 75,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),

                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                            child: CircleAvatar(
                              child: Icon(
                                  Icons.face_outlined,
                                  color: Theme.of(context).colorScheme.tertiary
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          Text(
                            AppLocalizations.of(context)!.deviceManagingMenuEmotion,
                            style: deviceIdStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final currentPosition = await weatherDataDownloader.determinePosition();
                      final latitude = currentPosition.latitude.toString();
                      final longitude = currentPosition.longitude.toString();

                      final tokenContent = {
                        'type': 'set_location',
                        'args': [latitude, longitude],
                      };

                      sendToken(tokenContent, showSucceedMsg:true);
                    },

                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      height: 75,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),

                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                            child: CircleAvatar(
                              child: Icon(
                                  Icons.location_on_outlined,
                                  color: Theme.of(context).colorScheme.tertiary
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          Text(
                            AppLocalizations.of(context)!.deviceManagingMenuSetLocation,
                            style: deviceIdStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final tokenContent = {
                        'type': 'refresh',
                        'args': [],
                      };

                      sendToken(tokenContent, showSucceedMsg:true);
                    },

                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      height: 75,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),

                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                            child: CircleAvatar(
                              child: Icon(
                                  Icons.refresh_outlined,
                                  color: Theme.of(context).colorScheme.tertiary
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          Text(
                            AppLocalizations.of(context)!.deviceManagingMenuRefreshWidget,
                            style: deviceIdStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final minvalue = await showIntervalEditingDialog();

                      if (minvalue != -1) {
                        final tokenContent = {
                          'type': 'set_auto_interval',
                          'args': [minvalue.toString()],
                        };

                        sendToken(tokenContent, showSucceedMsg:true);
                      }
                    },

                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                      height: 75,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: dashboardCardBorderRadius,
                      ),

                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
                            child: CircleAvatar(
                              child: Icon(
                                  Icons.timer_outlined,
                                  color: Theme.of(context).colorScheme.tertiary
                              ),
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          Text(
                            AppLocalizations.of(context)!.deviceManagingMenuSetInterval,
                            style: deviceIdStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  /* ADD NEW DEVICE MANAGING ELEMENT HERE */

                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/*
 * Bluetooth device connection
 *   Device connection mpage
 */

class DeviceConnectionPage extends StatefulWidget {
  const DeviceConnectionPage({Key? key}) : super(key: key);

  @override
  _DeviceConnectionPageState createState() => _DeviceConnectionPageState();
}

class _DeviceConnectionPageState extends State<DeviceConnectionPage> {
  bool isScanning = false;
  bool isConnecting = false;

  StreamSubscription<blue_serial.BluetoothDiscoveryResult>? streamSubscription;
  List<blue_serial.BluetoothDiscoveryResult> results = List<blue_serial.BluetoothDiscoveryResult>.empty(growable: true);

  Future<void> registerBluetoothDevice(blue_serial.BluetoothDiscoveryResult targetResult) async {
    await showDialog(
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () => Future.value(!isConnecting),  // Cannot go back if connecting

          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            alignment: Alignment.center,
            title: Text(AppLocalizations.of(context)!.deviceConnectionMenuTitle,
              style: deviceConnectionDialogTextStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  List<String> availableDevices = await readAvaliableDevices();
                  
                  if (availableDevices.contains(getDeviceName(targetResult))) {
                    bool bondResult = true;
                    final currentDeviceId = applicationSettings['managedDeviceMAC'];

                    if (currentDeviceId != getDeviceId(targetResult)) {
                      applicationSettings['managedDeviceMAC'] = getDeviceId(targetResult);
                    }

                    applicationSettings['managedDeviceName'] = getDeviceName(targetResult);

                    if (!targetResult.device.isBonded) {
                      bondResult = await blue_serial.FlutterBluetoothSerial.instance
                          .bondDeviceAtAddress(getDeviceId(targetResult)) ?? false;
                    }

                    if (bondResult) {
                      showToastMessage(AppLocalizations.of(context)!.deviceBondingSucceedMsg);
                    } else {
                      applicationSettings['managedDeviceName'] = defaultApplicationSettings['managedDeviceName']!;
                      applicationSettings['managedDeviceMAC'] = defaultApplicationSettings['managedDeviceMAC']!;
                      showToastMessage(AppLocalizations.of(context)!.deviceBondingFailedMsg);
                    }

                    saveSettings(applicationSettings);
                  } else {
                    showToastMessage(AppLocalizations.of(context)!.deviceNotAvailableMsg);
                  }

                  Navigator.of(context).pop();
                },
              ),
            ],
            content: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15, right: 8, left: 8),
                    child: Text("${AppLocalizations.of(context)!.deviceNameTag}: ${getDeviceName(targetResult)}",
                      style: deviceConnectionDialogTextStyle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8, bottom: 15),
                    child: Text(getDeviceId(targetResult),
                      style: deviceConnectionDialogTextStyle.copyWith(color: Colors.orange),
                    ),
                  ),

                  Text(AppLocalizations.of(context)!.deviceBondingDialogMsg,
                    style: deviceConnectionDialogTextStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void restartScanning() {
    setState(() {
      results.clear();
      isScanning = true;
    });

    startScanning();
  }

  void startScanning() {
    streamSubscription =
        blue_serial.FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
          setState(() {
            final existingIndex = results.indexWhere((element) => element.device.address == r.device.address);
            if (existingIndex >= 0) {
              results[existingIndex] = r;
            } else {
              results.add(r);
            }
          });
        });

    streamSubscription!.onDone(() {
      setState(() {
        isScanning = false;
      });
    });
  }

  String getDeviceName(blue_serial.BluetoothDiscoveryResult targetResult) {
    return targetResult.device.name ?? 'N/A';
  }

  String getDeviceId(blue_serial.BluetoothDiscoveryResult targetResult) {
    return targetResult.device.address;
  }

  @override
  void initState() {
    super.initState();
    isScanning = true;
    isConnecting = false;

    startScanning();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();  // avoid memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(!isConnecting),  // Cannot go back if connecting

      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,

        body: ScrollConfiguration(
          behavior: interface_tools.GlowRemovedBehavior(),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 150.0,
                  backgroundColor: Theme.of(context).colorScheme.background,
                  elevation: 0.0,
                  iconTheme: IconThemeData(color: Theme.of(context).colorScheme.tertiary),

                  actions: <Widget>[
                    IconButton(
                      icon: Icon(isScanning ? Icons.refresh_outlined : Icons.add,),
                      tooltip: AppLocalizations.of(context)!.settingsMenuTitle,
                      onPressed: restartScanning,
                    ),
                  ],

                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(AppLocalizations.of(context)!.deviceConnectionMenuTitle,
                      style: appBarStyle.copyWith(color: Theme.of(context).colorScheme.tertiary),
                    ),
                  ),
                ),

                SliverList(
                  delegate: SliverChildListDelegate(
                    List.generate(
                      results.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            if (!isConnecting) {
                              registerBluetoothDevice(results[index]);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                            padding: const EdgeInsets.all(15),
                            height: 70,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: dashboardCardBorderRadius,
                            ),

                            child: Row(
                              children: [
                                CircleAvatar(
                                  child: Icon(
                                    Icons.bluetooth,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                  radius: 22,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(left: 15, right: 15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(getDeviceName(results[index]), style: deviceIdStyle,),
                                      Text(getDeviceId(results[index]), style: deviceIdStyle.copyWith(color: Colors.orange),),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                    }) + [GestureDetector(
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 15),
                      ),
                    )],
                  ),
                ),

                /* ADD NEW DEVICE CONNECTION ELEMENT HERE */

              ],
            ),
          ),
        ),
      ),
    );
  }
}