enum ConnectionErrorCode {
  timeoutNotReceivedData('Timeout Not receiving data during expected time'),
  unknownData('Unknown data received from the device'),
  wifiLost('Unexpectedly connection to the device lost'),
  timeoutNotConnected('The device was not connected within the expected number of attempts'),
  unableToGetIpOnModem('Unable to get Ip of panel on the Modem'),
  unableToGetIpStatic('Unable to get static Ip'),
  // unableToGetWifiName('Unable to get the WIFI name'),
  emptyLocation('There is no location to connect'),
  errorInSocket('An error occurred in Socket'),
  socketClosedByOtherSide('Socket Connection closed by the other side'),
  repeatedLocation('repeated Location!!!!'),
  gottenIpFromLocationIsNull(' Gotten Ip of location is Null');

  final String value;
  const ConnectionErrorCode(this.value);

}
