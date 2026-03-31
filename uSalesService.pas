unit uSalesService;

interface

uses
  System.SysUtils, System.Classes, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param;

type
  TSalesService = class
  private
    FConnection: TFDConnection;
  public
    constructor Create(AConnection: TFDConnection);
    
    function GetTodaySales: Integer;
    function GetThisMonthSales: Integer;
    function GetOrderCount(AStatus: string = ''): Integer; // ステータス空白で全体件数
    function GetPopularItems: TFDQuery;
  end;

implementation

{ TSalesService }

constructor TSalesService.Create(AConnection: TFDConnection);
begin
  inherited Create;
  FConnection := AConnection;
end;

function TSalesService.GetTodaySales: Integer;
var
  Query: TFDQuery;
begin
  Result := 0;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    // SQLite の date('now', 'localtime') を利用
    Query.SQL.Text := 'SELECT SUM(total_price) as sum_sales FROM orders WHERE date(order_date, ''localtime'') = date(''now'', ''localtime'')';
    Query.Open;
    if not Query.FieldByName('sum_sales').IsNull then
      Result := Query.FieldByName('sum_sales').AsInteger;
  finally
    Query.Free;
  end;
end;

function TSalesService.GetThisMonthSales: Integer;
var
  Query: TFDQuery;
begin
  Result := 0;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT SUM(total_price) as sum_sales FROM orders ' +
                      'WHERE strftime(''%Y-%m'', order_date, ''localtime'') = strftime(''%Y-%m'', ''now'', ''localtime'')';
    Query.Open;
    if not Query.FieldByName('sum_sales').IsNull then
      Result := Query.FieldByName('sum_sales').AsInteger;
  finally
    Query.Free;
  end;
end;

function TSalesService.GetOrderCount(AStatus: string = ''): Integer;
var
  Query: TFDQuery;
begin
  Result := 0;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    if AStatus = '' then
    begin
      Query.SQL.Text := 'SELECT COUNT(id) as cnt FROM orders';
    end
    else
    begin
      Query.SQL.Text := 'SELECT COUNT(id) as cnt FROM orders WHERE status = :status';
      Query.ParamByName('status').AsString := AStatus;
    end;
    Query.Open;
    if not Query.FieldByName('cnt').IsNull then
      Result := Query.FieldByName('cnt').AsInteger;
  finally
    Query.Free;
  end;
end;

function TSalesService.GetPopularItems: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConnection;
  // 衣類の種類ごとの集計ランキング
  Result.SQL.Text := 'SELECT item_type, SUM(quantity) as total_qty ' +
                     'FROM order_items GROUP BY item_type ORDER BY total_qty DESC';
  Result.Open;
  
  if Result.FindField('item_type') <> nil then
    Result.FieldByName('item_type').DisplayLabel := 'アイテム';
  if Result.FindField('total_qty') <> nil then
    Result.FieldByName('total_qty').DisplayLabel := '注文点数';
end;

end.
