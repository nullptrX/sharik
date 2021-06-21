import 'dart:io';

import 'package:ackee_dart/ackee_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../components/page_router.dart';
import '../conf.dart';
import '../logic/language.dart';
import '../logic/sharing_object.dart';
import '../logic/theme.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    init();
  }

  Future<void> init() async {
    await Future.delayed(Duration.zero);

    if (context.read<LanguageManager>().initialized ||
        context.read<ThemeManager>().initialized) {
      return;
    }

    try {
      Hive.registerAdapter(SharingObjectTypeAdapter());
      Hive.registerAdapter(SharingObjectAdapter());

      if (Platform.isIOS || Platform.isAndroid) {
        await Hive.initFlutter();
      } else {
        Hive.init('sharik_storage');
      }

      await Hive.openBox<String>('strings');
      await Hive.openBox<SharingObject>('history');

      context.read<LanguageManager>().init();
      context.read<ThemeManager>().init();

      _initAnalytics(context);

      LicenseRegistry.addLicense(() async* {
        final fonts = ['Andika', 'Comfortaa', 'JetBrains', 'Poppins'];

        for (final el in fonts) {
          final license =
              await rootBundle.loadString('google_fonts/$el/OFL.txt');
          yield LicenseEntryWithLineBreaks(['google_fonts'], license);
        }
      });

      if (Platform.isAndroid || Platform.isIOS) {
        final sharedData = await ReceiveSharingIntent.getInitialMedia();

        if (sharedData.length > 1) {
          SharikRouter.navigateTo(
              context,
              _globalKey,
              Screens.error,
              RouteDirection.right,
              'Sorry, you can only share 1 file at a time');
          return;
        }

        if (sharedData.length == 1) {
          SharikRouter.navigateTo(
              context,
              _globalKey,
              Screens.sharing,
              RouteDirection.right,
              SharingObject(
                  type: SharingObjectType.file,
                  data: sharedData[0].path,
                  name: SharingObject.getSharingName(
                    SharingObjectType.file,
                    sharedData[0].path,
                  )));
          return;
        }
      }

      SharikRouter.navigateTo(
          context,
          _globalKey,
          Hive.box<String>('strings').containsKey('language')
              ? Screens.home
              : Screens.languagePicker,
          RouteDirection.right);
    } catch (error, trace) {
      SharikRouter.navigateTo(context, _globalKey, Screens.error,
          RouteDirection.right, '$error \n\n $trace');
    }
  }

  @override
  Widget build(BuildContext context) {

    return RepaintBoundary(
      key: _globalKey,
      child: Scaffold(
          backgroundColor: Colors.deepPurple.shade400,
          body: Center(
            child: SvgPicture.asset('assets/logo_inverse.svg',
                height: 60,
                semanticsLabel: 'Sharik app icon',
                color: Colors.grey.shade300),
          )),
    );
  }
}

Future<void> _initAnalytics(BuildContext context) async {
  if (!kReleaseMode) {
    print('Analytics is disabled since running in the debug mode');
    return;
  }

  startAckee(
    Uri.parse('https://ackee.mark.vin/api'),
    '0a143aeb-7105-449f-a2be-ed03b5674e96',
    Attributes(
      location: 'https://sharik.app',
      osName: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      referrer: source2url(source),
      screenWidth: MediaQuery.of(context).size.width,
      screenHeight: MediaQuery.of(context).size.height,
      browserWidth: MediaQuery.of(context).size.width,
      browserHeight: MediaQuery.of(context).size.height,
      browserName: 'Sharik ${context.read<LanguageManager>().language.name}',
      browserVersion: currentVersion,
      deviceName: Platform.localHostname,
      deviceManufacturer: Platform.operatingSystem,
      language: Localizations.localeOf(context).languageCode,
    ),
  );
}
