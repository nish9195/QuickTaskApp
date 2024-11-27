import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Back4App {

    static Future<void> connectToDB() async {
        const keyApplicationId = '<YOUR_APP_ID';
        const keyClientKey = '<YOUR_CLIENT_KEY>';
        const keyParseServerUrl = 'https://parseapi.back4app.com';

        await Parse().initialize(keyApplicationId, keyParseServerUrl, clientKey: keyClientKey, debug: true);
    }

}