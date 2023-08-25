unit Samples;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Horse, System.JSON,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MSSQL, FireDAC.Phys.MSSQLDef, FireDAC.VCLUI.Wait, FireDAC.DApt,
  Data.DB, FireDAC.Comp.Client, Horse.Core, Horse.CORS, Horse.Compression;

type
  THorseAPI = class(TForm)
    btIniciar: TButton;
    Conexao: TFDConnection;
    procedure Registry;
    procedure Gerar(Req : THorseRequest; Res: THorseResponse);
    procedure btIniciarClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Selecionar(Req : THorseRequest; Res: THorseResponse);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HorseAPI: THorseAPI;
  status : Boolean = False;
  Horse : THorse;

implementation

{$R *.dfm}

{ THorseAPI }

{ THorseAPI }

procedure THorseAPI.btIniciarClick(Sender: TObject);
begin
     Registry;

     if status then
     begin
          Close;
     end;

     btIniciar.Caption := 'Parar';

     status := True;
end;

procedure THorseAPI.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     if Horse.IsRunning then     
        Horse.StopListen;

end;

procedure THorseAPI.Gerar(Req : THorseRequest; Res: THorseResponse);
var
   xArrayContent : TJSONArray;
   xJSONContent : TJSONObject;
   xQry : TFDQUery;
begin
     try
        try
            xQry := TFDQuery.Create(nil);

            xArrayContent := TJSONArray.Create;

            xQry.Connection := Conexao;
            xQry.SQL.Add(' select '
                          +' COD_EMPRESA, '
                          +' CODIGO, '
                          +' NOME, '
                          +' COD_DEPARTAMENTO, '
                          +' EMAIL '
                          +' from csenha ');

            xQry.Open;
            xQry.First;
            while not xQry.Eof do
            begin
                xJSONContent := TJSONObject.Create;
                xJSONContent.AddPair('id', xQry.FieldByName('codigo').AsInteger.ToString);
                xJSONContent.AddPair('cod_empresa', xQry.FieldByName('cod_empresa').AsInteger.ToString);
                xJSONContent.AddPair('nome', xQry.FieldByName('nome').AsString);
                xJSONContent.AddPair('cod_departamento', xQry.FieldByName('cod_departamento').AsInteger.ToString);
                xJSONContent.AddPair('email', xQry.FieldByName('email').AsString);

                xArrayContent.AddElement(xJSONContent);

                xQry.Next;
            end;

            Res.Send(xArrayContent.ToJSON).ContentType('application/json').Status(THTTPStatus.OK);

        except on E: Exception do
            begin
                 Res.Send(E.Message).Status(THTTPStatus.BadRequest);
            end;
        end;
     finally
            if Assigned(xQry) then
               FreeAndNil(xQry);

            if Assigned(xArrayContent) then
               FreeAndNil(xArrayContent);
     end;
end;

procedure THorseAPI.Selecionar(Req : THorseRequest; Res: THorseResponse);
var
   xArrayContent : TJSONArray;
   xJSONContent : TJSONObject;
   xQry : TFDQUery;
begin
     try
        try
            xQry := TFDQuery.Create(nil);

            xArrayContent := TJSONArray.Create;

            xQry.Connection := Conexao;
            xQry.SQL.Add(' select '
                          +' COD_EMPRESA, '
                          +' CODIGO, '
                          +' NOME, '
                          +' COD_DEPARTAMENTO, '
                          +' EMAIL '
                          +' from csenha '
                          +' where codigo = ' + Req.Params.Field('id').AsString);

            xQry.Open;
            xQry.First;
            while not xQry.Eof do
            begin
                xJSONContent := TJSONObject.Create;
                xJSONContent.AddPair('id', xQry.FieldByName('codigo').AsInteger.ToString);
                xJSONContent.AddPair('cod_empresa', xQry.FieldByName('cod_empresa').AsInteger.ToString);
                xJSONContent.AddPair('nome', xQry.FieldByName('nome').AsString);
                xJSONContent.AddPair('cod_departamento', xQry.FieldByName('cod_departamento').AsInteger.ToString);
                xJSONContent.AddPair('email', xQry.FieldByName('email').AsString);

                xArrayContent.AddElement(xJSONContent);

                xQry.Next;
            end;

            Res.Send(xArrayContent.ToJSON).ContentType('application/json').Status(THTTPStatus.OK);

        except on E: Exception do
            begin
                 Res.Send(E.Message).Status(THTTPStatus.BadRequest);
            end;
        end;
     finally
            if Assigned(xQry) then
               FreeAndNil(xQry);

            if Assigned(xArrayContent) then
               FreeAndNil(xArrayContent);
     end;
end;

procedure THorseAPI.Registry;
begin
    if not Assigned(Horse) then
    begin
         Horse := THorse.Create;
         Horse.Use(CORS);
         Horse.Use(Compression());
         Horse.Get('/selecionar/:id', Selecionar);
         Horse.Get('/listar', Gerar);
         Horse.Listen(9000);
    end;
end;

end.
