import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
class DatabaseService {

  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('agrichain.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // ==================== CREATE TABLES ====================
  Future _createDB(Database db, int version) async {

    // 1. FARMERS TABLE
    await db.execute('''
      CREATE TABLE farmers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cnic TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        land_owned TEXT NOT NULL,
        farm_location TEXT NOT NULL,
        home_location TEXT NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. SHOPKEEPERS TABLE
    await db.execute('''
      CREATE TABLE shopkeepers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cnic TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        shopkeeper_name TEXT NOT NULL,
        age INTEGER NOT NULL,
        shop_name TEXT NOT NULL,
        shop_address TEXT NOT NULL,
        shop_size TEXT NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. BUYERS TABLE
    await db.execute('''
      CREATE TABLE buyers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cnic TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. CROPS TABLE (Farmer jo fasal sell karta hai)
    await db.execute('''
      CREATE TABLE crops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id INTEGER NOT NULL,
        crop_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price_per_kg REAL NOT NULL,
        location TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT DEFAULT 'available',
        created_at TEXT NOT NULL,
        FOREIGN KEY (farmer_id) REFERENCES farmers(id)
      )
    ''');

    // 5. ORDERS TABLE (Buyer ya Shopkeeper jo order karta hai)
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop_id INTEGER NOT NULL,
        buyer_id INTEGER,
        shopkeeper_id INTEGER,
        quantity REAL NOT NULL,
        total_price REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        order_date TEXT NOT NULL,
        FOREIGN KEY (crop_id) REFERENCES crops(id),
        FOREIGN KEY (buyer_id) REFERENCES buyers(id),
        FOREIGN KEY (shopkeeper_id) REFERENCES shopkeepers(id)
      )
    ''');

    // 6. GOVT PRICES TABLE (Government jo price set karta hai)
    await db.execute('''
      CREATE TABLE govt_prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop_name TEXT NOT NULL,
        min_price REAL NOT NULL,
        max_price REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // ==================== FARMER ====================

  // Farmer Register
  Future<int> insertFarmer(Map<String, dynamic> farmer) async {
    final db = await database;
    return await db.insert('farmers', farmer);
  }

  // Farmer Login
  Future<Map<String, dynamic>?> loginFarmer(String cnic, String password) async {
    final db = await database;
    final result = await db.query(
      'farmers',
      where: 'cnic = ? AND password = ?',
      whereArgs: [cnic, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Farmer Read
  Future<List<Map<String, dynamic>>> getAllFarmers() async {
    final db = await database;
    return await db.query('farmers');
  }

  // Farmer Update
  Future<int> updateFarmer(Map<String, dynamic> farmer) async {
    final db = await database;
    return await db.update(
      'farmers',
      farmer,
      where: 'id = ?',
      whereArgs: [farmer['id']],
    );
  }

  // Farmer Delete
  Future<int> deleteFarmer(int id) async {
    final db = await database;
    return await db.delete('farmers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SHOPKEEPER CRUD ====================

  // Shopkeeper Register
  Future<int> insertShopkeeper(Map<String, dynamic> shopkeeper) async {
    final db = await database;
    return await db.insert('shopkeepers', shopkeeper);
  }

  // Shopkeeper Login
  Future<Map<String, dynamic>?> loginShopkeeper(String cnic, String password) async {
    final db = await database;
    final result = await db.query(
      'shopkeepers',
      where: 'cnic = ? AND password = ?',
      whereArgs: [cnic, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Shopkeeper Read
  Future<List<Map<String, dynamic>>> getAllShopkeepers() async {
    final db = await database;
    return await db.query('shopkeepers');
  }

  // Shopkeeper Update
  Future<int> updateShopkeeper(Map<String, dynamic> shopkeeper) async {
    final db = await database;
    return await db.update(
      'shopkeepers',
      shopkeeper,
      where: 'id = ?',
      whereArgs: [shopkeeper['id']],
    );
  }

  // Shopkeeper Delete
  Future<int> deleteShopkeeper(int id) async {
    final db = await database;
    return await db.delete('shopkeepers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== BUYER CRUD ====================

  // Buyer Register
  Future<int> insertBuyer(Map<String, dynamic> buyer) async {
    final db = await database;
    return await db.insert('buyers', buyer);
  }

  // Buyer Login
  Future<Map<String, dynamic>?> loginBuyer(String cnic, String password) async {
    final db = await database;
    final result = await db.query(
      'buyers',
      where: 'cnic = ? AND password = ?',
      whereArgs: [cnic, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Buyer Read
  Future<List<Map<String, dynamic>>> getAllBuyers() async {
    final db = await database;
    return await db.query('buyers');
  }

  // Buyer Update
  Future<int> updateBuyer(Map<String, dynamic> buyer) async {
    final db = await database;
    return await db.update(
      'buyers',
      buyer,
      where: 'id = ?',
      whereArgs: [buyer['id']],
    );
  }

  // Buyer Delete
  Future<int> deleteBuyer(int id) async {
    final db = await database;
    return await db.delete('buyers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CROPS CRUD ====================

  // Crop Add
  Future<int> insertCrop(Map<String, dynamic> crop) async {
    final db = await database;
    return await db.insert('crops', crop);
  }

  // All Crops
  Future<List<Map<String, dynamic>>> getAllCrops() async {
    final db = await database;
    return await db.query('crops', where: "status = 'available'");
  }

  // Farmer ki apni crops
  Future<List<Map<String, dynamic>>> getFarmerCrops(int farmerId) async {
    final db = await database;
    return await db.query(
      'crops',
      where: 'farmer_id = ?',
      whereArgs: [farmerId],
    );
  }

  // Crop Update
  Future<int> updateCrop(Map<String, dynamic> crop) async {
    final db = await database;
    return await db.update(
      'crops',
      crop,
      where: 'id = ?',
      whereArgs: [crop['id']],
    );
  }

  // Crop Delete
  Future<int> deleteCrop(int id) async {
    final db = await database;
    return await db.delete('crops', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ORDERS CRUD ====================

  // Order Place
  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('orders', order);
  }

  // All Orders
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    return await db.query('orders');
  }

  // Buyer ke orders
  Future<List<Map<String, dynamic>>> getBuyerOrders(int buyerId) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'buyer_id = ?',
      whereArgs: [buyerId],
    );
  }

  // Order status update
  Future<int> updateOrderStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== GOVT PRICES CRUD ====================

  // Price Add
  Future<int> insertGovtPrice(Map<String, dynamic> price) async {
    final db = await database;
    return await db.insert('govt_prices', price);
  }

  // All Prices
  Future<List<Map<String, dynamic>>> getAllGovtPrices() async {
    final db = await database;
    return await db.query('govt_prices');
  }

  // Price Update
  Future<int> updateGovtPrice(Map<String, dynamic> price) async {
    final db = await database;
    return await db.update(
      'govt_prices',
      price,
      where: 'id = ?',
      whereArgs: [price['id']],
    );
  }

  // ==================== CLOSE ====================
  Future close() async {
    final db = await database;
    db.close();
  }
}