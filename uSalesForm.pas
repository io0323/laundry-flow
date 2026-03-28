unit uSalesForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids,
  Data.DB, FireDAC.Comp.Client, uSalesService;

type
  TSalesForm = class(TForm)
    pnlMetrics: TPanel;
    lblTodaySalesTitle: TLabel;
    lblTodaySales: TLabel;
    
    lblMonthSalesTitle: TLabel;
    lblMonthSales: TLabel;
    
    lblOrderCountTitle: TLabel;
    lblOrderCount: TLabel;
    
    pnlPopular: TPanel;
    lblPopularTitle: TLabel;
    dbgPopular: TDBGrid;
    btnRefresh: TButton;
    
    DataSource1: TDataSource;
    
    procedure FormShow(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FSalesService: TSalesService;
    FPopularQuery: TFDQuery;
    procedure LoadData;
  public
    property SalesService: TSalesService read FSalesService write FSalesService;
  end;

var
  SalesForm: TSalesForm;

implementation

{$R *.dfm}

procedure TSalesForm.FormShow(Sender: TObject);
begin
  LoadData;
end;

procedure TSalesForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FPopularQuery) then
    FPopularQuery.Free;
end;

procedure TSalesForm.LoadData;
var
  TodaySales, MonthSales, TotalOrders: Integer;
begin
  TodaySales := FSalesService.GetTodaySales;
  MonthSales := FSalesService.GetThisMonthSales;
  TotalOrders := FSalesService.GetOrderCount;
  
  lblTodaySales.Caption := Format('%d 円', [TodaySales]);
  lblMonthSales.Caption := Format('%d 円', [MonthSales]);
  lblOrderCount.Caption := Format('%d 件', [TotalOrders]);
  
  if Assigned(FPopularQuery) then
    FPopularQuery.Free;
    
  FPopularQuery := FSalesService.GetPopularItems;
  DataSource1.DataSet := FPopularQuery;
  dbgPopular.DataSource := DataSource1;
end;

procedure TSalesForm.btnRefreshClick(Sender: TObject);
begin
  LoadData;
end;

end.
