object HorseAPI: THorseAPI
  Left = 0
  Top = 0
  Caption = 'HorseAPI'
  ClientHeight = 140
  ClientWidth = 371
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object btIniciar: TButton
    Left = 48
    Top = 32
    Width = 273
    Height = 73
    Caption = 'Iniciar'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -33
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = btIniciarClick
  end
  object Conexao: TFDConnection
    Params.Strings = (
      'Database=precisao'
      'User_Name=sa'
      'Password=masterkey'
      'Server=PC48'
      'DriverID=MSSQL')
    Connected = True
    LoginPrompt = False
    Left = 176
    Top = 104
  end
end
