class Split {
  final double distance; // in meters
  final int movingTime; // in seconds
  final double averageSpeed; // in m/s

  Split({
    required this.distance,
    required this.movingTime,
    required this.averageSpeed,
  });

  factory Split.fromJson(Map<String, dynamic> json) {
    return Split(
      distance: (json['distance'] ?? 0.0).toDouble(),
      movingTime: json['moving_time'] ?? 0,
      averageSpeed: (json['average_speed'] ?? 0.0).toDouble(),
    );
  }
}

class StravaActivity {
  final int id;
  final String name;
  final String type;
  final double distance; // in meters
  final int movingTime; // in seconds
  final int elapsedTime; // in seconds
  final double totalElevationGain;
  final DateTime startDateLocal;
  final double? averageSpeed; // in m/s
  final double? averageHeartrate;
  final double? averageCadence;
  final List<Split>? splits;

  StravaActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.movingTime,
    required this.elapsedTime,
    required this.totalElevationGain,
    required this.startDateLocal,
    this.averageSpeed,
    this.averageHeartrate,
    this.averageCadence,
    this.splits,
  });

  factory StravaActivity.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? splitsJson = json['splits_metric'];
    final List<Split>? splits =
        splitsJson?.map((s) => Split.fromJson(s)).toList();

    return StravaActivity(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Activity',
      type: json['type'] ?? 'Unknown',
      distance: (json['distance'] ?? 0.0).toDouble(),
      movingTime: json['moving_time'] ?? 0,
      elapsedTime: json['elapsed_time'] ?? 0,
      totalElevationGain: (json['total_elevation_gain'] ?? 0.0).toDouble(),
      startDateLocal: DateTime.parse(json['start_date_local']),
      averageSpeed: (json['average_speed'] as num?)?.toDouble(),
      averageHeartrate: (json['average_heartrate'] as num?)?.toDouble(),
      // Cadence is often steps per minute * 2 in Strava API for running
      averageCadence: (json['average_cadence'] as num?)?.toDouble(),
      splits: splits,
    );
  }

  // Helper to get distance in kilometers
  double get distanceInKm => distance / 1000;

  // Helper to format moving time into HH:MM:SS
  String get formattedMovingTime {
    final duration = Duration(seconds: movingTime);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}