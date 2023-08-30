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
    procedure Produtos(Req : THorseRequest; Res: THorseResponse);
    procedure btIniciarClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Buscar(Req : THorseRequest; Res: THorseResponse);
    procedure Novo(Req : THorseRequest; Res: THorseResponse);
    procedure Delete(Req : THorseRequest; Res: THorseResponse);
    procedure Update(Req : THorseRequest; Res: THorseResponse);
    
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

procedure THorseAPI.Novo(Req: THorseRequest; Res: THorseResponse);
var
   xJSONContent : TJSONObject;
   xJsonReq : TJSONValue;
   xQry : TFDQUery;
   xCodigo : Integer;
   xNome, xFamilia, xUn, xCodInterno : string;
begin
     try
        try
           xJsonReq := nil;
           xJsonReq := TJSONObject.ParseJSONValue(Req.Body);
           xNome := EmptyStr;
           xJsonReq.TryGetValue('nome', xNome);
           xCodInterno := EmptyStr;
           xJsonReq.TryGetValue('codigo_interno', xCodInterno);
           xFamilia := EmptyStr;
           xJsonReq.TryGetValue('familia', xFamilia);
           xUn := EmptyStr;
           xJsonReq.TryGetValue('unidade', xUn);
        
           xQry := TFDQuery.Create(nil);
           xQry.Connection := Conexao;
           xQry.SQL.Add(' select '
                          +' COD_EMPRESA, '
                          +' CODIGO, '
                          +' CODIGO_INTERNO, '
                          +' NOME, '
                          +' FAMILIA, '
                          +' UNIDADE '
                          +' from tproduto'
                          +' where cod_empresa = 1 '
                          +' AND codigo = (SELECT MAX(CODIGO) FROM TPRODUTO WHERE COD_EMPRESA = 1) ');
           xQry.Open;

           xCodigo := xQry.FieldByName('CODIGO').AsInteger + 1;
           
           xQry.Append;
           xQry.FieldByName('COD_EMPRESA').AsInteger := 1;                         
           xQry.FieldByName('CODIGO').AsInteger := xCodigo;
           xQry.FieldByName('CODIGO_INTERNO').AsString := xCodInterno;
           xQry.FieldByName('NOME').AsString := xNome;
           xQry.FieldByName('FAMILIA').AsString := xFamilia;
           xQry.FieldByName('UNIDADE').AsString := xUn;
           xQry.Post;

           xJSONContent := TJSONObject.Create;
           xJSONContent.AddPair('cod_empresa','1');
           xJSONContent.AddPair('codigo', xCodigo.ToString);
           xJSONContent.AddPair('codigo_interno',xCodInterno);
           xJSONContent.AddPair('nome', xNome);
           xJSONContent.AddPair('unidade', xUn);
           xJSONContent.AddPair('familia', xFamilia);

           Res.Send(xJSONContent.ToJSON).ContentType('aplication/json').Status(THTTPStatus.Created);
           
        except on E: Exception do
            begin
                 Res.Send(E.Message).Status(THTTPStatus.BadRequest);
            end;
        end;
        
     finally
        if Assigned(xQry) then
            FreeAndNil(xQry);

        if Assigned(xJSONContent) then
            FreeAndNil(xJSONContent);

        if Assigned(xJsonReq) then
            FreeAndNil(xJsonReq);                
     end;
end;

procedure THorseAPI.Produtos(Req : THorseRequest; Res: THorseResponse);
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
                          +' CODIGO_INTERNO, '
                          +' NOME, '
                          +' FAMILIA, '
                          +' UNIDADE '
                          +' from tproduto'
                          +' where cod_empresa = 1 '
                          +' and codigo >= 1700 '
                          +' order by codigo desc');

            xQry.Open;
            xQry.First;
            while not xQry.Eof do
            begin
                xJSONContent := TJSONObject.Create;
                xJSONContent.AddPair('id', xQry.FieldByName('codigo').AsInteger.ToString);
                xJSONContent.AddPair('cod_empresa', xQry.FieldByName('cod_empresa').AsInteger.ToString);
                xJSONContent.AddPair('codigo_interno', xQry.FieldByName('codigo_interno').AsString);
                xJSONContent.AddPair('nome', xQry.FieldByName('nome').AsString);
                xJSONContent.AddPair('unidade', xQry.FieldByName('unidade').AsString);
                xJSONContent.AddPair('familia', xQry.FieldByName('familia').AsString);

                xArrayContent.AddElement(xJSONContent);

                xQry.Next;
            end;

            Res.Send(xArrayContent.ToJSON).ContentType('aplication/json').Status(THTTPStatus.OK);

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

procedure THorseAPI.Buscar(Req : THorseRequest; Res: THorseResponse);
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
                          +' CODIGO_INTERNO, '
                          +' NOME, '
                          +' FAMILIA, '
                          +' UNIDADE '
                          +' from tproduto '
                          +' where cod_empresa = 1 '
                          +' and codigo = ' + Req.Params.Field('id').AsString);

            xQry.Open;
            xQry.First;
            while not xQry.Eof do
            begin
                xJSONContent := TJSONObject.Create;
                xJSONContent.AddPair('id', xQry.FieldByName('codigo').AsInteger.ToString);
                xJSONContent.AddPair('cod_empresa', xQry.FieldByName('cod_empresa').AsInteger.ToString);
                xJSONContent.AddPair('codigo_interno', xQry.FieldByName('codigo_interno').AsString);
                xJSONContent.AddPair('nome', xQry.FieldByName('nome').AsString);
                xJSONContent.AddPair('unidade', xQry.FieldByName('unidade').AsString);
                xJSONContent.AddPair('familia', xQry.FieldByName('familia').AsString);

                xArrayContent.AddElement(xJSONContent);

                xQry.Next;
            end;

            Res.Send(xArrayContent.ToJSON).ContentType('aplication/json').Status(THTTPStatus.OK);

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

procedure THorseAPI.Delete(Req: THorseRequest; Res: THorseResponse);
var
   xID : integer;
begin
     try
        xID := Req.Params.Field('id').AsInteger;
        
        Conexao.ExecSQL(' delete from tproduto where codigo = :codigo and cod_empresa = 1',[xID]);

        Res.Send('Registro ' + xID.ToString + ' deletado com sucesso!').ContentType('aplication/json').Status(THTTPStatus.OK);

        except on E: Exception do
        begin
             Res.Send(E.Message).Status(THTTPStatus.BadRequest);
        end;
     end;
     
end;



procedure THorseAPI.Update(Req: THorseRequest; Res: THorseResponse);
var
   xID: Integer;
   xJsonReq : TJSONValue;
   xNome, xFamilia, xUn, xCodInterno : string;
   xQry : TFDQuery;
begin
     try
        try
            xID := Req.Params.Field('id').AsInteger;

            xJsonReq := nil;
            xJsonReq := TJSONObject.ParseJSONValue(Req.Body);
            xNome := EmptyStr;
            xJsonReq.TryGetValue('nome', xNome);
            xCodInterno := EmptyStr;
            xJsonReq.TryGetValue('codigo_interno', xCodInterno);
            xFamilia := EmptyStr;
            xJsonReq.TryGetValue('familia', xFamilia);
            xUn := EmptyStr;
            xJsonReq.TryGetValue('unidade', xUn);

            Conexao.ExecSQL(' update tproduto '
                               +' set codigo_interno = ''' + xCodInterno +'''' 
                               + ', nome = ''' + xNome +''''
                               + ', familia = '''+ xFamilia +'''' 
                               + ', unidade = '''+ xUn +''''
                               + ' where cod_empresa = 1 and codigo = '+ xID.ToString);

            Res.Send(xJsonReq.ToJSON).ContentType('aplication/json').Status(THTTPStatus.OK);
            
        except on E: Exception do
            begin
                 Res.Send(E.Message).Status(THTTPStatus.BadRequest);
            end;
        end;
        
     finally
        if Assigned(xJsonReq) then
           FreeAndNil(xJsonReq);
     end;
end;

procedure THorseAPI.Registry;
begin
    if not Assigned(Horse) then
    begin
         Horse := THorse.Create;
         Horse.Use(CORS);
         Horse.Use(Compression());
         Horse.Get('/buscar/:id', Buscar);
         Horse.Get('/produtos', Produtos);
         Horse.Delete('/delete/:id', Delete);
         Horse.Post('novo', Novo);
         Horse.Put('update/:id', Update);
         Horse.Listen(9000);
    end;
end;

end.
