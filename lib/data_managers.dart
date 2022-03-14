import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
 * Methods for datetime management
 *   - dateTime2String:
 *       convert DateTime to String
 *   - string2DateTime:
 *       convert String to DateTime
 */

String dateTime2String(DateTime targetDate) {
  return DateFormat('yyyy-MM-dd').format(targetDate);
}

DateTime string2DateTime(String targetString) {
  return DateTime.parse(targetString.substring(0, 10));
}


/*
 * Methods for reading and saving settings
 *   - settingsFile:
 *       returns File object for read and save application settings
 *   - readSettings:
 *       read application settings from settings File object
 *   - saveSettings:
 *       save application settings to settings File object
 *   - initializeSettings:
 *       initialize application settings (main function must call this function
 *       before running the applicaiton)
 *
 * Application settings:
 *   - defaultApplicationSettings:
 *       default settings
 *   - applicationSettings:
 *       actual application settings (needs to be initialized in main function)
 */

Map<String, String> defaultApplicationSettings = {
  'userName': 'default',
  'email': 'default',
  'profileImageUrl': 'default',
  'themeName': 'red',
  'autoSyncActivated': 'false',
  'isLoginInitialized': 'false',
};

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

Future<void> initializeSettings() async {
  Map<String, String> savedApplicationSettings = await readSettings();

  for (String settingsKey in defaultApplicationSettings.keys) {
    applicationSettings[settingsKey] = defaultApplicationSettings[settingsKey]!;
  }

  for (String settingsKey in savedApplicationSettings.keys) {
    applicationSettings[settingsKey] = savedApplicationSettings[settingsKey]!;
  }

  if (applicationSettings['isLoginInitialized'] == 'true') {
    await loginActivation();
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
 *   - isLoginActivated:
 *       checks whether login activated
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
    applicationSettings['isLoginInitialized'] = 'true';
    await saveSettings(applicationSettings);
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
    applicationSettings['isLoginInitialized'] = 'false';
    await saveSettings(applicationSettings);
  } catch (e) {
    return Future.error('google logout activation error occurred ($e)');
  }
}


/*
 * Module for downloading and uploading schedules
 *   - Description: Download and upload schedule data (uses google drive API)
 *
 * Methods
 *   - findScheduleDirID:
 *       find out schedule directory ID
 *   - download:
 *       download schedule of given date from user's google drive storage
 *   - upload:
 *       upload schedule of given date to user's google drive storage
 */

const String rootDirName = "Ice Cream Hub";  // Root directory name
const String scheduleDirName = "Schedules";  // Schedule directory name
const String folderMimeType = "application/vnd.google-apps.folder";  // Folder mimetype
const String textContentType = "text/plain; charset=UTF-8";  // Text file mimetype (encoded as UTF-8)

class ScheduleDownloader {
  Future<String> findScheduleDirID() async {
    try {
      String? rootDirID;      // root directory ID
      String? scheduleDirID;  // schedule directory ID

      // Find out root directory ID
      final rootDirList = await driveApi!.files.list(spaces: 'drive',
        q: "mimeType = '$folderMimeType' and name = '$rootDirName' and trashed = false",
      );

      if (rootDirList.files!.isEmpty) {  // If there's no root directory, make new one
        final rootDirFile = drive.File();
        rootDirFile.name = rootDirName;
        rootDirFile.mimeType = folderMimeType;
        final result = await driveApi!.files.create(rootDirFile);
        rootDirID = result.id;
      } else {
        rootDirID = rootDirList.files!.first.id!;
      }

      // Find out schedule directory ID
      final scheduleDirList = await driveApi!.files.list(spaces: 'drive',
        q: "mimeType = '$folderMimeType' and name = '$scheduleDirName' and trashed = false and '$rootDirID' in parents",
      );

      if (scheduleDirList.files!.isEmpty) {  // If there's no schedule directory, make new one
        final scheduleDirFile = drive.File();
        scheduleDirFile.name = rootDirName;
        scheduleDirFile.mimeType = folderMimeType;
        final result = await driveApi!.files.create(scheduleDirFile);
        scheduleDirID = result.id;
      } else {
        scheduleDirID = scheduleDirList.files!.first.id!;
      }

      return scheduleDirID!;
    } catch (e) {
      return Future.error('Schedule directory not defined due to fatal error ($e)');
    }
  }

  Future<List> download(String targetDate) async {
    try {
      // Find out target text file
      final scheduleDirID = await findScheduleDirID();
      final targetFileList = await driveApi!.files.list(spaces: 'drive',
        q: "name = '$targetDate.csv' and trashed = false and '$scheduleDirID' in parents",
      );

      if (targetFileList.files!.isEmpty) { return []; }  // return empty list if there's no target file

      final targetFileID = targetFileList.files!.first.id;

      // Send HTTP reauest to Google drive API v3
      http.Response req = await authenticateClient!.get(Uri.parse("https://www.googleapis.com/drive/v3/files/$targetFileID?alt=media"),);
      String targetContent = utf8.decode(req.bodyBytes);

      // Parse response
      List parsedTargetContent = targetContent.split('\n');
      for (int index = 0; index < parsedTargetContent.length; index++) {
        parsedTargetContent[index] = parsedTargetContent[index]!.split(',');
      }

      return parsedTargetContent;
    } catch (e) {
      return Future.error('Cannot download schedule of $targetDate due to fatal error ($e)');
    }
  }

  Future<void> upload(String targetDate, List content) async {
    try {
      // Encode content into utf8 (CSV text file format)
      List lineConcat = [];
      for (int index = 0; index < content.length; index++) {
        lineConcat.add(content[index].join('\n'));
      }
      List<int> encodedContents = utf8.encode(lineConcat.join('\n'));  // actual data transferred via Google drive API

      // Find out target file ID
      final scheduleDirID = await findScheduleDirID();
      final targetFileList = await driveApi!.files.list(spaces: 'drive',
        q: "name = '$targetDate.csv' and trashed = false and '$scheduleDirID' in parents",
      );

      // Remove all the existing targetFiles
      while (targetFileList.files!.isNotEmpty) {
        driveApi!.files.delete(targetFileList.files!.first.id!);
        targetFileList.files!.removeAt(0);
      }

      // Generate new target file
      final targetFile = drive.File();
      targetFile.name = "$targetDate.csv";
      targetFile.parents = [scheduleDirID];

      // Transfer encoded content via Google drive API
      Stream<List<int>> mediaStream = Future.value(encodedContents).asStream().asBroadcastStream();
      var media = drive.Media(mediaStream, encodedContents.length, contentType: "text/plain; charset=UTF-8");
      final result = await driveApi!.files.create(targetFile, uploadMedia: media,);

      print("Backup file ${targetFile.name} as file id  ${result.id}");

      return;
    } catch (e) {
      return Future.error('Cannot upload schedule of $targetDate due to fatal error ($e)');
    }
  }
}