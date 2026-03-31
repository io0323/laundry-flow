unit uCustomerService;

interface

uses
  System.SysUtils, System.Classes, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param;

type
  TCustomerRecord = record
    ID: Integer;
    Name: string;
    Phone: string;
    Address: string;
    MemberType: string;
    CreatedAt: TDateTime;
  end;

  TCustomerService = class
  private
    FConnection: TFDConnection;
  public
    constructor Create(AConnection: TFDConnection);
    
    procedure AddCustomer(const AName, APhone, AAddress, AMemberType: string);
    procedure EditCustomer(AID: Integer; const AName, APhone, AAddress, AMemberType: string);
    function SearchCustomers(const AKeyword: string): TFDQuery;
    function GetAllCustomers: TFDQuery;
    procedure DeleteCustomer(AID: Integer);
  end;

implementation

{ TCustomerService }

constructor TCustomerService.Create(AConnection: TFDConnection);
begin
  inherited Create;
  FConnection := AConnection;
end;

procedure TCustomerService.AddCustomer(const AName, APhone, AAddress, AMemberType: string);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'INSERT INTO customers (name, phone, address, member_type) ' +
                      'VALUES (:name, :phone, :address, :member_type)';
    Query.ParamByName('name').AsString := AName;
    Query.ParamByName('phone').AsString := APhone;
    Query.ParamByName('address').AsString := AAddress;
    Query.ParamByName('member_type').AsString := AMemberType;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

procedure TCustomerService.EditCustomer(AID: Integer; const AName, APhone, AAddress, AMemberType: string);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'UPDATE customers SET name = :name, phone = :phone, ' +
                      'address = :address, member_type = :member_type ' +
                      'WHERE id = :id';
    Query.ParamByName('name').AsString := AName;
    Query.ParamByName('phone').AsString := APhone;
    Query.ParamByName('address').AsString := AAddress;
    Query.ParamByName('member_type').AsString := AMemberType;
    Query.ParamByName('id').AsInteger := AID;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

function TCustomerService.SearchCustomers(const AKeyword: string): TFDQuery;
begin
  // 呼び出し側でFreeする必要があります(UIグリッドバインド等に利用）
  Result := TFDQuery.Create(nil);
  Result.Connection := FConnection;
  Result.SQL.Text := 'SELECT * FROM customers WHERE name LIKE :keyword OR phone LIKE :keyword ORDER BY created_at DESC';
  Result.ParamByName('keyword').AsString := '%' + AKeyword + '%';
  Result.Open;
  Result.FieldByName('id').Visible := False;
  Result.FieldByName('name').DisplayLabel := '氏名';
  Result.FieldByName('phone').DisplayLabel := '電話番号';
  Result.FieldByName('address').DisplayLabel := '住所';
  Result.FieldByName('member_type').DisplayLabel := '会員種別';
  Result.FieldByName('created_at').DisplayLabel := '登録日時';
end;

function TCustomerService.GetAllCustomers: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConnection;
  Result.SQL.Text := 'SELECT * FROM customers ORDER BY created_at DESC';
  Result.Open;
  Result.FieldByName('id').Visible := False;
  Result.FieldByName('name').DisplayLabel := '氏名';
  Result.FieldByName('phone').DisplayLabel := '電話番号';
  Result.FieldByName('address').DisplayLabel := '住所';
  Result.FieldByName('member_type').DisplayLabel := '会員種別';
  Result.FieldByName('created_at').DisplayLabel := '登録日時';
end;

procedure TCustomerService.DeleteCustomer(AID: Integer);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'DELETE FROM customers WHERE id = :id';
    Query.ParamByName('id').AsInteger := AID;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

end.
