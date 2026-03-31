unit uOrderService;

interface

uses
  System.SysUtils, System.Classes, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param;

type
  TOrderItemRecord = record
    ItemType: string;
    Quantity: Integer;
    UnitPrice: Integer;
    StainRemoval: Boolean;
    Urgent: Boolean;
    Subtotal: Integer;
  end;

  TOrderService = class
  private
    FConnection: TFDConnection;
    function GetBasePrice(const AItemType: string): Integer;
  public
    constructor Create(AConnection: TFDConnection);
    
    // ビジネスロジック：小計計算
    function CalculateSubtotal(const AItemType: string; AQuantity: Integer; 
                               AStainRemoval, AUrgent: Boolean): Integer;
    
    // 注文作成
    procedure CreateOrder(ACustomerID: Integer; APickupDate: TDateTime; 
                          const AItems: array of TOrderItemRecord; out ATotalAmount: Integer);
    
    // 注文一覧取得
    function GetOrders(ACustomerID: Integer = -1): TFDQuery;
    
    // 注文ステータス更新 (受付、洗浄中、仕上げ中、受取待ち、完了)
    procedure UpdateOrderStatus(AOrderID: Integer; const ANewStatus: string);
  end;

implementation

{ TOrderService }

constructor TOrderService.Create(AConnection: TFDConnection);
begin
  inherited Create;
  FConnection := AConnection;
end;

function TOrderService.GetBasePrice(const AItemType: string): Integer;
begin
  if AItemType = 'シャツ' then Result := 300
  else if AItemType = 'スーツ' then Result := 1200
  else if AItemType = 'コート' then Result := 1800
  else if AItemType = 'ドレス' then Result := 1500
  else if AItemType = '毛布' then Result := 2500
  else Result := 0;
end;

function TOrderService.CalculateSubtotal(const AItemType: string; AQuantity: Integer; 
                                         AStainRemoval, AUrgent: Boolean): Integer;
var
  BasePrice, SubAmount: Integer;
begin
  BasePrice := GetBasePrice(AItemType);
  SubAmount := BasePrice;
  
  if AStainRemoval then 
    Inc(SubAmount, 500);
    
  // 急ぎはベースに30%追加 (シミ抜きは含むか要件次第だが、ここでは一旦小計全体に30%として計算する)
  // 単価として計算
  if AUrgent then
    SubAmount := Trunc(SubAmount * 1.3);
    
  Result := SubAmount * AQuantity;
end;

procedure TOrderService.CreateOrder(ACustomerID: Integer; APickupDate: TDateTime; 
                                    const AItems: array of TOrderItemRecord; out ATotalAmount: Integer);
var
  OrderQuery, ItemQuery: TFDQuery;
  OrderID: Integer;
  Item: TOrderItemRecord;
begin
  ATotalAmount := 0;
  
  OrderQuery := TFDQuery.Create(nil);
  try
    ItemQuery := TFDQuery.Create(nil);
    try
      OrderQuery.Connection := FConnection;
      ItemQuery.Connection := FConnection;
      
      FConnection.StartTransaction;
      try
        // 合計金額の計算
        for Item in AItems do
        begin
          ATotalAmount := ATotalAmount + Item.Subtotal;
        end;
        
        // 注文ヘッダの作成
        OrderQuery.SQL.Text := 'INSERT INTO orders (customer_id, pickup_date, status, total_price) ' +
                               'VALUES (:cid, :pdate, :status, :total) RETURNING id';
        OrderQuery.ParamByName('cid').AsInteger := ACustomerID;
        OrderQuery.ParamByName('pdate').AsDateTime := APickupDate;
        OrderQuery.ParamByName('status').AsString := '受付';
        OrderQuery.ParamByName('total').AsInteger := ATotalAmount;
        OrderQuery.Open; // RETURNING句の場合はOpenで取得
        
        OrderID := OrderQuery.FieldByName('id').AsInteger;
        
        // 注文明細の作成
        ItemQuery.SQL.Text := 'INSERT INTO order_items (order_id, item_type, quantity, unit_price, stain_removal, urgent, subtotal) ' +
                              'VALUES (:oid, :itype, :qty, :uprice, :stain, :urgent, :subtotal)';
                              
        for Item in AItems do
        begin
          ItemQuery.ParamByName('oid').AsInteger := OrderID;
          ItemQuery.ParamByName('itype').AsString := Item.ItemType;
          ItemQuery.ParamByName('qty').AsInteger := Item.Quantity;
          ItemQuery.ParamByName('uprice').AsInteger := Item.UnitPrice;
          ItemQuery.ParamByName('stain').AsInteger := Ord(Item.StainRemoval); // Boolean to Int
          ItemQuery.ParamByName('urgent').AsInteger := Ord(Item.Urgent);
          ItemQuery.ParamByName('subtotal').AsInteger := Item.Subtotal;
          ItemQuery.ExecSQL;
        end;
        
        FConnection.Commit;
      except
        FConnection.Rollback;
        raise;
      end;
    finally
      ItemQuery.Free;
    end;
  finally
    OrderQuery.Free;
  end;
end;

function TOrderService.GetOrders(ACustomerID: Integer = -1): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConnection;
  
  if ACustomerID > 0 then
  begin
    Result.SQL.Text := 'SELECT o.*, c.name as customer_name FROM orders o ' +
                       'JOIN customers c ON o.customer_id = c.id ' +
                       'WHERE o.customer_id = :cid ORDER BY o.order_date DESC';
    Result.ParamByName('cid').AsInteger := ACustomerID;
  end
  else
  begin
    Result.SQL.Text := 'SELECT o.*, c.name as customer_name FROM orders o ' +
                       'JOIN customers c ON o.customer_id = c.id ' +
                       'ORDER BY o.order_date DESC';
  end;
  Result.Open;
  
  // 表示用ラベルと非表示設定
  if Result.FindField('id') <> nil then
    Result.FieldByName('id').DisplayLabel := '注文ID';
  if Result.FindField('customer_id') <> nil then
    Result.FieldByName('customer_id').Visible := False;
  if Result.FindField('customer_name') <> nil then
    Result.FieldByName('customer_name').DisplayLabel := '顧客名';
  if Result.FindField('order_date') <> nil then
    Result.FieldByName('order_date').DisplayLabel := '注文日時';
  if Result.FindField('pickup_date') <> nil then
    Result.FieldByName('pickup_date').DisplayLabel := '受取予定日';
  if Result.FindField('status') <> nil then
    Result.FieldByName('status').DisplayLabel := 'ステータス';
  if Result.FindField('total_price') <> nil then
    Result.FieldByName('total_price').DisplayLabel := '合計金額 (円)';
end;

procedure TOrderService.UpdateOrderStatus(AOrderID: Integer; const ANewStatus: string);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'UPDATE orders SET status = :status WHERE id = :id';
    Query.ParamByName('status').AsString := ANewStatus;
    Query.ParamByName('id').AsInteger := AOrderID;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

end.
