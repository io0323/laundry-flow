unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  uDatabaseManager, uCustomerService, uOrderService, uSalesService,
  uCustomerForm, uOrderForm, uOrderListForm, uSalesForm;

type
  TMainForm = class(TForm)
    pnlMenu: TPanel;
    btnCustomer: TButton;
    btnOrder: TButton;
    btnOrderList: TButton;
    btnSales: TButton;
    pnlStatus: TPanel;
    lblDBStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCustomerClick(Sender: TObject);
    procedure btnOrderClick(Sender: TObject);
    procedure btnOrderListClick(Sender: TObject);
    procedure btnSalesClick(Sender: TObject);
  private
    FDBManager: TDatabaseManager;
    FCustomerService: TCustomerService;
    FOrderService: TOrderService;
    FSalesService: TSalesService;
    
    // アプリケーションディレクトリのDBパスを取得
    function GetDatabasePath: string;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

function TMainForm.GetDatabasePath: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'laundryflow.db';
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  try
    FDBManager := TDatabaseManager.Create(GetDatabasePath);
    FCustomerService := TCustomerService.Create(FDBManager.Connection);
    FOrderService := TOrderService.Create(FDBManager.Connection);
    FSalesService := TSalesService.Create(FDBManager.Connection);
    
    lblDBStatus.Caption := 'DB接続: OK (' + GetDatabasePath + ')';
    lblDBStatus.Font.Color := clGreen;
  except
    on E: Exception do
    begin
      ShowMessage('データベース初期化エラー: ' + E.Message);
      lblDBStatus.Caption := 'DB接続: エラー';
      lblDBStatus.Font.Color := clRed;
    end;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FSalesService.Free;
  FOrderService.Free;
  FCustomerService.Free;
  FDBManager.Free;
end;

procedure TMainForm.btnCustomerClick(Sender: TObject);
begin
  CustomerForm := TCustomerForm.Create(Self);
  try
    CustomerForm.CustomerService := FCustomerService;
    CustomerForm.ShowModal;
  finally
    CustomerForm.Free;
  end;
end;

procedure TMainForm.btnOrderClick(Sender: TObject);
begin
  OrderForm := TOrderForm.Create(Self);
  try
    OrderForm.CustomerService := FCustomerService;
    OrderForm.OrderService := FOrderService;
    OrderForm.ShowModal;
  finally
    OrderForm.Free;
  end;
end;

procedure TMainForm.btnOrderListClick(Sender: TObject);
begin
  OrderListForm := TOrderListForm.Create(Self);
  try
    OrderListForm.OrderService := FOrderService;
    OrderListForm.ShowModal;
  finally
    OrderListForm.Free;
  end;
end;

procedure TMainForm.btnSalesClick(Sender: TObject);
begin
  SalesForm := TSalesForm.Create(Self);
  try
    SalesForm.SalesService := FSalesService;
    SalesForm.ShowModal;
  finally
    SalesForm.Free;
  end;
end;

end.
