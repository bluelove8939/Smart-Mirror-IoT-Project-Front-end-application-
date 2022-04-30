import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


// convert string to boolean
bool string2Bool(String targetString) {
  if (targetString == 'true') {
    return true;
  }
  return false;
}


// scroll glow effect deleted scroll behavior
class GlowRemovedBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}


Widget generateMonthlyDataChart(Map monthlyData, String xTitle, String xSuffix) {
  print("============== monthlyData: $monthlyData");
  List dataKeys = monthlyData.keys.toList();
  dataKeys.sort();
  dataKeys = dataKeys.sublist(dataKeys.length - 7);

  final chartData = LineChartData(
    gridData: FlGridData(
      show: true,
      drawVerticalLine: true,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: const Color(0xff37434d),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: const Color(0xff37434d),
          strokeWidth: 0.5,
        );
      },
    ),

    titlesData: FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        axisNameWidget: Text(xTitle, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold,
        ),),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35,
          getTitlesWidget: (double value, TitleMeta meta) {
            TextStyle titleStyle =  const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            );
            String titleValue = "";

            if (value.isFinite && value == value.roundToDouble() && value.toInt() < dataKeys.length) {
              titleValue = "${dataKeys[value.toInt()].split('-')[1]}$xSuffix";
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(titleValue, style: titleStyle, textAlign: TextAlign.right,),
            );
          },
        ),
      ),

      leftTitles: AxisTitles(
        sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (double value, TitleMeta meta) {
              TextStyle titleStyle =  const TextStyle(
                  color: Color(0xff68737d),
                  fontWeight: FontWeight.bold,
                  fontSize: 14);
              String titleValue = '';

              if (value.isFinite && 0 < value.toInt() && value.toInt() <= 100) {
                titleValue = (value.toInt()).toString();
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(titleValue.toString(), style: titleStyle, textAlign: TextAlign.left,),
              );
            }
        ),
      ),

      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),

      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    ),

    borderData: FlBorderData(
      show: false,
      border: Border.all(color: const Color(0xff37434d), width: 1,),
    ),

    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 100,

    lineBarsData: [
      LineChartBarData(
        spots: List.generate(dataKeys.length, (index) => FlSpot(
          index.toDouble(),  // x
          double.parse(monthlyData[dataKeys[index]]),  // y
        ),),
        isCurved: false,
        color: Colors.black,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
        ),
        belowBarData: BarAreaData(
          show: false,
          color: Colors.black,
        ),
      ),
    ],
  );

  return LineChart(chartData);
}