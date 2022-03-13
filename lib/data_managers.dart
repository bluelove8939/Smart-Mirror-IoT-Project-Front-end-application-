import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;  // read assets text file
import 'package:googleapis/drive/v3.dart' as drive;  // Google drive
import 'package:google_sign_in/google_sign_in.dart' as sign_in;  // Google signin


/*
 * Methods for application directory
 *   - applicationDirectoryPath:
 *       returns path String object of application directory
 */

Future<String> applicationDirectoryPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}


/*
 * Methods for reading API keys
 *   - readApikeys: read API keys from File object storing API keys
 *
 * Note:
 *   To use some apis supported, you should manually add apikeys.txt to
 *   'assets/keys/' directory.
 *
 * Keys to add:
 *   - openweathermap
 */

Future<Map<String, String>> readApikeys() async {
  try {
    String content = await rootBundle.loadString('assets/keys/apikeys.txt');
    Map<String, String> parsedContent = {};
    for (String line in content.split('\n')) {
      List<String> commaParsed = line.split(',');
      parsedContent[commaParsed[0]] = commaParsed[1];
    }
    return parsedContent;
  } catch (e) {
    print('Cannot read apikeys file ($e)');
    return {};
  }
}


/*
 * Methods for reading and saving settings
 *   - settingsFile: returns File object for read and save application settings
 *   - readSettings: read application settings from settings File object
 *   - saveSettings: save application settings to settings File object
 */

// Default application settings
Map<String, String> defaultApplicationSettings = {
  'userName': 'default',
  'email': 'default',
  'profileImageUrl': 'default',
  'themeName': 'red',
  'autoSyncActivated': 'false'
};

// Application settings (change application settings before running the app, especially main function)
Map<String, String> applicationSettings = {};

Future<File> settingsFile() async {
  final targetPath = await applicationDirectoryPath();
  return File('$targetPath/settings.csv');
}

Future<Map<String, String>> readSettings() async {
  try {
    File targetFile = await settingsFile();
    String content = await targetFile.readAsString(encoding: utf8);
    Map<String, String> parsedContent = {};
    for (String line in content.split('\n')) {
      List<String> commaParsed = line.split(',');
      parsedContent[commaParsed[0]] = commaParsed[1];
    }
    return parsedContent;
  } catch (e) {
    print('Cannot read settings file ($e)');
    return {};
  }
}

Future<void> saveSettings(Map<String, String> settingsContent) async {
  try {
    File targetFile = await settingsFile();
    List<String> lines = [];
    for (String settingsKey in settingsContent.keys) {
      lines.add('$settingsKey,${settingsContent[settingsKey]!}');
    }
    targetFile.writeAsString(lines.join('\n'), encoding: utf8);
  } catch (e) {
    print('Cannot save settings file ($e)');
    return;
  }
}


/*
 * Module for downloading weather data
 *   - Description: Download weather data via openweathermap api by using
 *                  current location from geoLocator package
 *
 * Methods
 *   - determinePosition:
 *       returns current position using Locaiton package (GPS)
 *       reference code from geoLocator package (identifies current positions)
 *   - refreshWeather:
 *       returns http response from openweathermap API by using current locaiton data
 */

class WeatherDataDownloader {
  String? _weatherApiKey;

  Future<LocationData> determinePosition() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return Future.error('location service disabled');
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return Future.error('location permission denied');
      }
    }

    _locationData = await location.getLocation();

    return _locationData;
  }

  Future<Map> refreshWeather({String langCode = 'en', String locale = 'en_US'}) async {
    if (_weatherApiKey == null) {
      Map apikeys = await readApikeys();
      _weatherApiKey = apikeys['openweathermap'];
    }

    var currentPosition = await determinePosition();
    String lat = currentPosition.latitude.toString();
    String lon = currentPosition.longitude.toString();
    String targetUrlString = 'http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric&lang=$langCode';
    var response = await http.get(Uri.parse(targetUrlString));

    if (response.statusCode == 200) {
      var data = response.body;
      var dataJson = jsonDecode(data);
      dataJson['weathericon'] = Image.network('http://openweathermap.org/img/wn/${dataJson['weather'][0]['icon']}@2x.png', width: 50, height: 40,);
      dataJson['refreshDateTime'] = DateFormat('yyyy-MM-dd hh:mm', locale).format(DateTime.now());
      return dataJson;
    } else {
      return Future.error('Cannot invoke weather data (http request error ${response.statusCode})');
    }
  }
}


/*
 * Module for google sign in authentication
 *   - Description: http client module for sign in authentication
 *
 * Methods
 *   - send:
 *       overriden method of http.BaseClient which sends request by using predefined header information
 *       (especially google account authHeaders)
 */

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;         // google account header (account.authHeaders)
  final http.Client _client = http.Client();  // body of client

  GoogleAuthClient(this._headers);  // insert header when generating client

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {  // overriden send method of client
    return _client.send(request..headers.addAll(_headers));       // just return response of http.Client()
  }
}


/*
 * Methods for google sign in and drive API manipulation
 *   - loginActivation:
 *       google sign in method (generates authenticated google account, http client and  drive api module)
 *       account, client and drive API module are null if user not signed in google service
 *   - logoutActivation:
 *       google sign out method (initializes every login elements)
 */

sign_in.GoogleSignIn? googleSignIn;        // sign in module
sign_in.GoogleSignInAccount? userAccount;  // user account (including authHeaders)
GoogleAuthClient? authenticateClient;      // google signin http client (defined below)
drive.DriveApi? driveApi;                  // drive api module

bool isLoginActivated() {
  return !(userAccount == null || authenticateClient == null || driveApi == null);
}

Future<void> loginActivation() async {
  try {
    googleSignIn = sign_in.GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);  // genreate sign in module
    userAccount = await googleSignIn!.signIn();  // generate account
    authenticateClient = GoogleAuthClient(await userAccount!.authHeaders);  // generate http client
    driveApi = drive.DriveApi(authenticateClient!);  // genereate google drive API module

    // Update applicaiton settings
    applicationSettings['userName'] = userAccount!.displayName!;
    applicationSettings['email'] = userAccount!.email;
    applicationSettings['profileImageUrl'] = userAccount!.photoUrl!;
  } catch (e) {
    return Future.error('google login activation error occurred ($e)');
  }
}

Future<void> logoutActivation() async {
  try {
    await googleSignIn!.signOut();  // sign out to google service
    userAccount = null;
    authenticateClient = null;
    driveApi = null;

    // Update applicaiton settings
    applicationSettings['userName'] = defaultApplicationSettings['userName']!;
    applicationSettings['email'] = defaultApplicationSettings['email']!;
    applicationSettings['profileImageUrl'] = defaultApplicationSettings['profileImageUrl']!;
  } catch (e) {
    return Future.error('google logout activation error occurred ($e)');
  }
}