unit uDatabaseManager;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.Wait,
  Data.DB, FireDAC.Comp.Client;

type
  TDatabaseManager = class
  private
    FConnection: TFDConnection;
    procedure InitializeDatabase;
  public
    constructor Create(const ADatabasePath: string);
    destructor Destroy; override;
    
    // 他のサービスクラスへ接続を提供するプロパティ
    property Connection: TFDConnection read FConnection;
  end;

implementation

{ TDatabaseManager }

constructor TDatabaseManager.Create(const ADatabasePath: string);
begin
  inherited Create;
  FConnection := TFDConnection.Create(nil);
  
  // SQLite 接続設定
  FConnection.Params.Clear;
  FConnection.Params.Add('DriverID=SQLite');
  // 'Database' パラメータを指定しないか空白で開くと、内部的にメモリDBになるが、実ファイルを指定
  FConnection.Params.Add('Database=' + ADatabasePath);
  FConnection.Params.Add('StringFormat=Unicode');
  FConnection.LoginPrompt := False;

  FConnection.Open;
  
  // 起動時の初期化
  InitializeDatabase;
end;

destructor TDatabaseManager.Destroy;
begin
  FConnection.Close;
  FConnection.Free;
  inherited Destroy;
end;

procedure TDatabaseManager.InitializeDatabase;
begin
  // Customers テーブル作成
  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS customers (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL,' +
    '  phone TEXT,' +
    '  address TEXT,' +
    '  member_type TEXT,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ')'
  );

  // Orders テーブル作成
  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS orders (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  customer_id INTEGER NOT NULL,' +
    '  order_date DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  pickup_date DATETIME,' +
    '  status TEXT,' + // 受付、洗浄中、仕上げ中、受取待ち、完了
    '  total_price INTEGER,' +
    '  FOREIGN KEY(customer_id) REFERENCES customers(id)' +
    ')'
  );

  // Order Items テーブル作成
  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS order_items (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  order_id INTEGER NOT NULL,' +
    '  item_type TEXT NOT NULL,' +
    '  quantity INTEGER,' +
    '  unit_price INTEGER,' +
    '  stain_removal INTEGER,' + // 0:なし 1:あり
    '  urgent INTEGER,' +       // 0:なし 1:あり
    '  subtotal INTEGER,' +
    '  FOREIGN KEY(order_id) REFERENCES orders(id)' +
    ')'
  );

  // Payments テーブル作成
  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS payments (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  order_id INTEGER NOT NULL,' +
    '  paid_amount INTEGER,' +
    '  paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  method TEXT,' +
    '  FOREIGN KEY(order_id) REFERENCES orders(id)' +
    ')'
  );
end;

end.
