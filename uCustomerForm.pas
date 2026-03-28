unit uCustomerForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids,
  Data.DB, FireDAC.Comp.Client, uCustomerService;

type
  TCustomerForm = class(TForm)
    pnlTop: TPanel;
    edtSearch: TEdit;
    btnSearch: TButton;
    pnlClient: TPanel;
    dbgCustomers: TDBGrid;
    pnlRight: TPanel;
    lblTitle: TLabel;
    edtName: TEdit;
    edtPhone: TEdit;
    edtAddress: TEdit;
    cmbMemberType: TComboBox;
    btnSave: TButton;
    btnNew: TButton;
    DataSource1: TDataSource;
    procedure FormShow(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FCustomerService: TCustomerService;
    FCurrentQuery: TFDQuery;
    procedure RefreshData(const AKeyword: string = '');
  public
    property CustomerService: TCustomerService read FCustomerService write FCustomerService;
  end;

var
  CustomerForm: TCustomerForm;

implementation

{$R *.dfm}

procedure TCustomerForm.FormShow(Sender: TObject);
begin
  RefreshData;
end;

procedure TCustomerForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FCurrentQuery) then
    FCurrentQuery.Free;
end;

procedure TCustomerForm.RefreshData(const AKeyword: string = '');
begin
  if Assigned(FCurrentQuery) then
    FCurrentQuery.Free;
    
  if AKeyword = '' then
    FCurrentQuery := FCustomerService.GetAllCustomers
  else
    FCurrentQuery := FCustomerService.SearchCustomers(AKeyword);
    
  DataSource1.DataSet := FCurrentQuery;
  dbgCustomers.DataSource := DataSource1;
end;

procedure TCustomerForm.btnSearchClick(Sender: TObject);
begin
  RefreshData(edtSearch.Text);
end;

procedure TCustomerForm.btnSaveClick(Sender: TObject);
begin
  if Trim(edtName.Text) = '' then
  begin
    ShowMessage('名前を入力してください。');
    Exit;
  end;
  
  FCustomerService.AddCustomer(
    edtName.Text,
    edtPhone.Text,
    edtAddress.Text,
    cmbMemberType.Text
  );
  
  ShowMessage('顧客を登録しました。');
  edtName.Clear;
  edtPhone.Clear;
  edtAddress.Clear;
  RefreshData;
end;

end.
