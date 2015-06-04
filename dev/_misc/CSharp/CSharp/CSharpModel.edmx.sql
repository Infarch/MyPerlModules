
-- --------------------------------------------------
-- Entity Designer DDL Script for SQL Server 2005, 2008, and Azure
-- --------------------------------------------------
-- Date Created: 01/08/2013 16:59:13
-- Generated from EDMX file: C:\Users\sku\Documents\Visual Studio 2010\Projects\CSharp\CSharp\CSharpModel.edmx
-- --------------------------------------------------

SET QUOTED_IDENTIFIER OFF;
GO
USE [CSharp];
GO
IF SCHEMA_ID(N'dbo') IS NULL EXECUTE(N'CREATE SCHEMA [dbo]');
GO

-- --------------------------------------------------
-- Dropping existing FOREIGN KEY constraints
-- --------------------------------------------------

IF OBJECT_ID(N'[dbo].[FK_ClassAccessModifier]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[ClassSet] DROP CONSTRAINT [FK_ClassAccessModifier];
GO
IF OBJECT_ID(N'[dbo].[FK_ClassMethod]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[MethodSet] DROP CONSTRAINT [FK_ClassMethod];
GO
IF OBJECT_ID(N'[dbo].[FK_MethodAccessModifier]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[MethodSet] DROP CONSTRAINT [FK_MethodAccessModifier];
GO
IF OBJECT_ID(N'[dbo].[FK_MethodParameter]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[ParameterSet] DROP CONSTRAINT [FK_MethodParameter];
GO
IF OBJECT_ID(N'[dbo].[FK_ClassParameter]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[ParameterSet] DROP CONSTRAINT [FK_ClassParameter];
GO
IF OBJECT_ID(N'[dbo].[FK_ClassClass]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[ClassSet] DROP CONSTRAINT [FK_ClassClass];
GO
IF OBJECT_ID(N'[dbo].[FK_ClassReturnType]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[ReturnTypeSet] DROP CONSTRAINT [FK_ClassReturnType];
GO
IF OBJECT_ID(N'[dbo].[FK_ReturnTypeMethod]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[ReturnTypeSet] DROP CONSTRAINT [FK_ReturnTypeMethod];
GO

-- --------------------------------------------------
-- Dropping existing tables
-- --------------------------------------------------

IF OBJECT_ID(N'[dbo].[AccessModifierSet]', 'U') IS NOT NULL
    DROP TABLE [dbo].[AccessModifierSet];
GO
IF OBJECT_ID(N'[dbo].[ClassSet]', 'U') IS NOT NULL
    DROP TABLE [dbo].[ClassSet];
GO
IF OBJECT_ID(N'[dbo].[MethodSet]', 'U') IS NOT NULL
    DROP TABLE [dbo].[MethodSet];
GO
IF OBJECT_ID(N'[dbo].[ParameterSet]', 'U') IS NOT NULL
    DROP TABLE [dbo].[ParameterSet];
GO
IF OBJECT_ID(N'[dbo].[ReturnTypeSet]', 'U') IS NOT NULL
    DROP TABLE [dbo].[ReturnTypeSet];
GO

-- --------------------------------------------------
-- Creating all tables
-- --------------------------------------------------

-- Creating table 'AccessModifierSet'
CREATE TABLE [dbo].[AccessModifierSet] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max)  NOT NULL
);
GO

-- Creating table 'ClassSet'
CREATE TABLE [dbo].[ClassSet] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max)  NOT NULL,
    [Alias] nvarchar(max)  NULL,
    [ClassId] int  NULL,
    [Comment] nvarchar(max)  NULL,
    [AccessModifier_Id] int  NOT NULL
);
GO

-- Creating table 'MethodSet'
CREATE TABLE [dbo].[MethodSet] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max)  NOT NULL,
    [ClassId] int  NOT NULL,
    [AccessModifierId] int  NOT NULL,
    [Comment] nvarchar(max)  NULL
);
GO

-- Creating table 'ParameterSet'
CREATE TABLE [dbo].[ParameterSet] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max)  NOT NULL,
    [MethodId] int  NOT NULL,
    [ClassId] int  NOT NULL,
    [OrderNmber] tinyint  NOT NULL
);
GO

-- Creating table 'ReturnTypeSet'
CREATE TABLE [dbo].[ReturnTypeSet] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [ClassId] int  NOT NULL,
    [ReturnTypeMethod_ReturnType_Id] int  NOT NULL
);
GO

-- Creating table 'MemberSet'
CREATE TABLE [dbo].[MemberSet] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max)  NOT NULL,
    [ClassId] int  NOT NULL,
    [AccessModifierId] int  NOT NULL,
    [MemberType_Id] int  NOT NULL
);
GO

-- Creating table 'MemberTypeSet'
CREATE TABLE [dbo].[MemberTypeSet] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [ClassId] int  NOT NULL
);
GO

-- --------------------------------------------------
-- Creating all PRIMARY KEY constraints
-- --------------------------------------------------

-- Creating primary key on [Id] in table 'AccessModifierSet'
ALTER TABLE [dbo].[AccessModifierSet]
ADD CONSTRAINT [PK_AccessModifierSet]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'ClassSet'
ALTER TABLE [dbo].[ClassSet]
ADD CONSTRAINT [PK_ClassSet]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'MethodSet'
ALTER TABLE [dbo].[MethodSet]
ADD CONSTRAINT [PK_MethodSet]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'ParameterSet'
ALTER TABLE [dbo].[ParameterSet]
ADD CONSTRAINT [PK_ParameterSet]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'ReturnTypeSet'
ALTER TABLE [dbo].[ReturnTypeSet]
ADD CONSTRAINT [PK_ReturnTypeSet]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'MemberSet'
ALTER TABLE [dbo].[MemberSet]
ADD CONSTRAINT [PK_MemberSet]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'MemberTypeSet'
ALTER TABLE [dbo].[MemberTypeSet]
ADD CONSTRAINT [PK_MemberTypeSet]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- --------------------------------------------------
-- Creating all FOREIGN KEY constraints
-- --------------------------------------------------

-- Creating foreign key on [AccessModifier_Id] in table 'ClassSet'
ALTER TABLE [dbo].[ClassSet]
ADD CONSTRAINT [FK_ClassAccessModifier]
    FOREIGN KEY ([AccessModifier_Id])
    REFERENCES [dbo].[AccessModifierSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ClassAccessModifier'
CREATE INDEX [IX_FK_ClassAccessModifier]
ON [dbo].[ClassSet]
    ([AccessModifier_Id]);
GO

-- Creating foreign key on [ClassId] in table 'MethodSet'
ALTER TABLE [dbo].[MethodSet]
ADD CONSTRAINT [FK_ClassMethod]
    FOREIGN KEY ([ClassId])
    REFERENCES [dbo].[ClassSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ClassMethod'
CREATE INDEX [IX_FK_ClassMethod]
ON [dbo].[MethodSet]
    ([ClassId]);
GO

-- Creating foreign key on [AccessModifierId] in table 'MethodSet'
ALTER TABLE [dbo].[MethodSet]
ADD CONSTRAINT [FK_MethodAccessModifier]
    FOREIGN KEY ([AccessModifierId])
    REFERENCES [dbo].[AccessModifierSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_MethodAccessModifier'
CREATE INDEX [IX_FK_MethodAccessModifier]
ON [dbo].[MethodSet]
    ([AccessModifierId]);
GO

-- Creating foreign key on [MethodId] in table 'ParameterSet'
ALTER TABLE [dbo].[ParameterSet]
ADD CONSTRAINT [FK_MethodParameter]
    FOREIGN KEY ([MethodId])
    REFERENCES [dbo].[MethodSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_MethodParameter'
CREATE INDEX [IX_FK_MethodParameter]
ON [dbo].[ParameterSet]
    ([MethodId]);
GO

-- Creating foreign key on [ClassId] in table 'ParameterSet'
ALTER TABLE [dbo].[ParameterSet]
ADD CONSTRAINT [FK_ClassParameter]
    FOREIGN KEY ([ClassId])
    REFERENCES [dbo].[ClassSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ClassParameter'
CREATE INDEX [IX_FK_ClassParameter]
ON [dbo].[ParameterSet]
    ([ClassId]);
GO

-- Creating foreign key on [ClassId] in table 'ClassSet'
ALTER TABLE [dbo].[ClassSet]
ADD CONSTRAINT [FK_ClassClass]
    FOREIGN KEY ([ClassId])
    REFERENCES [dbo].[ClassSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ClassClass'
CREATE INDEX [IX_FK_ClassClass]
ON [dbo].[ClassSet]
    ([ClassId]);
GO

-- Creating foreign key on [ClassId] in table 'ReturnTypeSet'
ALTER TABLE [dbo].[ReturnTypeSet]
ADD CONSTRAINT [FK_ClassReturnType]
    FOREIGN KEY ([ClassId])
    REFERENCES [dbo].[ClassSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ClassReturnType'
CREATE INDEX [IX_FK_ClassReturnType]
ON [dbo].[ReturnTypeSet]
    ([ClassId]);
GO

-- Creating foreign key on [ReturnTypeMethod_ReturnType_Id] in table 'ReturnTypeSet'
ALTER TABLE [dbo].[ReturnTypeSet]
ADD CONSTRAINT [FK_ReturnTypeMethod]
    FOREIGN KEY ([ReturnTypeMethod_ReturnType_Id])
    REFERENCES [dbo].[MethodSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ReturnTypeMethod'
CREATE INDEX [IX_FK_ReturnTypeMethod]
ON [dbo].[ReturnTypeSet]
    ([ReturnTypeMethod_ReturnType_Id]);
GO

-- Creating foreign key on [ClassId] in table 'MemberSet'
ALTER TABLE [dbo].[MemberSet]
ADD CONSTRAINT [FK_ClassMember]
    FOREIGN KEY ([ClassId])
    REFERENCES [dbo].[ClassSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ClassMember'
CREATE INDEX [IX_FK_ClassMember]
ON [dbo].[MemberSet]
    ([ClassId]);
GO

-- Creating foreign key on [AccessModifierId] in table 'MemberSet'
ALTER TABLE [dbo].[MemberSet]
ADD CONSTRAINT [FK_AccessModifierMember]
    FOREIGN KEY ([AccessModifierId])
    REFERENCES [dbo].[AccessModifierSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_AccessModifierMember'
CREATE INDEX [IX_FK_AccessModifierMember]
ON [dbo].[MemberSet]
    ([AccessModifierId]);
GO

-- Creating foreign key on [ClassId] in table 'MemberTypeSet'
ALTER TABLE [dbo].[MemberTypeSet]
ADD CONSTRAINT [FK_ClassMemberType]
    FOREIGN KEY ([ClassId])
    REFERENCES [dbo].[ClassSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ClassMemberType'
CREATE INDEX [IX_FK_ClassMemberType]
ON [dbo].[MemberTypeSet]
    ([ClassId]);
GO

-- Creating foreign key on [MemberType_Id] in table 'MemberSet'
ALTER TABLE [dbo].[MemberSet]
ADD CONSTRAINT [FK_MemberMemberType]
    FOREIGN KEY ([MemberType_Id])
    REFERENCES [dbo].[MemberTypeSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_MemberMemberType'
CREATE INDEX [IX_FK_MemberMemberType]
ON [dbo].[MemberSet]
    ([MemberType_Id]);
GO

-- --------------------------------------------------
-- Script has ended
-- --------------------------------------------------