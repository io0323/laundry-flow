unit uOrderListForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids,
  Data.DB, FireDAC.Comp.Client, uOrderService;

type
  TOrderListForm = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    btnRefresh: TButton;
    
    pnlClient: TPanel;
    dbgOrders: TDBGrid;
    
    pnlRight: TPanel;
    lblActionTitle: TLabel;
    cmbStatus: TComboBox;
    btnUpdateStatus: TButton;
    
    DataSource1: TDataSource;
    
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnUpdateStatusClick(Sender: TObject);
  private
    FOrderService: TOrderService;
    FCurrentQuery: TFDQuery;
    procedure LoadOrders;
  public
    property OrderService: TOrderService read FOrderService write FOrderService;
  end;

var
  OrderListForm: TOrderListForm;

implementation

{$R *.dfm}

procedure TOrderListForm.FormShow(Sender: TObject);
begin
  cmbStatus.Items.Clear;
  cmbStatus.Items.Add('受付');
  cmbStatus.Items.Add('洗浄中');
  cmbStatus.Items.Add('仕上げ中');
  cmbStatus.Items.Add('受取待ち');
  cmbStatus.Items.Add('完了');
  
  LoadOrders;
end;

procedure TOrderListForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FCurrentQuery) then
    FCurrentQuery.Free;
end;

procedure TOrderListForm.LoadOrders;
begin
  if Assigned(FCurrentQuery) then
    FCurrentQuery.Free;
    
  FCurrentQuery := FOrderService.GetOrders(-1); // -1 = All customers
  DataSource1.DataSet := FCurrentQuery;
  dbgOrders.DataSource := DataSource1;
end;

procedure TOrderListForm.btnRefreshClick(Sender: TObject);
begin
  LoadOrders;
end;

procedure TOrderListForm.btnUpdateStatusClick(Sender: TObject);
var
  OrderID: Integer;
begin
  if not Assigned(FCurrentQuery) or FCurrentQuery.IsEmpty then
  begin
    ShowMessage('注文が選択されていません。');
    Exit;
  end;
  
  if cmbStatus.ItemIndex = -1 then
  begin
    ShowMessage('新しいステータスを選択してください。');
    Exit;
  end;
  
  OrderID := FCurrentQuery.FieldByName('id').AsInteger;
  
  try
    FOrderService.UpdateOrderStatus(OrderID, cmbStatus.Text);
    ShowMessage('ステータスを更新しました。');
    LoadOrders;
  except
    on E: Exception do
      ShowMessage('更新エラー: ' + E.Message);
  end;
end;

end.
