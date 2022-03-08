import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


/*
 * Methods for application directory
 *   - applicationDirectoryPath: returns path String object of application directory
 */

Future<String> applicationDirectoryPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}


/*
 * Methods for read and save settings
 *   - settingsFile: returns File object for read and save application settings
 *   - readSettings: read application settings from settings File object
 *   - saveSettings: save application settings to settings File object
 */

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
 */

class WeatherDataDownloader {
  final _weatherApiKey = 'bfbfaac336f64b9f2b20f8b1bb583e56';


  // Reference code from geoLocator package (identifies current positions)
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Get permission from device
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    var currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(currentPosition);
    return currentPosition;
  }


  Future<Map> refreshWeather({String langCode = 'en', String locale = 'en_US'}) async {
    print(locale);
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