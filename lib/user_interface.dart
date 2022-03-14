import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';  // toast message

import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // generated localizations
import 'package:iot_project_demo/data_managers.dart';
import 'package:iot_project_demo/interface_tools.dart' as interface_tools;
import 'package:iot_project_demo/color_themes_presets.dart' as color_themes_presets;


// General text styles
TextStyle appBarStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);  // dashboard appbar title
TextStyle userNameStyle = const TextStyle(fontSize: 16, color: Colors.black);  // dashboard username
TextStyle emailStyle = const TextStyle(fontSize: 14, color: Colors.orange);  // dashboard emails
TextStyle deviceIdStyle = const TextStyle(fontSize: 16, color: Colors.black);  // dashboard device id
TextStyle errorTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // indicating error messages
TextStyle settingsWidgetTextStyle = const TextStyle(fontSize: 16, color: Colors.black);  // settings subtitles
TextStyle settingsWidgetSelectedTextStyle = const TextStyle(fontSize: 16, color: Colors.orange);  // settings values

// General border radius
Radius generalBorderRadius = const Radius.circular(15);
BorderRadius dashboardCardBorderRadius = BorderRadius.all(generalBorderRadius);

// General weather data module
WeatherDataDownloader weatherDataDownloader = WeatherDataDownloader();


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
                      }
                      ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/schedules').then((value) {
                      setState(() {});
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                    height: 300,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: dashboardCardBorderRadius,
                    ),
                    child: const Text("Schedules and Tasks"),
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


                /* ADD NEW DEVICE MANAGING ELEMENT HERE */

              ]),
            ),
          ],
        ),
      ),
    );
  }
}