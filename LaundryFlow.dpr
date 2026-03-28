program LaundryFlow;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uDatabaseManager in 'uDatabaseManager.pas',
  uCustomerService in 'uCustomerService.pas',
  uOrderService in 'uOrderService.pas',
  uSalesService in 'uSalesService.pas',
  uCustomerForm in 'uCustomerForm.pas' {CustomerForm},
  uOrderForm in 'uOrderForm.pas' {OrderForm},
  uOrderListForm in 'uOrderListForm.pas' {OrderListForm},
  uSalesForm in 'uSalesForm.pas' {SalesForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
