object MainFrm: TMainFrm
  Left = 0
  Top = 0
  Caption = 'CopyComOAuthExample'
  ClientHeight = 295
  ClientWidth = 934
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 32
    Top = 16
    Width = 88
    Height = 13
    Caption = 'App Key/ Client ID'
  end
  object Label2: TLabel
    Left = 40
    Top = 125
    Width = 58
    Height = 13
    Caption = 'Token_Auth'
  end
  object Label3: TLabel
    Left = 40
    Top = 171
    Width = 68
    Height = 13
    Caption = 'Token_Access'
  end
  object Label4: TLabel
    Left = 40
    Top = 217
    Width = 73
    Height = 13
    Caption = 'Token_Refresh'
  end
  object Label5: TLabel
    Left = 32
    Top = 62
    Width = 61
    Height = 13
    Caption = 'Client Secret'
  end
  object Button1: TButton
    Left = 680
    Top = 103
    Width = 145
    Height = 59
    Caption = 'Authenticate'
    TabOrder = 0
    OnClick = Button1Click
  end
  object AppKeyEdit: TEdit
    Left = 32
    Top = 35
    Width = 433
    Height = 21
    TabOrder = 1
    Text = 'FnQFwRZnBHZt1DmcHAaeVotL2Us5p5VV'
  end
  object SecterKeyEdit: TEdit
    Left = 32
    Top = 81
    Width = 433
    Height = 21
    TabOrder = 2
    Text = 'Gp8TClvnY9wRmYPMntk5mk0Khdx4JH3ZbT3WiCrJBUUFLJqM'
  end
  object Token_AuthEdit: TEdit
    Left = 40
    Top = 144
    Width = 634
    Height = 21
    TabOrder = 3
  end
  object Token_AccessEdit: TEdit
    Left = 40
    Top = 190
    Width = 329
    Height = 21
    TabOrder = 4
  end
  object Token_RefreshEdit: TEdit
    Left = 40
    Top = 236
    Width = 329
    Height = 21
    TabOrder = 5
  end
end
