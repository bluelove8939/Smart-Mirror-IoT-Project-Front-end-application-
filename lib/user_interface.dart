import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';  // toast message

import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // generated localizations
import 'package:iot_project_demo/data_managers.dart';
import 'package:iot_project_demo/interface_tools.dart' as interface_tools;
import 'package:iot_project_demo/color_themes_presets.dart' as color_themes_presets;

import 'package:flutter_blue/flutter_blue.dart' as blue;  // General bluetooth package
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as blue_serial;  // Bluetooth setial (classical bluetooth protocol, RFCOMM)


// General text styles
TextStyle appBarStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);  // dashboard appbar title
TextStyle userNameStyle = const TextStyle(fontSize: 16, color: Colors.black);  // dashboard username
TextStyle emailStyle = const TextStyle(fontSize: 14, color: Colors.orange);  // dashboard emails
TextStyle deviceIdStyle = const TextStyle(fontSize: 16, color: Colors.black);  // dashboard device id
TextStyle scheduleTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // dashboard schedules widget
TextStyle errorTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // indicating error messages

TextStyle settingsWidgetTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // settings subtitles
TextStyle settingsWidgetSelectedTextStyle = const TextStyle(fontSize: 16, color: Colors.orange);  // settings values

TextStyle scheduleManagerDateTimeTextStyle = const TextStyle(fontSize: 18, color: Colors.black);  // schedule manager datetime
TextStyle scheduleMagerDialogTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // schedule manger dialog font

TextStyle deviceConnectionDialogTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // device connection page dialog font

// General border radius
Radius generalBorderRadius = const Radius.circular(15);
BorderRadius dashboardCardBorderRadius = BorderRadius.all(generalBorderRadius);

// General data managing module
WeatherDataDownloader weatherDataDownloader = WeatherDataDownloader();  // wether data downloader
ScheduleManager scheduleManager = ScheduleManager();  // download and upload schedule data

StreamSubscription<blue.BluetoothDeviceState>? bluetoothDeviceStateListener;  // state listener


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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentScheduleData = readSchedule(dateTime2String(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
                    margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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
                    margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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

                        Text(AppLocalizations.of(context)!.warningsDeviceNotDetected, style: deviceIdStyle)
                      ],
                    ),
                  ),
                ),

                Container(
                  height: 160,
                  margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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
                    margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(15, 15, 7, 15),
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: dashboardCardBorderRadius,
                        ),
                        child: const Text("Control UI"),
                      ),
                    ),

                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(7, 15, 15, 15),
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: dashboardCardBorderRadius,
                        ),
                        child: const Text("Control UI"),
                      ),
                    ),
                  ],
                ),

                /* ADD NEW DASHBOARD ELEMENT HERE */

              ]),
            ),
          ],
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
                    margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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
                    margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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
                title: Text(AppLocalizations.of(context)!.deviceManagingMenuTitle,
                  style: appBarStyle.copyWith(color: Theme.of(context).colorScheme.tertiary),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/deviceManager/deviceConnection').then((value) {
                      setState(() {});
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.warningsDeviceNotDetected, style: deviceIdStyle),
                            Text('00:00:00:00:00:00', style: deviceIdStyle.copyWith(color: Colors.orange),)
                          ],
                        )
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
  List<blue.BluetoothDevice> deviceList = [];
  bool isScanning = false;
  bool isConnecting = false;

  void addDevice(blue.BluetoothDevice targetDevice) {
    if (!deviceList.contains(targetDevice)) {
      if (mounted) {
        setState(() {
          deviceList.add(targetDevice);
        });
      }
    }
  }

  void scan() {
    if (!isScanning) {
      setState(() {
        isScanning = true;
        deviceList = [];
      });

      // Add connected devices to list
      bluetoothManager.connectedDevices.asStream().listen((devices) {
        for (blue.BluetoothDevice device in devices) {
          addDevice(device);
        }
      });

      // Add found devices to list
      bluetoothManager.scanResults.listen((results) {
        for (blue.ScanResult result in results) {
          addDevice(result.device);
        }
      });

      // start scanning
      bluetoothManager.startScan(timeout: const Duration(seconds: 4)).then((value) {
        setState(() {
          isScanning = false;
        });
      });
    } else {
      bluetoothManager.stopScan();
      setState(() {
        isScanning = false;
      });
    }
  }

  String getDeviceName(blue.BluetoothDevice targetDevice) {
    print(targetDevice.name);
    if (targetDevice.name.isNotEmpty) {
      return targetDevice.name;
    } else {
      return 'N/A';
    }
  }

  String getDeviceMACId(blue.BluetoothDevice targetDevice) {
    return targetDevice.id.id;
  }

  Future<void> registerBluetoothDevice(blue.BluetoothDevice targetDevice) async {
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
                  if (bluetoothDevice != targetDevice) {
                    showToastMessage(AppLocalizations.of(context)!.deviceConnectionOngoingMsg);

                    isConnecting = true;
                    bool isConnected = await connectWithDevice(targetDevice);

                    if (isConnected) {
                      showToastMessage(AppLocalizations.of(context)!.deviceConnectionSucceedMsg);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    } else {
                      showToastMessage(AppLocalizations.of(context)!.deviceConnectionFailedMsg);
                      Navigator.of(context).pop();
                    }

                    isConnecting = false;
                  } else {
                    showToastMessage(AppLocalizations.of(context)!.deviceConnectionAlreadyMsg);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
            content: SizedBox(
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15, right: 8, left: 8),
                    child: Text("${AppLocalizations.of(context)!.deviceNameTag}: ${getDeviceName(targetDevice)}",
                      style: deviceConnectionDialogTextStyle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8, bottom: 15),
                    child: Text(getDeviceMACId(targetDevice),
                      style: deviceConnectionDialogTextStyle.copyWith(color: Colors.orange),
                    ),
                  ),

                  Text(AppLocalizations.of(context)!.deviceConnectionDialogMsg,
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

  @override
  void initState() {
    super.initState();
    deviceList = [];
    isScanning = false;
    isConnecting = false;

    scan();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(!isConnecting),  // Cannot go back if connecting

      child: Scaffold(
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

                actions: <Widget>[
                  IconButton(
                    icon: Icon(isScanning ? Icons.refresh_outlined : Icons.add,),
                    tooltip: AppLocalizations.of(context)!.settingsMenuTitle,
                    onPressed: scan,
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
                    deviceList.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          if (!isConnecting) {
                            registerBluetoothDevice(deviceList[index]);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
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
                                    Text(getDeviceName(deviceList[index]), style: deviceIdStyle,),
                                    Text(getDeviceMACId(deviceList[index]), style: deviceIdStyle.copyWith(color: Colors.orange),),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                  }),
                ),
              ),

              /* ADD NEW DEVICE CONNECTION ELEMENT HERE */

            ],
          ),
        ),
      ),
    );
  }
}