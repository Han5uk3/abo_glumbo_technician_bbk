
class GeohashHelper {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode(double latitude, double longitude, {int precision = 10}) {
    var latMin = -90.0, latMax = 90.0;
    var lonMin = -180.0, lonMax = 180.0;
    var geohash = StringBuffer();
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (geohash.length < precision) {
      if (isEven) {
        var mid = (lonMin + lonMax) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        var mid = (latMin + latMax) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return geohash.toString();
  }
}
