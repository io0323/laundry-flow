unit uOrderForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  uCustomerService, uOrderService, System.Generics.Collections;

type
  TOrderForm = class(TForm)
    pnlCustomer: TPanel;
    lblCustomer: TLabel;
    edtCustomerPhone: TEdit;
    btnSearchCustomer: TButton;
    lblCustomerName: TLabel;
    
    pnlItem: TPanel;
    lblItemType: TLabel;
    cmbItemType: TComboBox;
    lblQuantity: TLabel;
    edtQuantity: TEdit;
    chkStainRemoval: TCheckBox;
    chkUrgent: TCheckBox;
    btnAddItem: TButton;
    
    lstItems: TListBox;
    
    pnlBottom: TPanel;
    lblTotal: TLabel;
    dtpPickupDate: TDateTimePicker;
    btnCreateOrder: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSearchCustomerClick(Sender: TObject);
    procedure btnAddItemClick(Sender: TObject);
    procedure btnCreateOrderClick(Sender: TObject);
  private
    FCustomerService: TCustomerService;
    FOrderService: TOrderService;
    FSelectedCustomerID: Integer;
    FOrderItems: TList<TOrderItemRecord>;
    procedure RefreshItemList;
    procedure UpdateTotal;
  public
    property CustomerService: TCustomerService read FCustomerService write FCustomerService;
    property OrderService: TOrderService read FOrderService write FOrderService;
  end;

var
  OrderForm: TOrderForm;

implementation

{$R *.dfm}

procedure TOrderForm.FormCreate(Sender: TObject);
begin
  FOrderItems := TList<TOrderItemRecord>.Create;
  FSelectedCustomerID := -1;
  dtpPickupDate.Date := Date + 3; // デフォルト受取日は3日後
end;

procedure TOrderForm.FormDestroy(Sender: TObject);
begin
  FOrderItems.Free;
end;

procedure TOrderForm.btnSearchCustomerClick(Sender: TObject);
var
  Q: Data.DB.TDataSet;
begin
  if Trim(edtCustomerPhone.Text) = '' then Exit;
  
  Q := FCustomerService.SearchCustomers(edtCustomerPhone.Text);
  try
    if not Q.IsEmpty then
    begin
      FSelectedCustomerID := Q.FieldByName('id').AsInteger;
      lblCustomerName.Caption := Q.FieldByName('name').AsString + ' 様';
    end
    else
    begin
      ShowMessage('該当する顧客が見つかりません。');
      FSelectedCustomerID := -1;
      lblCustomerName.Caption := '未選択';
    end;
  finally
    Q.Free;
  end;
end;

procedure TOrderForm.btnAddItemClick(Sender: TObject);
var
  Item: TOrderItemRecord;
  Qty: Integer;
begin
  if cmbItemType.ItemIndex = -1 then
  begin
    ShowMessage('衣類種類を選択してください。');
    Exit;
  end;
  
  if not TryStrToInt(edtQuantity.Text, Qty) or (Qty <= 0) then
  begin
    ShowMessage('数量を正しく入力してください。');
    Exit;
  end;
  
  Item.ItemType := cmbItemType.Text;
  Item.Quantity := Qty;
  Item.StainRemoval := chkStainRemoval.Checked;
  Item.Urgent := chkUrgent.Checked;
  Item.UnitPrice := FOrderService.CalculateSubtotal(Item.ItemType, 1, Item.StainRemoval, Item.Urgent);
  Item.Subtotal := Item.UnitPrice * Item.Quantity;
  
  FOrderItems.Add(Item);
  RefreshItemList;
  UpdateTotal;
  
  // 入力クリア
  edtQuantity.Text := '1';
  chkStainRemoval.Checked := False;
end;

procedure TOrderForm.RefreshItemList;
var
  i: Integer;
  Item: TOrderItemRecord;
  S: string;
begin
  lstItems.Clear;
  for i := 0 to FOrderItems.Count - 1 do
  begin
    Item := FOrderItems[i];
    S := Format('%s x %d (単価: %d円) - 小計: %d円', [Item.ItemType, Item.Quantity, Item.UnitPrice, Item.Subtotal]);
    if Item.StainRemoval then S := S + ' [シミ抜き]';
    if Item.Urgent then S := S + ' [急ぎ]';
    lstItems.Items.Add(S);
  end;
end;

procedure TOrderForm.UpdateTotal;
var
  Total, i: Integer;
begin
  Total := 0;
  for i := 0 to FOrderItems.Count - 1 do
    Total := Total + FOrderItems[i].Subtotal;
  lblTotal.Caption := Format('合計金額: %d 円', [Total]);
end;

procedure TOrderForm.btnCreateOrderClick(Sender: TObject);
var
  TotalAmt: Integer;
begin
  if FSelectedCustomerID = -1 then
  begin
    ShowMessage('顧客を選択してください。');
    Exit;
  end;
  
  if FOrderItems.Count = 0 then
  begin
    ShowMessage('衣類が追加されていません。');
    Exit;
  end;
  
  try
    FOrderService.CreateOrder(FSelectedCustomerID, dtpPickupDate.Date, FOrderItems.ToArray, TotalAmt);
    ShowMessage(Format('注文を作成しました。合計: %d円', [TotalAmt]));
    Close;
  except
    on E: Exception do
      ShowMessage('注文作成エラー: ' + E.Message);
  end;
end;

end.
