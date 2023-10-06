create table Area_Type
(
    areatype_id char(4) not null collate SQL_Latin1_General_CP1251_CI_AS
        constraint PK_AREA_TYPE
            primary key nonclustered,
    name        varchar(30) collate SQL_Latin1_General_CP1251_CI_AS
)
go

exec sp_addextendedproperty 'MS_Description', N'Для териториального доступа', 'SCHEMA', 'dbo', 'TABLE', 'Area_Type'
go

exec sp_addextendedproperty 'MS_Description', N'код', 'SCHEMA', 'dbo', 'TABLE', 'Area_Type', 'COLUMN', 'areatype_id'
go

exec sp_addextendedproperty 'MS_Description', N'название', 'SCHEMA', 'dbo', 'TABLE', 'Area_Type', 'COLUMN', 'name'
go

