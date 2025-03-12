import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/home_page.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/device_manage.dart';
import 'package:warehouse_phase_1/src/helpers/log_cat.dart';

class SqlHelper {
  // Call this function at the start of your application to initialize the database factory
  static void initializeDatabaseFactory() {
    if (!kIsWeb) {
      sqfliteFfiInit();
      sql.databaseFactory = databaseFactoryFfi;
    }
  }

  // Function to create tables
  static Future<void> createTables(sql.Database database) async {
    await database.execute(
      """
      CREATE TABLE info(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        manufacturer TEXT,
        model TEXT,
        iemi TEXT UNIQUE,
        sno TEXT ,
        ram TEXT,
        mdm_status TEXT,
        oem TEXT,
        rom_gb TEXT,              -- New column for ROM size in GB
        carrier_lock_status TEXT, -- New column for carrier lock status
        ver TEXT,
        isSync TEXT,
       
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """,
    );
  }

  // Function to upgrade the database schema when the version changes
  static Future<void> upgradeDatabase(
      sql.Database database, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add columns added in version 2
      await database.execute("ALTER TABLE info ADD COLUMN ram TEXT;");
      await database.execute("ALTER TABLE info ADD COLUMN mdm_status TEXT;");
      await database.execute("ALTER TABLE info ADD COLUMN oem TEXT;");
    }
    if (oldVersion < 4) {
      // Add new columns for version 3
      await database.execute("ALTER TABLE info ADD COLUMN rom_gb TEXT;");
      await database
          .execute("ALTER TABLE info ADD COLUMN carrier_lock_status TEXT;");
    }
    if (oldVersion < 5) {
      // Add new columns for version 3
      await database.execute("ALTER TABLE info ADD COLUMN ver TEXT;");
      //await database.execute("ALTER TABLE info ADD COLUMN carrier_lock_status TEXT;");
    }
    if (oldVersion < 6) {
      // Add new columns for version 3
      await database.execute("ALTER TABLE info ADD COLUMN isSync TEXT;");
      //await database.execute("ALTER TABLE info ADD COLUMN carrier_lock_status TEXT;");
    }
  }

  // Function to open or create a new database
  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'new_databasev7.db', // Updated database name
      version: 7, // Incremented version number to trigger schema upgrade
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
      onUpgrade: (sql.Database database, int oldVersion, int newVersion) async {
        await upgradeDatabase(database, oldVersion, newVersion);
      },
    );
  }

  // Function to insert a new item into the 'info' table
  // Function to insert a new item into the 'info' table
  static Future<int> createItem(
      String? manufacturer,
      String? model,
      String? iemi,
      String? sno,
      String? ram,
      String? mdm,
      String? oem,
      String? romGb,
      String? carrierLockStatus,
      String? ver,
      String? isSync,
    
      ) async {
    final db = await SqlHelper.db();

    // Check if a device with either the same IMEI or SNO exists
    final List<Map<String, dynamic>> existingItems = await db.query(
      'info',
      where: 'iemi = ? OR sno = ?',
      whereArgs: [iemi, sno],
    );

    final data = {
      'manufacturer': manufacturer,
      'model': model,
      'iemi': iemi,
      'sno': sno,
      'ram': ram,
      'mdm_status': mdm,
      'oem': oem,
      'rom_gb': romGb,
      'carrier_lock_status': carrierLockStatus,
      'ver': ver,
      'isSync': isSync,
      //'createdAt':createdAt
    };

    if (existingItems.isNotEmpty) {
      // Update the existing device
      final id = existingItems.first['id'];
      try {
        return await db.update(
          'info',
          data,
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      } catch (e) {
        print('Error updating device: $e');
        return -1;
      }
    } else {
      // Insert new device
      try {
        return await db.insert('info', data,
            conflictAlgorithm: sql.ConflictAlgorithm.abort);
      } catch (e) {
        print('Error inserting device: $e');
        return -1;
      }
    }
  }

  // Function to retrieve all items from the 'info' table
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SqlHelper.db();
    return db.query('info', orderBy: "id");
  }

  // Function to delete an item from the 'info' table by its ID
  static Future<int> deleteItem(int id, String? sno) async {
    await DeviceProgressManager.deleteProgress(sno ?? 'n/a');
   // await LogCat.clearDeviceLogs(sno ?? 'n/a');
    final db = await SqlHelper.db();

    return await db.delete(
      'info',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Function to get item details by iemi or sno
  static Future<Map<String, dynamic>?> getItemDetails(String? deviceId) async {
    final db = await SqlHelper.db();
    final List<Map<String, dynamic>> result = await db.query(
      'info',
      where: 'sno = ?',
      whereArgs: [deviceId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // static Future<void> deleteDeviceProgress(String? deviceId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final key = '$deviceId-progress';

  //   if (prefs.containsKey(key)) {
  //     await prefs.remove(key);
  //     print('Progress for device "$deviceId" deleted from SharedPreferences.');
  //   } else {
  //     print('No progress found for device "$deviceId" in SharedPreferences.');
  //   }
  // }
  // Function to retrieve all unsynced items from the 'info' table
  static Future<List<Map<String, dynamic>>> getUnsyncedItems() async {
    final db = await SqlHelper.db();
    return await db.query(
      'info',
      where: 'isSync = ?',
      whereArgs: ['0'],
      orderBy: "id", // Optional: order the results by ID
    );
  }

// Function to update the isSync status of a specific device by deviceId
  static Future<int> markDeviceAsSynced(String deviceId) async {
    final db = await SqlHelper.db();
    // Update the isSync column for the specific deviceId from '0' to '1'
    return await db.update(
      'info',
      {'isSync': '1'}, // Set isSync to '1'
      where:
          'sno = ? AND isSync = ?', // Condition to check the deviceId and isSync status
      whereArgs: [deviceId, '0'],
    );
  }
  static Future<int> markDeviceAsUnSynced(String deviceId) async {
    final db = await SqlHelper.db();
    // Update the isSync column for the specific deviceId from '0' to '1'
    return await db.update(
      'info',
      {'isSync': '0'}, // Set isSync to '0'
      where:
          'sno = ? AND isSync = ?', // Condition to check the deviceId and isSync status
      whereArgs: [deviceId, '1'],
    );
  }

  static Future<int> deleteItemwithId(String? id) async {
    print('delete item in sql $id');
    await DeviceProgressManager.deleteProgress(id ?? 'n/a');
    await LogCat.clearDeviceLogs(id ?? 'n/a');

    final db = await SqlHelper.db();

    // await DeviceProgressManager.deleteProgress(id??'n/a');
    // MyHomePage hm=new MyHomePage(title: 'warehouse application', onThemeToggle: () {  }, onLocaleChange: (Locale ) {  },);
    // hm.resetPercent(id);
    return await db.delete(
      'info',
      where: 'sno = ?',
      whereArgs: [id],
    );
  }
  
    // Function to get the total number of unique IMEI entries
  static Future<int> getTotalItems() async {
    final db = await SqlHelper.db();
    // Query to count distinct IMEI values
    final result = await db.rawQuery(
      "SELECT COUNT(DISTINCT iemi) as total FROM info"
    );

    // Return the count
    return result.first["total"] as int? ?? 0;
  }

  
    // Function to delete all items from the 'info' table
  static Future<void> deleteAllItems() async {
    final db = await SqlHelper.db();
    await db.delete('info');
    print('All items deleted from the "info" table.');
  }

  // Function to delete the database
  static Future<void> deleteDatabase() async {
    final path = await sql.getDatabasesPath();
    final dbPath = '$path/new_databasev6.db'; // Use the new database name
    await databaseFactoryFfi.deleteDatabase(dbPath);
    print("Database deleted: $dbPath");
  }
}
