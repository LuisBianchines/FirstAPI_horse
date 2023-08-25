program PrjHorseLuis;

uses
  Vcl.Forms,
  Samples in 'Samples.pas' {HorseAPI};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(THorseAPI, HorseAPI);
  Application.Run;
end.
