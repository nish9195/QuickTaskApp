import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Back4App {

    static Future<void> connectToDB() async {
        const keyApplicationId = 'PPJJmYCS4ON6vG9YiKKGDKZUqV9u3vm14d23DiPe';
        const keyClientKey = '1AK7aZkNREjGDaICGcMJjVLPIIHa0oN8mIhi1k6W';
        const keyParseServerUrl = 'https://parseapi.back4app.com';

        await Parse().initialize(keyApplicationId, keyParseServerUrl, clientKey: keyClientKey, debug: true);
    }

}