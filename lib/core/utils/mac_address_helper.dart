import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Helper class to get MAC address of the device
class MacAddressHelper {
  static final NetworkInfo _networkInfo = NetworkInfo();

  /// Get MAC address of the device
  /// Returns null if unable to retrieve
  static Future<String?> getMacAddress() async {
    try {
      if (Platform.isWindows) {
        // On Windows, use getmac command to get physical MAC address
        try {
          final result = await Process.run('getmac', ['/fo', 'csv', '/nh'], runInShell: true);
          if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
            final output = result.stdout.toString();
            debugPrint('getmac output: $output');
            // Parse CSV output: "MAC Address","Connection Status"
            // Format: "E0-0A-F6-C3-BA-FF","\Device\Tcpip_{...}"
            final lines = output.split('\n');
            String? activeMacAddress;
            String? anyMacAddress;
            
            for (final line in lines) {
              if (line.trim().isEmpty) continue;
              
              // Extract MAC address from CSV line - first quoted field is the MAC
              final regex = RegExp(r'"([^"]+)"');
              final matches = regex.allMatches(line);
              if (matches.length >= 2) {
                // First match is the MAC address, second is the connection status
                var macAddress = matches.elementAt(0).group(1) ?? '';
                var connectionStatus = matches.elementAt(1).group(1) ?? '';
                macAddress = macAddress.trim();
                connectionStatus = connectionStatus.trim();
                
                // Skip invalid entries
                if (macAddress == 'N/A' || macAddress == 'Media disconnected' || macAddress.isEmpty) {
                  continue;
                }
                
                // Format: XX-XX-XX-XX-XX-XX, convert to XX:XX:XX:XX:XX:XX
                macAddress = macAddress.replaceAll('-', ':');
                
                // Validate MAC address format (should be 17 chars: XX:XX:XX:XX:XX:XX)
                if (macAddress.isNotEmpty && 
                    macAddress != '02:00:00:00:00:00' && 
                    macAddress.length == 17 &&
                    RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$', caseSensitive: false).hasMatch(macAddress)) {
                  final formattedMac = macAddress.toUpperCase();
                  
                  // Prioritize active connections (not "Media disconnected")
                  if (connectionStatus != 'Media disconnected' && !connectionStatus.contains('disconnected')) {
                    debugPrint('Found active MAC address: $formattedMac (Status: $connectionStatus)');
                    activeMacAddress = formattedMac;
                    // Return immediately if we find an active connection
                    return formattedMac;
                  } else {
                    // Store any valid MAC as fallback
                    if (anyMacAddress == null) {
                      anyMacAddress = formattedMac;
                      debugPrint('Found MAC address (inactive): $formattedMac');
                    }
                  }
                }
              }
            }
            
            // Return active MAC if found, otherwise return any valid MAC
            if (activeMacAddress != null) {
              return activeMacAddress;
            } else if (anyMacAddress != null) {
              debugPrint('Using inactive MAC address: $anyMacAddress');
              return anyMacAddress;
            }
          } else {
            debugPrint('getmac command failed with exit code: ${result.exitCode}');
            debugPrint('getmac stderr: ${result.stderr}');
          }
        } catch (e) {
          debugPrint('Error getting MAC via getmac: $e');
        }
        
        // Fallback: try network_info_plus
        try {
          final wifiBSSID = await _networkInfo.getWifiBSSID();
          if (wifiBSSID != null && wifiBSSID.isNotEmpty && wifiBSSID != '02:00:00:00:00:00') {
            debugPrint('Found MAC via network_info_plus: ${wifiBSSID.toUpperCase()}');
            return wifiBSSID.toUpperCase();
          }
        } catch (e) {
          debugPrint('Error getting MAC via network_info_plus: $e');
        }
      } else if (Platform.isAndroid) {
        final wifiBSSID = await _networkInfo.getWifiBSSID();
        if (wifiBSSID != null && wifiBSSID.isNotEmpty && wifiBSSID != '02:00:00:00:00:00') {
          return wifiBSSID.toUpperCase();
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        // iOS/MacOS may not provide MAC address due to privacy restrictions
        // Return a device identifier instead
        return null;
      } else if (Platform.isLinux) {
        // On Linux, try to read from /sys/class/net/
        try {
          final result = await Process.run('sh', ['-c', "ip link show | grep -oP '(?<=link/ether )[^ ]+' | head -1"], runInShell: false);
          if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
            final mac = result.stdout.toString().trim();
            if (mac.isNotEmpty && mac != '02:00:00:00:00:00') {
              return mac.toUpperCase();
            }
          }
        } catch (e) {
          debugPrint('Error getting MAC on Linux: $e');
        }
        return null;
      }
    } catch (e) {
      // If we can't get MAC address, return null
      debugPrint('Error getting MAC address: $e');
      return null;
    }
    return null;
  }

  /// Get a device identifier (fallback if MAC address is not available)
  /// This uses a combination of hostname and other identifiers
  static Future<String> getDeviceIdentifier() async {
    try {
      final hostname = await _networkInfo.getWifiName() ?? 'Unknown';
      return hostname.replaceAll(' ', '_').toUpperCase();
    } catch (e) {
      return 'DEVICE_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}

