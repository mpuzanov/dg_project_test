create table Bank_format_out
(
    id               smallint                                      not null
        constraint PK_BANK_FORMAT_OUT
            primary key,
    name             varchar(50)                                   not null collate SQL_Latin1_General_CP1251_CI_AS,
    visible          bit
        constraint DF_BANK_FORMAT_OUT_visible default 1            not null,
    format_tip       varchar(5)                                    not null collate SQL_Latin1_General_CP1251_CI_AS,
    format_string    varchar(200) collate SQL_Latin1_General_CP1251_CI_AS,
    code_page        varchar(5)
        constraint DF_BANK_FORMAT_OUT_code_page default 'ASCII' collate SQL_Latin1_General_CP1251_CI_AS,
    DECIMALSEPARATOR char
        constraint DF_BANK_FORMAT_OUT_DECIMALSEPARATOR default '.' not null collate SQL_Latin1_General_CP1251_CI_AS,
    DateFormat       varchar(15)
        constraint DF_BANK_FORMAT_OUT_DateFormat default 'mm'      not null collate SQL_Latin1_General_CP1251_CI_AS,
    full_name        as [name] + ' (' + [format_tip] + ')' collate SQL_Latin1_General_CP1251_CI_AS,
    field_str        varchar(100) collate SQL_Latin1_General_CP1251_CI_AS,
    bank_file_out    varchar(50) collate SQL_Latin1_General_CP1251_CI_AS,
    prepayment_0     bit
        constraint DF_BANK_FORMAT_OUT_prepayment_0 default 0       not null,
    modeOwerwrite    bit
        constraint DF_BANK_FORMAT_OUT_modeOwerwrite default 0      not null,
    date_edit        smalldatetime,
    znak_dolg        char
        constraint DF_Bank_format_out_znak_dolg default '+'        not null collate SQL_Latin1_General_CP1251_CI_AS,
    znak_sum_visible bit
        constraint DF_Bank_format_out_znak_dolg_visible default 1  not null,
    format_json      nvarchar(max) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Форматы файлов задолженности для банков', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format_out'
go

exec sp_addextendedproperty 'MS_Description', N'Наименование формата', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format_out',
     'COLUMN', 'name'
go

exec sp_addextendedproperty 'MS_Description', N'Видимость формата', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format_out',
     'COLUMN', 'visible'
go

exec sp_addextendedproperty 'MS_Description', N'Тип файла выгрузки (txt, dbf и т п.)', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format_out', 'COLUMN', 'format_tip'
go

exec sp_addextendedproperty 'MS_Description', N'Соответствия полей для переноса', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format_out', 'COLUMN', 'format_string'
go

exec sp_addextendedproperty 'MS_Description', N'Кодировка', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format_out', 'COLUMN',
     'code_page'
go

exec sp_addextendedproperty 'MS_Description', N'Разделитель суммы (Толька или запятая)', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format_out', 'COLUMN', 'DECIMALSEPARATOR'
go

exec sp_addextendedproperty 'MS_Description', N'Формат даты', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format_out', 'COLUMN',
     'DateFormat'
go

exec sp_addextendedproperty 'MS_Description', N'Форматы полей для создания файла', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format_out', 'COLUMN', 'field_str'
go

exec sp_addextendedproperty 'MS_Description', N'формат наименования файла с  задолженностью', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format_out', 'COLUMN', 'bank_file_out'
go

exec sp_addextendedproperty 'MS_Description', N'Обнулять переплату', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format_out',
     'COLUMN', 'prepayment_0'
go

exec sp_addextendedproperty 'MS_Description', N'Режим замены в тексте', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format_out',
     'COLUMN', 'modeOwerwrite'
go

exec sp_addextendedproperty 'MS_Description', N'Дата изменения', 'SCHEMA', 'dbo', 'TABLE', 'Bank_format_out', 'COLUMN',
     'date_edit'
go

exec sp_addextendedproperty 'MS_Description', N'Если минус - выводим, плюс - не выводим', 'SCHEMA', 'dbo', 'TABLE',
     'Bank_format_out', 'COLUMN', 'znak_sum_visible'
go

